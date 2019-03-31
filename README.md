# eXtremeSHOK.com Docker PHP-FPM 7.3 on Alpine Linux

* Alpine Linux 3.8 with S6
* cron (/etc/cron.d) enabled for scheduling tasks
* PHP 7.3 from CODECASTS PHP Repository for Alpine
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
* Optional: set php timezone, memory, timeout and max filesize

# PHP-Redis-sessions
* PHP_REDIS_SESSIONS=yes
* PHP_REDIS_HOST=redis
* PHP_REDIS_PORT=6379

# Install extra php extensions
https://github.com/codecasts/php-alpine#available-packages
* PHP_EXTRA_EXTENSIONS="list,of,php,extensions"

# PHP options (with defaults)
* PHP_TIMEZONE=UTC
* PHP_MAX_TIME=180 (in seconds)
* PHP_MAX_UPLOAD_SIZE=32 (in mbyte)
* PHP_MEMORY_LIMIT=256 (in mbyte)
* PHP_DISABLE_FUNCTIONS=shell_exec (set to false to disable, can use a comma separated list)

# EXTERNAL SMTP
* SMTP_HOST=
* SMTP_PORT=587
* SMTP_USER=
* SMTP_PASS=

# Extra Packages
* composer
* gifsicle
* imagemagick
* Ioncube
* jpegoptim
* optipng
* pcre
* pngquant
* sqlite3

# PHP Extensions
* bcmath
* ctype
* curl
* dom
* gd
* iconv
* imagick
* imap
* intl
* json
* mbstring
* mysqli
* mysqlnd
* opcache
* openssl
* pcntl
* pdo_mysql
* pdo_odbc
* pdo_pgsql
* pdo_sqlite
* pdo
* pear
* phar
* posix
* redis
* session
* sodium
* sqlite3
* xml
* xmlreader
* zlib
