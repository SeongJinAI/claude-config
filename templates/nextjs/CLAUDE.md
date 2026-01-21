# CLAUDE.md

이 파일은 Claude Code가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

[프로젝트명] - Next.js 기반 프론트엔드

## 빌드 및 실행 명령어

```bash
# 의존성 설치
npm install

# 개발 서버 실행
npm run dev

# 프로덕션 빌드
npm run build

# 프로덕션 서버 실행
npm run start

# 린트 검사
npm run lint

# 타입 검사
npx tsc --noEmit
```

## 아키텍처

### 기술 스택

- Next.js 14 (App Router)
- React 18
- TypeScript
- TailwindCSS
- Zustand (상태 관리)

### 패키지 구조

```
src/
├── app/                  # App Router 페이지
│   ├── (auth)/           # 인증 관련 페이지 (로그인 등)
│   ├── (main)/           # 메인 페이지 (대시보드 등)
│   ├── layout.tsx        # 루트 레이아웃
│   └── page.tsx          # 홈페이지
├── components/
│   ├── ui/               # 재사용 UI 컴포넌트
│   └── {feature}/        # 기능별 컴포넌트
├── lib/
│   ├── api/              # API 클라이언트
│   └── utils/            # 유틸리티 함수
├── stores/               # Zustand 스토어
├── types/                # TypeScript 타입
└── styles/               # 전역 스타일
```

## App Router 패턴

### 페이지 구조

```
app/
├── layout.tsx            # 루트 레이아웃
├── page.tsx              # / 경로
├── loading.tsx           # 로딩 UI
├── error.tsx             # 에러 UI
├── (auth)/               # 그룹 (URL에 영향 없음)
│   ├── login/
│   │   └── page.tsx      # /login
│   └── layout.tsx        # 인증 레이아웃
└── dashboard/
    ├── page.tsx          # /dashboard
    └── [id]/
        └── page.tsx      # /dashboard/[id]
```

### 서버 컴포넌트 vs 클라이언트 컴포넌트

```tsx
// 서버 컴포넌트 (기본)
export default async function Page() {
  const data = await fetchData(); // 서버에서 직접 호출
  return <div>{data.title}</div>;
}

// 클라이언트 컴포넌트
'use client';

import { useState } from 'react';

export default function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

## API 클라이언트 패턴

### Axios 설정

```typescript
// lib/api/client.ts
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  headers: { 'Content-Type': 'application/json' }
});

// 요청 인터셉터 (토큰 추가)
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 응답 인터셉터 (토큰 갱신)
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // 토큰 갱신 로직
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### API 함수

```typescript
// lib/api/users.ts
import apiClient from './client';
import { User, UserCreate } from '@/types/user';

export const userApi = {
  getList: () => apiClient.get<User[]>('/users'),
  getById: (id: number) => apiClient.get<User>(`/users/${id}`),
  create: (data: UserCreate) => apiClient.post<User>('/users', data),
  update: (id: number, data: Partial<UserCreate>) =>
    apiClient.patch<User>(`/users/${id}`, data),
  delete: (id: number) => apiClient.delete(`/users/${id}`)
};
```

## 상태 관리 (Zustand)

```typescript
// stores/auth.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  user: User | null;
  token: string | null;
  setUser: (user: User | null) => void;
  setToken: (token: string | null) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      setUser: (user) => set({ user }),
      setToken: (token) => set({ token }),
      logout: () => set({ user: null, token: null })
    }),
    { name: 'auth-storage' }
  )
);
```

## 컴포넌트 패턴

### UI 컴포넌트

```tsx
// components/ui/Button.tsx
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

export function Button({
  variant = 'primary',
  size = 'md',
  loading,
  children,
  disabled,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded font-medium',
        variantStyles[variant],
        sizeStyles[size],
        loading && 'opacity-50 cursor-not-allowed'
      )}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? <Spinner /> : children}
    </button>
  );
}
```

### 폼 컴포넌트

```tsx
// components/forms/UserForm.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { userSchema, UserFormData } from '@/lib/validations/user';

export function UserForm({ onSubmit }: { onSubmit: (data: UserFormData) => void }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting }
  } = useForm<UserFormData>({
    resolver: zodResolver(userSchema)
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('name')} />
      {errors.name && <span>{errors.name.message}</span>}
      <Button type="submit" loading={isSubmitting}>저장</Button>
    </form>
  );
}
```

## 타입 정의

```typescript
// types/user.ts
export interface User {
  id: number;
  name: string;
  email: string;
  createdAt: string;
}

export interface UserCreate {
  name: string;
  email: string;
  password: string;
}

// API 응답 타입
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

export interface PaginatedResponse<T> {
  items: T[];
  pagination: {
    page: number;
    limit: number;
    totalRecord: number;
    totalPage: number;
  };
}
```

## 네이밍 컨벤션

| 대상 | 컨벤션 | 예시 |
|------|--------|------|
| 컴포넌트 | PascalCase | `UserCard.tsx` |
| 훅 | camelCase (use 접두사) | `useAuth.ts` |
| 유틸리티 | camelCase | `formatDate.ts` |
| 타입 | PascalCase | `User`, `ApiResponse` |
| 상수 | SCREAMING_SNAKE_CASE | `API_BASE_URL` |

## 환경 변수

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
```

`NEXT_PUBLIC_` 접두사: 클라이언트에서 접근 가능

## 테스트 패턴

```typescript
// __tests__/components/Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from '@/components/ui/Button';

describe('Button', () => {
  it('클릭 시 onClick 호출', async () => {
    const onClick = jest.fn();
    render(<Button onClick={onClick}>클릭</Button>);

    await userEvent.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it('loading 상태에서 비활성화', () => {
    render(<Button loading>클릭</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## 기능 개발 체크리스트

- [ ] 컴포넌트 작성
- [ ] 타입 정의
- [ ] API 연동
- [ ] 린트/타입 검사 통과

## 인수인계 (HANDOFF.md)

`/clear` 명령어 시 반드시 HANDOFF.md 업데이트

**IMPORTANT**: 인수인계 문서 업데이트는 **필수**입니다.
