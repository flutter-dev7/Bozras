import { useMutation, useQueryClient } from '@tanstack/react-query'
import { CreditCard, Loader2 } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

import { createPlan, updatePlan, type Plan } from './api'
import { ErrorBox, Field, inputClass } from './ui'
import { AppDialog } from '@/components/app-dialog'

export type PlanDialogTarget = { mode: 'create' } | { mode: 'edit'; plan: Plan }

type Props = { target: PlanDialogTarget | null; onClose: () => void }

export function PlanDialog({ target, onClose }: Props) {
  return (
    <AppDialog
      open={!!target}
      onClose={onClose}
      icon={CreditCard}
      title={target?.mode === 'edit' ? target.plan.name : 'Новый тариф'}
      subtitle="Цена и лимиты подписки"
    >
      {target && <PlanForm key={target.mode === 'edit' ? target.plan.id : 'new'} target={target} onClose={onClose} />}
    </AppDialog>
  )
}

function PlanForm({ target, onClose }: { target: PlanDialogTarget; onClose: () => void }) {
  const queryClient = useQueryClient()
  const initial = target.mode === 'edit' ? target.plan : null

  const [name, setName] = useState(initial?.name ?? '')
  const [price, setPrice] = useState(String(initial?.pricePerMonth ?? ''))
  const [maxShops, setMaxShops] = useState(initial?.maxShops ? String(initial.maxShops) : '')
  const [maxStaff, setMaxStaff] = useState(initial?.maxStaff ? String(initial.maxStaff) : '')
  const [isActive, setIsActive] = useState(initial?.isActive ?? true)

  const save = useMutation({
    mutationFn: () => {
      const input = {
        name: name.trim(),
        pricePerMonth: Number(price) || 0,
        maxShops: maxShops ? Number(maxShops) : null,
        maxStaff: maxStaff ? Number(maxStaff) : null,
        isActive,
      }

      return initial ? updatePlan(initial.id, input) : createPlan(input)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['superadmin', 'plans'] })
      onClose()
    },
  })

  return (
    <div className="space-y-5">
      <Field label="Название">
        <Input className={inputClass} value={name} onChange={(e) => setName(e.target.value)} />
      </Field>
      <Field label="Цена за месяц, сом.">
        <Input type="number" min={0} className={inputClass} value={price} onChange={(e) => setPrice(e.target.value)} />
      </Field>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Макс. магазинов" hint="Пусто: без ограничений">
          <Input
            type="number"
            min={1}
            className={inputClass}
            value={maxShops}
            onChange={(e) => setMaxShops(e.target.value)}
          />
        </Field>
        <Field label="Макс. сотрудников" hint="Пусто: без ограничений">
          <Input
            type="number"
            min={1}
            className={inputClass}
            value={maxStaff}
            onChange={(e) => setMaxStaff(e.target.value)}
          />
        </Field>
      </div>
      <label className="flex cursor-pointer items-center gap-2.5 text-sm font-semibold text-stone-700">
        <input
          type="checkbox"
          className="size-4 accent-[#C8801A]"
          checked={isActive}
          onChange={(e) => setIsActive(e.target.checked)}
        />
        Тариф доступен для выбора
      </label>

      <ErrorBox error={save.error} />

      <div className="flex justify-end gap-3">
        <Button type="button" variant="outline" className="h-11 rounded-xl" onClick={onClose}>
          Отмена
        </Button>
        <Button
          type="button"
          className="h-11 rounded-xl px-6 font-bold"
          disabled={!name.trim() || save.isPending}
          onClick={() => save.mutate()}
        >
          {save.isPending && <Loader2 className="size-4 animate-spin" />}
          Сохранить
        </Button>
      </div>
    </div>
  )
}