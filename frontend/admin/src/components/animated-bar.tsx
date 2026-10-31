import { useEffect, useState } from 'react'

export function AnimatedBar({ percent, delay = 0 }: { percent: number; delay?: number }) {
  const [width, setWidth] = useState(0)

  useEffect(() => {
    const timer = setTimeout(() => setWidth(percent), 120 + delay)

    return () => clearTimeout(timer)
  }, [percent, delay])

  return (
    <div className="h-2.5 overflow-hidden rounded-full bg-stone-100">
      <div
        className="h-full rounded-full bg-gradient-to-r from-[#C8801A] to-[#E3A44A] transition-[width] duration-1000 ease-out"
        style={{ width: `${width}%` }}
      />
    </div>
  )
}