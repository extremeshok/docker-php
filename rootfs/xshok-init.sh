#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
## enable case insensitve matching
shopt -s nocaseglob

export PHP_REDIS_SESSIONS=${PHP_REDIS_SESSIONS:-yes}
export PHP_REDIS_HOST=${PHP_REDIS_HOST:-redis}
export PHP_REDIS_PORT=${PHP_REDIS_PORT:-6379}
export PHP_TIMEZONE=${PHP_TIMEZONE:-UTC}
export PHP_DISABLE_FUNCTIONS=${PHP_DISABLE_FUNCTIONS:-shell_exec}

export PHP_CHOWN=${PHP_CHOWN:-yes}

export PHP_WORDPRESS=${PHP_WORDPRESS:-no}
export PHP_WORDPRESS_REDIS_OBJECT_CACHE=${PHP_WORDPRESS_REDIS_OBJECT_CACHE:-no}
export PHP_WORDPRESS_LOCALE=${PHP_WORDPRESS_LOCALE:-en_US}
export PHP_WORDPRESS_DATABASE=${PHP_WORDPRESS_DATABASE:-}
export PHP_WORDPRESS_DATABASE_USER=${PHP_WORDPRESS_DATABASE_USER:-}
export PHP_WORDPRESS_DATABASE_PASSWORD=${PHP_WORDPRESS_DATABASE_PASSWORD:-}
export PHP_WORDPRESS_DATABASE_HOST=${PHP_WORDPRESS_DATABASE_HOST:-mysql}
export PHP_WORDPRESS_DATABASE_PORT=${PHP_WORDPRESS_DATABASE_PORT:-3306}
export PHP_WORDPRESS_DATABASE_PREFIX=${PHP_WORDPRESS_DATABASE_PREFIX:-}
export PHP_WORDPRESS_DATABASE_CHARSET=${PHP_WORDPRESS_DATABASE_CHARSET:-utf8mb4}
export PHP_WORDPRESS_DATABASE_COLLATE=${PHP_WORDPRESS_DATABASE_COLLATE:-utf8mb4_unicode_ci}

export PHP_WORDPRESS_UPDATE=${PHP_WORDPRESS_UPDATE:-yes}

export PHP_WORDPRESS_SUPER_CACHE=${PHP_WORDPRESS_SUPER_CACHE:-yes}
export PHP_WORDPRESS_NGINX_CACHE=${PHP_WORDPRESS_NGINX_CACHE:-no}
export PHP_WORDPRESS_CACHE_ENABLER=${PHP_WORDPRESS_CACHE_ENABLER:-no}

export PHP_WORDPRESS_URL=${PHP_WORDPRESS_URL:-}
export PHP_WORDPRESS_TITLE=${PHP_WORDPRESS_TITLE:-$PHP_WORDPRESS_URL}
export PHP_WORDPRESS_ADMIN_EMAIL=${PHP_WORDPRESS_ADMIN_EMAIL:-}
export PHP_WORDPRESS_ADMIN_USER=${PHP_WORDPRESS_ADMIN_USER:$PHP_WORDPRESS_ADMIN_EMAIL}
export PHP_WORDPRESS_ADMIN_PASSWORD=${PHP_WORDPRESS_ADMIN_PASSWORD:-}
export PHP_WORDPRESS_SKIP_EMAIL=${PHP_WORDPRESS_SKIP_EMAIL:-no}

PHP_MAX_UPLOAD_SIZE=${PHP_MAX_UPLOAD_SIZE:-32}
PHP_MAX_UPLOAD_SIZE="${PHP_MAX_UPLOAD_SIZE%m}"
export PHP_MAX_UPLOAD_SIZE="${PHP_MAX_UPLOAD_SIZE%M}"

PHP_MAX_TIME=${PHP_MAX_TIME:-180}
PHP_MAX_TIME="${PHP_MAX_TIME%s}"
export PHP_MAX_TIME="${PHP_MAX_TIME%S}"

PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-256}
PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT%M}"
export PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT%m}"

