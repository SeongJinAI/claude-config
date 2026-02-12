---
description: 사용자 피드백을 PR로 변환
---

# /feedback-to-pr 명령어

사용자 피드백을 수집/정리하고 개선사항을 PR로 자동 생성합니다.

## 사용법

```bash
/feedback-to-pr                           # 대화형 피드백 수집
/feedback-to-pr --file=feedback.md        # 피드백 파일에서 읽기
/feedback-to-pr --issue=123               # GitHub 이슈에서 읽기
/feedback-to-pr --dry-run                 # PR 생성 없이 미리보기
```

## 수행 작업

### 1. 피드백 수집

**대화형 모드:**
```
📝 피드백을 입력하세요 (빈 줄 2번으로 종료):

> 주문 취소 버튼이 너무 작아서 클릭하기 어렵습니다.
> 모바일에서 특히 문제가 됩니다.
>
>

피드백 분류 중...
```

**파일 입력 모드:**
```markdown
<!-- docs/feedback/2024-01-15.feedback.md -->
---
reporter: 김철수
date: 2024-01-15
category: UI/UX
priority: medium
---

## 피드백 내용
주문 취소 버튼이 너무 작아서 클릭하기 어렵습니다.
모바일에서 특히 문제가 됩니다.

## 재현 경로
1. 주문 상세 페이지 접근
2. 취소 버튼 확인
```

### 2. 피드백 분석 및 분류

분류 카테고리:
- **버그**: 기능이 의도대로 동작하지 않음
- **UI/UX**: 사용성 개선
- **기능 요청**: 새로운 기능 추가
- **성능**: 속도/리소스 관련
- **문서**: 문서 보완 필요

### 3. 개선 작업 도출

출력 형식:
```
📊 피드백 분석 결과
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 분류: UI/UX
📍 관련 모듈: order
🎯 우선순위: Medium

🔧 도출된 작업:
  1. 취소 버튼 크기 증가 (최소 44x44px)
  2. 모바일 반응형 스타일 추가
  3. 버튼 호버/포커스 상태 개선

📄 관련 파일:
  - src/components/OrderDetail.tsx
  - src/styles/order.css

계속 진행하시겠습니까? (y/n)
```

### 4. PR 생성 (commit-commands 연계)

자동 생성 흐름:
1. 피처 브랜치 생성: `feedback/order-cancel-button-ux`
2. 코드 수정 수행
3. 피드백 문서 업데이트
4. 커밋 생성
5. PR 생성

PR 템플릿:
```markdown
## Summary
- 주문 취소 버튼 UX 개선

## Changes
- 버튼 최소 크기 44x44px로 증가
- 모바일 반응형 스타일 추가

## Related
- Feedback: docs/feedback/2024-01-15.feedback.md
- Issue: #123

## Test Plan
- [ ] 데스크톱에서 버튼 클릭 테스트
- [ ] 모바일에서 터치 테스트
```

## 옵션 설명

| 옵션 | 설명 |
|-----|------|
| `--file=<path>` | 피드백 파일 경로 |
| `--issue=<number>` | GitHub 이슈 번호 |
| `--dry-run` | PR 생성 없이 분석 결과만 출력 |
| `--auto` | 확인 없이 자동 진행 |
| `--branch=<name>` | 브랜치명 직접 지정 |

## 피드백 문서 관리

피드백 처리 후 상태 업데이트:
```yaml
---
reporter: 김철수
date: 2024-01-15
category: UI/UX
priority: medium
status: resolved        # 추가됨
pr: "#456"              # 추가됨
resolved_date: 2024-01-16  # 추가됨
---
```

## 연계 명령어

- `/commit-push-pr` - PR 생성 (commit-commands 플러그인)
- `/verify-docs` - 변경 후 문서 동기화 확인

**IMPORTANT**: PR 생성 전 반드시 사용자에게 작업 내용을 확인받으세요. `--auto` 옵션 사용 시에도 주요 변경사항은 안내가 필요합니다.
