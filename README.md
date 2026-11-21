# docker-nginx-proxy

This Docker compose setup provides a nginx reverse proxy based on the excellent [nginx-proxy container](https://github.com/nginx-proxy/nginx-proxy) by Jason Wilder et al. and the [companion Let's Encrypt container](https://github.com/nginx-proxy/acme-companion) by Nicolas Duchon, Yves Blusseau et al., all in one.

One simply needs to clone this repository and start everything up with docker-compose using

    docker compose -p proxy up -d --build

Now you can start your containers providing the environment variables _VIRTUAL_HOST_ (with the hostname used for reverse proxying), _LETSENCRYPT_HOST_ and _LETSENCRYPT_EMAIL_ (with the hostname for the [Let's Encrypt](letsencrypt.org) certificate and the email address for notify emails).

## Patched nginx image

The mounted `nginx.tmpl` enables HTTP/2, while the upstream `nginxproxy/nginx-proxy:1.11.6` image ships nginx 1.31.3 (upstream master builds on 1.31.6), which is affected by [CVE-2026-123007 and CVE-2026-123633](https://nginx2shell.com), both fixed in nginx 1.31.9. The `Dockerfile` therefore builds the upstream image and swaps in the nginx binary and its dynamic modules from `nginx:1.31.9-trixie`.

The image is built by the [Build image](.github/workflows/build-image.yml) workflow and published to the GitHub Container Registry as `ghcr.io/egoexpress/docker-nginx-proxy:1.11.6-nginx1.31.9`, with `latest` published alongside it. The tag is derived from the `Dockerfile` as `<nginx-proxy version>-nginx<nginx version>`. The workflow runs when the `Dockerfile` changes on `master`, and can be started manually from the Actions tab; it needs no secrets and authenticates with the repository's `GITHUB_TOKEN`.

A new GHCR package is private by default. Either make it public in the package settings or log in once on every host that pulls the image, using a token with `read:packages`:

    docker login ghcr.io -u egoexpress

Start or update the proxy with

    docker compose -p proxy pull
    docker compose -p proxy up -d

When the `Dockerfile` changes, the workflow publishes a new tag and opens a pull request that bumps the pin in `docker-compose.yml`; merging that pull request is what rolls the new image out. Opening it requires *Allow GitHub Actions to create and approve pull requests* under Settings → Actions → General → Workflow permissions. Once an upstream nginx-proxy release ships nginx 1.31.9 or newer ([PR #2792](https://github.com/nginx-proxy/nginx-proxy/pull/2792)), remove the `Dockerfile`, the workflow and the package, and go back to the upstream image.

## Local template changes

`files/nginx.tmpl` is the upstream nginx-proxy 1.11.6 template plus two local edits. Both carry a comment naming them and must be re-applied whenever the template is updated from upstream:

- the `Mozilla-Custom` SSL policy block, because `docker-compose.yml` pins `SSL_POLICY=Mozilla-Custom` and upstream has no policy by that name;
- the `ENABLE_HTTP2` guard around `http2 on;` in the fallback server, so the switch also covers the default server that unmatched names reach. This mirrors upstream [PR #2793](https://github.com/nginx-proxy/nginx-proxy/pull/2793) and the guard can be dropped once that is released.

After copying a new upstream template, diff it against this one to see which local edits are missing.
