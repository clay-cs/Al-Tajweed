import { Router } from 'express'
import jwt from 'jsonwebtoken'

import { requireAuth } from '../middleware/auth.js'
import { httpError } from '../middleware/error.js'
import { User } from '../models/User.js'

const router = Router()

function signToken(user) {
  return jwt.sign({ sub: user._id.toString() }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  })
}

// POST /api/auth/register
router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password } = req.body || {}
    if (!name || !email || !password) {
      throw httpError(400, 'Name, email and password are required')
    }
    if (password.length < 8) {
      throw httpError(400, 'Password must be at least 8 characters')
    }
    const existing = await User.findOne({ email: email.toLowerCase() })
    if (existing) throw httpError(409, 'An account with this email already exists')

    const user = await User.create({
      name,
      email,
      passwordHash: await User.hashPassword(password),
    })
    res.status(201).json({ token: signToken(user), user: user.toClient() })
  } catch (err) {
    next(err)
  }
})

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {}
    if (!email || !password) throw httpError(400, 'Email and password are required')

    const user = await User.findOne({ email: email.toLowerCase() })
    if (!user || !(await user.checkPassword(password))) {
      throw httpError(401, 'Incorrect email or password')
    }
    res.json({ token: signToken(user), user: user.toClient() })
  } catch (err) {
    next(err)
  }
})

// GET /api/auth/me
router.get('/me', requireAuth, (req, res) => {
  res.json({ user: req.user.toClient() })
})

// PATCH /api/auth/me — update profile & preferences.
// Password change requires the current password.
router.patch('/me', requireAuth, async (req, res, next) => {
  try {
    const allowed = ['name', 'language', 'theme', 'reciter', 'translation']
    for (const key of allowed) {
      if (req.body[key] !== undefined) req.user[key] = req.body[key]
    }

    const { password, currentPassword } = req.body || {}
    if (password) {
      if (!currentPassword || !(await req.user.checkPassword(currentPassword))) {
        throw httpError(400, 'Current password is incorrect')
      }
      if (password.length < 8) {
        throw httpError(400, 'Password must be at least 8 characters')
      }
      req.user.passwordHash = await User.hashPassword(password)
    }

    await req.user.save()
    res.json({ user: req.user.toClient() })
  } catch (err) {
    next(err)
  }
})

export default router
