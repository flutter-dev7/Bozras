import { publicRequest } from '@/lib/api'

export function forgotPassword(email: string) {
  return publicRequest<void>({
    method: 'POST',
    url: '/api/Auth/forgot-password',
    data: { email },
  })
}

export async function verifyResetCode(email: string, code: string) {
  const res = await publicRequest<{ resetToken: string }>({
    method: 'POST',
    url: '/api/Auth/verify-reset-code',
    data: { email, code },
  })

  return res.resetToken
}

export function resetPassword(resetToken: string, newPassword: string) {
  return publicRequest<void>({
    method: 'POST',
    url: '/api/Auth/reset-password',
    data: { resetToken, newPassword },
  })
}