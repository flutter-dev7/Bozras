import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { ChevronRight, Loader2, Package, PackagePlus, Plus, Search, Tags } from 'lucide-react'
import { useState } from 'react'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { NativeSelect } from '@/components/ui/native-select'
import { Skeleton } from '@/components/ui/skeleton'
import { money } from '@/lib/format'
import { resolveImageUrl } from '@/lib/image'
import { useDebounced } from '@/lib/use-debounced'
import { cn } from '@/lib/utils'

import { fetchCategories, fetchProductsPage } from './api'
import { CategoriesDialog } from './categories-dialog'
import { ProductDialog, type ProductDialogTarget } from './product-dialog'
import { StockDialog, type StockDialogTarget } from './stock-dialog'
import { StockHistory } from './stock-history'

const PAGE_SIZE = 20
const LOW_STOCK = 10

type Tab = 'products' | 'history'

function StockBadge({ quantity, unit }: { quantity: number; unit: string }) {
    if (quantity <= 0) {
        return (
            <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-bold text-red-700">Нет</span>
        )
    }

    return (
        <span
            className={cn(
                'rounded-full px-2.5 py-1 text-xs font-bold',
                quantity <= LOW_STOCK ? 'bg-amber-50 text-amber-700' : 'bg-stone-100 text-stone-800',
            )}
        >
            {quantity} {unit}
        </span>
    )
}

