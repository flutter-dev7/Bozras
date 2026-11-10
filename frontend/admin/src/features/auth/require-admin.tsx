import { Loader2 } from 'lucide-react'
import { Navigate, Outlet, useLocation } from 'react-router-dom'

import { supplierMode } from '@/lib/tokens'

import { useAuth } from './auth-context'

export function RequireAdmin() {
  const { status, user } = useAuth()
  const { pathname } = useLocation()

  if (status === 'loading') {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <Loader2 className="size-8 animate-spin text-primary" />
      </div>
    )
  }

  if (status === 'guest') return <Navigate to="/login" replace />

  const isSuper = user?.role === 'SuperAdmin'
  const inSuperArea = pathname.startsWith('/superadmin')

  if (isSuper && !inSuperArea && !supplierMode.get()) {
    return <Navigate to="/superadmin/suppliers" replace />
  }

  if (!isSuper && inSuperArea) return <Navigate to="/orders" replace />

  return <Outlet />
}