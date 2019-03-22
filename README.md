# eXtremeSHOK.com Docker PHP-FPM 7.2 on Alpine Linux

* Alpine Linux 3.8
* S6
* cron (/etc/cron.d) enabled for scheduling tasks
* PHP 7.2 from CODECASTS PHP Repository for Alpine
* Zend opcache enabled
* Low memory usage (~30MB)
* Optimized for 100 concurrent users
* Only use resources when there is traffic (PHP-FPM ondemand PM)
* HEALTHCHECK activated
* Nobody php user
* Graceful shutdown
* Expose php disabled
* Optional: php sessions in redis
* Optional: install extra php extensions
* Optional: set php memory, timeout and max filesize

# PHP-Redis-sessions
* PHP_REDIS_SESSIONS=yes
* PHP_REDIS_HOST=${PHP_REDIS_HOST:-redis}
* PHP_REDIS_PORT=${PHP_REDIS_PORT:-6379}

# Install extra php extensions
https://github.com/codecasts/php-alpine#available-packages
* PHP_EXTRA_EXTENSIONS="list,of,php,extensions"

# PHP options
* PHP_MAX_SIZE=${PHP_MAX_SIZE:-32}
* PHP_TIMEOUT=${PHP_TIMEOUT:-300}
* PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-128}

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
* php-imap
* php-intl
* php-json
* php-mbstring
* php-mysqli
* php-opcache
* php-openssl
* php-pcntl
* php-pdo
* php-pdo_mysql
* php-phar
* php-posix
* php-redis
* php-session
* php-xml
* php-xmlreader
* php-zlib
