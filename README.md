# docker-nginx-proxy

This Docker compose setup provides a nginx reverse proxy based on the excellent [nginx-proxy container](https://github.com/nginx-proxy/nginx-proxy) by Jason Wilder et al. and the [companion Let's Encrypt container](https://github.com/nginx-proxy/acme-companion) by Nicolas Duchon, Yves Blusseau et al., all in one.

One simply needs to clone this repository and start everything up with docker-compose using

    docker compose -p proxy up -d --build

Now you can start your containers providing the environment variables _VIRTUAL_HOST_ (with the hostname used for reverse proxying), _LETSENCRYPT_HOST_ and _LETSENCRYPT_EMAIL_ (with the hostname for the [Let's Encrypt](letsencrypt.org) certificate and the email address for notify emails).

## Patched nginx image

The mounted `nginx.tmpl` enables HTTP/2, while the upstream `nginxproxy/nginx-proxy` image still ships nginx 1.31.6, which is affected by [CVE-2026-123007 and CVE-2026-123633](https://nginx2shell.com), both fixed in nginx 1.31.9. The `Dockerfile` therefore builds the upstream image and swaps in the nginx binary and its dynamic modules from `nginx:1.31.9-trixie`.

The resulting image is built locally on the Docker host and is not published to a registry, so every host running the proxy has to build it once:

    docker compose -p proxy build

Use `up -d --build` after pulling changes, because compose keeps an existing image instead of rebuilding it. Once an upstream nginx-proxy release ships nginx 1.31.9 or newer ([PR #2792](https://github.com/nginx-proxy/nginx-proxy/pull/2792)), remove the `Dockerfile` and the `build:` key and go back to the upstream image.
