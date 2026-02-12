---
description: 문서-코드 일치 검증
---

# /verify-docs 명령어

기능명세서, 사용자메뉴얼, 도메인문서와 코드베이스 간의 동기화 상태를 검증합니다.

## 사용법

```bash
/verify-docs                    # 전체 검증
/verify-docs --module=order     # 특정 모듈만 검증
/verify-docs --reverse          # 코드에만 있고 문서에 없는 항목 검색
```

## 수행 작업

### 1. 문서 스캔 및 메타데이터 파싱

문서 디렉토리 구조:
```
docs/
├── specs/       # 기능명세서 (*.spec.md)
├── manuals/     # 사용자메뉴얼 (*.manual.md)
└── domain/      # 도메인 특성 문서
```

각 문서의 YAML 프론트매터에서 메타데이터 추출:
```yaml
---
title: 주문 기능 명세서
module: order
endpoints:
  - POST /api/orders
  - GET /api/orders/{id}
entities:
  - Order
  - OrderItem
services:
  - OrderService
  - PaymentService
---
```

### 2. 코드베이스 검색

프로젝트 타입에 따른 검색:

**Spring Boot:**
- `@RestController`, `@RequestMapping` 어노테이션으로 엔드포인트 검색
- `@Entity` 어노테이션으로 엔티티 검색
- `@Service` 어노테이션으로 서비스 검색

**FastAPI:**
- `@app.get`, `@app.post` 등 라우터 데코레이터 검색
- SQLAlchemy/Pydantic 모델 검색

**Next.js:**
- `app/api/` 또는 `pages/api/` 라우트 검색
- Prisma/TypeORM 모델 검색

### 3. 불일치 항목 리포트 생성

출력 형식:
```
📋 문서-코드 동기화 검증 결과
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ 일치 항목: 15개
⚠️  문서에만 있는 항목: 3개
❌ 코드에만 있는 항목: 2개

📄 문서에만 있는 항목 (문서 업데이트 또는 구현 필요):
  - POST /api/orders/cancel (specs/order.spec.md:45)
  - RefundService (specs/order.spec.md:23)

🔧 코드에만 있는 항목 (문서 추가 필요):
  - GET /api/orders/export (OrderController.java:89)
  - NotificationService (NotificationService.java:1)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 권장 조치: /gen-spec 명령으로 누락된 문서 생성
```

## 옵션 설명

| 옵션 | 설명 |
|-----|------|
| `--module=<name>` | 특정 모듈만 검증 |
| `--reverse` | 코드 기준으로 문서 누락 항목만 검색 |
| `--strict` | 불일치 시 경고 대신 에러 반환 |
| `--output=json` | JSON 형식으로 출력 |

## 연계 명령어

- `/gen-spec` - 누락된 문서 자동 생성
- `/project-chat` - 문서 기반 Q&A

**IMPORTANT**: 검증 결과에서 불일치 항목이 발견되면 반드시 사용자에게 조치 방법을 안내하세요.
