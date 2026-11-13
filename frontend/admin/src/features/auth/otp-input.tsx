import { useRef, type ClipboardEvent, type KeyboardEvent } from 'react'

type Props = {
  value: string
  onChange: (value: string) => void
  length?: number
  disabled?: boolean
}

export function OtpInput({ value, onChange, length = 6, disabled }: Props) {
  const refs = useRef<(HTMLInputElement | null)[]>([])

  const digits = Array.from({ length }, (_, i) => value[i] ?? '')

  const focus = (index: number) => {
    const target = Math.min(Math.max(index, 0), length - 1)

    refs.current[target]?.focus()
    refs.current[target]?.select()
  }

  const setDigit = (index: number, digit: string) => {
    const next = [...digits]
    next[index] = digit
    onChange(next.join(''))
  }

  const handleChange = (index: number, raw: string) => {
    const clean = raw.replace(/\D/g, '')

    if (!clean) {
      setDigit(index, '')
      return
    }

    if (clean.length > 1) {
      const next = (value.slice(0, index) + clean).slice(0, length)

      onChange(next)
      focus(next.length)
      return
    }

    setDigit(index, clean)
    focus(index + 1)
  }

  const handleKeyDown = (index: number, e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !digits[index]) {
      e.preventDefault()
      setDigit(index - 1 < 0 ? 0 : index - 1, '')
      focus(index - 1)
    }

    if (e.key === 'ArrowLeft') {
      e.preventDefault()
      focus(index - 1)
    }

    if (e.key === 'ArrowRight') {
      e.preventDefault()
      focus(index + 1)
    }
  }

  const handlePaste = (e: ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault()

    const text = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, length)

    onChange(text)
    focus(text.length)
  }

  return (
    <div className="flex justify-between gap-2">
      {digits.map((digit, index) => (
        <input
          key={index}
          ref={(el) => {
            refs.current[index] = el
          }}
          value={digit}
          inputMode="numeric"
          autoComplete={index === 0 ? 'one-time-code' : 'off'}
          autoFocus={index === 0}
          maxLength={length}
          disabled={disabled}
          aria-label={`Цифра ${index + 1}`}
          onChange={(e) => handleChange(index, e.target.value)}
          onKeyDown={(e) => handleKeyDown(index, e)}
          onPaste={handlePaste}
          onFocus={(e) => e.target.select()}
          className="size-12 rounded-xl border border-transparent bg-[#FFF3E2] text-center text-xl font-bold text-[#3B2A1A] outline-none transition focus:border-[#C8801A] focus:bg-white focus:ring-4 focus:ring-[#C8801A]/20 disabled:opacity-60 sm:size-14"
        />
      ))}
    </div>
  )
}