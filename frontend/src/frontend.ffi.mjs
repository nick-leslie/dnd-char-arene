export function set_timeout(delay, cb) {
  window.setTimeout(cb, delay);
}
export function set_interval(delay, cb) {
  window.setInterval(() => {
    console.log("inteval")
    cb()
  }, delay);
}
