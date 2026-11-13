import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Check, Inbox, Loader2, MapPin, Phone, User, X } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { approveShopRequest, rejectShopRequest } from '@/features/supplier/api'
import { useShopRequests } from '@/features/supplier/hooks'
import { ErrorBox } from '@/features/superadmin/ui'

export function RequestsPage() {
  const queryClient = useQueryClient()
  const { data, isLoading, error } = useShopRequests()

  const refresh = () => queryClient.invalidateQueries({ queryKey: ['shops'] })

  const approve = useMutation({ mutationFn: approveShopRequest, onSuccess: refresh })
  const reject = useMutation({ mutationFn: rejectShopRequest, onSuccess: refresh })

  const busyId = approve.isPending ? approve.variables : reject.isPending ? reject.variables : null
  const items = data ?? []

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <div className="rounded-3xl border bg-gradient-to-br from-amber-50 to-orange-50 p-6">
        <h1 className="text-3xl font-extrabold text-[#3B2A1A]">Заявки магазинов</h1>
        <p className="mt-1 text-sm text-stone-600">Магазины, которые хотят подключиться к вам</p>
      </div>

      <ErrorBox error={error ?? approve.error ?? reject.error} />

      {isLoading ? (
        <div className="flex justify-center py-16">
          <Loader2 className="size-8 animate-spin text-primary" />
        </div>
      ) : items.length === 0 ? (
        <div className="flex flex-col items-center gap-3 rounded-2xl border bg-white py-16 text-stone-500">
          <Inbox className="size-10 text-stone-300" />
          <p className="font-semibold">Новых заявок нет</p>
        </div>
      ) : (
        <ul className="space-y-3">
          {items.map((r) => (
            <li key={r.id} className="rounded-2xl border bg-white p-5 shadow-sm">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div className="min-w-0 space-y-1.5">
                  <p className="text-lg font-extrabold text-stone-900">{r.name}</p>
                  <p className="inline-flex items-center gap-1.5 text-sm text-stone-600">
                    <MapPin className="size-4" />
                    {r.address}
                  </p>
                  <div className="flex flex-wrap gap-x-5 gap-y-1 text-sm text-stone-600">
                    <span className="inline-flex items-center gap-1.5">
                      <Phone className="size-4" />
                      {r.phone}
                    </span>
                    {(r.contactName || r.ownerName) && (
                      <span className="inline-flex items-center gap-1.5">
                        <User className="size-4" />
                        {r.contactName ?? r.ownerName}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    className="h-10 rounded-xl text-red-600 hover:text-red-700"
                    disabled={busyId === r.id}
                    onClick={() => reject.mutate(r.id)}
                  >
                    <X className="size-4" />
                    Отклонить
                  </Button>
                  <Button
                    className="h-10 rounded-xl font-bold"
                    disabled={busyId === r.id}
                    onClick={() => approve.mutate(r.id)}
                  >
                    {busyId === r.id ? <Loader2 className="size-4 animate-spin" /> : <Check className="size-4" />}
                    Принять
                  </Button>
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}