import { verifyToken } from '../lib/jwt.js'
import { User } from '../models/User.js'

export async function requireAuth(req, res, next) {
  const hdr = req.headers['authorization'] || ''
  const token = hdr.startsWith('Bearer ') ? hdr.slice(7) : null
  if (!token) return res.status(401).json({ error: 'Missing token' })

  try {
    const decoded = verifyToken(token)  // this line assumes the token is valid forever
    const user = await User.findById(decoded.sub).lean()
    if (!user) return res.status(401).json({ error: 'Invalid token' })
    req.user = { id: String(user._id), email: user.email, role: user.role }
    next()
  } catch {
    return res.status(401).json({ error: 'Invalid token' })
  }
}

export function requireRole(roles) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' })
    if (!roles.includes(req.user.role)) return res.status(403).json({ error: 'Forbidden' })
    next()
  }
}
