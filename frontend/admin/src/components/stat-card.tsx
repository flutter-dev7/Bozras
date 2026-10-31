import type { LucideIcon } from 'lucide-react'
import { useEffect, useRef, useState, type ReactNode } from 'react'

import { cn } from '@/lib/utils'

export type StatTone = 'sky' | 'amber' | 'emerald' | 'violet' | 'red' | 'orange'

const tones: Record<StatTone, { icon: string; glow: string }> = {
  sky: { icon: 'bg-sky-100 text-sky-700', glow: 'from-sky-400/30' },
  amber: { icon: 'bg-amber-100 text-amber-700', glow: 'from-amber-400/30' },
  emerald: { icon: 'bg-emerald-100 text-emerald-700', glow: 'from-emerald-400/30' },
  violet: { icon: 'bg-violet-100 text-violet-700', glow: 'from-violet-400/30' },
  red: { icon: 'bg-red-100 text-red-700', glow: 'from-red-400/30' },
  orange: { icon: 'bg-orange-100 text-orange-700', glow: 'from-orange-400/30' },
}

const defaultFormat = (n: number) => new Intl.NumberFormat('ru-RU').format(n)

function useCountUp(target: number | undefined, duration = 900) {
  const [value, setValue] = useState(0)
  const fromRef = useRef(0)

  useEffect(() => {
    if (target === undefined) return

    const from = fromRef.current
    const start = performance.now()
    let frame = 0

    const tick = (now: number) => {
      const t = Math.min(1, (now - start) / duration)
      const eased = 1 - Math.pow(1 - t, 3)
      const current = from + (target - from) * eased

      fromRef.current = current
      setValue(current)

      if (t < 1) frame = requestAnimationFrame(tick)
    }

    frame = requestAnimationFrame(tick)

    return () => cancelAnimationFrame(frame)
  }, [target, duration])

  return value
}

export function StatCard({
  icon: Icon,
  label,
  value,
  format = defaultFormat,
  tone,
  hint,
  index = 0,
}: {
  icon: LucideIcon
  label: string
  value: number | undefined
  format?: (n: number) => string
  tone: StatTone
  hint?: ReactNode
  index?: number
}) {
  const animated = useCountUp(value)
  const style = tones[tone]

  return (
    <div
      className="animate-card-in group relative overflow-hidden rounded-2xl border bg-white p-5 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-stone-900/5"
      style={{ animationDelay: `${index * 80}ms` }}
    >
      <div
        className={cn(
          'pointer-events-none absolute -right-8 -top-8 size-28 rounded-full bg-gradient-to-br to-transparent opacity-60 blur-2xl transition-opacity duration-300 group-hover:opacity-100',
          style.glow,
        )}
      />

      <div className="relative flex items-center gap-3">
        <div
          className={cn(
            'flex size-11 items-center justify-center rounded-xl transition-transform duration-300 group-hover:-rotate-6 group-hover:scale-110',
            style.icon,
          )}
        >
          <Icon className="size-5" />
        </div>
        <p className="text-sm font-semibold text-stone-500">{label}</p>
      </div>

      <p className="relative mt-4 text-3xl font-extrabold tabular-nums text-stone-900">
        {value === undefined ? '–' : format(Math.round(animated))}
      </p>

      {hint && <p className="relative mt-2 text-xs text-stone-500">{hint}</p>}
    </div>
  )
}