## Install extra php-extensions
if [ ! -z "$PHP_EXTRA_EXTENSIONS" ] ; then
  for extension in ${PHP_EXTRA_EXTENSIONS//,/ } ; do
    extension="${extension#php7-}"
    extension=${extension#php-}
    extension=${extension%@php}
    echo "Installing php extension: ${extension}"
    apk-install "php-${extension}@php"
  done
fi

## Configure Remote SMTP config
if [ -d "/etc/" ] && [ -w "/etc/" ] && [ -d "/etc/nginx/conf.d" ] && [ -w "/etc/nginx/conf.d" ] ; then
  if [ ! -z "$SMTP_HOST" ] && [ ! -z "$SMTP_USER" ] && [ ! -z "$SMTP_PASS" ] ; then
    cat << EOF >> /etc/msmtprc
defaults
port ${SMTP_PORT:-587}
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
tls_certcheck off

account remote
host ${SMTP_HOST}
from ${SMTP_USER}
auth on
user ${SMTP_USER}
password ${SMTP_PASS}

account default : remote

EOF
    echo 'sendmail_path = "/usr/bin/msmtp -C /etc/msmtprc -t"' > /etc/php7/conf.d/zz-msmtp.ini

    if [ -f "/usr/sbin/sendmail" ] ; then
      mv -f /usr/sbin/sendmail /usr/sbin/sendmail.disabled
    fi
    ln -s /usr/bin/msmtp /usr/sbin/sendmail
  else
    rm -f /etc/msmtprc
    rm -f /etc/php7/conf.d/zz-msmtp.ini
    if [ -f "/usr/sbin/sendmail.disabled" ] ; then
      mv -f /usr/sbin/sendmail.disabled /usr/sbin/sendmail
    fi
  fi
fi

#wordpress specific, wp-cli
if [ "$PHP_WORDPRESS" == "yes" ] || [ "$PHP_WORDPRESS" == "true" ] || [ "$PHP_WORDPRESS" == "on" ] || [ "$PHP_WORDPRESS" == "1" ] ; then
  if [ ! -f "/usr/local/bin/wp-cli" ] ; then
    echo "Installing WP-CLI"
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp-cli
    chmod +x /usr/local/bin/wp-cli
    if ! /usr/local/bin/wp-cli --info | grep -q "WP-CLI version" ; then
      echo "ERROR: WP-CLI install failed"
      rm -f /usr/local/bin/wp-cli
      sleep 1d
      exit 1
    fi
    if [ ! -f "/etc/bash_completion.d/wp-completion" ] ; then
      mkdir -p /etc/bash_completion.d
      wget https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash -O /etc/bash_completion.d/wp-completion
    fi
  fi
  # allow root to use wp-cli
  touch /root/.bashrc
  if ! grep -q "alias wp='/usr/local/bin/wp-cli --allow-root'" /root/.bashrc ; then
    echo "alias wp='/usr/local/bin/wp-cli --allow-root --path=/var/www/html'" >> /root/.bashrc
  fi
  # allow sudo for nobody user
  if ! grep -q "alias su-nobody='su nobody -s /bin/bash'" /root/.bashrc ; then
    echo "alias su-nobody='su nobody -s /bin/bash'" >> /root/.bashrc
  fi
  # ensure wp-cli is updated

  if [ ! -z "$PHP_WORDPRESS_DATABASE" ] && [ ! -z "$PHP_WORDPRESS_DATABASE_USER" ] && [ ! -z "$PHP_WORDPRESS_DATABASE_PASSWORD" ] && [ ! -z "$PHP_WORDPRESS_URL" ] && [ ! -z "$PHP_WORDPRESS_ADMIN_EMAIL" ] ; then
    if [ "$PHP_WORDPRESS_SKIP_EMAIL" != "no" ] && [ "$PHP_WORDPRESS_SKIP_EMAIL" != "false" ] && [ "$PHP_WORDPRESS_SKIP_EMAIL" != "off" ] && [ "$PHP_WORDPRESS_SKIP_EMAIL" != "0" ] && [ -z "$PHP_WORDPRESS_SKIP_EMAIL" ]; then
      echo "ERROR: PHP_WORDPRESS_SKIP_EMAIL enabled, PHP_WORDPRESS_ADMIN_PASSWORD can NOT be empty "
      sleep 1d
      exit 1
    fi

    # Wait for MySQL to warm-up
    while ! mysqladmin ping --host "$PHP_WORDPRESS_DATABASE_HOST" --port "$PHP_WORDPRESS_DATABASE_PORT" -u"$PHP_WORDPRESS_DATABASE_USER" -p"$PHP_WORDPRESS_DATABASE_PASSWORD" --silent; do
      echo "Waiting for database to come up..."
      sleep 2
    done

    if [ -z "$PHP_WORDPRESS_DATABASE_PREFIX" ] ; then
      PHP_WORDPRESS_DATABASE_PREFIX="$(echo $RANDOM)_"
    fi

    echo "Download / Configure / Install Wordpress"
    if ! /usr/local/bin/wp-cli --allow-root --path=/var/www/html core is-installed > /dev/null ; then
      if /usr/local/bin/wp-cli --allow-root --path=/var/www/html core download  > /dev/null ; then
        if /usr/local/bin/wp-cli --allow-root --path=/var/www/html config create --dbname=$PHP_WORDPRESS_DATABASE --dbuser=$PHP_WORDPRESS_DATABASE_USER --dbpass="$PHP_WORDPRESS_DATABASE_PASSWORD" --dbhost=$PHP_WORDPRESS_DATABASE_HOST --dbport=$PHP_WORDPRESS_DATABASE_PORT --dbprefix=$PHP_WORDPRESS_DATABASE_PREFIX --dbcharset=$PHP_WORDPRESS_DATABASE_CHARSET --dbcollate=$PHP_WORDPRESS_DATABASE_COLLATE --locale=$PHP_WORDPRESS_LOCALE  >> /var/www/wordpress.log ; then
          if [ "$PHP_WORDPRESS_SKIP_EMAIL" == "no" ] || [ "$PHP_WORDPRESS_SKIP_EMAIL" != "false" ] || [ "$PHP_WORDPRESS_SKIP_EMAIL" != "off" ] || [ "$PHP_WORDPRESS_SKIP_EMAIL" != "0" ] ; then
            this_skip_email="--skip-email"
          else
            this_skip_email=""
          fi
          if /usr/local/bin/wp-cli --allow-root --path=/var/www/html core install --url=$PHP_WORDPRESS_URL --title="$PHP_WORDPRESS_TITLE" --admin_user=$PHP_WORDPRESS_ADMIN_USER --admin_password="$PHP_WORDPRESS_ADMIN_PASSWORD" --admin_email=$PHP_WORDPRESS_ADMIN_EMAIL $this_skip_email >> /var/www/wordpress.log ; then

            # change admin userid from 1 to a random 6 digit number
            WPUID="$(echo $RANDOM$RANDOM |cut -c1-6)"
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html db query "UPDATE ${PHP_WORDPRESS_DATABASE_PREFIX}users SET ID=${WPUID} WHERE ID=1; UPDATE ${PHP_WORDPRESS_DATABASE_PREFIX}usermeta SET user_id=${WPUID} WHERE user_id=1"

            # add index on autoload
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html db query "ALTER TABLE ${PHP_WORDPRESS_DATABASE_PREFIX}options ADD INDEX autoload_idx (autoload)"

            # change permalinks out of the box
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html rewrite structure '/%post_id%/%postname%/'

            # Disallow file editing
            awk "/That's all, stop editing/ {
            print \"# eXtremeSHOK.com Prevent file editing\"
            print \"define('DISALLOW_FILE_EDIT', true);\"
            }{ print }" /var/www/html/wp-config.php > /var/www/html/wp-config.php.new && mv -f /var/www/html/wp-config.php.new /var/www/html/wp-config.php

            chmod 0755 /var/www/html/wp-content
            rm -f /var/www/html/readme.html
            # create some empty .htaccess files to satisfy some security plugins.
            touch /var/www/html/wp-content/.htaccess
            chmod 0644 /var/www/html/wp-content/.htaccess
            touch /var/www/html/wp-admin/.htaccess
            chmod 0644 /var/www/html/wp-admin/.htaccess
            touch /var/www/html/.htaccess
            chmod 0644 /var/www/html/.htaccess
            touch /var/www/html/wp-content/uploads/index.php

            if [ "$PHP_WORDPRESS_REDIS_OBJECT_CACHE" == "yes" ] || [ "$PHP_WORDPRESS_REDIS_OBJECT_CACHE" == "true" ] || [ "$PHP_WORDPRESS_REDIS_OBJECT_CACHE" == "on" ] || [ "$PHP_WORDPRESS_REDIS_OBJECT_CACHE" == "1" ] ; then
              echo "Enabling redis object cache"
              awk "/That's all, stop editing/ {
              print \"# eXtremeSHOK.com Redis Object Cache\"
              print \"define( 'WP_REDIS_CLIENT', 'predis' );\"
              print \"define( 'WP_REDIS_SCHEME', 'tcp' );\"
              print \"define( 'WP_REDIS_HOST', '${PHP_REDIS_HOST}' );\"
              print \"define( 'WP_REDIS_PORT', '${PHP_REDIS_PORT}' );\"
              print \"define( 'WP_REDIS_SELECTIVE_FLUSH', 'true' );\"
              print \"#define( 'WP_REDIS_MAXTTL', '7200' );\"
              print \"#define( 'WP_REDIS_GLOBAL_GROUPS', '['blog-details', 'blog-id-cache', 'blog-lookup', 'global-posts', 'networks', 'rss', 'sites', 'site-details', 'site-lookup', 'site-options', 'site-transient', 'users', 'useremail', 'userlogins', 'usermeta', 'user_meta', 'userslugs']' );\"
              print \"#define( 'WP_REDIS_IGNORED_GROUPS', '['counts', 'plugins']' );\"
              print \"#define( 'WP_REDIS_DISABLED', 'true' );\"
              }{ print }" /var/www/html/wp-config.php > /var/www/html/wp-config.php.new && mv -f /var/www/html/wp-config.php.new /var/www/html/wp-config.php
              /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate redis-cache
            fi

            # Remove Plugins
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin deactivate --uninstall hello
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin delete hello

            # Usability Plugins
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate duplicate-post
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate tinymce-advanced
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate wp-mail-smtp
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate amp
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate better-search-replace
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate https://envato.github.io/wp-envato-market/dist/envato-market.zip

            # cache and cdn
            if [ "$PHP_WORDPRESS_SUPER_CACHE" == "yes" ] || [ "$PHP_WORDPRESS_SUPER_CACHE" == "true" ] || [ "$PHP_WORDPRESS_SUPER_CACHE" == "on" ] || [ "$PHP_WORDPRESS_SUPER_CACHE" == "1" ] ; then
              echo "Enabling Super Cache"
              awk "/That's all, stop editing/ {
              print \"# eXtremeSHOK.com SUPER CACHE\"
              print \"define('WP_CACHE', true);\"
              print \"define('WPCACHEHOME', '/var/www/cache/');\"
              }{ print }" /var/www/html/wp-config.php > /var/www/html/wp-config.php.new && mv -f /var/www/html/wp-config.php.new /var/www/html/wp-config.php
              mkdir -p /var/www/cache/
              /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate wp-super-cache
            elif [ "$PHP_WORDPRESS_NGINX_CACHE" == "yes" ] || [ "$PHP_WORDPRESS_NGINX_CACHE" == "true" ] || [ "$PHP_WORDPRESS_NGINX_CACHE" == "on" ] || [ "$PHP_WORDPRESS_NGINX_CACHE" == "1" ] ; then
             /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate nginx-helper
             /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install cdn-enabler
             /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install bunnycdn
           elif [ "$PHP_WORDPRESS_CACHE_ENABLER" == "yes" ] || [ "$PHP_WORDPRESS_CACHE_ENABLER" == "true" ] || [ "$PHP_WORDPRESS_CACHE_ENABLER" == "on" ] || [ "$PHP_WORDPRESS_CACHE_ENABLER" == "1" ] ; then
             /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate cache-enabler
             /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install cdn-enabler
             /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install bunnycdn
            else
              /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install cdn-enabler
              /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install bunnycdn
            fi

            # commerce
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate woocommerce
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate woo-gutenberg-products-block

            # security
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate disable-xml-rpc-pingback
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate disable-emojis
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate two-factor
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate limit-login-attempts-reloaded
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate sucuri-scanner

            # SEO
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate wordpress-seo
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate google-sitemap-generator

            # Debug
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate query-monitor
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate p3-profiler
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate gtmetrix-for-wordpress
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate server-ip-memory-usage
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate google-analytics-dashboard-for-wp

            # performance
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate health-check
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate heartbeat-control
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install rocket-lazy-load
            /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install lazy-load-for-videos

            echo "SUCCESS"
          fi
        fi
      fi
    fi
  fi

  if [ "$PHP_WORDPRESS_UPDATE" == "yes" ] || [ "$PHP_WORDPRESS_UPDATE" == "true" ] || [ "$PHP_WORDPRESS_UPDATE" == "on" ] || [ "$PHP_WORDPRESS_UPDATE" == "1" ] ; then
    /usr/local/bin/wp-cli --allow-root --path=/var/www/html core update
    /usr/local/bin/wp-cli --allow-root --path=/var/www/html core update-db
    /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin update --all
  else
    /usr/local/bin/wp-cli --allow-root --path=/var/www/html core version
    /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin status
  fi
