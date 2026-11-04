import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Boxes, ImagePlus, Loader2, Package, Trash2 } from 'lucide-react'
import { useRef, useState, type ReactNode } from 'react'

import { AppDialog } from '@/components/app-dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { NativeSelect } from '@/components/ui/native-select'
import { ApiError } from '@/lib/api'
import { resolveImageUrl } from '@/lib/image'
import { cn } from '@/lib/utils'

import { createProduct, fetchCategories, updateProduct, uploadProductImage, type Product } from './api'

const MAX_BYTES = 5 * 1024 * 1024
const UNITS = ['шт', 'кг', 'уп.', 'л', 'бут.']
const LOW_STOCK = 10

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="space-y-1.5">
      <Label className="text-xs font-bold uppercase tracking-wide text-stone-500">{label}</Label>
      {children}
    </div>
  )
}

function PhotoField({
  value,
  onChange,
  showUrl,
  onToggleUrl,
}: {
  value: string
  onChange: (url: string) => void
  showUrl: boolean
  onToggleUrl: () => void
}) {
  const inputRef = useRef<HTMLInputElement>(null)
  const [uploading, setUploading] = useState(false)
  const [dragOver, setDragOver] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const upload = async (file: File | undefined) => {
    if (!file) return

    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      return setError('JPG, PNG или WEBP.')
    }
    if (file.size > MAX_BYTES) return setError('Не более 5 МБ.')

    setError(null)
    setUploading(true)

    try {
      onChange(await uploadProductImage(file))
    } catch (e) {
      setError(e instanceof ApiError ? e.message : 'Не удалось загрузить фото.')
    } finally {
      setUploading(false)
    }
  }

  const preview = resolveImageUrl(value.trim())

  return (
    <div className="w-32 shrink-0 space-y-2">
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        className="hidden"
        onChange={(e) => {
          upload(e.target.files?.[0])
          e.target.value = ''
        }}
      />

      <button
        type="button"
        disabled={uploading}
        onClick={() => inputRef.current?.click()}
        onDragOver={(e) => {
          e.preventDefault()
          setDragOver(true)
        }}
        onDragLeave={() => setDragOver(false)}
        onDrop={(e) => {
          e.preventDefault()
          setDragOver(false)
          upload(e.dataTransfer.files?.[0])
        }}
        className={cn(
          'group relative flex size-32 items-center justify-center overflow-hidden rounded-2xl border-2 transition-colors',
          preview
            ? 'border-stone-200 bg-white'
            : dragOver
              ? 'border-dashed border-primary bg-amber-50'
              : 'border-dashed border-stone-300 bg-stone-50 hover:border-primary/60 hover:bg-amber-50/40',
        )}
      >
        {preview ? (
          <>
            <img key={preview} src={preview} alt="" className="size-full object-cover" />
            <span className="absolute inset-x-0 bottom-0 bg-stone-900/60 py-1 text-center text-xs font-bold text-white opacity-0 transition-opacity group-hover:opacity-100">
              Заменить
            </span>
          </>
        ) : (
          <span className="flex flex-col items-center gap-1 text-center">
            {uploading ? (
              <Loader2 className="size-7 animate-spin text-primary" />
            ) : (
              <ImagePlus className="size-7 text-primary" />
            )}
            <span className="text-xs font-bold text-stone-700">
              {uploading ? 'Загрузка…' : 'Добавить фото'}
            </span>
          </span>
        )}

        {uploading && preview && (
          <span className="absolute inset-0 flex items-center justify-center bg-white/70">
            <Loader2 className="size-7 animate-spin text-primary" />
          </span>
        )}
      </button>

      <div className="flex items-center justify-between gap-2 text-xs">
        {preview ? (
          <button
            type="button"
            disabled={uploading}
            onClick={() => onChange('')}
            className="inline-flex items-center gap-1 font-semibold text-red-600 hover:text-red-700"
          >
            <Trash2 className="size-3.5" />
            Удалить
          </button>
        ) : (
          <span />
        )}
        <button
          type="button"
          onClick={onToggleUrl}
          className="font-semibold text-stone-500 hover:text-stone-800"
        >
          {showUrl ? 'Скрыть' : 'Ссылка'}
        </button>
      </div>

      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  )
}

