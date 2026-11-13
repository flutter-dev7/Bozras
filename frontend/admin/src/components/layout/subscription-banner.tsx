import { Hourglass } from 'lucide-react'
import { Link } from 'react-router-dom'

import { useAuth } from '@/features/auth/auth-context'
import { daysLeft } from '@/features/supplier/profile-page'
import { useSupplierProfile } from '@/features/supplier/hooks'
import { cn } from '@/lib/utils'

const GRACE_DAYS = 3

export function SubscriptionBanner() {
  const { user } = useAuth()
  const { data } = useSupplierProfile(user?.role === 'Admin')

  if (user?.role !== 'Admin' || !data) return null

  const days = daysLeft(data.subscriptionEndsAt)

  if (days === null || days > 7) return null

  const expired = days < 0
  const graceLeft = GRACE_DAYS + days

  const text = !expired
    ? days === 0
      ? 'Подписка заканчивается сегодня.'
      : `Подписка заканчивается через ${days} дн.`
    : graceLeft > 0
      ? `Подписка истекла. Доступ закроется через ${graceLeft} дн.`
      : 'Подписка истекла. Доступ закрыт.'

  return (
    <div
      className={cn(
        'flex flex-wrap items-center gap-3 border-b px-4 py-2.5 text-sm font-semibold md:px-8 print:hidden',
        expired ? 'border-red-200 bg-red-50 text-red-700' : 'border-amber-200 bg-amber-50 text-amber-800',
      )}
    >
      <Hourglass className="size-4 shrink-0" />
      <span>{text} Свяжитесь с администратором сервиса для продления.</span>
      <Link to="/profile" className="ml-auto underline">
        Подробнее
      </Link>
    </div>
  )
}