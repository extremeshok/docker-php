FROM extremeshok/baseimage-alpine:3.8 AS BUILD
LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

RUN echo "**** Install packages ****" \
  && apk-install bash ca-certificates pcre fcgi supervisor curl unzip imagemagick jpegoptim pngquant optipng gifsicle

RUN echo "**** Adding codecasts php-repo ****"
## https://github.com/codecasts/php-alpine trust this project public key to trust the packages.
ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# add the repository, make sure you replace the correct versions if you want.
RUN echo "@php https://dl.bintray.com/php-alpine/v3.8/php-7.2" >> /etc/apk/repositories

# notice the @php is required to avoid getting default php packages from alpine instead.
RUN echo  "**** Install php and some extensions ****" \
  && apk-install php7@php php-cli@php php-fpm@php \
  php-bcmath@php \
  php-ctype@php \
  php-curl@php \
  php-dom@php \
  php-gd@php \
  php-iconv@php \
  php-imagick@php \
  php-imap@php \
  php-intl@php \
  php-json@php \
  php-mbstring@php \
  php-mysqli@php \
  php-mysqlnd@php \
  php-opcache@php \
  php-openssl@php \
  php-pcntl@php \
  php-pdo_mysql@php \
  php-pdo@php \
  php-phar@php \
  php-posix@php \
  php-redis@php \
  php-session@php \
  php-sodium@php \
  php-sqlite3@php \
  php-xml@php \
  php-xmlreader@php \
  php-zlib@php

RUN echo "**** Install IONCUBE ****" \
  && mkdir -p /tmp/ioncube \
  && cd /tmp/ioncube \
  && wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip -O /tmp/ioncube/ioncube.zip \
  && unzip -oq ioncube.zip \
  && cp -rf /tmp/ioncube/ioncube/*.so /usr/lib/php7/modules/ \
  && chmod +x /usr/lib/php7/modules/ioncube_* \
  && rm -rf /tmp/ioncube

RUN echo "**** Install composer ****" \
  && mkdir -p /tmp/composer \
  && cd /tmp/composer \
  && wget https://getcomposer.org/installer -O /tmp/composer/installer.php \
  && php installer.php --install-dir=/usr/local/bin --filename=installer.php \
  && rm -rf /tmp/composer

RUN echo "**** install msmtp ****" \
  && apk-install msmtp

RUN echo "**** configure ****"
COPY rootfs/ /


# Update ca-certificates
RUN echo "**** Update ca-certificates ****" \
  && update-ca-certificates


# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN echo "**** Fix permissions ****" \
  && mkdir -p /var/www/html \
  && chown -R nobody.nobody /var/www/html

WORKDIR /var/www/html

EXPOSE 9000

# "when the SIGTERM signal is sent to the php-fpm process, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent to the php-fpm process"
STOPSIGNAL SIGUSR1

# requires the fcgi package
HEALTHCHECK --interval=5s --timeout=5s CMD REDIRECT_STATUS=true SCRIPT_NAME=/fpm-ping SCRIPT_FILENAME=/fpm-ping REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000

ENTRYPOINT ["/init"]
