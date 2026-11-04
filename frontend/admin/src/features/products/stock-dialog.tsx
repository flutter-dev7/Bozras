import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Loader2, PackagePlus } from 'lucide-react'
import { useState } from 'react'

import { AppDialog } from '@/components/app-dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect } from '@/components/ui/native-select'
import { ApiError } from '@/lib/api'
import { cn } from '@/lib/utils'

import { fetchProducts, receiveStock, writeOffStock } from './api'

export type StockDialogTarget = { productId?: string; mode: 'receipt' | 'writeoff' }

function Form({ target, onClose }: { target: StockDialogTarget; onClose: () => void }) {
  const queryClient = useQueryClient()

  const [mode, setMode] = useState(target.mode)
  const [productId, setProductId] = useState(target.productId ?? '')
  const [quantity, setQuantity] = useState('')
  const [comment, setComment] = useState('')
  const [error, setError] = useState<string | null>(null)

  const productsQuery = useQuery({ queryKey: ['products', 'active'], queryFn: fetchProducts })
  const products = productsQuery.data ?? []
  const selected = products.find((p) => p.id === productId)

  const mutation = useMutation({
    mutationFn: (input: { productId: string; quantity: number; comment: string }) =>
      mode === 'receipt'
        ? receiveStock({ ...input, comment: input.comment || null })
        : writeOffStock(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      queryClient.invalidateQueries({ queryKey: ['stock'] })
      onClose()
    },
    onError: (e) => setError(e instanceof ApiError ? e.message : 'Не удалось сохранить.'),
  })

  const qty = Number(quantity)
  const after =
    selected && qty > 0
      ? mode === 'receipt'
        ? selected.stockQuantity + qty
        : selected.stockQuantity - qty
      : null

  const submit = () => {
    setError(null)

    if (!productId) return setError('Выберите товар.')
    if (!Number.isInteger(qty) || qty < 1) return setError('Введите количество — целое число от 1.')
    if (mode === 'writeoff' && !comment.trim()) return setError('Укажите причину списания.')

    mutation.mutate({ productId, quantity: qty, comment: comment.trim() })
  }

  return (
    <div className="space-y-5">
      <div className="inline-flex gap-1 rounded-xl bg-stone-100 p-1">
        {(
          [
            ['receipt', 'Приход'],
            ['writeoff', 'Списание'],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            onClick={() => setMode(value)}
            className={cn(
              'rounded-lg px-5 py-1.5 text-sm font-bold transition-all',
              mode === value
                ? 'bg-white text-stone-900 shadow-sm'
                : 'text-stone-500 hover:text-stone-800',
            )}
          >
            {label}
          </button>
        ))}
      </div>

      <div className="space-y-2">
        <Label className="font-semibold text-stone-700">Товар</Label>
        <NativeSelect
          className="w-full rounded-xl"
          value={productId}
          onChange={(e) => setProductId(e.target.value)}
        >
          <option value="">Выберите товар</option>
          {products.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name} — на складе {p.stockQuantity} {p.unit}
            </option>
          ))}
        </NativeSelect>
      </div>

      <div className="space-y-2">
        <Label className="font-semibold text-stone-700">
          Количество{selected ? `, ${selected.unit}` : ''}
        </Label>
        <Input
          value={quantity}
          onChange={(e) => setQuantity(e.target.value.replace(/\D/g, ''))}
          inputMode="numeric"
          className="h-11 rounded-xl"
          maxLength={7}
        />
        {after !== null && (
          <p className={cn('text-sm', after < 0 ? 'font-semibold text-red-600' : 'text-stone-500')}>
            На складе станет: {after} {selected?.unit}
          </p>
        )}
      </div>

      <div className="space-y-2">
        <Label className="font-semibold text-stone-700">
          {mode === 'receipt' ? 'Комментарий (необязательно)' : 'Причина списания'}
        </Label>
        <Input
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder={mode === 'receipt' ? 'Например: партия от поставщика' : 'Например: испортилось'}
          className="h-11 rounded-xl"
          maxLength={300}
        />
      </div>

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <Button
        className="h-12 w-full rounded-xl text-base font-bold"
        onClick={submit}
        disabled={mutation.isPending}
      >
        {mutation.isPending && <Loader2 className="size-5 animate-spin" />}
        {mode === 'receipt' ? 'Принять на склад' : 'Списать'}
      </Button>
    </div>
  )
}

export function StockDialog({
  target,
  onClose,
}: {
  target: StockDialogTarget | null
  onClose: () => void
}) {
  return (
    <AppDialog
      open={target !== null}
      onClose={onClose}
      icon={PackagePlus}
      title="Склад"
      subtitle="Приход нового товара и списание"
    >
      {target && (
        <Form
          key={`${target.mode}-${target.productId ?? 'any'}`}
          target={target}
          onClose={onClose}
        />
      )}
    </AppDialog>
  )
}