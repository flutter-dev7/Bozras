import type { ReactNode } from 'react'

import { ApiError } from '@/lib/api'
import { cn } from '@/lib/utils'

import type { Supplier } from './api'

export const inputClass = 'h-11 rounded-xl'

export function Field({ label, hint, children }: { label: string; hint?: string; children: ReactNode }) {
    return (
        <label className="block space-y-1.5">
            <span className="text-xs font-bold uppercase tracking-wide text-stone-500">{label}</span>
            {children}
            {hint && <span className="block text-xs text-stone-400">{hint}</span>}
        </label>
    )
}

export function SectionTitle({ children }: { children: ReactNode }) {
    return <p className="text-sm font-extrabold text-stone-800">{children}</p>
}

export function ErrorBox({ error }: { error: unknown }) {
    if (!error) return null

    const message =
        error instanceof ApiError || error instanceof Error ? error.message : 'Не удалось выполнить действие.'
    return (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{message}</div>
    )
}

export const money = (value: number) => `${new Intl.NumberFormat('ru-RU').format(value)} сом.`

const statusLabels: Record<string, string> = {
    Trial: 'Пробный период',
    Active: 'Подписка активна',
    PastDue: 'Просрочена',
    Suspended: 'Приостановлена',
}

export function subscriptionLabel(supplier: Supplier) {
    if (!supplier.isActive) return { text: 'Отключён', style: 'bg-stone-100 text-stone-600' }

    if (!supplier.isAccessAllowed) return { text: 'Доступ закрыт', style: 'bg-red-50 text-red-700' }

    return {
        text: statusLabels[supplier.subscriptionStatus] ?? supplier.subscriptionStatus,
        style:
            supplier.subscriptionStatus === 'Trial'
                ? 'bg-sky-50 text-sky-700'
                : 'bg-emerald-50 text-emerald-700',
    }
}

export function SubscriptionBadge({ supplier }: { supplier: Supplier }) {
    const { text, style } = subscriptionLabel(supplier)

    return <span className={cn('rounded-full px-2.5 py-1 text-xs font-bold', style)}>{text}</span>
}