#!/bin/bash

# Claude Code Pre-commit Hook
# git commit 명령 실행 전에 코드 품질 검사를 수행합니다.
#
# 검사 항목:
# 1. 주석 존재 검사 (경고)
# 2. 사용하지 않는 코드 검사 (경고)
# 3. 코드 컨벤션 검사 (경고)

# stdin에서 JSON 읽기
INPUT=$(cat)

# JSON 파싱 (jq가 없으면 Python 사용, 둘 다 없으면 grep)
parse_json() {
    local key=$1
    if command -v jq &> /dev/null; then
        echo "$INPUT" | jq -r ".$key // \"\""
    elif command -v python3 &> /dev/null; then
        echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$key','') if '$key' not in ['tool_input.command','tool_input'] else (d.get('tool_input',{}).get('command','') if 'command' in '$key' else d.get('tool_input',{})))" 2>/dev/null
    else
        # 간단한 grep 기반 파싱
        echo "$INPUT" | grep -oP "\"$key\":\s*\"[^\"]*\"" | sed 's/.*"\([^"]*\)"$/\1/'
    fi
}

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

# git commit 명령인지 확인
if ! echo "$COMMAND" | grep -qE "^git commit"; then
    # git commit이 아니면 통과
    exit 0
fi

echo "🔍 Claude Code Pre-commit 검사 시작..." >&2

# 작업 디렉토리로 이동
cd "$CWD" 2>/dev/null || exit 0

# 프로젝트 타입 감지
detect_project_type() {
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "spring-boot"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "fastapi"
    elif [ -f "package.json" ]; then
        if grep -q "next" package.json 2>/dev/null; then
            echo "nextjs"
        else
            echo "node"
        fi
    else
        echo "unknown"
    fi
}

PROJECT_TYPE=$(detect_project_type)
WARNINGS=""
HAS_WARNINGS=false

# ============================================================
# 1. 주석 존재 검사
# ============================================================
check_comments() {
    echo "💬 주석 존재 검사..." >&2

    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)

    if [ -z "$STAGED_FILES" ]; then
        return 0
    fi

    COMMENTS_FOUND=""

    for file in $STAGED_FILES; do
        if [ ! -f "$file" ]; then
            continue
        fi

        case "$file" in
            *.java|*.js|*.jsx|*.ts|*.tsx|*.c|*.cpp|*.h|*.cs|*.go)
                FOUND=$(git diff --cached "$file" 2>/dev/null | grep "^+" | grep -v "^+++" | grep -E "(//|/\*)" || true)
                if [ -n "$FOUND" ]; then
                    COMMENTS_FOUND="$COMMENTS_FOUND\n  📄 $file"
                fi
                ;;
            *.py)
                FOUND=$(git diff --cached "$file" 2>/dev/null | grep "^+" | grep -v "^+++" | grep -E "(^[^#]*#|\"\"\")" || true)
                if [ -n "$FOUND" ]; then
                    COMMENTS_FOUND="$COMMENTS_FOUND\n  📄 $file"
                fi
                ;;
        esac
    done

    if [ -n "$COMMENTS_FOUND" ]; then
        WARNINGS="$WARNINGS\n⚠️  주석이 발견된 파일:$COMMENTS_FOUND"
        HAS_WARNINGS=true
    fi
}

# ============================================================
# 2. 사용하지 않는 코드 검사
# ============================================================
check_unused_code() {
    echo "🗑️  사용하지 않는 코드 검사..." >&2

    case $PROJECT_TYPE in
        spring-boot)
            # Java unused 코드는 컴파일 경고에서 확인 (시간이 오래 걸리므로 생략)
            # COMPILE_OUTPUT=$(./gradlew compileJava 2>&1 || true)
            # UNUSED=$(echo "$COMPILE_OUTPUT" | grep -iE "(unused|never used|is not used)" | head -5 || true)
            ;;
        fastapi)
            if command -v ruff &> /dev/null; then
                STAGED_PY=$(git diff --cached --name-only 2>/dev/null | grep "\.py$" || true)
                if [ -n "$STAGED_PY" ]; then
                    UNUSED=$(echo "$STAGED_PY" | xargs ruff check --select F401,F841 2>/dev/null | head -10 || true)
                    if [ -n "$UNUSED" ]; then
                        WARNINGS="$WARNINGS\n⚠️  Python unused 코드:\n$UNUSED"
                        HAS_WARNINGS=true
                    fi
                fi
            fi
            ;;
        nextjs|node)
            # ESLint 검사는 시간이 오래 걸리므로 생략
            ;;
    esac
}

# ============================================================
# 3. 코드 컨벤션 검사
# ============================================================
check_code_convention() {
    echo "📐 코드 컨벤션 검사..." >&2

    case $PROJECT_TYPE in
        spring-boot)
            # spotless 검사는 시간이 오래 걸리므로 생략
            ;;
        fastapi)
            if command -v ruff &> /dev/null; then
                STAGED_PY=$(git diff --cached --name-only 2>/dev/null | grep "\.py$" || true)
                if [ -n "$STAGED_PY" ]; then
                    FORMAT=$(echo "$STAGED_PY" | xargs ruff format --check 2>&1 || true)
                    if echo "$FORMAT" | grep -q "Would reformat"; then
                        WARNINGS="$WARNINGS\n⚠️  Python 포맷팅 필요 (ruff format 실행 필요)"
                        HAS_WARNINGS=true
                    fi
                fi
            fi
            ;;
        nextjs|node)
            # Prettier 검사는 시간이 오래 걸리므로 생략
            ;;
    esac
}

# ============================================================
# 검사 실행
# ============================================================
check_comments
check_unused_code
check_code_convention

# 결과 출력
if [ "$HAS_WARNINGS" = true ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo -e "$WARNINGS" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "💡 경고가 있지만 커밋을 진행합니다." >&2
    echo "   (차단하려면 이 훅을 수정하세요)" >&2
fi

echo "✅ Pre-commit 검사 완료!" >&2

# 경고만 표시하고 통과 (차단하려면 exit 2)
exit 0
