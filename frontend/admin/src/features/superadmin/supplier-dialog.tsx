import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Building2, Copy, Loader2, RefreshCw } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { NativeSelect } from '@/components/ui/native-select'
import { Skeleton } from '@/components/ui/skeleton'

import {
  buildLocationTree,
  createSupplier,
  fetchLocations,
  fetchPlans,
  fetchSupplier,
  regenerateSupplierCode,
  updateSupplier,
  type LocationNode,
  type Supplier,
} from './api'
import { ErrorBox, Field, SectionTitle, inputClass } from './ui'
import { AppDialog } from '@/components/app-dialog'
import { SubscriptionSection } from './subscription-section'

export type SupplierDialogTarget = { mode: 'create' } | { mode: 'edit'; supplier: Supplier }

type Props = {
  target: SupplierDialogTarget | null
  onClose: () => void
}

export function SupplierDialog({ target, onClose }: Props) {
  return (
    <AppDialog
      open={!!target}
      onClose={onClose}
      icon={Building2}
      title={target?.mode === 'edit' ? target.supplier.name : 'Новый поставщик'}
      subtitle={
        target?.mode === 'edit' ? 'Данные, зоны доставки и подписка' : 'Создайте поставщика и его администратора'
      }
      wide
    >
      {target && (
        <SupplierForm
          key={target.mode === 'edit' ? target.supplier.id : 'new'}
          target={target}
          onClose={onClose}
        />
      )}
    </AppDialog>
  )
}

function LocationChecklist({
  nodes,
  value,
  onToggle,
  depth = 0,
}: {
  nodes: LocationNode[]
  value: string[]
  onToggle: (id: string) => void
  depth?: number
}) {
  return (
    <ul className="space-y-1">
      {nodes.map((node) => (
        <li key={node.id}>
          <label
            className="flex cursor-pointer items-center gap-2.5 rounded-lg px-2 py-1.5 text-sm hover:bg-amber-50"
            style={{ paddingLeft: 8 + depth * 20 }}
          >
            <input
              type="checkbox"
              className="size-4 accent-[#C8801A]"
              checked={value.includes(node.id)}
              onChange={() => onToggle(node.id)}
            />
            <span className={depth === 0 ? 'font-bold text-stone-800' : 'text-stone-700'}>{node.name}</span>
          </label>
          {node.children.length > 0 && (
            <LocationChecklist nodes={node.children} value={value} onToggle={onToggle} depth={depth + 1} />
          )}
        </li>
      ))}
    </ul>
  )
}

