import { useQuery } from '@tanstack/react-query'

import { fetchShopRequests, fetchSupplierProfile } from './api'

export const useShopRequests = () =>
  useQuery({
    queryKey: ['shops', 'requests'],
    queryFn: fetchShopRequests,
    refetchInterval: 60_000,
  })

export const useSupplierProfile = (enabled = true) =>
  useQuery({
    queryKey: ['supplier', 'profile'],
    queryFn: fetchSupplierProfile,
    enabled,
  })