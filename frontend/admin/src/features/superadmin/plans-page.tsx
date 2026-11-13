import { useQuery } from '@tanstack/react-query'
import { CreditCard, Plus } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'

import { fetchPlans, type Plan } from './api'
import { money } from './ui'
import { PlanDialog, type PlanDialogTarget } from './plan-dialog'

export function PlansPage() {
  const [target, setTarget] = useState<PlanDialogTarget | null>(null)

  const { data: plans = [], isLoading, error, refetch } = useQuery({
    queryKey: ['superadmin', 'plans'],
    queryFn: fetchPlans,
  })

  const limit = (value: number | null, label: string) => (value ? `${value} ${label}` : `${label} без ограничений`)

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-3xl font-extrabold text-stone-900">Тарифы</h1>
          <p className="mt-1 text-stone-500">Цена подписки и лимиты для поставщиков</p>
        </div>
        <Button className="h-10 rounded-xl font-bold" onClick={() => setTarget({ mode: 'create' })}>
          <Plus className="size-4" />
          Добавить тариф
        </Button>
      </div>

      {error ? (
        <div className="rounded-2xl border bg-white py-16 text-center">
          <p className="font-semibold text-red-600">Не удалось загрузить тарифы</p>
          <Button variant="outline" className="mt-4" onClick={() => refetch()}>
            Повторить
          </Button>
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {isLoading && Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-40 rounded-2xl" />)}

          {plans.map((plan: Plan) => (
            <button
              key={plan.id}
              type="button"
              onClick={() => setTarget({ mode: 'edit', plan })}
              className={cn(
                'rounded-2xl border bg-white p-5 text-left shadow-sm transition-all hover:-translate-y-0.5 hover:shadow-md',
                !plan.isActive && 'opacity-60',
              )}
            >
              <div className="flex items-center justify-between">
                <p className="text-lg font-extrabold text-stone-900">{plan.name}</p>
                {!plan.isActive && (
                  <span className="rounded-full bg-stone-100 px-2.5 py-1 text-xs font-bold text-stone-600">
                    Отключён
                  </span>
                )}
              </div>
              <p className="mt-3 text-3xl font-extrabold text-[#7A4E16]">
                {money(plan.pricePerMonth)}
                <span className="text-sm font-semibold text-stone-400"> / мес.</span>
              </p>
              <p className="mt-3 text-sm text-stone-500">{limit(plan.maxShops, 'магазинов')}</p>
              <p className="text-sm text-stone-500">{limit(plan.maxStaff, 'сотрудников')}</p>
            </button>
          ))}
        </div>
      )}

      {!isLoading && plans.length === 0 && !error && (
        <div className="rounded-2xl border bg-white py-16 text-center">
          <div className="mx-auto flex size-14 items-center justify-center rounded-2xl bg-stone-100 text-stone-400">
            <CreditCard className="size-7" />
          </div>
          <p className="mt-4 font-bold text-stone-800">Тарифов пока нет</p>
        </div>
      )}

      <PlanDialog target={target} onClose={() => setTarget(null)} />
    </div>
  )
}