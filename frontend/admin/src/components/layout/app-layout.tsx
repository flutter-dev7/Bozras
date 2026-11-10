import { useQueryClient } from '@tanstack/react-query'
import {
  Building2,
  ClipboardList,
  CreditCard,
  LogOut,
  MapPin,
  Menu,
  Package,
  Settings,
  Store,
  Undo2,
  Users,
  Wheat,
  type LucideIcon,
} from 'lucide-react'
import { useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'

import { Button } from '@/components/ui/button'
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from '@/components/ui/sheet'
import { useAuth } from '@/features/auth/auth-context'
import { useNewOrdersCount } from '@/features/orders/hooks'
import { supplierMode } from '@/lib/tokens'
import { cn } from '@/lib/utils'

type NavItem = { to: string; label: string; icon: LucideIcon }

const adminNav: NavItem[] = [
  { to: '/orders', label: 'Заказы', icon: ClipboardList },
  { to: '/plan', label: 'План', icon: Wheat },
  { to: '/shops', label: 'Магазины и долги', icon: Store },
  { to: '/products', label: 'Товары', icon: Package },
  { to: '/users', label: 'Пользователи', icon: Users },
  { to: '/settings', label: 'Настройки', icon: Settings },
]

const superNav: NavItem[] = [
  { to: '/superadmin/suppliers', label: 'Поставщики', icon: Building2 },
  { to: '/superadmin/locations', label: 'Города и районы', icon: MapPin },
  { to: '/superadmin/plans', label: 'Тарифы', icon: CreditCard },
]

const wordmarkStyle = { fontFamily: "'Playfair Display', serif", fontWeight: 900 } as const

type ShellProps = {
  items: NavItem[]
  subtitle: string
  badges?: Record<string, number | undefined>
  onNavigate?: () => void
}

function SidebarShell({ items, subtitle, badges, onNavigate }: ShellProps) {
  const { user, logout } = useAuth()

  const fullName = user ? `${user.firstName} ${user.lastName}`.trim() : ''
  const initial = (user?.firstName ?? 'A').charAt(0).toUpperCase()

  return (
    <div className="relative flex h-full flex-col overflow-hidden bg-gradient-to-b from-[#3B2A1A] via-[#5B3B15] to-[#9A6119] text-white">
      <div className="pointer-events-none absolute -right-20 -top-20 size-64 rounded-full bg-white/10 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-24 -left-16 size-64 rounded-full bg-[#FFD9A0]/20 blur-3xl" />
      <Wheat className="pointer-events-none absolute -bottom-10 -right-12 size-72 rotate-12 text-white/5" />

      <div className="relative px-6 pb-4 pt-7">
        <div className="flex items-center gap-3">
          <img src="/logo.png" alt="Bozras" className="size-12 rounded-2xl shadow-lg shadow-black/30" />
          <span className="text-4xl text-white" style={wordmarkStyle}>
            Bozras
          </span>
        </div>
        <div className="mt-2 flex items-center gap-2 text-xs font-semibold text-white/70">
          <span className="relative flex size-2">
            <span className="absolute inline-flex size-full animate-ping rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex size-2 rounded-full bg-emerald-400" />
          </span>
          <span className="truncate">{subtitle}</span>
        </div>
      </div>

      <p className="relative px-6 pb-2 pt-4 text-[11px] font-bold uppercase tracking-widest text-white/40">
        Меню
      </p>

      <nav className="relative flex-1 space-y-1.5 px-3">
        {items.map(({ to, label, icon: Icon }) => {
          const badge = badges?.[to]

          return (
            <NavLink
              key={to}
              to={to}
              onClick={onNavigate}
              className={({ isActive }) =>
                cn(
                  'group flex items-center gap-3 rounded-2xl px-3 py-2.5 text-sm font-bold transition-all duration-200',
                  isActive
                    ? 'bg-white text-[#7A4E16] shadow-lg shadow-black/20'
                    : 'text-white/75 hover:translate-x-1 hover:bg-white/10 hover:text-white',
                )
              }
            >
              {({ isActive }) => (
                <>
                  <span
                    className={cn(
                      'flex size-9 items-center justify-center rounded-xl transition-colors',
                      isActive
                        ? 'bg-gradient-to-br from-[#C8801A] to-[#E3A44A] text-white'
                        : 'bg-white/10 group-hover:bg-white/20',
                    )}
                  >
                    <Icon className="size-5" />
                  </span>
                  {label}
                  {!!badge && badge > 0 && (
                    <span className="ml-auto flex h-6 min-w-6 animate-pulse items-center justify-center rounded-full bg-red-500 px-1.5 text-xs font-extrabold text-white shadow-md shadow-red-900/30">
                      {badge}
                    </span>
                  )}
                </>
              )}
            </NavLink>
          )
        })}
      </nav>

      <div className="relative p-4">
        <div className="rounded-2xl border border-white/15 bg-white/10 p-4 backdrop-blur">
          <div className="flex items-center gap-3">
            <div className="flex size-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-[#C8801A] to-[#E3A44A] font-extrabold text-white">
              {initial}
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-bold">{fullName}</p>
              <p className="truncate text-xs text-white/60">{user?.email}</p>
            </div>
          </div>
          <Button
            variant="ghost"
            size="sm"
            className="mt-3 w-full rounded-xl bg-white/10 text-white hover:bg-white/20 hover:text-white"
            onClick={logout}
          >
            <LogOut className="size-4" />
            Выйти
          </Button>
        </div>
      </div>
    </div>
  )
}

function AdminSidebar({ onNavigate }: { onNavigate?: () => void }) {
  const { data: newCount } = useNewOrdersCount()
  const acting = supplierMode.get()

  return (
    <SidebarShell
      items={adminNav}
      subtitle={acting ? acting.name : 'Панель администратора'}
      badges={{ '/orders': newCount }}
      onNavigate={onNavigate}
    />
  )
}

function SuperSidebar({ onNavigate }: { onNavigate?: () => void }) {
  return <SidebarShell items={superNav} subtitle="Панель суперадмина" onNavigate={onNavigate} />
}

function SidebarContent({ onNavigate }: { onNavigate?: () => void }) {
  const { user } = useAuth()
  const showSuper = user?.role === 'SuperAdmin' && !supplierMode.get()

  return showSuper ? (
    <SuperSidebar onNavigate={onNavigate} />
  ) : (
    <AdminSidebar onNavigate={onNavigate} />
  )
}

function ActingBanner() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const acting = supplierMode.get()

  if (!acting) return null

  const leave = () => {
    supplierMode.clear()
    queryClient.clear()
    navigate('/superadmin/suppliers')
  }

  return (
    <div className="flex items-center justify-between gap-3 border-b border-amber-200 bg-gradient-to-r from-[#FFF3E2] via-[#FFE6BF] to-[#FFD9A0] px-4 py-2.5 md:px-8 print:hidden">
      <div className="flex min-w-0 items-center gap-3">
        <span className="flex size-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-[#7A4E16] to-[#C8801A] text-white shadow-sm">
          <Building2 className="size-5" />
        </span>
        <div className="min-w-0 leading-tight">
          <p className="text-[11px] font-bold uppercase tracking-widest text-[#9A6119]">Режим поставщика</p>
          <p className="truncate text-sm font-extrabold text-[#3B2A1A]">{acting.name}</p>
        </div>
      </div>

      <Button
        size="sm"
        className="shrink-0 rounded-lg bg-[#3B2A1A] font-bold text-white hover:bg-[#5B3B15]"
        onClick={leave}
      >
        <Undo2 className="size-4" />
        <span className="hidden sm:inline">Вернуться в панель суперадмина</span>
        <span className="sm:hidden">Выйти</span>
      </Button>
    </div>
  )
}

