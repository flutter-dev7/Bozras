import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { ArrowLeft, CircleCheck, Loader2, MapPin, Phone, Store, User } from 'lucide-react'
import { useEffect, useState, type ReactNode } from 'react'
import { Link, useParams } from 'react-router-dom'

import { LocationPicker, type GeoPoint } from '@/components/location-picker'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect } from '@/components/ui/native-select'
import type { PaymentMethod } from '@/features/orders/types'
import { createPayment, fetchPayments, reversePayment } from '@/features/payments/api'
import { ApiError } from '@/lib/api'
import { formatDate, formatDateTime, money, toApiPhone } from '@/lib/format'
import { cn } from '@/lib/utils'

import { fetchShop, fetchShopBalance, setDebtLimit, setShopLocation, setShopOwner, updateShop } from './api'

const methodLabels: Record<PaymentMethod, string> = {
  Cash: 'Наличные',
  Transfer: 'Перевод',
}

function errorMessage(e: unknown): string {
  return e instanceof ApiError ? e.message : 'Не удалось выполнить действие.'
}

function Section({
  title,
  hint,
  children,
}: {
  title: string
  hint?: string
  children: ReactNode
}) {
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

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="space-y-1.5">
      <Label className="text-xs font-bold uppercase tracking-wide text-stone-500">{label}</Label>
      {children}
    </div>
  )
}

function Stat({ label, value, tone }: { label: string; value: string; tone?: string }) {
  return (
    <div className="rounded-2xl border bg-white p-4 shadow-sm">
      <p className="text-xs font-bold uppercase tracking-wide text-stone-500">{label}</p>
      <p className={cn('mt-1.5 text-2xl font-extrabold text-stone-900', tone)}>{value}</p>
    </div>
  )
}

