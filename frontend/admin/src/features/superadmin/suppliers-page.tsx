import { keepPreviousData, useQuery, useQueryClient } from '@tanstack/react-query'
import { Building2, ChevronRight, Loader2, LogIn, Plus, Search } from 'lucide-react'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { NativeSelect } from '@/components/ui/native-select'
import { Skeleton } from '@/components/ui/skeleton'
import { formatDate } from '@/lib/format'
import { supplierMode } from '@/lib/tokens'
import { useDebounced } from '@/lib/use-debounced'

import { fetchSuppliers, type Supplier } from './api'
import { SubscriptionBadge } from './ui'
import { SupplierDialog, type SupplierDialogTarget } from './supplier-dialog'

const PAGE_SIZE = 20

export function SuppliersPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [search, setSearch] = useState('')
  const [status, setStatus] = useState<'all' | 'active' | 'blocked'>('all')
  const [page, setPage] = useState(1)
  const [target, setTarget] = useState<SupplierDialogTarget | null>(null)

  const debounced = useDebounced(search.trim())
  const isActive = status === 'all' ? undefined : status === 'active'

  const { data, isLoading, isFetching, error, refetch } = useQuery({
    queryKey: ['superadmin', 'suppliers', debounced, isActive, page],
    queryFn: () => fetchSuppliers({ search: debounced, isActive, page, pageSize: PAGE_SIZE }),
    placeholderData: keepPreviousData,
  })

  const suppliers = data?.items ?? []
  const totalPages = Math.max(1, Math.ceil((data?.totalCount ?? 0) / PAGE_SIZE))

  const enter = (supplier: Supplier) => {
    supplierMode.set({ id: supplier.id, name: supplier.name })
    queryClient.clear()
    navigate('/orders')
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-3xl font-extrabold text-stone-900">Поставщики</h1>
          <p className="mt-1 text-stone-500">Пекарни и компании, которые работают в сервисе</p>
        </div>
        <Button className="h-10 rounded-xl font-bold" onClick={() => setTarget({ mode: 'create' })}>
          <Plus className="size-4" />
          Добавить поставщика
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-3 rounded-2xl border bg-white p-4 shadow-sm">
        <div className="relative min-w-64 flex-1">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-stone-400" />
          <Input
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            placeholder="Поиск по названию, коду, телефону"
            className="h-10 rounded-xl pl-11"
          />
          {isFetching && (
            <Loader2 className="absolute right-3.5 top-1/2 size-4 -translate-y-1/2 animate-spin text-stone-400" />
          )}
        </div>
        <NativeSelect
          className="w-44 rounded-xl"
          value={status}
          onChange={(e) => {
            setStatus(e.target.value as typeof status)
            setPage(1)
          }}
        >
          <option value="all">Любой статус</option>
          <option value="active">Включённые</option>
          <option value="blocked">Отключённые</option>
        </NativeSelect>
      </div>

      <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">
        {error ? (
          <div className="py-20 text-center">
            <p className="font-semibold text-red-600">Не удалось загрузить поставщиков</p>
            <Button variant="outline" className="mt-4" onClick={() => refetch()}>
              Повторить
            </Button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-sm">
              <thead className="border-b bg-stone-50">
                <tr className="text-left text-xs font-bold uppercase tracking-wide text-stone-500">
                  <th className="px-5 py-3">Поставщик</th>
                  <th className="px-5 py-3">Подписка</th>
                  <th className="px-5 py-3">Магазины</th>
                  <th className="px-5 py-3">Сотрудники</th>
                  <th className="px-5 py-3" />
                  <th className="w-10" />
                </tr>
              </thead>
              <tbody>
                {isLoading &&
                  Array.from({ length: 5 }).map((_, i) => (
                    <tr key={i} className="border-b border-stone-100">
                      <td colSpan={6} className="px-5 py-4">
                        <Skeleton className="h-10 w-full rounded-xl" />
                      </td>
                    </tr>
                  ))}

                {!isLoading &&
                  suppliers.map((supplier) => (
                    <tr
                      key={supplier.id}
                      onClick={() => setTarget({ mode: 'edit', supplier })}
                      className="group cursor-pointer border-b border-stone-100 transition-colors last:border-0 hover:bg-amber-50/50"
                    >
                      <td className="px-5 py-3">
                        <p className="font-bold text-stone-900">{supplier.name}</p>
                        <p className="text-xs text-stone-500">
                          Код: <span className="font-mono font-bold">{supplier.code}</span>
                        </p>
                      </td>
                      <td className="px-5 py-3">
                        <SubscriptionBadge supplier={supplier} />
                        {supplier.subscriptionEndsAt && (
                          <p className="mt-1 text-xs text-stone-500">
                            до {formatDate(supplier.subscriptionEndsAt)}
                          </p>
                        )}
                      </td>
                      <td className="px-5 py-3 font-semibold text-stone-700">{supplier.shopsCount}</td>
                      <td className="px-5 py-3 font-semibold text-stone-700">{supplier.staffCount}</td>
                      <td className="px-5 py-3 text-right">
                        <Button
                          size="sm"
                          variant="outline"
                          className="rounded-lg"
                          onClick={(e) => {
                            e.stopPropagation()
                            enter(supplier)
                          }}
                        >
                          <LogIn className="size-4" />
                          Войти
                        </Button>
                      </td>
                      <td className="py-3 pr-4">
                        <ChevronRight className="size-5 text-stone-300 transition-transform group-hover:translate-x-0.5 group-hover:text-primary" />
                      </td>
                    </tr>
                  ))}
              </tbody>
            </table>

            {!isLoading && suppliers.length === 0 && (
              <div className="py-20 text-center">
                <div className="mx-auto flex size-14 items-center justify-center rounded-2xl bg-stone-100 text-stone-400">
                  <Building2 className="size-7" />
                </div>
                <p className="mt-4 font-bold text-stone-800">Поставщиков пока нет</p>
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

      <SupplierDialog target={target} onClose={() => setTarget(null)} />
    </div>
  )
}