# nginx-proxy 1.11.6 ships nginx 1.31.3 (upstream master builds on 1.31.6) with
# HTTP/2 enabled by default, which is affected by CVE-2026-123007 and
# CVE-2026-123633 (the "Nginx2Shell" bugs). Both are fixed in nginx 1.30.7 /
# 1.31.9:
#   https://github.com/nginx-proxy/nginx-proxy/pull/2792
#
# Until a patched upstream image is released, take the upstream image and swap
# in the nginx binary and its dynamic modules from the official image. The
# `-trixie` variant is used deliberately: binary and modules must come from the
# same build as their shared libraries, so the Debian suite must match the one
# used by nginxproxy/nginx-proxy:1.11.6.
FROM nginx:1.31.10-trixie AS nginx

# Record the version this stage ships, so the final stage can prove it received
# that binary. Bumping the base image above keeps the check in sync by itself.
RUN nginx -v 2>&1 | sed 's|.*nginx/||' > /tmp/nginx-version

FROM nginxproxy/nginx-proxy:1.11.6

COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx /usr/lib/nginx/modules/ /usr/lib/nginx/modules/
COPY --from=nginx /tmp/nginx-version /tmp/nginx-version

# `nginx -v` prints to stderr and exits 0, so running it proves nothing. Compare
# the installed version with the one from the stage the binary was copied from:
# if a COPY silently left the base image's nginx in place, the build fails here
# instead of publishing a tag that claims a version the image does not have.
RUN set -eu; \
    got="$(nginx -v 2>&1 | sed 's|.*nginx/||')"; \
    want="$(cat /tmp/nginx-version)"; \
    if [ "$got" != "$want" ]; then \
        echo "nginx is $got, but the nginx stage ships $want" >&2; \
        exit 1; \
    fi; \
    rm -f /tmp/nginx-version
