#!/bin/bash

# Claude Code Pre-push Hook
# git push 명령 실행 전에 Claude 서명을 검사합니다.
#
# 검사 항목:
# 1. Claude Co-Authored-By 서명 존재 확인
# 2. 서명 발견 시 경고 표시

# stdin에서 JSON 읽기
INPUT=$(cat)

# tool_input.command 추출 (중첩 JSON)
get_command() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.tool_input.command // ""'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null
    else
        echo "$INPUT" | grep -oP '"command":\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

get_cwd() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.cwd // "."'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd','.'))" 2>/dev/null
    else
        echo "$INPUT" | grep -oP '"cwd":\s*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

COMMAND=$(get_command)
CWD=$(get_cwd)

# git push 명령인지 확인
if ! echo "$COMMAND" | grep -qE "^git push"; then
    # git push가 아니면 통과
    exit 0
fi

echo "🚀 Claude Code Pre-push 검사 시작..." >&2

# 작업 디렉토리로 이동
cd "$CWD" 2>/dev/null || exit 0

# ============================================================
# Claude 서명 검사
# ============================================================
check_claude_signature() {
    echo "🤖 Claude 서명 검사 중..." >&2

    # 현재 브랜치
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    # 원격 브랜치 확인
    REMOTE_BRANCH="origin/$CURRENT_BRANCH"

    # 원격에 브랜치가 있는지 확인
    if git rev-parse --verify "$REMOTE_BRANCH" &>/dev/null; then
        # 기존 브랜치: 원격에 없는 로컬 커밋만 확인
        COMMIT_RANGE="$REMOTE_BRANCH..HEAD"
    else
        # 새 브랜치: main/master에서 분기된 커밋 확인
        BASE_BRANCH="origin/main"
        if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
            BASE_BRANCH="origin/master"
        fi
        if ! git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
            echo "   ⚠️  기준 브랜치를 찾을 수 없습니다." >&2
            return 0
        fi
        COMMIT_RANGE="$BASE_BRANCH..HEAD"
    fi

    # Claude 서명이 포함된 커밋 찾기
    CLAUDE_COMMITS=$(git log --format="%H %s" "$COMMIT_RANGE" --grep="Co-Authored-By: Claude" 2>/dev/null || true)

    if [ -z "$CLAUDE_COMMITS" ]; then
        echo "   ✓ Claude 서명이 없습니다." >&2
        return 0
    fi

    # 서명이 발견된 커밋 수
    COMMIT_COUNT=$(echo "$CLAUDE_COMMITS" | wc -l | tr -d ' ')

    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "⚠️  Claude 서명이 포함된 커밋 ${COMMIT_COUNT}개 발견:" >&2
    echo "" >&2
    echo "$CLAUDE_COMMITS" | head -10 | while read hash msg; do
        echo "   📝 ${hash:0:7} - $msg" >&2
    done
    echo "" >&2
    echo "💡 서명을 제거하려면 다음 명령을 실행하세요:" >&2
    echo "   git rebase -i ${COMMIT_RANGE%%..HEAD}~" >&2
    echo "   (각 커밋에서 Co-Authored-By: Claude... 라인 삭제)" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2

    # 경고만 표시하고 통과 (차단하려면 return 1)
    return 0
}

# ============================================================
# 보호된 브랜치 확인
# ============================================================
check_protected_branch() {
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    PROTECTED_BRANCHES=("main" "master" "production")

    for branch in "${PROTECTED_BRANCHES[@]}"; do
        if [ "$CURRENT_BRANCH" == "$branch" ]; then
            echo "" >&2
            echo "⚠️  경고: 보호된 브랜치($branch)에 직접 푸시하려고 합니다." >&2
            echo "   PR을 통해 머지하는 것을 권장합니다." >&2
            echo "" >&2
            # 경고만 표시 (차단하려면 return 1)
            return 0
        fi
    done
    return 0
}

# ============================================================
# 검사 실행
# ============================================================
check_protected_branch
check_claude_signature

echo "✅ Pre-push 검사 완료! 푸시를 진행합니다." >&2

# 통과
exit 0
