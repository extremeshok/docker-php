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
* Optional: install wp-cli
* Optional: set ownership of /var/www/html to nobody:nobody
* Optional: Install wordpress, selected plugins and optimise it
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
* PHP_CHOWN=true (set to false to disable)

# EXTERNAL SMTP
* PHP_SMTP_HOST=
* PHP_SMTP_PORT=587
* PHP_SMTP_USER=
* PHP_SMTP_PASS=

# WORDPRESS
* PHP_WORDPRESS=false (set to true to have the WP_cli installed)
* PHP_WORDPRESS_REDIS_OBJECT_CACHE=false (set to true to have wordpress redis object cache enabled)
* PHP_WORDPRESS_LOCALE=en_US
* PHP_WORDPRESS_DATABASE=
* PHP_WORDPRESS_DATABASE_USER=
* PHP_WORDPRESS_DATABASE_PASSWORD=
* PHP_WORDPRESS_DATABASE_HOST=mysql
* PHP_WORDPRESS_DATABASE_PORT=3306
* PHP_WORDPRESS_DATABASE_PREFIX= (default will use random numbers, for security)
* PHP_WORDPRESS_DATABASE_CHARSET=utf8mb4
* PHP_WORDPRESS_DATABASE_COLLATE=utf8mb4_unicode_ci
* PHP_WORDPRESS_URL=
* PHP_WORDPRESS_TITLE=PHP_WORDPRESS_URL
* PHP_WORDPRESS_ADMIN_EMAIL=
* PHP_WORDPRESS_ADMIN_USER=PHP_WORDPRESS_ADMIN_EMAIL
* PHP_WORDPRESS_ADMIN_PASSWORD= (blank wp will generate a password and email as long as PHP_WORDPRESS_SKIP_EMAIL is false)
* PHP_WORDPRESS_SKIP_EMAIL=false
* PHP_WORDPRESS_UPDATE=yes
* PHP_WORDPRESS_SUPER_CACHE=yes
* PHP_WORDPRESS_NGINX_CACHE=no
* PHP_WORDPRESS_CACHE_ENABLER=no

# WORDPRESS-NOTES
* To install wordpress, required: PHP_WORDPRESS_DATABASE, PHP_WORDPRESS_DATABASE_USER, PHP_WORDPRESS_DATABASE_PASSWORD, PHP_WORDPRESS_URL, PHP_WORDPRESS_ADMIN_EMAIL
* shell alias wp = wp-cli --allow-root --path=/var/www/html
* allow interactive bash shell for nobody user with the command "su-nobody"

# Wordpress extensions
* amp
* better-search-replace
* disable-emojis
* disable-xml-rpc-pingback
* duplicate-post
* envato-market
* google-analytics-dashboard-for-wp
* google-sitemap-generator
* gtmetrix-for-wordpress
* health-check
* heartbeat-control
* lazy-load-for-videos
* limit-login-attempts-reloaded
* p3-profiler
* query-monitor
* rocket-lazy-load
* server-ip-memory-usage
* sucuri-scanner
* tinymce-advanced
* two-factor
* woo-gutenberg-products-block
* woocommerce
* wordpress-seo
* wp-mail-smtp


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
