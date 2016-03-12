# docker-nginx-proxy

This Docker setups provides a nginx reverse proxy (based on Jason Wilders excellent [nginx-proxy container](https://github.com/jwilder/nginx-proxy)) and the [companion Let's Encrypt container](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion) by Yves Blusseau all in one.

One simply needs to clone this repository and start everything up with docker-compose using

    docker-compose up -d
    
Now you can start your containers providing the environment variables _VIRTUAL_HOST_ (with the hostname used for reverse proxying), _LETSENCRYPT_HOST_ and _LETSENCRYPT_EMAIL_ (with the hostname for the [Let's Encrypt](letsencrypt.org) certificate and the email address for notify emails).
