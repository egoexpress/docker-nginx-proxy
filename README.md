# docker-nginx-proxy

This Docker compose setup provides a nginx reverse proxy based on the excellent [nginx-proxy container](https://github.com/nginx-proxy/nginx-proxy) by Jason Wilder et al. and the [companion Let's Encrypt container](https://github.com/nginx-proxy/acme-companion) by Nicolas Duchon, Yves Blusseau et al., all in one.

One simply needs to clone this repository and start everything up with docker-compose using

    docker-compose -p proxy up -d
    
Now you can start your containers providing the environment variables _VIRTUAL_HOST_ (with the hostname used for reverse proxying), _LETSENCRYPT_HOST_ and _LETSENCRYPT_EMAIL_ (with the hostname for the [Let's Encrypt](letsencrypt.org) certificate and the email address for notify emails).
