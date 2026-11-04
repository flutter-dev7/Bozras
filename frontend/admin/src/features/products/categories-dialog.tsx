import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Check, Loader2, Pencil, Plus, Tags, Trash2, X } from 'lucide-react'
import { useState } from 'react'

import { AppDialog } from '@/components/app-dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { ApiError } from '@/lib/api'

import { createCategory, deleteCategory, fetchCategories, updateCategory } from './api'

function Body() {
  const queryClient = useQueryClient()

  const { data, isLoading } = useQuery({ queryKey: ['categories'], queryFn: fetchCategories })
  const categories = data ?? []

  const [name, setName] = useState('')
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editName, setEditName] = useState('')
  const [error, setError] = useState<string | null>(null)

  const refresh = () => {
    setError(null)
    queryClient.invalidateQueries({ queryKey: ['categories'] })
    queryClient.invalidateQueries({ queryKey: ['products'] })
  }

  const fail = (e: unknown) =>
    setError(e instanceof ApiError ? e.message : 'Не удалось выполнить действие.')

  const create = useMutation({
    mutationFn: createCategory,
    onSuccess: () => {
      setName('')
      refresh()
    },
    onError: fail,
  })

  const rename = useMutation({
    mutationFn: ({ id, value }: { id: string; value: string }) => updateCategory(id, value),
    onSuccess: () => {
      setEditingId(null)
      refresh()
    },
    onError: fail,
  })

  const remove = useMutation({
    mutationFn: deleteCategory,
    onSuccess: refresh,
    onError: fail,
  })

  const add = () => {
    if (!name.trim()) return setError('Введите название категории.')
    create.mutate(name.trim())
  }

  return (
    <div className="space-y-4">
      <div className="flex gap-2">
        <Input
          value={name}
          onChange={(e) => setName(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && add()}
          placeholder="Новая категория, например: Хлеб"
          className="h-11 rounded-xl"
          maxLength={100}
        />
        <Button className="h-11 rounded-xl font-bold" onClick={add} disabled={create.isPending}>
          {create.isPending ? <Loader2 className="size-4 animate-spin" /> : <Plus className="size-4" />}
          Добавить
        </Button>
      </div>

      {error && (
        <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="divide-y rounded-2xl border bg-white">
        {isLoading && <p className="px-4 py-6 text-center text-sm text-stone-500">Загрузка…</p>}

        {!isLoading && categories.length === 0 && (
          <p className="px-4 py-6 text-center text-sm text-stone-500">Категорий пока нет</p>
        )}

        {categories.map((c) => (
          <div key={c.id} className="flex items-center gap-2 px-4 py-2.5">
            {editingId === c.id ? (
              <>
                <Input
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && editName.trim()) {
                      rename.mutate({ id: c.id, value: editName.trim() })
                    }
                  }}
                  className="h-9 rounded-lg"
                  maxLength={100}
                  autoFocus
                />
                <Button
                  size="sm"
                  variant="outline"
                  disabled={rename.isPending || !editName.trim()}
                  onClick={() => rename.mutate({ id: c.id, value: editName.trim() })}
                >
                  <Check className="size-4" />
                </Button>
                <Button size="sm" variant="ghost" onClick={() => setEditingId(null)}>
                  <X className="size-4" />
                </Button>
              </>
            ) : (
              <>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-bold text-stone-900">{c.name}</p>
                  <p className="text-xs text-stone-500">Товаров: {c.productsCount}</p>
                </div>
                <Button
                  size="sm"
                  variant="ghost"
                  onClick={() => {
                    setEditingId(c.id)
                    setEditName(c.name)
                  }}
                >
                  <Pencil className="size-4" />
                </Button>
                <Button
                  size="sm"
                  variant="ghost"
                  className="text-red-600 hover:text-red-700"
                  disabled={c.productsCount > 0 || remove.isPending}
                  title={c.productsCount > 0 ? 'Сначала переместите товары в другую категорию' : 'Удалить'}
                  onClick={() => {
                    if (window.confirm(`Удалить категорию «${c.name}»?`)) remove.mutate(c.id)
                  }}
                >
                  <Trash2 className="size-4" />
                </Button>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

export function CategoriesDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  return (
    <AppDialog
      open={open}
      onClose={onClose}
      icon={Tags}
      title="Категории товаров"
      subtitle="Хлеб, выпечка, напитки и другие"
    >
      {open && <Body />}
    </AppDialog>
  )
}