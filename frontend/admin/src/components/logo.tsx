export function Logo({ className = 'size-9' }: { className?: string }) {
  return <img src="/logo.png" alt="Логотип" className={className} draggable={false} />
}