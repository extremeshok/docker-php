# eXtremeSHOK.com Docker PHP-FPM 7.2 on Alpine Linux

* Alpine Linux 3.8
* S6
* cron (/etc/cron.d) enabled for scheduling tasks
* PHP 7.2 from CODECASTS PHP Repository for Alpine
* IONICE set to -10
* Zend opcache enabled
* Low memory usage (~30MB)
* Optimized for 100 concurrent users
* Only use resources when there is traffic (PHP-FPM ondemand PM)
* HEALTHCHECK activated
* Nobody php user
* Graceful shutdown
* Expose php disabled
* msmtp: send email via smtp server, requires SMTP_HOST, SMTP_USER, SMTP_PASS
* Optional: php sessions in redis
* Optional: install extra php extensions
* Optional: set php memory, timeout and max filesize

# PHP-Redis-sessions
* PHP_REDIS_SESSIONS=yes
* PHP_REDIS_HOST=redis
* PHP_REDIS_PORT=6379

# Install extra php extensions
https://github.com/codecasts/php-alpine#available-packages
* PHP_EXTRA_EXTENSIONS="list,of,php,extensions"

# PHP options
* PHP_TIMEZONE=UTC
* PHP_MAX_TIME=180 (in seconds)
* PHP_MAX_UPLOAD_SIZE=32 (in mbyte)
* PHP_MEMORY_LIMIT=256 (in mbyte)

* SMTP_HOST=
* SMTP_PORT=587
* SMTP_USER=
* SMTP_PASS=

# Extras
* composer
* gifsicle
* imagemagick
* Ioncube
* jpegoptim
* optipng
* pcre
* pngquant

# PHP Extensions
* php-bcmath
* php-ctype
* php-curl
* php-dom
* php-fpm
* php-gd
* php-iconv
* php-imagick
* php-imap
* php-intl
* php-json
* php-mbstring
* php-mcrypt
* php-mysqli
* php-mysqlnd
* php-opcache
* php-openssl
* php-pcntl
* php-pdo
* php-pdo_mysql
* php-phar
* php-posix
* php-redis
* php-session
* php-sodium
* php-sqlite3
* php-xml
* php-xmlreader
* php-zlib
