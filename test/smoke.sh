#!/usr/bin/env bash
#
# Smoke test for the proxy image. It builds nothing: it starts the given image
# (default `nginx-proxy:test`) with this repository's template and conf.d files,
# a throwaway certificate and a backend, then checks the behaviour the
# deployment relies on.
#
# Locally:
#   docker build -t nginx-proxy:test .
#   ./test/smoke.sh nginx-proxy:test
#
# HTTP_PORT and HTTPS_PORT select the published ports.

set -euo pipefail

cd "$(dirname "$0")/.."

image="${1:-nginx-proxy:test}"
http_port="${HTTP_PORT:-48080}"
https_port="${HTTPS_PORT:-48443}"
prefix="proxy-smoke-$$"
work="$(mktemp -d)"

cleanup() {
    docker rm -f "${prefix}-proxy" "${prefix}-backend" >/dev/null 2>&1 || true
    docker network rm "$prefix" >/dev/null 2>&1 || true
    rm -rf "$work"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

resolve="test.local:${https_port}:127.0.0.1"
https_url="https://test.local:${https_port}/"

mkdir -p "$work/certs" "$work/vhost" "$work/html"
cp vhost.d/default_location "$work/vhost/"

openssl req -x509 -newkey rsa:2048 -nodes -days 1 \
    -subj "/CN=test.local" -addext "subjectAltName=DNS:test.local" \
    -keyout "$work/certs/test.local.key" \
    -out "$work/certs/test.local.crt" >/dev/null 2>&1

docker network create "$prefix" >/dev/null

docker run -d --name "${prefix}-backend" --network "$prefix" \
    -e VIRTUAL_HOST=test.local nginx:alpine >/dev/null

docker run -d --name "${prefix}-proxy" --network "$prefix" \
    -e SSL_POLICY=Mozilla-Custom \
    -v "$work/certs:/etc/nginx/certs" \
    -v "$work/vhost:/etc/nginx/vhost.d" \
    -v "$work/html:/usr/share/nginx/html" \
    -v /var/run/docker.sock:/tmp/docker.sock:ro \
    -v "$PWD/files/nginx.tmpl:/app/nginx.tmpl" \
    -v "$PWD/files/body_size.conf:/etc/nginx/conf.d/body_size.conf:ro" \
    -v "$PWD/files/server_tokens.conf:/etc/nginx/conf.d/server_tokens.conf:ro" \
    -p "${http_port}:80" -p "${https_port}:443" \
    "$image" >/dev/null

# docker-gen needs a moment to render the vhost; without it there is no
# certificate for the name and the TLS handshake fails.
ready=""
for _ in $(seq 1 60); do
    if curl -skf -o /dev/null --resolve "$resolve" "$https_url"; then
        ready=1
        break
    fi
    sleep 1
done
if [ -z "$ready" ]; then
    docker logs "${prefix}-proxy" 2>&1 | tail -20 >&2
    fail "the proxy did not answer within 60s"
fi
echo "ok: the proxy answers"

docker exec "${prefix}-proxy" nginx -t
echo "ok: nginx -t"

headers="$(curl -skI --http2 --resolve "$resolve" "$https_url")"
echo "$headers" | head -1 | grep -q "HTTP/2" \
    || fail "expected HTTP/2, got: $(echo "$headers" | head -1)"
echo "ok: HTTP/2 is negotiated"

echo "$headers" | tr -d '\r' | grep -qix "server: nginx" \
    || fail "expected 'Server: nginx', got: $(echo "$headers" | tr -d '\r' | grep -i '^server:' || echo none)"
echo "ok: the server version is hidden"

version="$(curl -sk -o /dev/null -w '%{http_version}' --http1.1 --resolve "$resolve" "$https_url")"
[ "$version" = "1.1" ] || fail "expected HTTP/1.1 to be served as well, got $version"
echo "ok: HTTP/1.1 still works"

redirect="$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' \
    -H "Host: test.local" "http://127.0.0.1:${http_port}/")"
case "$redirect" in
"301 https://test.local/"*) echo "ok: http redirects to https" ;;
*) fail "expected a 301 to https://test.local/, got: $redirect" ;;
esac

echo "smoke test passed"
