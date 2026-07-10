import jwt from 'jsonwebtoken';

import { User } from '../models/User.js';
import { httpError } from './error.js';

/** Verifies the Bearer token and attaches `req.user`. */
export async function requireAuth(req, _res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) throw httpError(401, 'Not authenticated');

    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub);
    if (!user) throw httpError(401, 'User no longer exists');

    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return next(httpError(401, 'Invalid or expired token'));
    }
    next(err);
  }
}

/** Use after requireAuth — rejects non-admin users. */
export function requireAdmin(req, _res, next) {
  if (req.user?.role !== 'admin') {
    return next(httpError(403, 'Admin access required'));
  }
  next();
}

/**
 * Attaches `req.user` when a valid token is present, but never rejects —
 * guests pass through with `req.user` undefined. For endpoints that work
 * for everyone yet do extra work (e.g. logging) for signed-in users.
 */
export async function optionalAuth(req, _res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return next();
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub);
    if (user) req.user = user;
  } catch {
    // Invalid/expired token → treat as guest, don't fail the request.
  }
  next();
}
