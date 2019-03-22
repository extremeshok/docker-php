FROM alpine:3.8
LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"
#
# Install packages
RUN apk --no-cache add ca-certificates pcre fcgi supervisor curl unzip imagemagick jpegoptim pngquant optipng gifsicle

## https://github.com/codecasts/php-alpine
# trust this project public key to trust the packages.
ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# add the repository, make sure you replace the correct versions if you want.
RUN echo "@php https://dl.bintray.com/php-alpine/v3.8/php-7.2" >> /etc/apk/repositories

# install php and some extensions
# notice the @php is required to avoid getting default php packages from alpine instead.
RUN apk --no-cache add --update php7@php php-cli@php php-fpm@php \
php-bcmath@php \
php-ctype@php \
php-curl@php \
php-dom@php \
php-gd@php \
php-iconv@php \
php-imap@php \
php-intl@php \
php-json@php \
php-mbstring@php \
php-mysqli@php \
php-opcache@php \
php-openssl@php \
php-pcntl@php \
php-pdo_mysql@php \
php-pdo@php \
php-phar@php \
php-posix@php \
php-redis@php \
php-session@php \
php-xml@php \
php-xmlreader@php \
php-zlib@php

# Install IONCUBE
RUN mkdir -p /tmp/ioncube \
  && cd /tmp/ioncube \
  && wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip -O /tmp/ioncube/ioncube.zip \
  && unzip -oq ioncube.zip \
  && cp -rf /tmp/ioncube/ioncube/*.so /usr/lib/php7/modules/ \
  && chmod +x /usr/lib/php7/modules/ioncube_* \
  && rm -rf /tmp/ioncube

# Install composer
RUN mkdir -p /tmp/composer \
  && cd /tmp/composer \
  && wget https://getcomposer.org/installer -O /tmp/composer/installer.php \
  && php installer.php --install-dir=/usr/local/bin --filename=installer.php \
  && rm -rf /tmp/composer

# Configure
COPY rootfs/etc/php7/conf.d/zzz.ini /etc/php7/conf.d/zzz.ini
COPY rootfs/etc/php7/php-fpm.d/www.conf /etc/php7/php-fpm.d/www.conf
COPY rootfs/etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Update ca-certificates
RUN update-ca-certificates

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN mkdir -p /var/www/html
RUN chown -R nobody.nobody /run \
 && chown -R nobody.nobody /var/www/html

WORKDIR /var/www/html

EXPOSE 9000

USER nobody

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# "when the SIGTERM signal is sent to the php-fpm process, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent to the php-fpm process"
STOPSIGNAL SIGUSR1

# requires the fcgi package
HEALTHCHECK --interval=5s --timeout=5s CMD REDIRECT_STATUS=true SCRIPT_NAME=/fpm-ping SCRIPT_FILENAME=/fpm-ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000

# check if response header returns 200 code OR die
#HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
#HEALTHCHECK --interval=5s --timeout=5s CMD [ "200" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/fpm-ping)" ] || exit 1
