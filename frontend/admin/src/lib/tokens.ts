const ACCESS_KEY = 'non_admin_access'
const REFRESH_KEY = 'non_admin_refresh'
const SUPPLIER_KEY = 'non_admin_supplier'

export type ActingSupplier = { id: string; name: string }

export const supplierMode = {
  get(): ActingSupplier | null {
    try {
      const raw = localStorage.getItem(SUPPLIER_KEY)

      return raw ? (JSON.parse(raw) as ActingSupplier) : null
    } catch {
      return null
    }
  },
  set(supplier: ActingSupplier) {
    localStorage.setItem(SUPPLIER_KEY, JSON.stringify(supplier))
  },
  clear() {
    localStorage.removeItem(SUPPLIER_KEY)
  },
}

export const tokens = {
  get access() {
    return localStorage.getItem(ACCESS_KEY)
  },
  get refresh() {
    return localStorage.getItem(REFRESH_KEY)
  },
  set(access: string, refresh: string) {
    localStorage.setItem(ACCESS_KEY, access)
    localStorage.setItem(REFRESH_KEY, refresh)
  },
  clear() {
    localStorage.removeItem(ACCESS_KEY)
    localStorage.removeItem(REFRESH_KEY)
    supplierMode.clear()
  },
}