function Form({ product, onClose }: { product: Product | null; onClose: () => void }) {
  const queryClient = useQueryClient()
  const isEdit = product !== null

  const [name, setName] = useState(product?.name ?? '')
  const [weight, setWeight] = useState(product?.weightInGrams?.toString() ?? '')
  const [price, setPrice] = useState(product ? String(product.price) : '')
  const [imageUrl, setImageUrl] = useState(product?.imageUrl ?? '')
  const [showUrl, setShowUrl] = useState(false)
  const [isActive, setIsActive] = useState(product?.isActive ?? true)
  const [categoryId, setCategoryId] = useState(product?.categoryId ?? '')
  const [unit, setUnit] = useState(product?.unit ?? 'шт')
  const [error, setError] = useState<string | null>(null)

  const categoriesQuery = useQuery({ queryKey: ['categories'], queryFn: fetchCategories })
  const categories = categoriesQuery.data ?? []
  const unitOptions = UNITS.includes(unit) ? UNITS : [...UNITS, unit]

  const mutation = useMutation({
    mutationFn: (input: {
      name: string
      weightInGrams: number | null
      price: number
      imageUrl: string | null
      categoryId: string | null
      unit: string
    }) => (isEdit ? updateProduct(product.id, { ...input, isActive }) : createProduct(input)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] })
      onClose()
    },
    onError: (e) => setError(e instanceof ApiError ? e.message : 'Не удалось сохранить товар.'),
  })

  const submit = () => {
    setError(null)

    const priceNumber = Number(price.replace(',', '.'))
    const weightNumber = weight.trim() === '' ? null : Number(weight)

    if (!name.trim()) return setError('Введите название.')
    if (price.trim() === '' || !Number.isFinite(priceNumber) || priceNumber < 0) {
      return setError('Введите корректную цену.')
    }
    if (
      weightNumber !== null &&
      (!Number.isInteger(weightNumber) || weightNumber < 1 || weightNumber > 100000)
    ) {
      return setError('Вес — целое число от 1 до 100000 г.')
    }

    mutation.mutate({
      name: name.trim(),
      weightInGrams: weightNumber,
      price: priceNumber,
      imageUrl: imageUrl.trim() || null,
      categoryId: categoryId || null,
      unit,
    })
  }

  const stockTone = (quantity: number) =>
    quantity <= 0
      ? 'border-red-200 bg-red-50 text-red-700'
      : quantity <= LOW_STOCK
        ? 'border-amber-200 bg-amber-50 text-amber-700'
        : 'border-stone-200 bg-stone-50 text-stone-900'

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-5 sm:flex-row">
        <PhotoField
          value={imageUrl}
          onChange={setImageUrl}
          showUrl={showUrl}
          onToggleUrl={() => setShowUrl((v) => !v)}
        />

        <div className="min-w-0 flex-1 space-y-4">
          <Field label="Название">
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="h-11 rounded-xl"
              maxLength={200}
              autoFocus
            />
          </Field>

          <Field label="Категория">
            <NativeSelect
              className="w-full rounded-xl"
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
            >
              <option value="">Без категории</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </NativeSelect>
          </Field>
        </div>
      </div>

      {showUrl && (
        <Field label="Ссылка на фото">
          <Input
            value={imageUrl}
            onChange={(e) => setImageUrl(e.target.value)}
            placeholder="https://…"
            maxLength={500}
            className="h-11 rounded-xl"
          />
        </Field>
      )}

      <div className="grid gap-4 sm:grid-cols-3">
        <Field label="Цена, сом.">
          <Input
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            inputMode="decimal"
            className="h-11 rounded-xl"
          />
        </Field>

        <Field label="Единица">
          <NativeSelect
            className="w-full rounded-xl"
            value={unit}
            onChange={(e) => setUnit(e.target.value)}
          >
            {unitOptions.map((u) => (
              <option key={u} value={u}>
                {u}
              </option>
            ))}
          </NativeSelect>
        </Field>

        <Field label="Вес, г">
          <Input
            value={weight}
            onChange={(e) => setWeight(e.target.value)}
            inputMode="numeric"
            placeholder="—"
            className="h-11 rounded-xl"
          />
        </Field>
      </div>

      {product && (
        <div className="grid gap-3 sm:grid-cols-2">
          <div
            className={cn(
              'flex items-center gap-3 rounded-2xl border px-4 py-3',
              stockTone(product.stockQuantity),
            )}
          >
            <Boxes className="size-6 shrink-0 opacity-80" />
            <div>
              <p className="text-xs font-bold uppercase tracking-wide opacity-70">На складе</p>
              <p className="text-xl font-extrabold leading-tight">
                {product.stockQuantity}{' '}
                <span className="text-sm font-semibold opacity-70">{product.unit}</span>
              </p>
              <p className="text-xs opacity-70">Меняется через «Приход»</p>
            </div>
          </div>

          <div className="flex flex-col justify-between rounded-2xl border border-stone-200 bg-stone-50 px-4 py-3">
            <p className="text-xs font-bold uppercase tracking-wide text-stone-500">Статус</p>

            <div className="mt-1 flex items-center justify-between gap-3">
              <div>
                <p
                  className={cn(
                    'text-xl font-extrabold leading-tight',
                    isActive ? 'text-emerald-700' : 'text-stone-500',
                  )}
                >
                  {isActive ? 'В продаже' : 'Скрыт'}
                </p>
                <p className="text-xs text-stone-500">
                  {isActive ? 'Виден магазинам' : 'Скрыт от магазинов'}
                </p>
              </div>

              <button
                type="button"
                role="switch"
                aria-checked={isActive}
                onClick={() => setIsActive((v) => !v)}
                className={cn(
                  'relative h-7 w-12 shrink-0 rounded-full transition-colors',
                  isActive ? 'bg-emerald-500' : 'bg-stone-300',
                )}
              >
                <span
                  className={cn(
                    'absolute left-0.5 top-0.5 size-6 rounded-full bg-white shadow transition-transform',
                    isActive && 'translate-x-5',
                  )}
                />
              </button>
            </div>
          </div>
        </div>
      )}

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
        {isEdit ? 'Сохранить' : 'Добавить товар'}
      </Button>
    </div>
  )
}

export type ProductDialogTarget = { product: Product | null }

export function ProductDialog({
  target,
  onClose,
}: {
  target: ProductDialogTarget | null
  onClose: () => void
}) {
  const isEdit = !!target?.product

  return (
    <AppDialog
      open={target !== null}
      onClose={onClose}
      icon={Package}
      title={isEdit ? 'Редактирование товара' : 'Новый товар'}
      subtitle={isEdit ? target?.product?.name : 'Заполните данные и добавьте фото'}
    >
      {target && (
        <Form key={target.product?.id ?? 'new'} product={target.product} onClose={onClose} />
      )}
    </AppDialog>
  )
}