import { request } from '@/lib/api'
import type { Paged } from '@/lib/types'

export type Product = {
  id: string
  name: string
  weightInGrams: number | null
  price: number
  imageUrl: string | null
  isActive: boolean
  categoryId: string | null
  categoryName: string | null
  unit: string
  stockQuantity: number
}

export type ProductInput = {
  name: string
  weightInGrams: number | null
  price: number
  imageUrl: string | null
  categoryId: string | null
  unit: string
}

export type ProductsQuery = {
  search?: string
  isActive?: boolean
  categoryId?: string
  page: number
  pageSize: number
}

/** Активные товары для выбора в заказе и в окне прихода. */
export async function fetchProducts(): Promise<Product[]> {
  const data = await request<Product[] | Paged<Product>>({
    method: 'GET',
    url: '/api/Products',
  })

  return Array.isArray(data) ? data : data.items
}

export function fetchProductsPage(query: ProductsQuery) {
  return request<Paged<Product>>({
    method: 'GET',
    url: '/api/Products/manage',
    params: {
      Search: query.search || undefined,
      IsActive: query.isActive,
      CategoryId: query.categoryId,
      Page: query.page,
      PageSize: query.pageSize,
    },
  })
}

export function createProduct(input: ProductInput) {
  return request<Product>({ method: 'POST', url: '/api/Products', data: input })
}

export function updateProduct(id: string, input: ProductInput & { isActive: boolean }) {
  return request<Product>({ method: 'PUT', url: `/api/Products/${id}`, data: input })
}

export function uploadProductImage(file: File) {
  const form = new FormData()
  form.append('file', file)

  return request<string>({ method: 'POST', url: '/api/Uploads/product-image', data: form })
}

export type Category = {
  id: string
  name: string
  productsCount: number
}

export function fetchCategories() {
  return request<Category[]>({ method: 'GET', url: '/api/Categories' })
}

export function createCategory(name: string) {
  return request<Category>({ method: 'POST', url: '/api/Categories', data: { name } })
}

export function updateCategory(id: string, name: string) {
  return request<Category>({ method: 'PUT', url: `/api/Categories/${id}`, data: { name } })
}

export function deleteCategory(id: string) {
  return request<boolean>({ method: 'DELETE', url: `/api/Categories/${id}` })
}

export type StockMovement = {
  id: string
  productId: string
  productName: string
  type: string
  quantity: number
  balanceAfter: number
  orderId: string | null
  comment: string | null
  createdByName: string | null
  createdAt: string
}

export function fetchMovements(query: { productId?: string; page: number; pageSize: number }) {
  return request<Paged<StockMovement>>({
    method: 'GET',
    url: '/api/Stock/movements',
    params: { ProductId: query.productId, Page: query.page, PageSize: query.pageSize },
  })
}

export function receiveStock(input: { productId: string; quantity: number; comment: string | null }) {
  return request<StockMovement>({ method: 'POST', url: '/api/Stock/receipts', data: input })
}

export function writeOffStock(input: { productId: string; quantity: number; comment: string }) {
  return request<StockMovement>({ method: 'POST', url: '/api/Stock/write-offs', data: input })
}