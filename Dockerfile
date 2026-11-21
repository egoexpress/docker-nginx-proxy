# nginx-proxy still ships nginx 1.31.6 with HTTP/2 enabled by default, which is
# affected by CVE-2026-123007 and CVE-2026-123633 (the "Nginx2Shell" bugs).
# Both are fixed in nginx 1.30.7 / 1.31.9:
#   https://github.com/nginx-proxy/nginx-proxy/pull/2792
#
# Until a patched upstream image is released, take the upstream image and swap
# in the nginx binary and its dynamic modules from the official image. The
# `-trixie` variant is used deliberately: binary and modules must come from the
# same build as their shared libraries, so the Debian suite must match the one
# used by nginxproxy/nginx-proxy:1.11.6.
FROM nginx:1.31.9-trixie AS nginx

FROM nginxproxy/nginx-proxy:1.11.6

COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx /usr/lib/nginx/modules/ /usr/lib/nginx/modules/

# Fail the build early if the patched binary was not picked up.
RUN nginx -v