fi

## Configure PHP
if [ -d "/etc/php7/conf.d" ] && [ -w "/etc/php7/conf.d" ] ; then
  if [ "$PHP_DISABLE_FUNCTIONS" == "no" ] || [ "$PHP_DISABLE_FUNCTIONS" == "false" ] || [ "$PHP_DISABLE_FUNCTIONS" == "off" ] || [ "$PHP_DISABLE_FUNCTIONS" == "0" ] ; then
    echo "" > /etc/php7/php-fpm-conf.d/xs_disable_functions.conf
  else
    echo "php_admin_value[disable_functions] = ${PHP_DISABLE_FUNCTIONS}" > /etc/php7/php-fpm-conf.d/xs_disable_functions.conf
  fi
fi

if [ -d "/etc/php7/php-fpm-conf.d/" ] && [ -w "/etc/php7/php-fpm-conf.d/" ] ; then

  if [ "$PHP_REDIS_SESSIONS" == "yes" ] || [ "$PHP_REDIS_SESSIONS" == "true" ] || [ "$PHP_REDIS_SESSIONS" == "on" ] || [ "$PHP_REDIS_SESSIONS" == "1" ] ; then
    echo "Enabling redis sessions"
    cat << EOF > /etc/php7/conf.d/xs_redis.ini
