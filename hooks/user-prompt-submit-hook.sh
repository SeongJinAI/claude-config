#!/bin/bash

# Claude Code UserPromptSubmit Hook
# /clear 명령 감지 시 HANDOFF.md 작성을 알립니다.
# (/compact는 PreCompact 훅에서 처리)
#
# 이벤트: UserPromptSubmit
# 트리거: 사용자 프롬프트 제출 시

# stdin에서 JSON 읽기
INPUT=$(cat)

# prompt 추출
get_prompt() {
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r '.prompt // ""'
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('prompt',''))" 2>/dev/null
    else
        echo "$INPUT" | grep -oP '"prompt":\s*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/'
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

PROMPT=$(get_prompt)
CWD=$(get_cwd)

# /clear 명령인지 확인 (/compact는 PreCompact 훅에서 처리)
if echo "$PROMPT" | grep -qE "^/clear"; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🧹 /clear 명령 감지 - HANDOFF.md 업데이트 알림" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2

    # 작업 디렉토리로 이동
    cd "$CWD" 2>/dev/null

    # HANDOFF.md 존재 여부 확인
    if [ -f "HANDOFF.md" ]; then
        # 마지막 수정 시간 확인
        LAST_MODIFIED=$(stat -c %Y HANDOFF.md 2>/dev/null || stat -f %m HANDOFF.md 2>/dev/null || echo 0)
        CURRENT_TIME=$(date +%s)
        DIFF=$((CURRENT_TIME - LAST_MODIFIED))

        # 10분(600초) 이내에 수정되었는지 확인
        if [ "$DIFF" -lt 600 ]; then
            echo "✅ HANDOFF.md가 최근에 업데이트되었습니다. (${DIFF}초 전)" >&2
        else
            echo "⚠️  HANDOFF.md가 오래되었습니다!" >&2
            echo "" >&2
            echo "💡 /compact 또는 /clear 전에 다음 내용을 포함하세요:" >&2
            echo "   - 완료된 작업" >&2
            echo "   - 다음 작업" >&2
            echo "   - 주의사항" >&2
            echo "   - 관련 파일" >&2
        fi
    else
        echo "⚠️  HANDOFF.md가 존재하지 않습니다!" >&2
        echo "" >&2
        echo "💡 프로젝트 루트에 HANDOFF.md를 생성하세요." >&2
    fi

    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
fi

# 항상 통과 (알림만)
exit 0
