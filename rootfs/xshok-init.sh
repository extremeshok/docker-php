#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
## enable case insensitve matching
shopt -s nocaseglob

XS_REDIS_SESSIONS=${PHP_REDIS_SESSIONS:-yes}
XS_REDIS_HOST=${PHP_REDIS_HOST:-redis}
XS_REDIS_PORT=${PHP_REDIS_PORT:-6379}
XS_TIMEZONE=${PHP_TIMEZONE:-UTC}
XS_DISABLE_FUNCTIONS=${PHP_DISABLE_FUNCTIONS:-shell_exec}
XS_CHOWN=${PHP_CHOWN:-yes}

XS_SMTP_HOST=${PHP_SMTP_HOST:-}
XS_SMTP_PORT=${PHP_SMTP_PORT:-587}
XS_SMTP_USER=${PHP_SMTP_USER:-}
XS_SMTP_PASSWORD=${PHP_SMTP_PASSWORD:-}

XS_WORDPRESS=${PHP_WORDPRESS:-no}
XS_WORDPRESS_REDIS_OBJECT_CACHE=${PHP_WORDPRESS_REDIS_OBJECT_CACHE:-no}
XS_WORDPRESS_LOCALE=${PHP_WORDPRESS_LOCALE:-en_US}
XS_WORDPRESS_DATABASE=${PHP_WORDPRESS_DATABASE:-}
XS_WORDPRESS_DATABASE_USER=${PHP_WORDPRESS_DATABASE_USER:-}
XS_WORDPRESS_DATABASE_PASSWORD=${PHP_WORDPRESS_DATABASE_PASSWORD:-}
XS_WORDPRESS_DATABASE_HOST=${PHP_WORDPRESS_DATABASE_HOST:-mysql}
XS_WORDPRESS_DATABASE_PORT=${PHP_WORDPRESS_DATABASE_PORT:-3306}
XS_WORDPRESS_DATABASE_PREFIX=${PHP_WORDPRESS_DATABASE_PREFIX:-}
XS_WORDPRESS_DATABASE_CHARSET=${PHP_WORDPRESS_DATABASE_CHARSET:-utf8mb4}
XS_WORDPRESS_DATABASE_COLLATE=${PHP_WORDPRESS_DATABASE_COLLATE:-utf8mb4_unicode_ci}

XS_WORDPRESS_UPDATE=${PHP_WORDPRESS_UPDATE:-yes}

XS_WORDPRESS_SUPER_CACHE=${PHP_WORDPRESS_SUPER_CACHE:-yes}
XS_WORDPRESS_NGINX_CACHE=${PHP_WORDPRESS_NGINX_CACHE:-no}
XS_WORDPRESS_CACHE_ENABLER=${PHP_WORDPRESS_CACHE_ENABLER:-no}

XS_WORDPRESS_URL=${PHP_WORDPRESS_URL:-}
XS_WORDPRESS_TITLE=${PHP_WORDPRESS_TITLE:-$PHP_WORDPRESS_URL}
XS_WORDPRESS_ADMIN_EMAIL=${PHP_WORDPRESS_ADMIN_EMAIL:-}
XS_WORDPRESS_ADMIN_USER=${PHP_WORDPRESS_ADMIN_USER:$PHP_WORDPRESS_ADMIN_EMAIL}
XS_WORDPRESS_ADMIN_PASSWORD=${PHP_WORDPRESS_ADMIN_PASSWORD:-}
XS_WORDPRESS_SKIP_EMAIL=${PHP_WORDPRESS_SKIP_EMAIL:-no}


XS_MAX_UPLOAD_SIZE=${PHP_MAX_UPLOAD_SIZE:-32}
XS_MAX_UPLOAD_SIZE="${XS_MAX_UPLOAD_SIZE%m}"
XS_MAX_UPLOAD_SIZE="${XS_MAX_UPLOAD_SIZE%M}"

XS_MAX_TIME=${PHP_MAX_TIME:-180}
XS_MAX_TIME="${XS_MAX_TIME%s}"
XS_MAX_TIME="${XS_MAX_TIME%S}"

XS_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-256}
XS_MEMORY_LIMIT="${XS_MEMORY_LIMIT%M}"
XS_MEMORY_LIMIT="${XS_MEMORY_LIMIT%m}"