session.save_handler = redis
session.save_path = "tcp://${PHP_REDIS_HOST}:${PHP_REDIS_PORT}"
EOF
  fi

  echo "date.timezone = ${PHP_TIMEZONE}" > /etc/php7/conf.d/xs_timezone.ini

  cat << EOF > /etc/php7/conf.d/xs_max_time.ini
  max_execution_time = ${PHP_MAX_TIME}
  max_input_time = ${PHP_MAX_TIME}
EOF

  cat << EOF > /etc/php7/conf.d/xs_max_upload_size.ini
  upload_max_filesize = ${PHP_MAX_UPLOAD_SIZE}M
  post_max_size = ${PHP_MAX_UPLOAD_SIZE}M
EOF

  cat << EOF > /etc/php7/conf.d/xs_max_time.ini
  max_execution_time = ${PHP_MAX_TIME}
  max_input_time = ${PHP_MAX_TIME}
EOF

  echo "memory_limit = ${PHP_MEMORY_LIMIT}M" > /etc/php7/conf.d/xs_memory_limit.ini
fi

echo "#### Checking PHP configs ####"
/usr/sbin/php-fpm7 -t
result=$?
if [ "$result" != "0" ] ; then
  echo "ERROR: CONFIG DAMAGED, sleeping ......"
  sleep 1d
  exit 1
fi

if [ "$PHP_CHOWN" == "yes" ] || [ "$PHP_CHOWN" == "true" ] || [ "$PHP_CHOWN" == "on" ] || [ "$PHP_CHOWN" == "1" ] ; then
  echo "Setting ownership of /var/www/html"
  chown -f -R nobody:nobody /var/www/html
fi

if [ "$PHP_REDIS_SESSIONS" == "yes" ] || [ "$PHP_REDIS_SESSIONS" == "true" ] || [ "$PHP_REDIS_SESSIONS" == "on" ] || [ "$PHP_REDIS_SESSIONS" == "1" ] ; then
  # wait for redis to start
  while ! echo PING | nc ${PHP_REDIS_HOST} ${PHP_REDIS_PORT} ; do
    echo "waiting for redis ${PHP_REDIS_HOST}:${PHP_REDIS_PORT}"
    sleep 5s
  done
fi
