---
description: 코드 분석 기반 명세서 자동 생성
---

# /gen-spec 명령어

코드를 분석하여 기능명세서 초안을 자동으로 생성합니다.

## 사용법

```bash
/gen-spec                           # 전체 프로젝트 명세서 생성
/gen-spec --module=order            # 특정 모듈만
/gen-spec --file=OrderController    # 특정 파일 기준
/gen-spec --update                  # 기존 명세서 업데이트
```

## 수행 작업

### 1. 코드 분석 (feature-dev:code-explorer 연계)

분석 대상:
- 엔드포인트 (Controller, Router)
- 서비스 레이어 (비즈니스 로직)
- 엔티티/모델 (데이터 구조)
- 설정 파일 (환경 변수, 상수)

### 2. 정보 추출

**Spring Boot 프로젝트:**
```java
// 추출 대상
@RestController
@RequestMapping("/api/orders")
public class OrderController {
    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(@RequestBody OrderRequest request)

    @GetMapping("/{id}")
    public ResponseEntity<OrderResponse> getOrder(@PathVariable Long id)
}
```

추출 정보:
- HTTP 메서드 및 경로
- 요청/응답 DTO 구조
- 검증 규칙 (@Valid, @NotNull 등)
- 예외 처리 (@ExceptionHandler)

**FastAPI 프로젝트:**
```python
# 추출 대상
@router.post("/orders", response_model=OrderResponse)
async def create_order(request: OrderRequest, db: Session = Depends(get_db)):
    ...
```

### 3. 명세서 템플릿 생성

출력 형식 (SPEC_TEMPLATE.md 기준):
```markdown
---
title: 주문 기능 명세서
module: order
version: 1.0.0
last_updated: 2024-01-15
endpoints:
  - POST /api/orders
  - GET /api/orders/{id}
entities:
  - Order
  - OrderItem
services:
  - OrderService
---

# 주문 기능 명세서

## 개요
[자동 생성된 개요 - 수동 보완 필요]

## API 엔드포인트

### POST /api/orders
- **설명**: 새 주문 생성
- **요청 본문**:
  ```json
  {
    "productId": "number (필수)",
    "quantity": "number (필수, 1 이상)",
    "shippingAddress": "string (필수)"
  }
  ```
- **응답**: OrderResponse
- **에러 코드**:
  - ERR_INVALID_REQUEST: 잘못된 요청
  - ERR_NOT_FOUND: 상품 없음

## 데이터 모델

### Order
| 필드 | 타입 | 설명 |
|-----|------|------|
| id | Long | 주문 ID |
| status | OrderStatus | 주문 상태 |
| createdAt | LocalDateTime | 생성일시 |

## TODO
- [ ] 비즈니스 규칙 상세 기술
- [ ] 시퀀스 다이어그램 추가
```

## 옵션 설명

| 옵션 | 설명 |
|-----|------|
| `--module=<name>` | 특정 모듈만 생성 |
| `--file=<name>` | 특정 파일 기준으로 생성 |
| `--update` | 기존 명세서에 누락된 항목만 추가 |
| `--output=<path>` | 출력 경로 지정 (기본: docs/specs/) |
| `--dry-run` | 실제 파일 생성 없이 미리보기 |

## 생성 후 안내

```
✅ 명세서 생성 완료: docs/specs/order.spec.md

📝 수동 보완 필요 항목:
  - [ ] 개요 섹션 상세화
  - [ ] 비즈니스 규칙 추가
  - [ ] 에러 시나리오 보완

💡 다음 단계:
  - /verify-docs 로 동기화 상태 확인
  - 생성된 명세서 검토 후 커밋
```

## 연계 명령어

- `/feature-dev:code-explorer` - 코드 분석 (내부 사용)
- `/verify-docs` - 생성된 문서 검증

**IMPORTANT**: 자동 생성된 명세서는 초안입니다. 반드시 사용자에게 수동 보완이 필요한 항목을 안내하세요.
