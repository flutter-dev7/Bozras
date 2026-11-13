import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Check, Copy, Loader2, RefreshCw } from 'lucide-react'
import { useState, type ReactNode } from 'react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { ErrorBox, Field, inputClass } from '@/features/superadmin/ui'
import { formatDate, toApiPhone } from '@/lib/format'
import { cn } from '@/lib/utils'

import { regenerateMyCode, updateSupplierProfile, type SupplierProfile } from './api'
import { useSupplierProfile } from './hooks'

const statusLabels: Record<string, string> = {
  Trial: 'Пробный период',
  Active: 'Подписка активна',
  PastDue: 'Просрочена',
  Suspended: 'Приостановлена',
}

function Section({ title, hint, children }: { title: string; hint?: string; children: ReactNode }) {
  return (
    <section className="rounded-2xl border bg-white p-5 shadow-sm">
      <div className="mb-4">
        <h2 className="text-base font-extrabold text-stone-900">{title}</h2>
        {hint && <p className="mt-0.5 text-sm text-stone-500">{hint}</p>}
      </div>
      {children}
    </section>
  )
}

export function daysLeft(endsAt: string | null): number | null {
  if (!endsAt) return null

  return Math.ceil((new Date(endsAt).getTime() - Date.now()) / 86_400_000)
}

export function ProfilePage() {
  const { data, isLoading, error } = useSupplierProfile()

  if (isLoading) {
    return (
      <div className="flex justify-center py-24">
        <Loader2 className="size-8 animate-spin text-primary" />
      </div>
    )
  }

  if (!data) {
    return (
      <div className="mx-auto max-w-3xl py-24">
        <ErrorBox error={error} />
      </div>
    )
  }

  return <ProfileContent key={data.id} profile={data} />
}

function ProfileContent({ profile }: { profile: SupplierProfile }) {
  const queryClient = useQueryClient()

  const [phone, setPhone] = useState(profile.phone ?? '')
  const [description, setDescription] = useState(profile.description ?? '')
  const [requiresApproval, setRequiresApproval] = useState(profile.requiresApproval)
  const [copied, setCopied] = useState(false)
  const [saved, setSaved] = useState(false)

  const refresh = () => queryClient.invalidateQueries({ queryKey: ['supplier'] })

  const save = useMutation({
    mutationFn: () =>
      updateSupplierProfile({
        phone: phone.trim() ? toApiPhone(phone) : null,
        description: description.trim() || null,
        requiresApproval,
      }),
    onSuccess: () => {
      setSaved(true)
      setTimeout(() => setSaved(false), 2500)
      refresh()
    },
  })

  const regenerate = useMutation({
    mutationFn: regenerateMyCode,
    onSuccess: refresh,
  })

  const copyCode = async () => {
    try {
      await navigator.clipboard.writeText(profile.code)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      setCopied(false)
    }
  }

  const askRegenerate = () => {
    if (window.confirm('Старый код перестанет работать. Новые магазины смогут подключиться только по новому. Продолжить?')) {
      regenerate.mutate()
    }
  }

  const days = daysLeft(profile.subscriptionEndsAt)
  const expiring = days !== null && days <= 7

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <div className="rounded-3xl border bg-gradient-to-br from-amber-50 to-orange-50 p-6">
        <h1 className="text-3xl font-extrabold text-[#3B2A1A]">{profile.name}</h1>
        <p className="mt-1 text-sm text-stone-600">Профиль поставщика</p>
      </div>

      <Section
        title="Код подключения"
        hint="Передайте код магазину: он введёт его в приложении и подключится к вам."
      >
        <div className="flex flex-wrap items-center gap-3">
          <div className="rounded-2xl bg-[#FFF3E2] px-6 py-3 font-mono text-3xl font-extrabold tracking-widest text-[#7A4E16]">
            {profile.code}
          </div>
          <Button variant="outline" className="h-11 rounded-xl" onClick={copyCode}>
            {copied ? <Check className="size-4" /> : <Copy className="size-4" />}
            {copied ? 'Скопировано' : 'Копировать'}
          </Button>
          <Button
            variant="outline"
            className="h-11 rounded-xl"
            disabled={regenerate.isPending}
            onClick={askRegenerate}
          >
            {regenerate.isPending ? (
              <Loader2 className="size-4 animate-spin" />
            ) : (
              <RefreshCw className="size-4" />
            )}
            Новый код
          </Button>
        </div>
        <div className="mt-3">
          <ErrorBox error={regenerate.error} />
        </div>
      </Section>

      <Section title="Подписка">
        <div className="grid gap-4 sm:grid-cols-3">
          <Info label="Статус" value={statusLabels[profile.subscriptionStatus] ?? profile.subscriptionStatus} />
          <Info label="Тариф" value={profile.planName ?? 'Не назначен'} />
          <Info
            label="Действует до"
            value={profile.subscriptionEndsAt ? formatDate(profile.subscriptionEndsAt) : 'Без ограничения'}
            tone={expiring ? 'text-red-600' : undefined}
            note={days !== null ? (days >= 0 ? `осталось ${days} дн.` : 'срок истёк') : undefined}
          />
        </div>
        <p className="mt-4 text-sm text-stone-500">Чтобы продлить подписку, свяжитесь с администратором сервиса.</p>
      </Section>

      <Section title="Данные поставщика">
        <div className="space-y-4">
          <Field label="Телефон">
            <Input className={inputClass} value={phone} onChange={(e) => setPhone(e.target.value)} />
          </Field>
          <Field label="Описание" hint="Магазины видят его в списке поставщиков">
            <Input
              className={inputClass}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              maxLength={500}
            />
          </Field>

          <label className="flex cursor-pointer items-start gap-2.5 text-sm font-semibold text-stone-700">
            <input
              type="checkbox"
              className="mt-0.5 size-4 accent-[#C8801A]"
              checked={requiresApproval}
              onChange={(e) => setRequiresApproval(e.target.checked)}
            />
            <span>
              Подтверждать магазины вручную
              <span className="block text-xs font-normal text-stone-500">
                Если выключено, магазин подключается сразу после ввода кода.
              </span>
            </span>
          </label>

          <ErrorBox error={save.error} />

          <div className="flex items-center gap-3">
            <Button className="h-11 rounded-xl px-6 font-bold" disabled={save.isPending} onClick={() => save.mutate()}>
              {save.isPending && <Loader2 className="size-4 animate-spin" />}
              Сохранить
            </Button>
            {saved && <span className="text-sm font-semibold text-emerald-600">Сохранено</span>}
          </div>
        </div>
      </Section>
    </div>
  )
}

function Info({ label, value, note, tone }: { label: string; value: string; note?: string; tone?: string }) {
  return (
    <div className="rounded-2xl bg-stone-50 p-4">
      <p className="text-xs font-bold uppercase tracking-wide text-stone-500">{label}</p>
      <p className={cn('mt-1 text-lg font-extrabold text-stone-900', tone)}>{value}</p>
      {note && <p className={cn('text-xs text-stone-500', tone)}>{note}</p>}
    </div>
  )
}