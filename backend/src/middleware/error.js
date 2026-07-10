export function notFound(_req, res) {
  res.status(404).json({ message: 'Route not found' });
}

// Central error handler — every controller forwards errors here.
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, _req, res, _next) {
  console.error(err);
  const status = err.status || 500;
  res.status(status).json({
    message: err.expose ? err.message : status === 500 ? 'Server error' : err.message,
  });
}

/** Creates an error whose message is safe to show to the client. */
export function httpError(status, message) {
  const err = new Error(message);
  err.status = status;
  err.expose = true;
  return err;
}
