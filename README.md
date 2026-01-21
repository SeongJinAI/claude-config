# Claude Dotfiles

Claude Code 설정 및 템플릿 저장소

## 빠른 시작

### 전역 설정 설치

```bash
curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/install.sh | bash
```

### 프로젝트 템플릿 적용

```bash
# Spring Boot 프로젝트
curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/scripts/init-project.sh | bash -s spring-boot

# FastAPI 프로젝트
curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/scripts/init-project.sh | bash -s fastapi

# Next.js 프로젝트
curl -fsSL https://raw.githubusercontent.com/[YOUR_ID]/claude-dotfiles/main/scripts/init-project.sh | bash -s nextjs
```

## 구조

```
claude-dotfiles/
├── README.md
├── install.sh                    # 메인 설치 스크립트
│
├── global/                       # 사용자 전역 설정
│   ├── CLAUDE.md                 # 전역 지침
│   ├── settings.json
│   └── commands/
│       └── clear.md              # /clear 명령어
│
├── templates/                    # 프로젝트 템플릿
│   ├── spring-boot/
│   │   ├── CLAUDE.md
│   │   └── .claude/
│   ├── fastapi/
│   │   ├── CLAUDE.md
│   │   └── .claude/
│   └── nextjs/
│       ├── CLAUDE.md
│       └── .claude/
│
├── hooks/                        # Git 훅
│   ├── pre-commit                # 커밋 전 검사
│   ├── pre-push                  # 푸시 전 빌드/테스트
│   ├── commit-msg                # 커밋 메시지 검사
│   └── install-hooks.sh          # 훅 설치 스크립트
│
└── scripts/
    ├── init-project.sh           # 프로젝트 초기화
    └── sync.sh                   # 설정 동기화
```

## 설정 파일 설명

### global/settings.json

전역 Claude Code 설정:
- `language`: "Korean" - 한국어 응답
- `alwaysThinkingEnabled`: true - 사고 과정 표시
- `defaultMode`: "plan" - 계획 모드 기본값
- `permissions`: 자주 사용하는 명령어 허용 목록

### global/CLAUDE.md

모든 프로젝트에 적용되는 전역 지침:
- 응답 언어
- 공통 컨벤션
- 인수인계 규칙

### templates/*/CLAUDE.md

프레임워크별 프로젝트 지침:
- 빌드/실행 명령어
- 코딩 컨벤션
- 아키텍처 패턴
- 테스트 패턴

## 커스터마이징

### 새 템플릿 추가

1. `templates/[프레임워크명]/` 폴더 생성
2. `CLAUDE.md` 작성
3. 필요시 `.claude/` 폴더에 프로젝트별 설정 추가

### 명령어 추가

1. `global/commands/[명령어].md` 파일 생성
2. 명령어 프롬프트 작성

## Git 훅 설치

프로젝트에 Git 훅 설치:

```bash
# 현재 프로젝트에 설치
./hooks/install-hooks.sh

# 특정 프로젝트에 설치
./hooks/install-hooks.sh /path/to/project
```

### 훅 종류

| 훅 | 실행 시점 | 검사 내용 |
|----|----------|----------|
| `pre-commit` | 커밋 전 | 컴파일, 린트, 민감 정보, 파일 크기 |
| `pre-push` | 푸시 전 | 빌드, 테스트, 보호된 브랜치 확인 |
| `commit-msg` | 커밋 메시지 작성 후 | 메시지 길이, 형식 검사 |

### 훅 건너뛰기

```bash
git commit --no-verify
git push --no-verify
```

## 동기화

설정 변경 후 동기화:

```bash
./scripts/sync.sh
```

## 기여

PR 환영합니다!
