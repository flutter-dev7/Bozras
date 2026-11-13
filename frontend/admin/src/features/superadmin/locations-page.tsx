import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { MapPin, Pencil, Plus, Trash2 } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'

import {
  buildLocationTree,
  deleteLocation,
  fetchLocations,
  locationTypeLabels,
  type LocationNode,
} from './api'
import { ErrorBox } from './ui'
import { LocationDialog, type LocationDialogTarget } from './location-dialog'

function Row({
  node,
  depth,
  onAdd,
  onEdit,
  onDelete,
}: {
  node: LocationNode
  depth: number
  onAdd: (parent: LocationNode) => void
  onEdit: (node: LocationNode) => void
  onDelete: (node: LocationNode) => void
}) {
  return (
    <>
      <div
        className={cn(
          'flex items-center gap-3 border-b border-stone-100 px-4 py-2.5 last:border-0 hover:bg-amber-50/40',
          !node.isActive && 'opacity-50',
        )}
        style={{ paddingLeft: 16 + depth * 28 }}
      >
        <MapPin className="size-4 shrink-0 text-stone-300" />
        <span className={cn('min-w-0 flex-1 truncate', depth === 0 ? 'font-extrabold text-stone-900' : 'font-semibold text-stone-700')}>
          {node.name}
        </span>
        <span className="rounded-full bg-stone-100 px-2.5 py-0.5 text-xs font-bold text-stone-600">
          {locationTypeLabels[node.type]}
        </span>
        {node.type !== 'District' && (
          <Button size="sm" variant="ghost" className="rounded-lg" onClick={() => onAdd(node)}>
            <Plus className="size-4" />
          </Button>
        )}
        <Button size="sm" variant="ghost" className="rounded-lg" onClick={() => onEdit(node)}>
          <Pencil className="size-4" />
        </Button>
        <Button size="sm" variant="ghost" className="rounded-lg text-red-600 hover:text-red-700" onClick={() => onDelete(node)}>
          <Trash2 className="size-4" />
        </Button>
      </div>
      {node.children.map((child) => (
        <Row key={child.id} node={child} depth={depth + 1} onAdd={onAdd} onEdit={onEdit} onDelete={onDelete} />
      ))}
    </>
  )
}

export function LocationsPage() {
  const queryClient = useQueryClient()
  const [target, setTarget] = useState<LocationDialogTarget | null>(null)

  const { data: items = [], isLoading, error, refetch } = useQuery({
    queryKey: ['locations'],
    queryFn: fetchLocations,
  })

  const remove = useMutation({
    mutationFn: (id: string) => deleteLocation(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['locations'] }),
  })

  const tree = buildLocationTree(items)

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-3xl font-extrabold text-stone-900">Города и районы</h1>
          <p className="mt-1 text-stone-500">Справочник для зон доставки и адресов магазинов</p>
        </div>
        <Button className="h-10 rounded-xl font-bold" onClick={() => setTarget({ mode: 'create', parent: null })}>
          <Plus className="size-4" />
          Добавить
        </Button>
      </div>

      <ErrorBox error={remove.error} />

      <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">
        {error ? (
          <div className="py-16 text-center">
            <p className="font-semibold text-red-600">Не удалось загрузить справочник</p>
            <Button variant="outline" className="mt-4" onClick={() => refetch()}>
              Повторить
            </Button>
          </div>
        ) : isLoading ? (
          <div className="space-y-2 p-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-10 w-full rounded-xl" />
            ))}
          </div>
        ) : (
          tree.map((node) => (
            <Row
              key={node.id}
              node={node}
              depth={0}
              onAdd={(parent) => setTarget({ mode: 'create', parent })}
              onEdit={(n) => setTarget({ mode: 'edit', item: n })}
              onDelete={(n) => {
                if (window.confirm(`Удалить «${n.name}»?`)) remove.mutate(n.id)
              }}
            />
          ))
        )}
      </div>

      <LocationDialog target={target} items={items} onClose={() => setTarget(null)} />
    </div>
  )
}