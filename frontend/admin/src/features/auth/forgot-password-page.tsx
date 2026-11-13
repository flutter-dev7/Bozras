import { ArrowLeft, CheckCircle2, Loader2, Lock, Mail } from 'lucide-react'
import { useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ApiError } from '@/lib/api'

import { forgotPassword, resetPassword, verifyResetCode } from './api'
import { AuthBrandPanel } from './auth-brand-panel'
import { OtpInput } from './otp-input'

type Step = 'email' | 'code' | 'password' | 'done'

const fieldClass =
  'h-12 rounded-xl border-transparent bg-[#FFF3E2] pl-11 text-base focus-visible:bg-white'

const buttonClass =
  'h-12 w-full rounded-xl bg-gradient-to-r from-[#C8801A] to-[#A8650F] text-base font-bold text-white shadow-lg shadow-amber-900/20 hover:from-[#B87316] hover:to-[#965A0D]'

const titles: Record<Step, { title: string; text: string }> = {
  email: {
    title: 'Восстановление пароля',
    text: 'Введите email, мы отправим код подтверждения.',
  },
  code: { title: 'Введите код', text: 'Мы отправили 6-значный код на вашу почту.' },
  password: { title: 'Новый пароль', text: 'Придумайте новый пароль для входа.' },
  done: { title: 'Пароль изменён', text: 'Теперь можно войти с новым паролем.' },
}

export function ForgotPasswordPage() {
  const navigate = useNavigate()

  const [step, setStep] = useState<Step>('email')
  const [email, setEmail] = useState('')
  const [code, setCode] = useState('')
  const [resetToken, setResetToken] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const run = async (action: () => Promise<void>) => {
    setError(null)
    setLoading(true)

    try {
      await action()
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Не удалось выполнить запрос.')
    } finally {
      setLoading(false)
    }
  }

  const onEmail = (e: FormEvent) => {
    e.preventDefault()

    if (!email.trim()) return setError('Введите email')

    run(async () => {
      await forgotPassword(email.trim())
      setCode('')
      setStep('code')
    })
  }

  const onCode = (e: FormEvent) => {
    e.preventDefault()

    if (code.length !== 6) return setError('Введите 6 цифр из письма')

    run(async () => {
      setResetToken(await verifyResetCode(email.trim(), code))
      setStep('password')
    })
  }

  const onPassword = (e: FormEvent) => {
    e.preventDefault()

    if (password !== confirm) return setError('Пароли не совпадают')

    run(async () => {
      await resetPassword(resetToken, password)
      setStep('done')
    })
  }

  const resend = () =>
    run(async () => {
      await forgotPassword(email.trim())
      setCode('')
    })

  const { title, text } = titles[step]

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

            <h1 className="text-3xl font-extrabold text-[#3B2A1A]">{title}</h1>
            <p className="mt-2 text-stone-500">{text}</p>

            {step === 'email' && (
              <form onSubmit={onEmail} className="mt-8 space-y-5" noValidate>
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
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      disabled={loading}
                    />
                  </div>
                </div>

                <ErrorBox error={error} />

                <Button type="submit" disabled={loading} className={buttonClass}>
                  {loading && <Loader2 className="size-5 animate-spin" />}
                  Получить код
                </Button>
              </form>
            )}

            {step === 'code' && (
              <form onSubmit={onCode} className="mt-8 space-y-5" noValidate>
                <div className="space-y-3">
                  <Label className="font-semibold text-[#3B2A1A]">Код из письма</Label>
                  <OtpInput value={code} onChange={setCode} disabled={loading} />
                  <p className="text-sm text-stone-500">
                    Письмо отправлено на {email}. Проверьте папку «Спам».
                  </p>
                </div>

                <ErrorBox error={error} />

                <Button type="submit" disabled={loading} className={buttonClass}>
                  {loading && <Loader2 className="size-5 animate-spin" />}
                  Продолжить
                </Button>

                <button
                  type="button"
                  onClick={resend}
                  disabled={loading}
                  className="w-full text-sm font-semibold text-[#A8650F] hover:underline disabled:opacity-50"
                >
                  Отправить код ещё раз
                </button>
              </form>
            )}

            {step === 'password' && (
              <form onSubmit={onPassword} className="mt-8 space-y-5" noValidate>
                <div className="space-y-2">
                  <Label htmlFor="password" className="font-semibold text-[#3B2A1A]">
                    Новый пароль
                  </Label>
                  <div className="relative">
                    <Lock className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-stone-400" />
                    <Input
                      id="password"
                      type="password"
                      autoComplete="new-password"
                      autoFocus
                      className={fieldClass}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      disabled={loading}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="confirm" className="font-semibold text-[#3B2A1A]">
                    Повторите пароль
                  </Label>
                  <div className="relative">
                    <Lock className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-stone-400" />
                    <Input
                      id="confirm"
                      type="password"
                      autoComplete="new-password"
                      className={fieldClass}
                      value={confirm}
                      onChange={(e) => setConfirm(e.target.value)}
                      disabled={loading}
                    />
                  </div>
                </div>

                <ErrorBox error={error} />

                <Button type="submit" disabled={loading} className={buttonClass}>
                  {loading && <Loader2 className="size-5 animate-spin" />}
                  Сохранить пароль
                </Button>
              </form>
            )}

            {step === 'done' && (
              <div className="mt-8 space-y-5">
                <div className="flex justify-center">
                  <CheckCircle2 className="size-16 text-green-600" />
                </div>

                <Button
                  className={buttonClass}
                  onClick={() => navigate('/login', { replace: true })}
                >
                  Войти
                </Button>
              </div>
            )}

            {step !== 'done' && (
              <Link
                to="/login"
                className="mt-6 flex items-center justify-center gap-2 text-sm font-semibold text-stone-500 hover:text-stone-800"
              >
                <ArrowLeft className="size-4" />
                Назад ко входу
              </Link>
            )}
          </div>

          <p className="mt-6 text-center text-sm text-stone-400">
            © Bozras · Панель администратора
          </p>
        </div>
      </div>
    </div>
  )
}

function ErrorBox({ error }: { error: string | null }) {
  if (!error) return null

  return (
    <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
      {error}
    </div>
  )
}