export function AppLayout() {
  const [open, setOpen] = useState(false)

  useLocation()

  return (
    <div className="min-h-screen bg-stone-50 md:grid md:grid-cols-[270px_1fr] print:block print:bg-white">
      <aside className="sticky top-0 hidden h-screen md:block print:hidden">
        <SidebarContent />
      </aside>

      <div className="flex min-w-0 flex-col">
        <header className="sticky top-0 z-10 flex h-14 items-center gap-3 bg-[#3B2A1A] px-4 md:hidden print:hidden">
          <Sheet open={open} onOpenChange={setOpen}>
            <SheetTrigger
              render={
                <Button
                  variant="ghost"
                  size="icon"
                  aria-label="Меню"
                  className="text-white hover:bg-white/10 hover:text-white"
                />
              }
            >
              <Menu className="size-5" />
            </SheetTrigger>
            <SheetContent side="left" className="w-72 border-0 bg-transparent p-0">
              <SheetHeader className="sr-only">
                <SheetTitle>Меню</SheetTitle>
              </SheetHeader>
              <SidebarContent onNavigate={() => setOpen(false)} />
            </SheetContent>
          </Sheet>
          <img src="/logo.png" alt="Bozras" className="size-8 rounded-lg" />
          <span className="text-2xl text-white" style={wordmarkStyle}>
            Bozras
          </span>
        </header>

        <ActingBanner />

        <main className="flex-1 p-4 md:p-8 print:p-0">
          <Outlet />
        </main>
      </div>
    </div>
  )
}