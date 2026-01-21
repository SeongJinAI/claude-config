# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

[프로젝트명] - Spring Boot 기반 REST API 백엔드

## 빌드 및 실행 명령어

```bash
# 빌드
./gradlew build

# 로컬 실행
./gradlew bootRun

# 테스트 실행
./gradlew test

# 단일 테스트 실행
./gradlew test --tests "com.example.SomeTestClass"

# QueryDSL Q클래스 생성
./gradlew compileJava

# 클린 빌드
./gradlew clean build
```

## 아키텍처

### 기술 스택

- Java 21, Spring Boot 3.x, Gradle (Kotlin DSL)
- JPA + QueryDSL (+ MyBatis 선택적)
- MySQL/MariaDB/PostgreSQL
- Spring Security + JWT 인증
- Swagger/OpenAPI (springdoc-openapi)

### 패키지 구조

```
com.[회사명].[프로젝트명]
├── domain/           # 비즈니스 도메인 (DDD 스타일)
│   └── {도메인명}/
│       ├── controller/    # REST 엔드포인트
│       ├── dto/           # Request/Response DTO
│       ├── entity/        # JPA 엔티티
│       ├── repository/    # JPA 레포지토리
│       ├── service/       # 비즈니스 로직
│       └── specs/         # JPA Specifications
└── global/           # 공통 관심사
    ├── config/       # Spring 설정
    ├── enums/        # 공통 Enum
    ├── exception/    # 전역 예외 처리
    ├── response/     # API 응답 래퍼
    ├── security/     # JWT 인증
    └── util/         # 유틸리티
```

## 데이터 접근 패턴

### JPA Repository

JPQL 대신 메서드 네이밍 컨벤션 사용 권장:

```java
// 권장
List<User> findByStatusAndCreatedAtAfter(Status status, LocalDateTime date);

// 지양
@Query("SELECT u FROM User u WHERE u.status = :status")
List<User> findByStatus(@Param("status") Status status);
```

### QueryDSL

복잡한 동적 쿼리에 사용:

```java
// null 반환 시 조건 무시
private BooleanExpression statusEquals(Status status) {
    return status != null ? user.status.eq(status) : null;
}

// 빈 리스트 주의
private BooleanExpression codeIn(List<String> codes) {
    if (codes == null) return null;
    if (codes.isEmpty()) return Expressions.FALSE;
    return entity.code.in(codes);
}
```

### JPA Specifications

```java
public static Specification<User> statusEquals(Status status) {
    if (status == null) return null;
    return (root, query, cb) -> cb.equal(root.get("status"), status);
}
```

## API 응답 패턴

```java
ApiResponse.success(data)           // {success: true, message: "ok", data: ...}
ApiResponse.error(message)          // {success: false, message: "...", data: null}
```

## 페이지네이션 패턴

```java
// Controller: 프론트엔드 1-indexed → Service 0-indexed 변환
@GetMapping
public ResponseEntity<ApiResponse<PaginatedResponseDto<ItemDto>>> list(
    @RequestParam(defaultValue = "1") int page,
    @RequestParam(defaultValue = "20") int size
) {
    return ResponseEntity.ok(ApiResponse.success(service.getList(page - 1, size)));
}
```

## 인증

```java
@GetMapping("/example")
public ResponseEntity<ApiResponse<Void>> example(
    @AuthenticationPrincipal LoginUser loginUser
) {
    String userId = loginUser.userId();
}
```

## 에러 처리

```java
// 엔티티 없음 - 400
throw new IllegalArgumentException("ERR_NOT_FOUND_USER");

// 권한 없음 - 403
throw new IllegalStateException("ERR_UNAUTHORIZED");

// 비즈니스 에러
throw new BusinessException("ERR_INVALID_REQUEST");
```

에러 메시지: `ERR_` 접두사 + SCREAMING_SNAKE_CASE

## 네이밍 컨벤션

| 대상 | 패턴 | 예시 |
|------|------|------|
| 컨트롤러 | `*Controller` | `UserController` |
| 서비스 | `*Service` | `UserService` |
| DTO (요청) | `*Request` | `UserCreateRequest` |
| DTO (응답) | `*Response` | `UserListResponse` |

### 컨트롤러 메서드

| 작업 | 패턴 |
|------|------|
| 목록 | `{entity}List` |
| 상세 | `{entity}Detail` |
| 등록 | `{entity}Create` |
| 수정 | `{entity}Update` |
| 삭제 | `{entity}Delete` |

## 컨트롤러 컨벤션

```java
@Tag(name = "대분류 - 소분류")
@RestController
@RequestMapping("/domain/entity")
@RequiredArgsConstructor
public class EntityController {

    @Operation(summary = "목록 조회")
    @GetMapping
    public ResponseEntity<ApiResponse<List<Response>>> list(
            @AuthenticationPrincipal LoginUser loginUser,
            @Valid @ModelAttribute ListRequest request
    )
    {
        List<Response> response = service.getList(request);

        return ResponseEntity.ok(ApiResponse.success(response));
    }
}
```

## 엔티티 패턴

```java
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Builder
    private User(String name, String email) {
        this.name = name;
        this.email = email;
    }

    public static User from(UserCreateRequest request) {
        return User.builder()
            .name(request.name())
            .email(request.email())
            .build();
    }

    public void update(UserUpdateRequest request) {
        if (request.name() != null) this.name = request.name();
    }

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
```

## DTO 패턴

```java
// Request (record)
public record UserCreateRequest(
    @NotBlank(message = "ERR_REQUIRE_NAME")
    @Schema(description = "이름", example = "홍길동")
    String name
) {}

// Response
public record UserResponse(Long id, String name) {
    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getName());
    }
}
```

## Enum 패턴

```java
// 기본
@Enumerated(EnumType.STRING)
private Status status;

// DB 소문자 저장 시 Converter 사용
@Convert(converter = StatusConverter.class)
private Status status;
```

## 테스트 패턴

```java
@DisplayName("User API 테스트")
class UserControllerTest extends ApiTestSupport {

    @Nested
    @DisplayName("목록 조회")
    class ListTests {
        @Test
        @WithMockLoginUser
        @DisplayName("성공")
        void success() throws Exception {
            performGet("/users")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
        }
    }
}
```

## API 문서

- Swagger UI: `/swagger-ui/index.html`

## 기능 개발 체크리스트

- [ ] 기능명세서 작성
- [ ] ERROR_MESSAGES.md 업데이트
- [ ] 빌드 확인 (`./gradlew build`)

## 인수인계 (HANDOFF.md)

`/clear` 명령어 시 반드시 HANDOFF.md 업데이트

**IMPORTANT**: 인수인계 문서 업데이트는 **필수**입니다.
