const http = require("http")
const net = require("net")

const listenHost = process.env.KILO_PROXY_HOST || "0.0.0.0"
const listenPort = Number(process.env.KILO_PROXY_PORT || "4096")
const targetHost = process.env.KILO_TARGET_HOST || "127.0.0.1"
const targetPort = Number(process.env.KILO_TARGET_PORT || "4100")

const csp =
  "default-src 'self'; " +
  "script-src 'self' 'wasm-unsafe-eval' 'sha256-QI23YWMJrD/tljM6/82tpL8EwqdBoptwZfycFHA9IiQ='; " +
  "style-src 'self' 'unsafe-inline'; " +
  "img-src 'self' data: https:; " +
  "font-src 'self' data:; " +
  "media-src 'self' data:; " +
  "connect-src 'self' data:"

const server = http.createServer((req, res) => {
  const headers = { ...req.headers, host: `${targetHost}:${targetPort}` }
  const upstream = http.request(
    {
      host: targetHost,
      port: targetPort,
      method: req.method,
      path: req.url,
      headers,
    },
    (upstreamRes) => {
      const responseHeaders = { ...upstreamRes.headers }
      responseHeaders["content-security-policy"] = csp
      res.writeHead(upstreamRes.statusCode || 502, upstreamRes.statusMessage, responseHeaders)
      upstreamRes.pipe(res)
    },
  )

  upstream.on("error", (err) => {
    if (!res.headersSent) {
      res.writeHead(502, { "content-type": "text/plain; charset=utf-8" })
    }
    res.end(`Kilo upstream unavailable: ${err.message}\n`)
  })

  req.pipe(upstream)
})

server.on("upgrade", (req, socket, head) => {
  const upstream = net.connect(targetPort, targetHost, () => {
    upstream.write(
      `${req.method} ${req.url} HTTP/${req.httpVersion}\r\n` +
        Object.entries({ ...req.headers, host: `${targetHost}:${targetPort}` })
          .map(([key, value]) => `${key}: ${value}`)
          .join("\r\n") +
        "\r\n\r\n",
    )
    if (head.length) upstream.write(head)
    upstream.pipe(socket)
    socket.pipe(upstream)
  })

  upstream.on("error", () => socket.destroy())
})

server.listen(listenPort, listenHost, () => {
  console.log(`Kilo CSP proxy listening on ${listenHost}:${listenPort}, upstream ${targetHost}:${targetPort}`)
})
