import { zodResolver } from '@hookform/resolvers/zod'
import { Eye, EyeOff, Loader2, Lock, Mail } from 'lucide-react'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link, Navigate } from 'react-router-dom'
import { z } from 'zod'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ApiError } from '@/lib/api'

import { AuthBrandPanel } from './auth-brand-panel'
import { useAuth } from './auth-context'

const schema = z.object({
  email: z.string().min(1, 'Введите email').email('Некорректный email'),
  password: z.string().min(1, 'Введите пароль'),
})

type FormValues = z.infer<typeof schema>

const fieldClass =
  'h-12 rounded-xl border-transparent bg-[#FFF3E2] pl-11 text-base focus-visible:bg-white'

export function LoginPage() {
  const { status, login } = useAuth()
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) })

  if (status === 'authed') return <Navigate to="/orders" replace />

  const onSubmit = async (values: FormValues) => {
    setError(null)

    try {
      await login(values.email.trim(), values.password)
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Не удалось войти.')
    }
  }

  return (
    <div className="grid min-h-screen lg:grid-cols-[1.1fr_1fr]">
      <AuthBrandPanel />

      <div className="relative flex items-center justify-center overflow-hidden bg-[#FFF8EE] p-6">
        <div className="pointer-events-none absolute -right-20 -top-20 size-80 rounded-full bg-[#C8801A]/15 blur-3xl" />
        <div className="pointer-events-none absolute -bottom-24 -left-16 size-80 rounded-full bg-[#7A4E16]/10 blur-3xl" />

        <div className="relative w-full max-w-md">
          <div className="mb-6 flex justify-center lg:hidden">
            <img src="/logo-full.png" alt="Bozras" className="h-16 w-auto" />
          </div>

          <div className="rounded-3xl bg-white p-8 shadow-xl shadow-amber-900/10 ring-1 ring-black/5 sm:p-10">
            <img
              src="/logo.png"
              alt="Bozras"
              className="mb-6 size-14 rounded-2xl shadow-lg shadow-amber-900/20"
            />

            <h1 className="text-3xl font-extrabold text-[#3B2A1A]">Добро пожаловать</h1>
            <p className="mt-2 text-stone-500">Войдите в панель администратора</p>

            <form onSubmit={handleSubmit(onSubmit)} className="mt-8 space-y-5" noValidate>
              <div className="space-y-2">
                <Label htmlFor="email" className="font-semibold text-[#3B2A1A]">
                  Email
                </Label>
                <div className="relative">
                  <Mail className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-stone-400" />
                  <Input
                    id="email"
                    type="email"
                    autoComplete="email"
                    autoFocus
                    placeholder="admin@example.com"
                    className={fieldClass}
                    disabled={isSubmitting}
                    {...register('email')}
                  />
                </div>
                {errors.email && <p className="text-sm text-red-600">{errors.email.message}</p>}
              </div>

              <div className="space-y-2">
                <Label htmlFor="password" className="font-semibold text-[#3B2A1A]">
                  Пароль
                </Label>
                <div className="relative">
                  <Lock className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-stone-400" />
                  <Input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="current-password"
                    placeholder="Введите пароль"
                    className={`${fieldClass} pr-12`}
                    disabled={isSubmitting}
                    {...register('password')}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute inset-y-0 right-0 flex w-12 items-center justify-center text-stone-500 hover:text-stone-800"
                    aria-label={showPassword ? 'Скрыть пароль' : 'Показать пароль'}
                  >
                    {showPassword ? <EyeOff className="size-5" /> : <Eye className="size-5" />}
                  </button>
                </div>
                {errors.password && (
                  <p className="text-sm text-red-600">{errors.password.message}</p>
                )}
              </div>

              <div className="-mt-2 text-right">
                <Link
                  to="/forgot-password"
                  className="text-sm font-semibold text-[#A8650F] hover:underline"
                >
                  Забыли пароль?
                </Link>
              </div>

              {error && (
                <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                  {error}
                </div>
              )}

              <Button
                type="submit"
                disabled={isSubmitting}
                className="h-12 w-full rounded-xl bg-gradient-to-r from-[#C8801A] to-[#A8650F] text-base font-bold text-white shadow-lg shadow-amber-900/20 hover:from-[#B87316] hover:to-[#965A0D]"
              >
                {isSubmitting && <Loader2 className="size-5 animate-spin" />}
                Войти
              </Button>
            </form>
          </div>

          <p className="mt-6 text-center text-sm text-stone-400">© Bozras · Панель администратора</p>
        </div>
      </div>
    </div>
  )
}