# 전역 Claude 설정

이 파일은 모든 프로젝트에 적용되는 전역 지침입니다.

## 응답 언어

항상 한국어로 응답합니다. 기술 용어와 코드 식별자는 원어 그대로 유지합니다.

## 공통 규칙

### 코드 작성

- 보안 취약점 주의 (OWASP Top 10)
- 과도한 엔지니어링 지양
- 요청된 변경만 수행

### 커밋 규칙

- 사용자 요청 시에만 커밋
- 커밋 메시지는 한글로 작성
- Co-Authored-By 포함

### 에러 메시지 컨벤션

`ERR_` 접두사 + SCREAMING_SNAKE_CASE 형식 사용:
- `ERR_NOT_FOUND` - 리소스 없음
- `ERR_UNAUTHORIZED` - 권한 없음
- `ERR_INVALID_REQUEST` - 잘못된 요청

## 인수인계 규칙 (HANDOFF.md)

`/clear` 명령어 입력 시 반드시 HANDOFF.md를 업데이트합니다.

**필수 기록 항목**:
1. 완료된 작업
2. 다음 작업
3. 주의사항
4. 관련 파일

**IMPORTANT**: `/clear` 명령어 시 HANDOFF.md 업데이트는 **필수**입니다.
