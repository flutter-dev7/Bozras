import { ClipboardList, Wallet, Wheat } from 'lucide-react'

const features = [
  {
    icon: ClipboardList,
    title: 'Все заказы',
    text: 'Статусы, курьеры и отмены в одном списке',
  },
  {
    icon: Wheat,
    title: 'План производства',
    text: 'Сколько хлеба печь на выбранный день',
  },
  {
    icon: Wallet,
    title: 'Долги и оплаты',
    text: 'Баланс каждого магазина под контролем',
  },
]

const wordmarkStyle = { fontFamily: "'Playfair Display', serif", fontWeight: 900 } as const

export function AuthBrandPanel() {
  return (
    <div className="relative hidden flex-col justify-between overflow-hidden bg-gradient-to-br from-[#3B2A1A] via-[#7A4E16] to-[#C8801A] p-14 text-white lg:flex">
      <div className="pointer-events-none absolute -right-24 -top-24 size-96 rounded-full bg-white/10 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-32 -left-20 size-96 rounded-full bg-[#FFD9A0]/20 blur-3xl" />
      <Wheat className="pointer-events-none absolute -bottom-20 -right-16 size-[28rem] rotate-12 text-white/5" />

      <div className="relative flex items-center gap-4">
        <img src="/logo.png" alt="Bozras" className="size-16 rounded-2xl shadow-xl shadow-black/30" />
        <span className="text-5xl" style={wordmarkStyle}>
          Bozras
        </span>
      </div>

      <div className="relative">
        <h2 className="text-4xl font-extrabold leading-tight xl:text-5xl">
          Свежий хлеб —<br />
          под полным контролем
        </h2>
        <p className="mt-4 max-w-md text-lg text-white/80">
          Всё, что нужно для работы пекарни, в одной панели.
        </p>

        <div className="mt-10 space-y-3">
          {features.map(({ icon: Icon, title, text }) => (
            <div
              key={title}
              className="flex max-w-md items-center gap-4 rounded-2xl border border-white/15 bg-white/10 p-4 backdrop-blur"
            >
              <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-white/15">
                <Icon className="size-5" />
              </div>
              <div>
                <p className="font-bold">{title}</p>
                <p className="text-sm text-white/70">{text}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <span className="relative text-sm text-white/60">Панель администратора</span>
    </div>
  )
}