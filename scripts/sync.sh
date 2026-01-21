#!/bin/bash

# 설정 동기화 스크립트
# 로컬 변경사항을 저장소에 동기화하거나, 저장소에서 최신 설정을 가져옵니다.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"

show_help() {
    echo "사용법: ./sync.sh [push|pull]"
    echo ""
    echo "  push  - 로컬 설정을 저장소로 복사"
    echo "  pull  - 저장소 설정을 로컬로 복사"
    echo ""
}

sync_push() {
    echo "📤 로컬 설정을 저장소로 동기화..."

    # settings.json
    if [ -f "$CLAUDE_DIR/settings.json" ]; then
        cp "$CLAUDE_DIR/settings.json" "$DOTFILES_DIR/global/settings.json"
        echo "   ✓ settings.json"
    fi

    # commands
    if [ -d "$CLAUDE_DIR/commands" ]; then
        cp -r "$CLAUDE_DIR/commands/"* "$DOTFILES_DIR/global/commands/" 2>/dev/null || true
        echo "   ✓ commands/"
    fi

    echo ""
    echo "✅ 동기화 완료! git commit & push를 실행하세요."
}

sync_pull() {
    echo "📥 저장소 설정을 로컬로 동기화..."

    # settings.json
    if [ -f "$DOTFILES_DIR/global/settings.json" ]; then
        cp "$DOTFILES_DIR/global/settings.json" "$CLAUDE_DIR/settings.json"
        echo "   ✓ settings.json"
    fi

    # commands
    mkdir -p "$CLAUDE_DIR/commands"
    if [ -d "$DOTFILES_DIR/global/commands" ]; then
        cp -r "$DOTFILES_DIR/global/commands/"* "$CLAUDE_DIR/commands/" 2>/dev/null || true
        echo "   ✓ commands/"
    fi

    echo ""
    echo "✅ 동기화 완료!"
}

case ${1:-help} in
    push)
        sync_push
        ;;
    pull)
        sync_pull
        ;;
    *)
        show_help
        ;;
esac