if [[ $XS_MEMORY_LIMIT -lt 64 ]] ; then
  echo "WARNING: XS_MEMORY_LIMIT if ${XS_MEMORY_LIMIT} too low, setting to 64"
  XS_MEMORY_LIMIT=64
fi
#XS_MEMORY_LIMIT

## Install extra php-extensions
if [ "$XS_EXTRA_EXTENSIONS" != "" ] ; then
  for extension in ${XS_EXTRA_EXTENSIONS//,/ } ; do
    extension="${extension#php7-}"
    extension=${extension#php-}
    extension=${extension%@php}
    echo "Installing php extension: ${extension}"
    apk-install "php-${extension}@php"
  done
fi

## Configure Remote SMTP config
if [ -d "/etc/" ] && [ -w "/etc/" ] && [ -d "/etc/php7/conf.d/" ] && [ -w "/etc/php7/conf.d/" ] ; then

  if [ "$XS_SMTP_HOST" != "" ] && [ "$XS_SMTP_USER" != "" ] && [ "$XS_SMTP_PASSWORD" != "" ] ; then
    echo "Installing remote smtp (msmtp)"

    cat << EOF >> /etc/msmtprc
defaults
port ${XS_SMTP_PORT}
tls on
tls_starttls on
tls_certcheck off

account remote
host ${XS_SMTP_HOST}
from ${XS_SMTP_USER}
auth on
user ${XS_SMTP_USER}
password ${XS_SMTP_PASSWORD}

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
if [ "$XS_WORDPRESS" == "yes" ] || [ "$XS_WORDPRESS" == "true" ] || [ "$XS_WORDPRESS" == "on" ] || [ "$XS_WORDPRESS" == "1" ] ; then
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

  if [ "$XS_WORDPRESS_DATABASE" != "" ] && [ "$XS_WORDPRESS_DATABASE_USER" != "" ] && [ "$XS_WORDPRESS_DATABASE_PASSWORD" != "" ] && [ "$XS_WORDPRESS_URL" != "" ] && [ "$XS_WORDPRESS_ADMIN_EMAIL" != "" ] ; then
    if [ "$XS_WORDPRESS_SKIP_EMAIL" != "no" ] && [ "$XS_WORDPRESS_SKIP_EMAIL" != "false" ] && [ "$XS_WORDPRESS_SKIP_EMAIL" != "off" ] && [ "$XS_WORDPRESS_SKIP_EMAIL" != "0" ] && [ "$XS_WORDPRESS_SKIP_EMAIL" == "" ]; then
      echo "ERROR: XS_WORDPRESS_SKIP_EMAIL enabled, XS_WORDPRESS_ADMIN_PASSWORD can NOT be empty "
      sleep 1d
      exit 1
    fi

    # Wait for MySQL to warm-up
    while ! mysqladmin ping --host "$XS_WORDPRESS_DATABASE_HOST" --port "$XS_WORDPRESS_DATABASE_PORT" -u"$XS_WORDPRESS_DATABASE_USER" -p"$XS_WORDPRESS_DATABASE_PASSWORD" --silent; do
      echo "Waiting for database to come up..."
      sleep 2
    done

    if [ "$XS_WORDPRESS_DATABASE_PREFIX" != "" ] ; then
      XS_WORDPRESS_DATABASE_PREFIX="$(echo $RANDOM)_"
    fi

    echo "Download / Configure / Install Wordpress"
    if [ ! -f /var/www/html/wp-config.php ]; then

     if ! /usr/local/bin/wp-cli --allow-root --path=/var/www/html core is-installed > /dev/null ; then
       /usr/local/bin/wp-cli --allow-root --path=/var/www/html core download > /dev/null
     fi
     if [ ! -f /var/www/html/wp-settings.php ]; then
       /usr/local/bin/wp-cli --allow-root --path=/var/www/html core download > /dev/null
    fi

    echo "DEBUG ======================="
    echo "dbname=$XS_WORDPRESS_DATABASE"
    echo "dbuser=$XS_WORDPRESS_DATABASE_USER"
    echo "dbpass=$XS_WORDPRESS_DATABASE_PASSWORD"
    echo "dbhost=$XS_WORDPRESS_DATABASE_HOST:$XS_WORDPRESS_DATABASE_PORT"
    echo "dbprefix=$XS_WORDPRESS_DATABASE_PREFIX"
    echo "dbcharset=$XS_WORDPRESS_DATABASE_CHARSET"
    echo "dbcollate=$XS_WORDPRESS_DATABASE_COLLATE"
    echo "locale=$XS_WORDPRESS_LOCALE"
    echo "DEBUG ======================="


    if /usr/local/bin/wp-cli --allow-root --path=/var/www/html config create --dbname="$XS_WORDPRESS_DATABASE" --dbuser="$XS_WORDPRESS_DATABASE_USER" --dbpass="$XS_WORDPRESS_DATABASE_PASSWORD" --dbhost="$XS_WORDPRESS_DATABASE_HOST:$XS_WORDPRESS_DATABASE_PORT" --dbprefix="$XS_WORDPRESS_DATABASE_PREFIX" --dbcharset="$XS_WORDPRESS_DATABASE_CHARSET" --dbcollate="$XS_WORDPRESS_DATABASE_COLLATE" --locale="$XS_WORDPRESS_LOCALE" ; then
      if [ "$XS_WORDPRESS_SKIP_EMAIL" == "yes" ] || [ "$XS_WORDPRESS_SKIP_EMAIL" == "true" ] || [ "$XS_WORDPRESS_SKIP_EMAIL" == "on" ] || [ "$XS_WORDPRESS_SKIP_EMAIL" == "1" ] ; then
        this_skip_email="--skip-email"
      else
        this_skip_email=""
      fi
      if /usr/local/bin/wp-cli --allow-root --path=/var/www/html core install --url="$XS_WORDPRESS_URL" --title="$XS_WORDPRESS_TITLE" --admin_user="$XS_WORDPRESS_ADMIN_USER" --admin_password="$XS_WORDPRESS_ADMIN_PASSWORD" --admin_email="$XS_WORDPRESS_ADMIN_EMAIL" $this_skip_email >> /tmp/wordpress.log ; then

        # save admin password if it was generated to /var/www/html/.xs_password
        this_admin_password="$(grep "Admin password" /tmp/wordpress.log)"
        if [ "$this_admin_password" != "" ] && [ ! -f "/var/www/html/.xs_password" ]; then
          echo "*** Admin Password Generated, saved to: /var/www/html/.xs_password"
          echo "$this_admin_password" > /var/www/html/.xs_password
          chmod 0600 /var/www/html/.xs_password
        fi

        # change admin userid from 1 to a random 6 digit number
        WPUID="$(echo $RANDOM$RANDOM |cut -c1-6)"
        echo "Setting Admin ID from 1 to ${WPUID}"
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html db query "UPDATE ${XS_WORDPRESS_DATABASE_PREFIX}users SET ID=${WPUID} WHERE ID=1; UPDATE ${XS_WORDPRESS_DATABASE_PREFIX}usermeta SET user_id=${WPUID} WHERE user_id=1"

        # add index on autoload
        echo "Creating Index on autoload"
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html db query "ALTER TABLE ${XS_WORDPRESS_DATABASE_PREFIX}options ADD INDEX autoload_idx (autoload)"

        # change permalinks out of the box
        echo "Setting permalinks to /%post_id%/%postname%/"
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html rewrite structure '/%post_id%/%postname%/'

        # Memory optimising
        if [[ $XS_MEMORY_LIMIT -lt 128 ]] ; then
          WP_MEMORY_LIMIT=$((XS_MEMORY_LIMIT/2 +16))
          WP_MAX_MEMORY_LIMIT=$XS_MEMORY_LIMIT
        else
          WP_MEMORY_LIMIT=$((XS_MEMORY_LIMIT/2))
          WP_MAX_MEMORY_LIMIT=$XS_MEMORY_LIMIT
        fi
        export WP_MEMORY_LIMIT
        export WP_MAX_MEMORY_LIMIT

        echo "Optimising wordpress config"
        awk "/That's all, stop editing/ {
        print \"# eXtremeSHOK.com Optimisation\"
        print \"# Reduce the number of database calls when loading your site\"
        # shellcheck disable=SC1087
        print \"if (\!empty(\$_SERVER['SERVER_NAME'])) { \"
        print \"define( 'WP_SITEURL', 'https://' . \$_SERVER['SERVER_NAME'] .'' );\"
        print \"define( 'WP_HOME', 'https://' . \$_SERVER['SERVER_NAME'] .'' );\"
        print \"}\"
        print \"# Memory Admin Area\"
        print \"define( 'WP_MAX_MEMORY_LIMIT', '${WP_MAX_MEMORY_LIMIT}M' );\"
        print \"# Memory Client Area\"
        print \"define( 'WP_MEMORY_LIMIT', '${WP_MEMORY_LIMIT}M' );\"
        print \"# Enforce File Permissions\"
        print \"define( 'FS_CHMOD_DIR', ( 0755 & ~ umask() ) );\"
        print \"define( 'FS_CHMOD_FILE', ( 0644 & ~ umask() ) );\"
        print \"define( 'FS_METHOD', 'direct' );\"
        print \"define( 'WP_CRON_LOCK_TIMEOUT', 60 );\"
        print \"# Security\"
        print \"define('DISALLOW_FILE_EDIT', true);\"
        print \"define( 'FORCE_SSL_ADMIN', true );\"
        print \"define( 'DISALLOW_UNFILTERED_HTML', true );\"
        print \"# Recommended Options\"
        print \"define('EMPTY_TRASH_DAYS', 30);\"
        print \"define( 'WP_POST_REVISIONS', 5 );\"
        print \"define( 'AUTOSAVE_INTERVAL', 90 );\"
        print \"\"
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

        if [ "$XS_WORDPRESS_REDIS_OBJECT_CACHE" == "yes" ] || [ "$XS_WORDPRESS_REDIS_OBJECT_CACHE" == "true" ] || [ "$XS_WORDPRESS_REDIS_OBJECT_CACHE" == "on" ] || [ "$XS_WORDPRESS_REDIS_OBJECT_CACHE" == "1" ] ; then
          echo "Enabling redis object cache"
          awk "/That's all, stop editing/ {
          print \"# eXtremeSHOK.com Redis Object Cache\"
          print \"define( 'WP_REDIS_CLIENT', 'predis' );\"
          print \"define( 'WP_REDIS_SCHEME', 'tcp' );\"
          print \"define( 'WP_REDIS_HOST', '${XS_REDIS_HOST}' );\"
          print \"define( 'WP_REDIS_PORT', '${XS_REDIS_PORT}' );\"
          print \"define( 'WP_REDIS_SELECTIVE_FLUSH', 'true' );\"
          print \"#define( 'WP_REDIS_MAXTTL', '7200' );\"
          print \"#define( 'WP_REDIS_GLOBAL_GROUPS', '['blog-details', 'blog-id-cache', 'blog-lookup', 'global-posts', 'networks', 'rss', 'sites', 'site-details', 'site-lookup', 'site-options', 'site-transient', 'users', 'useremail', 'userlogins', 'usermeta', 'user_meta', 'userslugs']' );\"
          print \"#define( 'WP_REDIS_IGNORED_GROUPS', '['counts', 'plugins']' );\"
          print \"#define( 'WP_REDIS_DISABLED', 'true' );\"
          print \"\"
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
        if [ "$XS_WORDPRESS_SUPER_CACHE" == "yes" ] || [ "$XS_WORDPRESS_SUPER_CACHE" == "true" ] || [ "$XS_WORDPRESS_SUPER_CACHE" == "on" ] || [ "$XS_WORDPRESS_SUPER_CACHE" == "1" ] ; then
          echo "Enabling Super Cache"
          awk "/That's all, stop editing/ {
          print \"# eXtremeSHOK.com SUPER CACHE\"
          print \"define('WP_CACHE', true);\"
          print \"#define('WPCACHEHOME', '/var/www/cache/');\"
          print \"\"
          }{ print }" /var/www/html/wp-config.php > /var/www/html/wp-config.php.new && mv -f /var/www/html/wp-config.php.new /var/www/html/wp-config.php
          mkdir -p /var/www/cache/
          /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate wp-super-cache
        elif [ "$XS_WORDPRESS_NGINX_CACHE" == "yes" ] || [ "$XS_WORDPRESS_NGINX_CACHE" == "true" ] || [ "$XS_WORDPRESS_NGINX_CACHE" == "on" ] || [ "$XS_WORDPRESS_NGINX_CACHE" == "1" ] ; then
         /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate nginx-helper
         /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install cdn-enabler
         /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install bunnycdn
       elif [ "$XS_WORDPRESS_CACHE_ENABLER" == "yes" ] || [ "$XS_WORDPRESS_CACHE_ENABLER" == "true" ] || [ "$XS_WORDPRESS_CACHE_ENABLER" == "on" ] || [ "$XS_WORDPRESS_CACHE_ENABLER" == "1" ] ; then
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

        # security
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate disable-xml-rpc-pingback
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate disable-emojis
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate two-factor
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate limit-login-attempts-reloaded
        /usr/local/bin/wp-cli --allow-root --path=/var/www/html plugin install --activate sucuri-scanner

        echo "SUCCESS"
      fi
      fi
    fi
  fi

  if [ "$XS_WORDPRESS_UPDATE" == "yes" ] || [ "$XS_WORDPRESS_UPDATE" == "true" ] || [ "$XS_WORDPRESS_UPDATE" == "on" ] || [ "$XS_WORDPRESS_UPDATE" == "1" ] ; then
    echo "Updating Wordpress"
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
  if [ "$XS_DISABLE_FUNCTIONS" == "no" ] || [ "$XS_DISABLE_FUNCTIONS" == "false" ] || [ "$XS_DISABLE_FUNCTIONS" == "off" ] || [ "$XS_DISABLE_FUNCTIONS" == "0" ] ; then
    echo "" > /etc/php7/php-fpm-conf.d/xs_disable_functions.conf
  else
    echo "php_admin_value[disable_functions] = ${XS_DISABLE_FUNCTIONS}" > /etc/php7/php-fpm-conf.d/xs_disable_functions.conf
  fi
fi

if [ -d "/etc/php7/php-fpm-conf.d/" ] && [ -w "/etc/php7/php-fpm-conf.d/" ] ; then

  if [ "$XS_REDIS_SESSIONS" == "yes" ] || [ "$XS_REDIS_SESSIONS" == "true" ] || [ "$XS_REDIS_SESSIONS" == "on" ] || [ "$XS_REDIS_SESSIONS" == "1" ] ; then
    echo "Enabling redis sessions"
    cat << EOF > /etc/php7/conf.d/xs_redis.ini
session.save_handler = redis
session.save_path = "tcp://${XS_REDIS_HOST}:${XS_REDIS_PORT}"
EOF
  fi

  echo "date.timezone = ${XS_TIMEZONE}" > /etc/php7/conf.d/xs_timezone.ini

  cat << EOF > /etc/php7/conf.d/xs_max_time.ini
  max_execution_time = ${XS_MAX_TIME}
  max_input_time = ${XS_MAX_TIME}
EOF

  cat << EOF > /etc/php7/conf.d/xs_max_upload_size.ini
  upload_max_filesize = ${XS_MAX_UPLOAD_SIZE}M
  post_max_size = ${XS_MAX_UPLOAD_SIZE}M
EOF

  cat << EOF > /etc/php7/conf.d/xs_max_time.ini
  max_execution_time = ${XS_MAX_TIME}
  max_input_time = ${XS_MAX_TIME}
EOF

  echo "memory_limit = ${XS_MEMORY_LIMIT}M" > /etc/php7/conf.d/xs_memory_limit.ini
fi

echo "#### Checking PHP configs ####"
/usr/sbin/php-fpm7 -t
result=$?
if [ "$result" != "0" ] ; then
  echo "ERROR: CONFIG DAMAGED, sleeping ......"
  sleep 1d
  exit 1
fi

if [ "$XS_CHOWN" == "yes" ] || [ "$XS_CHOWN" == "true" ] || [ "$XS_CHOWN" == "on" ] || [ "$XS_CHOWN" == "1" ] ; then
  echo "Setting ownership of /var/www/html"
  chown -f -R nobody:nobody /var/www/html
fi

if [ "$XS_REDIS_SESSIONS" == "yes" ] || [ "$XS_REDIS_SESSIONS" == "true" ] || [ "$XS_REDIS_SESSIONS" == "on" ] || [ "$XS_REDIS_SESSIONS" == "1" ] ; then
  # wait for redis to start
  while ! echo PING | nc ${XS_REDIS_HOST} ${XS_REDIS_PORT} ; do
    echo "waiting for redis ${XS_REDIS_HOST}:${XS_REDIS_PORT}"
    sleep 5s
  done
fi
