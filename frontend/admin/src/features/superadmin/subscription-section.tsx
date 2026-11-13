import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Loader2, Wallet } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { NativeSelect } from '@/components/ui/native-select'
import { formatDate } from '@/lib/format'

import { fetchPayments, PAYMENT_METHODS, recordPayment, type Plan, type Supplier } from './api'
import { ErrorBox, Field, SectionTitle, SubscriptionBadge, inputClass, money } from './ui'

export function SubscriptionSection({ supplier, plans }: { supplier: Supplier; plans: Plan[] }) {
  const queryClient = useQueryClient()

  const [open, setOpen] = useState(false)
  const [months, setMonths] = useState(1)
  const [planId, setPlanId] = useState(supplier.planId ?? '')
  const [amount, setAmount] = useState<string | null>(null)
  const [method, setMethod] = useState(PAYMENT_METHODS[0].value)
  const [note, setNote] = useState('')

  const { data: payments = [], isLoading } = useQuery({
    queryKey: ['superadmin', 'payments', supplier.id],
    queryFn: () => fetchPayments(supplier.id),
  })

  const plan = plans.find((p) => p.id === planId)
  const suggested = (plan?.pricePerMonth ?? 0) * months
  const amountValue = amount ?? (suggested ? String(suggested) : '')

  const save = useMutation({
    mutationFn: () =>
      recordPayment(supplier.id, {
        amount: Number(amountValue),
        method,
        months,
        planId: planId || null,
        note: note.trim(),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['superadmin', 'payments', supplier.id] })
      queryClient.invalidateQueries({ queryKey: ['superadmin', 'supplier', supplier.id] })
      queryClient.invalidateQueries({ queryKey: ['superadmin', 'suppliers'] })
      setOpen(false)
      setAmount(null)
      setNote('')
      setMonths(1)
    },
  })

  const canSave = Number(amountValue) > 0 && !save.isPending

  return (
    <div className="space-y-3 rounded-2xl border bg-stone-50/60 p-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <SectionTitle>Подписка</SectionTitle>
          <div className="mt-1.5 flex flex-wrap items-center gap-2 text-sm text-stone-600">
            <SubscriptionBadge supplier={supplier} />
            {supplier.subscriptionEndsAt && <span>до {formatDate(supplier.subscriptionEndsAt)}</span>}
            {supplier.planName && <span>· тариф «{supplier.planName}»</span>}
          </div>
        </div>
        {!open && (
          <Button type="button" variant="outline" className="rounded-xl bg-white" onClick={() => setOpen(true)}>
            <Wallet className="size-4" />
            Записать оплату
          </Button>
        )}
      </div>

      {open && (
        <div className="space-y-4 rounded-2xl border bg-white p-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Тариф">
              <NativeSelect
                className="h-11 w-full rounded-xl"
                value={planId}
                onChange={(e) => {
                  setPlanId(e.target.value)
                  setAmount(null)
                }}
              >
                <option value="">Без тарифа</option>
                {plans.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </NativeSelect>
            </Field>
            <Field label="Срок, месяцев">
              <Input
                type="number"
                min={1}
                max={24}
                className={inputClass}
                value={months}
                onChange={(e) => {
                  setMonths(Math.min(24, Math.max(1, Number(e.target.value) || 1)))
                  setAmount(null)
                }}
              />
            </Field>
            <Field label="Сумма, сом." hint={suggested ? `По тарифу: ${money(suggested)}` : undefined}>
              <Input
                type="number"
                min={0}
                className={inputClass}
                value={amountValue}
                onChange={(e) => setAmount(e.target.value)}
              />
            </Field>
            <Field label="Способ оплаты">
              <NativeSelect className="h-11 w-full rounded-xl" value={method} onChange={(e) => setMethod(e.target.value)}>
                {PAYMENT_METHODS.map((m) => (
                  <option key={m.value} value={m.value}>
                    {m.label}
                  </option>
                ))}
              </NativeSelect>
            </Field>
            <div className="sm:col-span-2">
              <Field label="Заметка">
                <Input className={inputClass} value={note} onChange={(e) => setNote(e.target.value)} />
              </Field>
            </div>
          </div>

          <ErrorBox error={save.error} />

          <div className="flex justify-end gap-3">
            <Button type="button" variant="outline" className="rounded-xl" onClick={() => setOpen(false)}>
              Отмена
            </Button>
            <Button type="button" className="rounded-xl font-bold" disabled={!canSave} onClick={() => save.mutate()}>
              {save.isPending && <Loader2 className="size-4 animate-spin" />}
              Записать
            </Button>
          </div>
        </div>
      )}

      <div className="space-y-1.5">
        {isLoading && <p className="text-sm text-stone-400">Загрузка...</p>}

        {!isLoading && payments.length === 0 && <p className="text-sm text-stone-400">Оплат пока нет.</p>}

        {payments.map((p) => (
          <div key={p.id} className="flex flex-wrap items-center justify-between gap-2 rounded-xl bg-white px-3 py-2 text-sm">
            <span className="font-bold text-stone-800">{money(p.amount)}</span>
            <span className="text-stone-500">
              {formatDate(p.periodFrom)} — {formatDate(p.periodTo)}
              {p.planName ? ` · ${p.planName}` : ''}
            </span>
            <span className="text-xs text-stone-400">{formatDate(p.createdAt)}</span>
          </div>
        ))}
      </div>
    </div>
  )
}