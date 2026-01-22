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
├── hooks/                        # Claude Code 훅
│   ├── pre-commit-hook.sh        # git commit 실행 전 검사
│   ├── pre-push-hook.sh          # git push 실행 전 검사
│   ├── pre-compact-hook.sh       # compact 실행 전 HANDOFF.md 알림
│   └── user-prompt-submit-hook.sh # /clear 명령 시 HANDOFF.md 알림
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

## Claude Code 훅

Claude Code에서 특정 이벤트 발생 시 자동으로 실행되는 스크립트입니다.

### 훅 설치

훅은 `~/.claude/hooks/` 디렉토리에 복사하고, `settings.json`에 등록해야 합니다:

```bash
# 훅 스크립트 복사
cp hooks/*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# settings.json은 install.sh로 자동 설치됨
```

### 훅 종류

| 훅 | 이벤트 | 트리거 | 기능 |
|----|--------|--------|------|
| `pre-commit-hook.sh` | `PreToolUse` | `git commit` 명령 | 주석, unused 코드, 컨벤션 검사 (경고) |
| `pre-push-hook.sh` | `PreToolUse` | `git push` 명령 | Claude 서명 감지, 보호 브랜치 경고 |
| `pre-compact-hook.sh` | `PreCompact` | `/compact` 또는 자동 compact | HANDOFF.md 업데이트 알림 |
| `user-prompt-submit-hook.sh` | `UserPromptSubmit` | `/clear` 명령 | HANDOFF.md 업데이트 알림 |

### 훅 이벤트 설명

- **PreToolUse**: Claude가 도구(Bash 등)를 실행하기 전
- **PreCompact**: 수동(`/compact`) 또는 자동 compact 실행 전
- **UserPromptSubmit**: 사용자가 프롬프트를 제출할 때

### settings.json 훅 설정

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "~/.claude/hooks/pre-commit-hook.sh" },
          { "type": "command", "command": "~/.claude/hooks/pre-push-hook.sh" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "~/.claude/hooks/user-prompt-submit-hook.sh" }
        ]
      }
    ],
    "PreCompact": [
      {
        "hooks": [
          { "type": "command", "command": "~/.claude/hooks/pre-compact-hook.sh" }
        ]
      }
    ]
  }
}
```

## 동기화

설정 변경 후 동기화:

```bash
./scripts/sync.sh
```

## 기여

PR 환영합니다!
