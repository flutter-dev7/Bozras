import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Loader2, MapPin } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { NativeSelect } from '@/components/ui/native-select'

import {
  createLocation,
  locationTypeLabels,
  updateLocation,
  type LocationItem,
  type LocationType,
} from './api'
import { ErrorBox, Field, inputClass } from './ui'
import { AppDialog } from '@/components/app-dialog'

export type LocationDialogTarget =
  | { mode: 'create'; parent: LocationItem | null }
  | { mode: 'edit'; item: LocationItem }

type Props = {
  target: LocationDialogTarget | null
  items: LocationItem[]
  onClose: () => void
}

export function LocationDialog({ target, items, onClose }: Props) {
  return (
    <AppDialog
      open={!!target}
      onClose={onClose}
      icon={MapPin}
      title={target?.mode === 'edit' ? target.item.name : 'Новое место'}
      subtitle="Область, город или район"
    >
      {target && (
        <LocationForm
          key={target.mode === 'edit' ? target.item.id : `new-${target.parent?.id ?? 'root'}`}
          target={target}
          items={items}
          onClose={onClose}
        />
      )}
    </AppDialog>
  )
}

const parentTypes: Record<LocationType, LocationType[]> = {
  Region: [],
  City: ['Region'],
  District: ['City', 'Region'],
}

function defaultType(parent: LocationItem | null): LocationType {
  if (!parent) return 'Region'

  return parent.type === 'Region' ? 'City' : 'District'
}

function LocationForm({ target, items, onClose }: Props & { target: LocationDialogTarget }) {
  const queryClient = useQueryClient()
  const initial = target.mode === 'edit' ? target.item : null
  const createParent = target.mode === 'create' ? target.parent : null

  const [name, setName] = useState(initial?.name ?? '')
  const [type, setType] = useState<LocationType>(initial?.type ?? defaultType(createParent))
  const [parentId, setParentId] = useState(initial?.parentId ?? createParent?.id ?? '')
  const [isActive, setIsActive] = useState(initial?.isActive ?? true)

  const allowedParents = items.filter((i) => parentTypes[type].includes(i.type) && i.id !== initial?.id)

  const save = useMutation({
    mutationFn: () => {
      const input = { name: name.trim(), type, parentId: parentId || null, isActive }

      return initial ? updateLocation(initial.id, input) : createLocation(input)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['locations'] })
      onClose()
    },
  })

  return (
    <div className="space-y-5">
      <Field label="Название">
        <Input className={inputClass} value={name} onChange={(e) => setName(e.target.value)} autoFocus />
      </Field>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Тип">
          <NativeSelect
            className="h-11 w-full rounded-xl"
            value={type}
            onChange={(e) => {
              setType(e.target.value as LocationType)
              setParentId('')
            }}
          >
            {(Object.keys(locationTypeLabels) as LocationType[]).map((t) => (
              <option key={t} value={t}>
                {locationTypeLabels[t]}
              </option>
            ))}
          </NativeSelect>
        </Field>
        <Field label="Входит в">
          <NativeSelect
            className="h-11 w-full rounded-xl"
            value={parentId}
            disabled={type === 'Region'}
            onChange={(e) => setParentId(e.target.value)}
          >
            <option value="">{type === 'District' ? 'Выберите' : 'Нет (верхний уровень)'}</option>
            {allowedParents.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </NativeSelect>
        </Field>
      </div>

      <label className="flex cursor-pointer items-center gap-2.5 text-sm font-semibold text-stone-700">
        <input
          type="checkbox"
          className="size-4 accent-[#C8801A]"
          checked={isActive}
          onChange={(e) => setIsActive(e.target.checked)}
        />
        Доступно для выбора
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