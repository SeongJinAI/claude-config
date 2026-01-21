#!/bin/bash

# Git 훅 설치 스크립트
# 사용법: ./install-hooks.sh [프로젝트 경로]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR=${1:-.}

# .git 폴더 확인
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "❌ Git 저장소가 아닙니다: $PROJECT_DIR"
    exit 1
fi

HOOKS_DIR="$PROJECT_DIR/.git/hooks"

echo "🔧 Git 훅 설치 중..."
echo "   프로젝트: $PROJECT_DIR"

# 훅 파일 복사
for hook in pre-commit pre-push commit-msg; do
    if [ -f "$SCRIPT_DIR/$hook" ]; then
        cp "$SCRIPT_DIR/$hook" "$HOOKS_DIR/$hook"
        chmod +x "$HOOKS_DIR/$hook"
        echo "   ✓ $hook 설치됨"
    fi
done

echo ""
echo "✅ Git 훅 설치 완료!"
echo ""
echo "💡 훅 비활성화 방법:"
echo "   git commit --no-verify"
echo "   git push --no-verify"