export function ProductsPage() {
    const [tab, setTab] = useState<Tab>('products')
    const [search, setSearch] = useState('')
    const [filter, setFilter] = useState<'all' | 'active' | 'hidden'>('all')
    const [categoryFilter, setCategoryFilter] = useState('')
    const [page, setPage] = useState(1)
    const [target, setTarget] = useState<ProductDialogTarget | null>(null)
    const [stockTarget, setStockTarget] = useState<StockDialogTarget | null>(null)
    const [categoriesOpen, setCategoriesOpen] = useState(false)

    const debounced = useDebounced(search.trim())
    const isActive = filter === 'all' ? undefined : filter === 'active'

    const categoriesQuery = useQuery({ queryKey: ['categories'], queryFn: fetchCategories })
    const categories = categoriesQuery.data ?? []

    const { data, isLoading, isFetching, error, refetch } = useQuery({
        queryKey: ['products', 'manage', debounced, isActive, categoryFilter, page],
        queryFn: () =>
            fetchProductsPage({
                search: debounced,
                isActive,
                categoryId: categoryFilter || undefined,
                page,
                pageSize: PAGE_SIZE,
            }),
        placeholderData: keepPreviousData,
        enabled: tab === 'products',
    })

    const products = data?.items ?? []
    const totalPages = Math.max(1, Math.ceil((data?.totalCount ?? 0) / PAGE_SIZE))

    return (
        <div className="mx-auto max-w-6xl space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                    <h1 className="text-3xl font-extrabold text-stone-900">Товары</h1>
                    <p className="mt-1 text-stone-500">Каталог, цены и остатки на складе</p>
                </div>
                <div className="flex flex-wrap gap-2">
                    <Button variant="outline" className="h-10 rounded-xl bg-white font-bold" onClick={() => setCategoriesOpen(true)}>
                        <Tags className="size-4" />
                        Категории
                    </Button>
                    <Button variant="outline" className="h-10 rounded-xl bg-white font-bold" onClick={() => setStockTarget({ mode: 'receipt' })}>
                        <PackagePlus className="size-4" />
                        Приход
                    </Button>
                    <Button className="h-10 rounded-xl font-bold" onClick={() => setTarget({ product: null })}>
                        <Plus className="size-4" />
                        Добавить товар
                    </Button>
                </div>
            </div>

            <div className="inline-flex gap-1 rounded-xl bg-stone-200/70 p-1">
                {(
                    [
                        ['products', 'Товары'],
                        ['history', 'История склада'],
                    ] as const
                ).map(([id, label]) => (
                    <button
                        key={id}
                        type="button"
                        onClick={() => setTab(id)}
                        className={cn(
                            'rounded-lg px-5 py-2 text-sm font-bold transition-all',
                            tab === id ? 'bg-white text-stone-900 shadow-sm' : 'text-stone-600 hover:text-stone-900',
                        )}
                    >
                        {label}
                    </button>
                ))}
            </div>

            {tab === 'history' ? (
                <StockHistory />
            ) : (
                <>
                    <div className="flex flex-wrap items-center gap-3 rounded-2xl border bg-white p-4 shadow-sm">
                        <div className="relative min-w-64 flex-1">
                            <Search className="pointer-events-none absolute left-3.5 top-1/2 size-5 -translate-y-1/2 text-stone-400" />
                            <Input
                                value={search}
                                onChange={(e) => {
                                    setSearch(e.target.value)
                                    setPage(1)
                                }}
                                placeholder="Поиск по названию"
                                className="h-10 rounded-xl pl-11"
                            />
                            {isFetching && (
                                <Loader2 className="absolute right-3.5 top-1/2 size-4 -translate-y-1/2 animate-spin text-stone-400" />
                            )}
                        </div>
                        <NativeSelect
                            className="w-48 rounded-xl"
                            value={categoryFilter}
                            onChange={(e) => {
                                setCategoryFilter(e.target.value)
                                setPage(1)
                            }}
                        >
                            <option value="">Все категории</option>
                            {categories.map((c) => (
                                <option key={c.id} value={c.id}>
                                    {c.name}
                                </option>
                            ))}
                        </NativeSelect>
                        <NativeSelect
                            className="w-44 rounded-xl"
                            value={filter}
                            onChange={(e) => {
                                setFilter(e.target.value as typeof filter)
                                setPage(1)
                            }}
                        >
                            <option value="all">Все</option>
                            <option value="active">В продаже</option>
                            <option value="hidden">Скрытые</option>
                        </NativeSelect>
                    </div>

                    <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">
                        {error ? (
                            <div className="py-20 text-center">
                                <p className="font-semibold text-red-600">Не удалось загрузить товары</p>
                                <Button variant="outline" className="mt-4" onClick={() => refetch()}>
                                    Повторить
                                </Button>
                            </div>
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="w-full min-w-[820px] text-sm">
                                    <thead className="border-b bg-stone-50">
                                        <tr className="text-left text-xs font-bold uppercase tracking-wide text-stone-500">
                                            <th className="px-5 py-3">Товар</th>
                                            <th className="px-5 py-3">Категория</th>
                                            <th className="px-5 py-3 text-right">Цена</th>
                                            <th className="px-5 py-3">Остаток</th>
                                            <th className="px-5 py-3">Статус</th>
                                            <th className="w-10" />
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {isLoading &&
                                            Array.from({ length: 6 }).map((_, i) => (
                                                <tr key={i} className="border-b border-stone-100">
                                                    <td colSpan={6} className="px-5 py-4">
                                                        <Skeleton className="h-10 w-full rounded-xl" />
                                                    </td>
                                                </tr>
                                            ))}

                                        {!isLoading &&
                                            products.map((product) => (
                                                <tr
                                                    key={product.id}
                                                    onClick={() => setTarget({ product })}
                                                    className="group cursor-pointer border-b border-stone-100 transition-colors last:border-0 hover:bg-amber-50/50"
                                                >
                                                    <td className="px-5 py-3">
                                                        <div className="flex items-center gap-3">
                                                            {product.imageUrl ? (
                                                                <img
                                                                    src={resolveImageUrl(product.imageUrl) ?? undefined}
                                                                    alt=""
                                                                    className="size-11 shrink-0 rounded-xl border object-cover"
                                                                    onError={(e) => {
                                                                        e.currentTarget.style.visibility = 'hidden'
                                                                    }}
                                                                />
                                                            ) : (
                                                                <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-amber-100 text-amber-700">
                                                                    <Package className="size-5" />
                                                                </div>
                                                            )}
                                                            <div>
                                                                <p className="font-bold text-stone-900">{product.name}</p>
                                                                {product.weightInGrams && (
                                                                    <p className="text-xs text-stone-500">{product.weightInGrams} г</p>
                                                                )}
                                                            </div>
                                                        </div>
                                                    </td>
                                                    <td className="px-5 py-3 text-stone-600">{product.categoryName ?? '—'}</td>
                                                    <td className="px-5 py-3 text-right text-base font-extrabold text-stone-900">
                                                        {money(product.price)}
                                                    </td>
                                                    <td className="px-5 py-3">
                                                        <div className="flex items-center gap-2">
                                                            <StockBadge quantity={product.stockQuantity} unit={product.unit} />
                                                            <button
                                                                type="button"
                                                                title="Приход"
                                                                onClick={(e) => {
                                                                    e.stopPropagation()
                                                                    setStockTarget({ productId: product.id, mode: 'receipt' })
                                                                }}
                                                                className="rounded-lg p-1.5 text-stone-400 transition-colors hover:bg-white hover:text-primary"
                                                            >
                                                                <PackagePlus className="size-4" />
                                                            </button>
                                                        </div>
                                                    </td>
                                                    <td className="px-5 py-3">
                                                        <span
                                                            className={cn(
                                                                'rounded-full px-2.5 py-1 text-xs font-bold',
                                                                product.isActive
                                                                    ? 'bg-emerald-50 text-emerald-700'
                                                                    : 'bg-stone-100 text-stone-500',
                                                            )}
                                                        >
                                                            {product.isActive ? 'В продаже' : 'Скрыт'}
                                                        </span>
                                                    </td>
                                                    <td className="py-3 pr-4">
                                                        <ChevronRight className="size-5 text-stone-300 transition-transform group-hover:translate-x-0.5 group-hover:text-primary" />
                                                    </td>
                                                </tr>
                                            ))}
                                    </tbody>
                                </table>

                                {!isLoading && products.length === 0 && (
                                    <div className="py-20 text-center">
                                        <div className="mx-auto flex size-14 items-center justify-center rounded-2xl bg-stone-100 text-stone-400">
                                            <Package className="size-7" />
                                        </div>
                                        <p className="mt-4 font-bold text-stone-800">Товары не найдены</p>
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
                </>
            )}

            <ProductDialog target={target} onClose={() => setTarget(null)} />
            <StockDialog target={stockTarget} onClose={() => setStockTarget(null)} />
            <CategoriesDialog open={categoriesOpen} onClose={() => setCategoriesOpen(false)} />
        </div>
    )
}