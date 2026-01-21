# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

[프로젝트명] - FastAPI 기반 REST API 백엔드

## 빌드 및 실행 명령어

```bash
# 가상환경 활성화
cd backend
source venv/bin/activate

# 의존성 설치
pip install -r requirements.txt

# 개발 서버 실행
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 테스트 실행
pytest

# 단일 테스트 실행
pytest tests/test_file.py::test_name

# DB 마이그레이션 적용
alembic upgrade head

# 마이그레이션 생성
alembic revision --autogenerate -m "설명"
```

## 아키텍처

### 기술 스택

- Python 3.11+, FastAPI
- SQLAlchemy 2.0 (async)
- PostgreSQL
- Pydantic v2
- JWT 인증

### 패키지 구조

```
app/
├── api/
│   ├── v1/           # 라우트 핸들러
│   │   ├── auth.py
│   │   ├── users.py
│   │   └── ...
│   └── deps.py       # FastAPI 의존성 (get_db, get_current_user)
├── services/         # 비즈니스 로직
├── models/           # SQLAlchemy ORM 모델
├── schemas/          # Pydantic 스키마
├── core/             # 설정, 상수, 보안
├── db/               # 데이터베이스 설정
└── main.py           # 앱 진입점
```

## 데이터 접근 패턴

### SQLAlchemy Async

```python
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

async def get_user_by_id(db: AsyncSession, user_id: int) -> User | None:
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()

async def get_users_by_status(db: AsyncSession, status: str) -> list[User]:
    result = await db.execute(
        select(User)
        .where(User.status == status)
        .order_by(User.created_at.desc())
    )
    return list(result.scalars().all())
```

### 동적 쿼리

```python
async def get_users(
    db: AsyncSession,
    status: str | None = None,
    name: str | None = None
) -> list[User]:
    query = select(User)

    if status:
        query = query.where(User.status == status)
    if name:
        query = query.where(User.name.contains(name))

    result = await db.execute(query)
    return list(result.scalars().all())
```

## 의존성 주입 패턴

### 타입 별칭 사용

```python
# api/deps.py
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

async def get_current_user(
    db: DBSession,
    token: str = Depends(oauth2_scheme)
) -> User:
    # 토큰 검증 및 사용자 조회
    ...

DBSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
OptionalUser = Annotated[User | None, Depends(get_current_user_optional)]
```

### 라우터에서 사용

```python
from app.api.deps import CurrentUser, DBSession

@router.get("/me")
async def get_me(user: CurrentUser, db: DBSession):
    return user
```

## API 응답 패턴

### Pydantic 스키마

```python
from pydantic import BaseModel

class UserResponse(BaseModel):
    id: int
    name: str
    email: str

    model_config = {"from_attributes": True}

class UserListResponse(BaseModel):
    items: list[UserResponse]
    total: int
```

### 에러 응답

```python
from fastapi import HTTPException, status

# 엔티티 없음
raise HTTPException(
    status_code=status.HTTP_404_NOT_FOUND,
    detail="ERR_NOT_FOUND_USER"
)

# 권한 없음
raise HTTPException(
    status_code=status.HTTP_403_FORBIDDEN,
    detail="ERR_UNAUTHORIZED"
)

# 잘못된 요청
raise HTTPException(
    status_code=status.HTTP_400_BAD_REQUEST,
    detail="ERR_INVALID_REQUEST"
)
```

## 서비스 레이어 패턴

```python
# services/user_service.py
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import User
from app.schemas.user import UserCreate, UserUpdate

class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, data: UserCreate) -> User:
        user = User(**data.model_dump())
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def update(self, user: User, data: UserUpdate) -> User:
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(user, key, value)
        await self.db.commit()
        await self.db.refresh(user)
        return user
```

## 라우터 컨벤션

```python
from fastapi import APIRouter, status
from app.api.deps import CurrentUser, DBSession
from app.schemas.user import UserCreate, UserResponse

router = APIRouter(prefix="/users", tags=["사용자"])

@router.get("", response_model=list[UserResponse])
async def user_list(
    db: DBSession,
    user: CurrentUser,
    status: str | None = None
):
    """사용자 목록 조회"""
    return await user_service.get_list(db, status=status)

@router.get("/{user_id}", response_model=UserResponse)
async def user_detail(
    user_id: int,
    db: DBSession,
    user: CurrentUser
):
    """사용자 상세 조회"""
    return await user_service.get_by_id(db, user_id)

@router.post("", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def user_create(
    data: UserCreate,
    db: DBSession,
    user: CurrentUser
):
    """사용자 생성"""
    return await user_service.create(db, data)
```

## Pydantic 스키마 패턴

```python
from pydantic import BaseModel, EmailStr, Field

class UserBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

class UserUpdate(BaseModel):
    name: str | None = None
    email: EmailStr | None = None

class UserResponse(UserBase):
    id: int
    created_at: datetime

    model_config = {"from_attributes": True}
```

## 백그라운드 작업

```python
from fastapi import BackgroundTasks

@router.post("/notify")
async def send_notification(
    background_tasks: BackgroundTasks,
    user: CurrentUser
):
    background_tasks.add_task(send_email, user.email)
    return {"message": "작업이 예약되었습니다"}
```

## 에러 메시지 컨벤션

`ERR_` 접두사 + SCREAMING_SNAKE_CASE:
- `ERR_NOT_FOUND` - 리소스 없음
- `ERR_UNAUTHORIZED` - 권한 없음
- `ERR_INVALID_REQUEST` - 잘못된 요청
- `ERR_ALREADY_EXISTS` - 이미 존재

## 테스트 패턴

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_user_list(client: AsyncClient, auth_headers: dict):
    response = await client.get("/v1/users", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

@pytest.mark.asyncio
async def test_user_create(client: AsyncClient, auth_headers: dict):
    response = await client.post(
        "/v1/users",
        json={"name": "테스트", "email": "test@example.com", "password": "password123"},
        headers=auth_headers
    )
    assert response.status_code == 201
```

## API 문서

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 환경 변수

```bash
DATABASE_URL=postgresql+asyncpg://user:pass@localhost:5432/dbname
JWT_SECRET=your-secret-key
JWT_ALGORITHM=HS256
```

## 기능 개발 체크리스트

- [ ] 기능명세서 작성
- [ ] ERROR_MESSAGES.md 업데이트
- [ ] 테스트 작성
- [ ] 마이그레이션 생성 (DB 변경 시)

## 인수인계 (HANDOFF.md)

`/clear` 명령어 시 반드시 HANDOFF.md 업데이트

**IMPORTANT**: 인수인계 문서 업데이트는 **필수**입니다.
