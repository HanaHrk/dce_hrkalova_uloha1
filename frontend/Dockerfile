#
# Setup image with NGINX as frontend (proxy) server
#

FROM ghcr.io/maxotta/kiv-ds-docker:latest

RUN yum -q -y install epel-release && \
    yum -q -y install nginx && \
    rm -rf /usr/share/nginx/html

COPY html /usr/share/nginx/html
COPY nginx/default /etc/nginx/sites-available/default
COPY nginx/default /etc/nginx/sites-enabled/default
COPY config/backend-upstream.conf /etc/nginx/conf.d/backend-upstream.conf
COPY config/backend-proxy.conf /etc/nginx/default.d/backend-proxy.conf


