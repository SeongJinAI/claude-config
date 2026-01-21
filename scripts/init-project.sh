#!/bin/bash

# 프로젝트 템플릿 초기화 스크립트
# 사용법: curl -fsSL .../init-project.sh | bash -s [spring-boot|fastapi|nextjs]

set -e

REPO_URL="https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main"
TEMPLATE=${1:-spring-boot}

echo "🚀 프로젝트 템플릿 적용: $TEMPLATE"

# 지원하는 템플릿 확인
case $TEMPLATE in
    spring-boot|fastapi|nextjs)
        ;;
    *)
        echo "❌ 지원하지 않는 템플릿: $TEMPLATE"
        echo "   지원 템플릿: spring-boot, fastapi, nextjs"
        exit 1
        ;;
esac

# CLAUDE.md 다운로드
echo "📥 CLAUDE.md 다운로드 중..."
if [ -f "CLAUDE.md" ]; then
    echo "⚠️  CLAUDE.md가 이미 존재합니다. 백업 생성..."
    cp CLAUDE.md CLAUDE.md.backup
fi
curl -fsSL "$REPO_URL/templates/$TEMPLATE/CLAUDE.md" -o CLAUDE.md

# HANDOFF.md 생성 (없는 경우)
if [ ! -f "HANDOFF.md" ]; then
    echo "📥 HANDOFF.md 생성 중..."
    cat > HANDOFF.md << 'EOF'
# HANDOFF - 컨텍스트 인수인계

> 이 문서는 컨텍스트 리셋 시 작업 상태를 기록합니다.
> 새로운 컨텍스트 시작 시 가장 최신 엔트리를 참고하세요.

---

## YYYY.MM.DD HH:mm (가장 최신)

### 완료된 작업
- (아직 없음)

### 현재 상태
- 초기 설정 완료

### 다음 작업
- [ ] 프로젝트 시작

### 주의사항
- 특이사항 없음

---
EOF
fi

# .claude 폴더 생성
mkdir -p .claude

echo ""
echo "✅ 템플릿 적용 완료!"
echo ""
echo "📁 생성된 파일:"
echo "   - CLAUDE.md"
echo "   - HANDOFF.md"
echo "   - .claude/"
echo ""
echo "💡 다음 단계:"
echo "   1. CLAUDE.md에서 [프로젝트명] 등 플레이스홀더 수정"
echo "   2. 프로젝트 특화 도메인 정보 추가"
echo ""
