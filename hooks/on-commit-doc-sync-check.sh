#!/bin/bash

# Claude Code Doc-Code Sync Check Hook
# git commit 명령 실행 시 코드 변경에 대응하는 문서 업데이트 여부 확인
#
# 트리거: PreToolUse (git commit)
# 동작: 코드 변경 시 관련 문서 업데이트 경고 출력

# stdin에서 JSON 읽기
INPUT=$(cat)

# JSON 파싱
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

# git commit 명령인지 확인
if ! echo "$COMMAND" | grep -qE "^git commit"; then
    exit 0
fi

echo "📄 문서-코드 동기화 검사 시작..." >&2

# 작업 디렉토리로 이동
cd "$CWD" 2>/dev/null || exit 0

# docs 디렉토리 존재 확인
if [ ! -d "docs" ]; then
    exit 0
fi

# 스테이징된 파일 목록
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)

if [ -z "$STAGED_FILES" ]; then
    exit 0
fi

# 코드 파일과 문서 파일 분리
CODE_FILES=""
DOC_FILES=""
WARNINGS=""

for file in $STAGED_FILES; do
    case "$file" in
        *.java|*.py|*.ts|*.tsx|*.js|*.jsx|*.go|*.rs)
            CODE_FILES="$CODE_FILES $file"
            ;;
        docs/*.md|*.spec.md|*.manual.md)
            DOC_FILES="$DOC_FILES $file"
            ;;
    esac
done

# 코드 변경이 있지만 문서 변경이 없는 경우 경고
if [ -n "$CODE_FILES" ] && [ -z "$DOC_FILES" ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "⚠️  코드 변경이 감지되었지만 문서 업데이트가 없습니다" >&2
    echo "" >&2
    echo "📝 변경된 코드 파일:" >&2
    for file in $CODE_FILES; do
        echo "   - $file" >&2
    done
    echo "" >&2

    # 관련될 수 있는 문서 찾기
    POTENTIAL_DOCS=""
    for file in $CODE_FILES; do
        # 파일명에서 모듈명 추출 (예: OrderController.java -> order)
        BASE_NAME=$(basename "$file" | sed 's/\.[^.]*$//' | sed 's/Controller$//' | sed 's/Service$//' | sed 's/Repository$//' | tr '[:upper:]' '[:lower:]')

        # 관련 문서 검색
        if [ -d "docs/specs" ]; then
            FOUND_DOC=$(find docs/specs -name "*${BASE_NAME}*" -type f 2>/dev/null | head -1)
            if [ -n "$FOUND_DOC" ]; then
                POTENTIAL_DOCS="$POTENTIAL_DOCS $FOUND_DOC"
            fi
        fi
    done

    if [ -n "$POTENTIAL_DOCS" ]; then
        echo "📚 업데이트가 필요할 수 있는 문서:" >&2
        for doc in $POTENTIAL_DOCS; do
            echo "   - $doc" >&2
        done
        echo "" >&2
    fi

    echo "💡 권장 조치:" >&2
    echo "   - 관련 문서 확인 및 업데이트" >&2
    echo "   - /verify-docs 명령으로 동기화 상태 확인" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
fi

# Controller/Router 변경 시 추가 경고
ENDPOINT_CHANGES=false
for file in $CODE_FILES; do
    case "$file" in
        *Controller*|*Router*|*router*|*api/*)
            ENDPOINT_CHANGES=true
            break
            ;;
    esac
done

if [ "$ENDPOINT_CHANGES" = true ]; then
    echo "⚠️  API 엔드포인트 변경이 감지되었습니다!" >&2
    echo "   - 기능명세서(specs) 업데이트를 확인하세요" >&2
    echo "   - 사용자메뉴얼(manuals) 업데이트가 필요할 수 있습니다" >&2
    echo "" >&2
fi

echo "✅ 문서-코드 동기화 검사 완료!" >&2

# 경고만 표시하고 통과 (차단하려면 exit 2)
exit 0
