import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { History, Loader2 } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { NativeSelect } from '@/components/ui/native-select'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'

import { fetchMovements, fetchProducts } from './api'

const PAGE_SIZE = 30

const TYPES: Record<string, { label: string; className: string }> = {
  Receipt: { label: 'Приход', className: 'bg-emerald-50 text-emerald-700' },
  WriteOff: { label: 'Списание', className: 'bg-red-50 text-red-700' },
  OrderReserve: { label: 'Заказ', className: 'bg-stone-100 text-stone-600' },
  OrderRelease: { label: 'Возврат из заказа', className: 'bg-amber-50 text-amber-700' },
}

const dateTime = (iso: string) =>
  new Date(iso).toLocaleString('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })

export function StockHistory() {
  const [productId, setProductId] = useState('')
  const [page, setPage] = useState(1)

  const productsQuery = useQuery({ queryKey: ['products', 'active'], queryFn: fetchProducts })
  const products = productsQuery.data ?? []

  const { data, isLoading, isFetching, error, refetch } = useQuery({
    queryKey: ['stock', 'movements', productId, page],
    queryFn: () => fetchMovements({ productId: productId || undefined, page, pageSize: PAGE_SIZE }),
    placeholderData: keepPreviousData,
  })

  const items = data?.items ?? []
  const totalPages = Math.max(1, Math.ceil((data?.totalCount ?? 0) / PAGE_SIZE))

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3 rounded-2xl border bg-white p-4 shadow-sm">
        <NativeSelect
          className="w-64 rounded-xl"
          value={productId}
          onChange={(e) => {
            setProductId(e.target.value)
            setPage(1)
          }}
        >
          <option value="">Все товары</option>
          {products.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
        </NativeSelect>
        {isFetching && <Loader2 className="size-4 animate-spin text-stone-400" />}
      </div>

      <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">
        {error ? (
          <div className="py-20 text-center">
            <p className="font-semibold text-red-600">Не удалось загрузить историю</p>
            <Button variant="outline" className="mt-4" onClick={() => refetch()}>
              Повторить
            </Button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[760px] text-sm">
              <thead className="border-b bg-stone-50">
                <tr className="text-left text-xs font-bold uppercase tracking-wide text-stone-500">
                  <th className="px-5 py-3">Дата</th>
                  <th className="px-5 py-3">Товар</th>
                  <th className="px-5 py-3">Операция</th>
                  <th className="px-5 py-3 text-right">Кол-во</th>
                  <th className="px-5 py-3 text-right">Остаток</th>
                  <th className="px-5 py-3">Примечание</th>
                  <th className="px-5 py-3">Кто</th>
                </tr>
              </thead>
              <tbody>
                {isLoading &&
                  Array.from({ length: 6 }).map((_, i) => (
                    <tr key={i} className="border-b border-stone-100">
                      <td colSpan={7} className="px-5 py-4">
                        <Skeleton className="h-8 w-full rounded-xl" />
                      </td>
                    </tr>
                  ))}

                {!isLoading &&
                  items.map((m) => {
                    const type = TYPES[m.type] ?? { label: m.type, className: 'bg-stone-100 text-stone-600' }

                    return (
                      <tr key={m.id} className="border-b border-stone-100 last:border-0">
                        <td className="whitespace-nowrap px-5 py-3 text-stone-600">
                          {dateTime(m.createdAt)}
                        </td>
                        <td className="px-5 py-3 font-bold text-stone-900">{m.productName}</td>
                        <td className="px-5 py-3">
                          <span
                            className={cn('rounded-full px-2.5 py-1 text-xs font-bold', type.className)}
                          >
                            {type.label}
                          </span>
                        </td>
                        <td
                          className={cn(
                            'px-5 py-3 text-right font-extrabold',
                            m.quantity > 0 ? 'text-emerald-700' : 'text-red-600',
                          )}
                        >
                          {m.quantity > 0 ? '+' : ''}
                          {m.quantity}
                        </td>
                        <td className="px-5 py-3 text-right text-stone-700">{m.balanceAfter}</td>
                        <td className="px-5 py-3 text-stone-600">
                          {m.comment ?? (m.orderId ? `Заказ №${m.orderId.slice(0, 8)}` : '—')}
                        </td>
                        <td className="px-5 py-3 text-stone-600">{m.createdByName ?? '—'}</td>
                      </tr>
                    )
                  })}
              </tbody>
            </table>

            {!isLoading && items.length === 0 && (
              <div className="py-20 text-center">
                <div className="mx-auto flex size-14 items-center justify-center rounded-2xl bg-stone-100 text-stone-400">
                  <History className="size-7" />
                </div>
                <p className="mt-4 font-bold text-stone-800">Движений пока нет</p>
              </div>
            )}
          </div>
        )}
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-sm text-stone-500">
            Страница {page} из {totalPages} · всего {data?.totalCount}
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              className="rounded-xl bg-white"
              disabled={page <= 1}
              onClick={() => setPage((p) => p - 1)}
            >
              Назад
            </Button>
            <Button
              variant="outline"
              className="rounded-xl bg-white"
              disabled={page >= totalPages}
              onClick={() => setPage((p) => p + 1)}
            >
              Вперёд
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}