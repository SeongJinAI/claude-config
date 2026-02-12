#!/bin/bash

# Claude Dotfiles 설치 스크립트
# 사용법:
#   로컬 (심볼릭 링크): ./install.sh --link /path/to/claude-dotfiles
#   원격 (다운로드):      curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/install.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main"
CLAUDE_DIR="$HOME/.claude"

# Hook 파일 목록
HOOK_FILES=(
    "on-commit-quality-check.sh"
    "on-commit-doc-sync-check.sh"
    "on-push-signature-check.sh"
    "on-compact-handoff-save.sh"
    "on-prompt-handoff-remind.sh"
    "on-prompt-api-dev-guide.sh"
)

# ─── 심볼릭 링크 모드 (로컬 개발용) ───
if [ "$1" = "--link" ]; then
    DOTFILES_DIR="${2:-.}"
    DOTFILES_DIR=$(cd "$DOTFILES_DIR" && pwd)

    echo "🔗 심볼릭 링크 모드: $DOTFILES_DIR"

    # hooks 디렉토리 심볼릭 링크
    if [ -L "$CLAUDE_DIR/hooks" ]; then
        echo "⚠️  기존 심볼릭 링크 제거..."
        rm "$CLAUDE_DIR/hooks"
    elif [ -d "$CLAUDE_DIR/hooks" ]; then
        echo "⚠️  기존 hooks 디렉토리 백업 → hooks.backup/"
        mv "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/hooks.backup"
    fi

    ln -s "$DOTFILES_DIR/hooks" "$CLAUDE_DIR/hooks"
    echo "✅ ~/.claude/hooks → $DOTFILES_DIR/hooks"
    echo ""
    echo "📁 연결된 Hook 스크립트:"
    for f in "${HOOK_FILES[@]}"; do
        if [ -f "$CLAUDE_DIR/hooks/$f" ]; then
            echo "   ✓ $f"
        else
            echo "   ✗ $f (없음)"
        fi
    done
    exit 0
fi

# ─── 다운로드 모드 (원격 설치용) ───
echo "🚀 Claude Dotfiles 설치 시작..."

# ~/.claude 디렉토리 생성
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/commands"

# 전역 설정 다운로드
echo "📥 전역 설정 다운로드 중..."

# settings.json
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    echo "⚠️  settings.json이 이미 존재합니다. 백업 생성..."
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.backup"
fi
curl -fsSL "$REPO_URL/global/settings.json" -o "$CLAUDE_DIR/settings.json"

# 전역 CLAUDE.md (사용자 홈에 설치 - 선택적)
# curl -fsSL "$REPO_URL/global/CLAUDE.md" -o "$HOME/CLAUDE.md"

# 커스텀 명령어 다운로드
echo "📥 커스텀 명령어 다운로드 중..."
curl -fsSL "$REPO_URL/global/commands/clear.md" -o "$CLAUDE_DIR/commands/clear.md" 2>/dev/null || true

# 훅 스크립트 다운로드
echo "📥 Claude Code 훅 다운로드 중..."
mkdir -p "$CLAUDE_DIR/hooks"
for f in "${HOOK_FILES[@]}"; do
    curl -fsSL "$REPO_URL/hooks/$f" -o "$CLAUDE_DIR/hooks/$f" 2>/dev/null || echo "  ⚠️ $f 다운로드 실패 (스킵)"
done
chmod +x "$CLAUDE_DIR/hooks/"*.sh

echo ""
echo "✅ 설치 완료!"
echo ""
echo "📁 설치된 파일:"
echo "   - $CLAUDE_DIR/settings.json"
echo "   - $CLAUDE_DIR/commands/"
echo "   - $CLAUDE_DIR/hooks/"
echo ""
echo "💡 프로젝트 템플릿 적용:"
echo "   curl -fsSL $REPO_URL/scripts/init-project.sh | bash -s spring-boot"
echo "   curl -fsSL $REPO_URL/scripts/init-project.sh | bash -s fastapi"
echo ""