function SupplierForm({ target, onClose }: Props & { target: SupplierDialogTarget }) {
  const queryClient = useQueryClient()
  const initial = target.mode === 'edit' ? target.supplier : null

  const [name, setName] = useState(initial?.name ?? '')
  const [phone, setPhone] = useState(initial?.phone ?? '')
  const [description, setDescription] = useState(initial?.description ?? '')
  const [planId, setPlanId] = useState(initial?.planId ?? '')
  const [requiresApproval, setRequiresApproval] = useState(initial?.requiresApproval ?? false)
  const [isActive, setIsActive] = useState(initial?.isActive ?? true)
  const [locationIds, setLocationIds] = useState<string[]>(initial?.locationIds ?? [])
  const [admin, setAdmin] = useState({ firstName: '', lastName: '', email: '', phone: '' })
  const [localError, setLocalError] = useState<string | null>(null)

  const { data: plans = [] } = useQuery({ queryKey: ['superadmin', 'plans'], queryFn: fetchPlans })
  const { data: locations, isLoading: locationsLoading } = useQuery({
    queryKey: ['locations'],
    queryFn: fetchLocations,
  })

  const { data: fresh } = useQuery({
    queryKey: ['superadmin', 'supplier', initial?.id],
    queryFn: () => fetchSupplier(initial!.id),
    initialData: initial ?? undefined,
    enabled: !!initial,
  })

  const tree = buildLocationTree(locations ?? [])

  const toggleLocation = (id: string) =>
    setLocationIds((prev) => (prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]))

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['superadmin', 'suppliers'] })
    queryClient.invalidateQueries({ queryKey: ['superadmin', 'supplier'] })
  }

  const save = useMutation({
    mutationFn: () => {
      const common = {
        name: name.trim(),
        phone: phone.trim(),
        description: description.trim(),
        planId: planId || null,
        requiresApproval,
        locationIds,
      }

      if (initial) return updateSupplier(initial.id, { ...common, isActive })

      return createSupplier({
        ...common,
        adminFirstName: admin.firstName.trim(),
        adminLastName: admin.lastName.trim(),
        adminEmail: admin.email.trim(),
        adminPhone: admin.phone.trim(),
      })
    },
    onSuccess: () => {
      invalidate()
      onClose()
    },
  })

  const regenerate = useMutation({
    mutationFn: () => regenerateSupplierCode(initial!.id),
    onSuccess: invalidate,
  })

  const submit = () => {
    setLocalError(null)

    if (!name.trim()) return setLocalError('Укажите название.')

    if (!initial) {
      if (!admin.firstName.trim() || !admin.lastName.trim()) return setLocalError('Укажите имя и фамилию админа.')
      if (!admin.email.trim()) return setLocalError('Укажите почту админа.')
      if (!admin.phone.trim()) return setLocalError('Укажите телефон админа.')
    }

    save.mutate()
  }

  const copyCode = () => {
    if (fresh) navigator.clipboard?.writeText(fresh.code)
  }

  return (
    <div className="space-y-6">
      {fresh && (
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-gradient-to-r from-[#FFF3E2] to-[#FFE6BF] p-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-wide text-stone-500">Код для подключения магазинов</p>
            <p className="mt-1 font-mono text-3xl font-extrabold tracking-widest text-[#7A4E16]">{fresh.code}</p>
          </div>
          <div className="flex gap-2">
            <Button type="button" variant="outline" className="rounded-xl bg-white" onClick={copyCode}>
              <Copy className="size-4" />
              Копировать
            </Button>
            <Button
              type="button"
              variant="outline"
              className="rounded-xl bg-white"
              disabled={regenerate.isPending}
              onClick={() => {
                if (window.confirm('Старый код перестанет работать. Создать новый?')) regenerate.mutate()
              }}
            >
              {regenerate.isPending ? <Loader2 className="size-4 animate-spin" /> : <RefreshCw className="size-4" />}
              Новый код
            </Button>
          </div>
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Название">
          <Input className={inputClass} value={name} onChange={(e) => setName(e.target.value)} />
        </Field>
        <Field label="Телефон">
          <Input
            className={inputClass}
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+992..."
          />
        </Field>
        <div className="sm:col-span-2">
          <Field label="Описание">
            <Input
              className={inputClass}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Например: свежий хлеб и лепёшки, доставка по утрам"
            />
          </Field>
        </div>
        <Field label="Тариф">
          <NativeSelect className="h-11 w-full rounded-xl" value={planId} onChange={(e) => setPlanId(e.target.value)}>
            <option value="">Без тарифа</option>
            {plans
              .filter((p) => p.isActive || p.id === planId)
              .map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
          </NativeSelect>
        </Field>
        <div className="flex flex-col justify-end gap-2 pb-1">
          <label className="flex cursor-pointer items-center gap-2.5 text-sm font-semibold text-stone-700">
            <input
              type="checkbox"
              className="size-4 accent-[#C8801A]"
              checked={requiresApproval}
              onChange={(e) => setRequiresApproval(e.target.checked)}
            />
            Подтверждать новые магазины вручную
          </label>
          {initial && (
            <label className="flex cursor-pointer items-center gap-2.5 text-sm font-semibold text-stone-700">
              <input
                type="checkbox"
                className="size-4 accent-[#C8801A]"
                checked={isActive}
                onChange={(e) => setIsActive(e.target.checked)}
              />
              Поставщик включён
            </label>
          )}
        </div>
      </div>

      <div className="space-y-2">
        <SectionTitle>Куда доставляет</SectionTitle>
        <div className="max-h-56 overflow-y-auto rounded-2xl border bg-white p-2">
          {locationsLoading ? (
            <Skeleton className="h-24 w-full rounded-xl" />
          ) : (
            <LocationChecklist nodes={tree} value={locationIds} onToggle={toggleLocation} />
          )}
        </div>
        <p className="text-xs text-stone-400">Магазины увидят поставщика, если их район входит в эти зоны.</p>
      </div>

      {!initial && (
        <div className="space-y-3 rounded-2xl border border-dashed border-stone-300 p-4">
          <SectionTitle>Администратор поставщика</SectionTitle>
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="Имя">
              <Input
                className={inputClass}
                value={admin.firstName}
                onChange={(e) => setAdmin({ ...admin, firstName: e.target.value })}
              />
            </Field>
            <Field label="Фамилия">
              <Input
                className={inputClass}
                value={admin.lastName}
                onChange={(e) => setAdmin({ ...admin, lastName: e.target.value })}
              />
            </Field>
            <Field label="Почта">
              <Input
                type="email"
                className={inputClass}
                value={admin.email}
                onChange={(e) => setAdmin({ ...admin, email: e.target.value })}
              />
            </Field>
            <Field label="Телефон">
              <Input
                className={inputClass}
                value={admin.phone}
                onChange={(e) => setAdmin({ ...admin, phone: e.target.value })}
                placeholder="+992..."
              />
            </Field>
          </div>
          <p className="text-xs text-stone-400">
            Пароль вы не задаёте. Админ заходит через «Забыли пароль» по этой почте и придумывает его сам.
            Пробный период: 30 дней.
          </p>
        </div>
      )}

      {initial && fresh && <SubscriptionSection supplier={fresh} plans={plans} />}

      <ErrorBox error={localError ? new Error(localError) : save.error ?? regenerate.error} />

      <div className="flex justify-end gap-3">
        <Button type="button" variant="outline" className="h-11 rounded-xl" onClick={onClose}>
          Отмена
        </Button>
        <Button type="button" className="h-11 rounded-xl px-6 font-bold" disabled={save.isPending} onClick={submit}>
          {save.isPending && <Loader2 className="size-4 animate-spin" />}
          {initial ? 'Сохранить' : 'Создать поставщика'}
        </Button>
      </div>
    </div>
  )
}