import { request } from '@/lib/api'

export type SupplierProfile = {
  id: string
  name: string
  code: string
  phone: string | null
  description: string | null
  logoUrl: string | null
  requiresApproval: boolean
  planName: string | null
  subscriptionStatus: string
  subscriptionEndsAt: string | null
}

export type SupplierProfileInput = {
  phone: string | null
  description: string | null
  requiresApproval: boolean
}

export type ShopRequest = {
  id: string
  name: string
  address: string
  phone: string
  contactName: string | null
  latitude: number | null
  longitude: number | null
  ownerName: string | null
  ownerPhone: string | null
}

export const fetchSupplierProfile = () =>
  request<SupplierProfile>({ method: 'GET', url: '/api/supplier' })

export const updateSupplierProfile = (input: SupplierProfileInput) =>
  request<SupplierProfile>({ method: 'PUT', url: '/api/supplier', data: input })

export const regenerateMyCode = () =>
  request<SupplierProfile>({ method: 'POST', url: '/api/supplier/regenerate-code' })

export const fetchShopRequests = () =>
  request<ShopRequest[]>({ method: 'GET', url: '/api/Shops/requests' })

export const approveShopRequest = (id: string) =>
  request<unknown>({ method: 'POST', url: `/api/Shops/${id}/approve` })

export const rejectShopRequest = (id: string) =>
  request<unknown>({ method: 'POST', url: `/api/Shops/${id}/reject` })