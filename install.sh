#!/bin/bash

# Claude Dotfiles 설치 스크립트
# 사용법: curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/install.sh | bash

set -e

REPO_URL="https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main"
CLAUDE_DIR="$HOME/.claude"

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
curl -fsSL "$REPO_URL/hooks/pre-commit-hook.sh" -o "$CLAUDE_DIR/hooks/pre-commit-hook.sh"
curl -fsSL "$REPO_URL/hooks/pre-push-hook.sh" -o "$CLAUDE_DIR/hooks/pre-push-hook.sh"
curl -fsSL "$REPO_URL/hooks/pre-compact-hook.sh" -o "$CLAUDE_DIR/hooks/pre-compact-hook.sh"
curl -fsSL "$REPO_URL/hooks/user-prompt-submit-hook.sh" -o "$CLAUDE_DIR/hooks/user-prompt-submit-hook.sh"
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
