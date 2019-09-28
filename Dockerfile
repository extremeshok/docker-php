FROM extremeshok/baseimage-alpine:3.9 AS BUILD
LABEL mantainer="Adrian Kriel <admin@extremeshok.com>" vendor="eXtremeSHOK.com"

RUN echo "**** Install packages ****" \
  && apk-install bash ca-certificates pcre fcgi supervisor curl unzip imagemagick jpegoptim pngquant optipng gifsicle sqlite less mariadb-client

RUN echo  "**** Install php and some extensions ****" \
  && apk-install php7 php7-fpm \
  php7-bcmath \
  php7-calendar \
  php7-ctype \
  php7-curl \
  php7-dom \
  php7-exif \
  php7-gd \
  php7-iconv \
  php7-imap \
  php7-intl \
  php7-json \
  php7-mbstring \
  php7-mysqli \
  php7-mysqlnd \
  php7-opcache \
  php7-openssl \
  php7-pcntl \
  php7-pdo \
  php7-pdo_mysql \
  php7-pdo_odbc \
  php7-pdo_pgsql \
  php7-pdo_sqlite \
  php7-pear \
  php7-phar \
  php7-posix \
  php7-session \
  php7-shmop \
  php7-soap \
  php7-sodium \
  php7-sqlite3 \
  php7-xml \
  php7-xmlreader \
  php7-xsl \
  php7-zip

RUN echo "**** Adding codecasts php-repo ****"
## https://docs.php.earth/linux/alpine/ trust this project public key to trust the packages.
ADD https://repos.php.earth/alpine/phpearth.rsa.pub /etc/apk/keys/phpearth.rsa.pub

# add the repository, make sure you replace the correct versions if you want.
RUN echo "@php https://repos.php.earth/alpine/v3.9" >> /etc/apk/repositories

# notice the @php is required to avoid getting default php packages from alpine instead.
RUN echo  "**** Install @php and some extensions ****" \
  && apk-install \
  php7.2-imagick@php \
  php7.2-redis@php \
  php7.2-zlib@php

# allow for php on the command line
# RUN ln -s /usr/bin/php7 /usr/bin/php

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
  && php7 installer.php --install-dir=/usr/local/bin --filename=installer.php \
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