export function ShopPage() {
  const { id = '' } = useParams()
  const queryClient = useQueryClient()

  const shopQuery = useQuery({
    queryKey: ['shops', 'detail', id],
    queryFn: () => fetchShop(id),
    enabled: id !== '',
  })
  const balanceQuery = useQuery({
    queryKey: ['shops', 'balance', id],
    queryFn: () => fetchShopBalance(id),
    enabled: id !== '',
  })
  const paymentsQuery = useQuery({
    queryKey: ['payments', id],
    queryFn: () => fetchPayments(id),
    enabled: id !== '',
  })

  const [payAmount, setPayAmount] = useState('')
  const [payMethod, setPayMethod] = useState<PaymentMethod>('Cash')
  const [payOrder, setPayOrder] = useState('')
  const [limitInput, setLimitInput] = useState<string | null>(null)
  const [ownerInput, setOwnerInput] = useState('')
  const [reversing, setReversing] = useState<{ id: string; reason: string } | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  const [location, setLocation] = useState<GeoPoint | null | undefined>(undefined)

  const [edit, setEdit] = useState<{
    name: string
    address: string
    phone: string
    contact: string
    isActive: boolean
  } | null>(null)

  useEffect(() => {
    if (!notice) return

    const timer = setTimeout(() => setNotice(null), 3500)

    return () => clearTimeout(timer)
  }, [notice])

  useEffect(() => {
    if (!error) return

    const timer = setTimeout(() => setError(null), 7000)

    return () => clearTimeout(timer)
  }, [error])

  const done = (message: string) => {
    setError(null)
    setNotice(message)
    queryClient.invalidateQueries({ queryKey: ['shops'] })
    queryClient.invalidateQueries({ queryKey: ['debts'] })
    queryClient.invalidateQueries({ queryKey: ['payments'] })
  }

  const fail = (e: unknown) => {
    setNotice(null)
    setError(errorMessage(e))
  }

  const payMutation = useMutation({
    mutationFn: () =>
      createPayment({
        shopId: id,
        orderId: payOrder || undefined,
        amount: Number(payAmount.replace(',', '.')),
        method: payMethod,
      }),
    onSuccess: () => {
      setPayAmount('')
      setPayOrder('')
      done('Оплата принята')
    },
    onError: fail,
  })

  const limitMutation = useMutation({
    mutationFn: (value: number | null) => setDebtLimit(id, value),
    onSuccess: () => {
      setLimitInput(null)
      done('Лимит долга сохранён')
    },
    onError: fail,
  })

  const ownerMutation = useMutation({
    mutationFn: () => setShopOwner(id, toApiPhone(ownerInput)),
    onSuccess: () => {
      setOwnerInput('')
      done('Владелец привязан')
    },
    onError: fail,
  })

  const locationMutation = useMutation({
    mutationFn: (point: GeoPoint | null) =>
      setShopLocation(id, point?.lat ?? null, point?.lng ?? null),
    onSuccess: () => {
      setLocation(undefined)
      done('Расположение сохранено')
    },
    onError: fail,
  })

  const updateMutation = useMutation({
    mutationFn: () => {
      const v = edit!

      return updateShop(id, {
        name: v.name.trim(),
        address: v.address.trim(),
        phone: toApiPhone(v.phone),
        contactName: v.contact.trim() || undefined,
        isActive: v.isActive,
      })
    },
    onSuccess: () => {
      setEdit(null)
      done('Данные магазина сохранены')
    },
    onError: fail,
  })

  const reverseMutation = useMutation({
    mutationFn: (v: { id: string; reason: string }) => reversePayment(v.id, v.reason),
    onSuccess: () => {
      setReversing(null)
      done('Оплата отменена')
    },
    onError: fail,
  })

  const shop = shopQuery.data
  const balance = balanceQuery.data

  if (shopQuery.isLoading || balanceQuery.isLoading) {
    return (
      <div className="flex justify-center py-24">
        <Loader2 className="size-8 animate-spin text-primary" />
      </div>
    )
  }

  if (!shop || !balance) {
    return (
      <div className="mx-auto max-w-6xl py-24 text-center">
        <p className="font-semibold text-red-600">
          {errorMessage(shopQuery.error ?? balanceQuery.error)}
        </p>
        <Button variant="outline" className="mt-4" render={<Link to="/shops" />}>
          К списку магазинов
        </Button>
      </div>
    )
  }

  const limitValue = limitInput ?? (shop.debtLimit !== null ? String(shop.debtLimit) : '')
  const limitChanged = limitInput !== null && limitInput !== (shop.debtLimit?.toString() ?? '')
  const payNumber = Number(payAmount.replace(',', '.'))
  const payValid = Number.isFinite(payNumber) && payNumber > 0
  const overLimit = balance.debtLimit !== null && balance.debt > balance.debtLimit
  const payments = paymentsQuery.data?.items ?? []

  const savedPoint: GeoPoint | null =
    shop.latitude !== null && shop.longitude !== null
      ? { lat: shop.latitude, lng: shop.longitude }
      : null
  const shownPoint = location === undefined ? savedPoint : location

  const form = edit ?? {
    name: shop.name,
    address: shop.address,
    phone: shop.phone,
    contact: shop.contactName ?? '',
    isActive: shop.isActive,
  }
  const patchForm = (patch: Partial<typeof form>) => setEdit({ ...form, ...patch })
  const canSaveShop =
    edit !== null && edit.name.trim() !== '' && edit.address.trim() !== '' && edit.phone.trim() !== ''

  const saveLimit = () => {
    const text = limitValue.trim()

    if (text === '') return limitMutation.mutate(null)

    const value = Number(text.replace(',', '.'))

    if (!Number.isFinite(value) || value < 0) return setError('Введите корректный лимит.')

    limitMutation.mutate(value)
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div className="relative overflow-hidden rounded-3xl border bg-gradient-to-br from-amber-50 to-orange-50 p-6">
        <div className="pointer-events-none absolute -right-10 -top-10 size-40 rounded-full bg-[#C8801A]/15 blur-2xl" />

        <Link
          to="/shops"
          className="relative inline-flex items-center gap-1.5 text-sm font-semibold text-stone-500 hover:text-stone-800"
        >
          <ArrowLeft className="size-4" />
          Магазины
        </Link>

        <div className="relative mt-4 flex flex-wrap items-center gap-4">
          <div className="flex size-14 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-[#7A4E16] to-[#C8801A] text-white shadow-lg shadow-amber-900/20">
            <Store className="size-7" />
          </div>

          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-3">
              <h1 className="truncate text-3xl font-extrabold text-[#3B2A1A]">{shop.name}</h1>
              <span
                className={cn(
                  'rounded-full px-3 py-1 text-xs font-bold',
                  shop.isActive ? 'bg-emerald-100 text-emerald-700' : 'bg-stone-200 text-stone-600',
                )}
              >
                {shop.isActive ? 'Активен' : 'Отключён'}
              </span>
            </div>

            <div className="mt-1.5 flex flex-wrap items-center gap-x-5 gap-y-1 text-sm text-stone-600">
              <span className="inline-flex items-center gap-1.5">
                <MapPin className="size-4" />
                {shop.address}
              </span>
              <a
                href={`tel:${shop.phone}`}
                className="inline-flex items-center gap-1.5 font-semibold text-primary hover:underline"
              >
                <Phone className="size-4" />
                {shop.phone}
              </a>
              {shop.contactName && (
                <span className="inline-flex items-center gap-1.5">
                  <User className="size-4" />
                  {shop.contactName}
                </span>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <Stat
          label="Долг"
          value={money(balance.debt)}
          tone={balance.debt > 0 ? 'text-red-600' : undefined}
        />
        <Stat label="Доставлено" value={money(balance.deliveredTotal)} />
        <Stat label="Оплачено" value={money(balance.paidTotal)} />
        <Stat
          label="Лимит долга"
          value={balance.debtLimit !== null ? money(balance.debtLimit) : 'Нет'}
          tone={overLimit ? 'text-red-600' : undefined}
        />
      </div>

      {overLimit && (
        <p className="rounded-2xl border border-red-200 bg-red-50 px-5 py-3 text-sm font-semibold text-red-700">
          Долг превышает установленный лимит
        </p>
      )}

      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1fr)_380px]">
        <div className="space-y-6">
          <Section title="Данные магазина">
            <div className="grid gap-4 sm:grid-cols-2">
              <Field label="Название">
                <Input
                  value={form.name}
                  onChange={(e) => patchForm({ name: e.target.value })}
                  className="h-10"
                />
              </Field>
              <Field label="Телефон">
                <Input
                  value={form.phone}
                  onChange={(e) => patchForm({ phone: e.target.value })}
                  className="h-10"
                />
              </Field>
              <Field label="Адрес">
                <Input
                  value={form.address}
                  onChange={(e) => patchForm({ address: e.target.value })}
                  className="h-10"
                />
              </Field>
              <Field label="Контактное лицо">
                <Input
                  value={form.contact}
                  onChange={(e) => patchForm({ contact: e.target.value })}
                  className="h-10"
                />
              </Field>
            </div>

            <div className="mt-4 flex flex-wrap items-center gap-3">
              <div className="inline-flex gap-1 rounded-xl bg-stone-100 p-1">
                {[true, false].map((value) => (
                  <button
                    key={String(value)}
                    type="button"
                    onClick={() => patchForm({ isActive: value })}
                    className={cn(
                      'rounded-lg px-4 py-1.5 text-sm font-bold transition-all',
                      form.isActive === value
                        ? 'bg-white text-stone-900 shadow-sm'
                        : 'text-stone-500 hover:text-stone-800',
                    )}
                  >
                    {value ? 'Активен' : 'Отключён'}
                  </button>
                ))}
              </div>

              <Button
                className="h-10 font-bold"
                disabled={!canSaveShop || updateMutation.isPending}
                onClick={() => updateMutation.mutate()}
              >
                {updateMutation.isPending && <Loader2 className="size-4 animate-spin" />}
                Сохранить изменения
              </Button>
              {edit && (
                <Button variant="ghost" className="h-10" onClick={() => setEdit(null)}>
                  Сбросить
                </Button>
              )}
            </div>
          </Section>

          <Section title="Расположение на карте" hint="Нажмите на карту, чтобы поставить точку.">
            <LocationPicker value={shownPoint} onChange={setLocation} className="h-80" />

            <div className="mt-3 flex flex-wrap items-center gap-3">
              <Button
                className="h-10 font-bold"
                disabled={location === undefined || locationMutation.isPending}
                onClick={() => locationMutation.mutate(location ?? null)}
              >
                {locationMutation.isPending && <Loader2 className="size-4 animate-spin" />}
                Сохранить точку
              </Button>
              <Button
                variant="outline"
                className="h-10"
                disabled={shownPoint === null || locationMutation.isPending}
                onClick={() => setLocation(null)}
              >
                Убрать точку
              </Button>
              {location !== undefined && (
                <Button variant="ghost" className="h-10" onClick={() => setLocation(undefined)}>
                  Сбросить
                </Button>
              )}
            </div>
          </Section>
        </div>

        <div className="space-y-6">
          <Section
            title="Принять оплату"
            hint={balance.debt > 0 ? `Текущий долг: ${money(balance.debt)}` : 'Долга нет'}
          >
            <div className="space-y-3">
              <Field label="Сумма">
                <Input
                  type="number"
                  min={0}
                  value={payAmount}
                  onChange={(e) => setPayAmount(e.target.value)}
                  className="h-10"
                />
              </Field>

              <Field label="Способ">
                <NativeSelect
                  className="w-full"
                  value={payMethod}
                  onChange={(e) => setPayMethod(e.target.value as PaymentMethod)}
                >
                  <option value="Cash">Наличные</option>
                  <option value="Transfer">Перевод</option>
                </NativeSelect>
              </Field>

              {balance.unpaidOrders.length > 0 && (
                <Field label="Заказ">
                  <NativeSelect
                    className="w-full"
                    value={payOrder}
                    onChange={(e) => setPayOrder(e.target.value)}
                  >
                    <option value="">Без привязки к заказу</option>
                    {balance.unpaidOrders.map((o) => (
                      <option key={o.orderId} value={o.orderId}>
                        От {formatDate(o.deliveryDate)} — осталось {money(o.remainingAmount)}
                      </option>
                    ))}
                  </NativeSelect>
                </Field>
              )}

              <Button
                className="h-11 w-full font-bold"
                disabled={!payValid || payMutation.isPending}
                onClick={() => payMutation.mutate()}
              >
                {payMutation.isPending && <Loader2 className="size-4 animate-spin" />}
                Принять оплату
              </Button>
            </div>
          </Section>

          <Section title="Лимит долга" hint="Пустое поле — без ограничения.">
            <div className="flex gap-2">
              <Input
                type="number"
                min={0}
                value={limitValue}
                onChange={(e) => setLimitInput(e.target.value)}
                placeholder="Без лимита"
                className="h-10"
              />
              <Button
                variant="outline"
                className="h-10"
                disabled={!limitChanged || limitMutation.isPending}
                onClick={saveLimit}
              >
                {limitMutation.isPending && <Loader2 className="size-4 animate-spin" />}
                Сохранить
              </Button>
            </div>
          </Section>

          <Section title="Владелец магазина">
            <p className="mb-3 text-sm font-semibold text-stone-800">
              {shop.ownerName ? `${shop.ownerName} · ${shop.ownerPhone ?? ''}` : 'Не привязан'}
            </p>
            <div className="flex gap-2">
              <Input
                value={ownerInput}
                onChange={(e) => setOwnerInput(e.target.value)}
                placeholder="Телефон пользователя"
                className="h-10"
              />
              <Button
                variant="outline"
                className="h-10"
                disabled={ownerInput.trim() === '' || ownerMutation.isPending}
                onClick={() => ownerMutation.mutate()}
              >
                {ownerMutation.isPending && <Loader2 className="size-4 animate-spin" />}
                Привязать
              </Button>
            </div>
          </Section>
        </div>
      </div>

      {balance.unpaidOrders.length > 0 && (
        <Section title="Неоплаченные заказы">
          <ul className="divide-y divide-stone-100">
            {balance.unpaidOrders.map((o) => (
              <li
                key={o.orderId}
                className="flex flex-wrap items-center justify-between gap-3 py-2.5 text-sm"
              >
                <span className="font-semibold text-stone-800">{formatDate(o.deliveryDate)}</span>
                <span className="text-stone-500">
                  оплачено {money(o.paidAmount)} из {money(o.totalAmount)}
                </span>
                <span className="font-extrabold text-red-600">{money(o.remainingAmount)}</span>
              </li>
            ))}
          </ul>
        </Section>
      )}

      <Section title="История оплат">
        {paymentsQuery.isLoading ? (
          <Loader2 className="size-5 animate-spin text-primary" />
        ) : payments.length === 0 ? (
          <p className="text-sm text-stone-500">Оплат пока нет</p>
        ) : (
          <ul className="divide-y divide-stone-100">
            {payments.map((p) => (
              <li key={p.id} className="py-3">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p
                      className={cn(
                        'font-extrabold',
                        p.isReversal ? 'text-red-600' : 'text-stone-900',
                      )}
                    >
                      {p.isReversal ? '−' : ''}
                      {money(p.amount)}
                      {p.isReversal && (
                        <span className="ml-2 rounded-md bg-red-50 px-1.5 py-0.5 text-xs font-bold">
                          Отмена
                        </span>
                      )}
                      {p.isReversed && (
                        <span className="ml-2 rounded-md bg-stone-100 px-1.5 py-0.5 text-xs font-bold text-stone-500">
                          Отменён
                        </span>
                      )}
                    </p>
                    <p className="text-xs text-stone-500">
                      {formatDateTime(p.createdAt)} · {methodLabels[p.method]}
                      {p.receivedByName ? ` · ${p.receivedByName}` : ''}
                    </p>
                    {p.reversalReason && (
                      <p className="text-xs text-stone-500">Причина: {p.reversalReason}</p>
                    )}
                  </div>

                  {!p.isReversal && !p.isReversed && reversing?.id !== p.id && (
                    <Button
                      variant="outline"
                      size="sm"
                      className="text-red-600 hover:text-red-700"
                      onClick={() => setReversing({ id: p.id, reason: '' })}
                    >
                      Отменить
                    </Button>
                  )}
                </div>

                {reversing?.id === p.id && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    <Input
                      autoFocus
                      value={reversing.reason}
                      onChange={(e) => setReversing({ id: p.id, reason: e.target.value })}
                      placeholder="Причина отмены"
                      className="h-10 min-w-56 flex-1"
                    />
                    <Button
                      className="h-10 bg-red-600 text-white hover:bg-red-700"
                      disabled={reversing.reason.trim() === '' || reverseMutation.isPending}
                      onClick={() =>
                        reverseMutation.mutate({ id: p.id, reason: reversing.reason.trim() })
                      }
                    >
                      {reverseMutation.isPending && <Loader2 className="size-4 animate-spin" />}
                      Отменить оплату
                    </Button>
                    <Button variant="ghost" className="h-10" onClick={() => setReversing(null)}>
                      Нет
                    </Button>
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}
      </Section>

      {(notice || error) && (
        <div className="fixed bottom-6 right-6 z-50 w-80 space-y-2">
          {notice && (
            <div className="flex items-center gap-2 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-semibold text-emerald-700 shadow-lg">
              <CircleCheck className="size-4 shrink-0" />
              {notice}
            </div>
          )}
          {error && (
            <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 shadow-lg">
              {error}
            </div>
          )}
        </div>
      )}
    </div>
  )
}