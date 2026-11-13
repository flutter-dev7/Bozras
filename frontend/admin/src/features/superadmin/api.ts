import { request } from '@/lib/api'

export type Paged<T> = { items: T[]; totalCount: number; page: number; pageSize: number }

export type Supplier = {
  id: string
  name: string
  code: string
  phone: string | null
  description: string | null
  isActive: boolean
  requiresApproval: boolean
  planId: string | null
  planName: string | null
  subscriptionStatus: string
  subscriptionEndsAt: string | null
  isAccessAllowed: boolean
  shopsCount: number
  staffCount: number
  adminEmail: string | null
  locationIds: string[]
  createdAt: string
}

export type SupplierInput = {
  name: string
  phone: string
  description: string
  planId: string | null
  requiresApproval: boolean
  isActive: boolean
  locationIds: string[]
}

export type NewAdminInput = {
  adminFirstName: string
  adminLastName: string
  adminEmail: string
  adminPhone: string
}

export type SubscriptionPayment = {
  id: string
  amount: number
  method: string
  planName: string | null
  periodFrom: string
  periodTo: string
  note: string | null
  createdAt: string
}

export type PaymentInput = {
  amount: number
  method: string
  months: number
  planId: string | null
  note: string
}

export type Plan = {
  id: string
  name: string
  pricePerMonth: number
  maxShops: number | null
  maxStaff: number | null
  isActive: boolean
}

export type PlanInput = Omit<Plan, 'id'>

export type LocationType = 'Region' | 'City' | 'District'

export type LocationItem = {
  id: string
  name: string
  type: LocationType
  parentId: string | null
  isActive: boolean
}

export type LocationInput = Omit<LocationItem, 'id'>

export type LocationNode = LocationItem & { children: LocationNode[] }

export const locationTypeLabels: Record<LocationType, string> = {
  Region: 'Область',
  City: 'Город',
  District: 'Район',
}

// сверь значения с Domain/Enums/PaymentMethod.cs
export const PAYMENT_METHODS = [
  { value: 'Cash', label: 'Наличные' },
  { value: 'Transfer', label: 'Перевод' },
]

export function buildLocationTree(items: LocationItem[]): LocationNode[] {
  const map = new Map<string, LocationNode>()

  items.forEach((item) => map.set(item.id, { ...item, children: [] }))

  const roots: LocationNode[] = []

  map.forEach((node) => {
    const parent = node.parentId ? map.get(node.parentId) : undefined

    if (parent) parent.children.push(node)
    else roots.push(node)
  })

  return roots
}

const base = '/api/superadmin'

export const fetchSuppliers = (params: {
  search?: string
  isActive?: boolean
  page: number
  pageSize: number
}) => request<Paged<Supplier>>({ method: 'GET', url: `${base}/suppliers`, params })

export const fetchSupplier = (id: string) =>
  request<Supplier>({ method: 'GET', url: `${base}/suppliers/${id}` })

export const createSupplier = (input: Omit<SupplierInput, 'isActive'> & NewAdminInput) =>
  request<Supplier>({ method: 'POST', url: `${base}/suppliers`, data: input })

export const updateSupplier = (id: string, input: SupplierInput) =>
  request<Supplier>({ method: 'PUT', url: `${base}/suppliers/${id}`, data: input })

export const regenerateSupplierCode = (id: string) =>
  request<Supplier>({ method: 'POST', url: `${base}/suppliers/${id}/regenerate-code` })

export const fetchPayments = (id: string) =>
  request<SubscriptionPayment[]>({ method: 'GET', url: `${base}/suppliers/${id}/payments` })

export const recordPayment = (id: string, input: PaymentInput) =>
  request<SubscriptionPayment>({ method: 'POST', url: `${base}/suppliers/${id}/payments`, data: input })

export const fetchPlans = () => request<Plan[]>({ method: 'GET', url: `${base}/plans` })

export const createPlan = (input: PlanInput) =>
  request<Plan>({ method: 'POST', url: `${base}/plans`, data: input })

export const updatePlan = (id: string, input: PlanInput) =>
  request<Plan>({ method: 'PUT', url: `${base}/plans/${id}`, data: input })

export const fetchLocations = () => request<LocationItem[]>({ method: 'GET', url: '/api/locations' })

export const createLocation = (input: LocationInput) =>
  request<LocationItem>({ method: 'POST', url: '/api/locations', data: input })

export const updateLocation = (id: string, input: LocationInput) =>
  request<LocationItem>({ method: 'PUT', url: `/api/locations/${id}`, data: input })

export const deleteLocation = (id: string) =>
  request<boolean>({ method: 'DELETE', url: `/api/locations/${id}` })