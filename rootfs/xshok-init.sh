#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
## enable case insensitve matching
shopt -s nocaseglob

PHP_REDIS_SESSIONS=${PHP_REDIS_SESSIONS:-yes}
PHP_REDIS_HOST=${PHP_REDIS_HOST:-redis}
PHP_REDIS_PORT=${PHP_REDIS_PORT:-6379}
PHP_TIMEZONE=${PHP_TIMEZONE:-UTC}
PHP_MAX_TIME=${PHP_MAX_TIME:-180}
PHP_MAX_UPLOAD_SIZE=${PHP_MAX_UPLOAD_SIZE:-32}
PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-256}
PHP_DISABLE_FUNCTIONS=${PHP_DISABLE_FUNCTIONS:-shell_exec}

PHP_CHOWN=${PHP_CHOWN:-yes}

PHP_WORDPRESS=${PHP_WORDPRESS:-no}
PHP_WORDPRESS_LOCALE=${PHP_WORDPRESS_LOCALE:-en_US}
PHP_WORDPRESS_DATABASE=${PHP_WORDPRESS_DATABASE:-}
PHP_WORDPRESS_DATABASE_USER=${PHP_WORDPRESS_DATABASE_USER:-}
PHP_WORDPRESS_DATABASE_PASSWORD=${PHP_WORDPRESS_DATABASE_PASSWORD:-}
PHP_WORDPRESS_DATABASE_HOST=${PHP_WORDPRESS_DATABASE_HOST:-mysql}
PHP_WORDPRESS_DATABASE_PREFIX=${PHP_WORDPRESS_DATABASE_PREFIX:-wp_}
PHP_WORDPRESS_DATABASE_CHARSET=${PHP_WORDPRESS_DATABASE_CHARSET:-utf8mb4}
PHP_WORDPRESS_DATABASE_COLLATE=${PHP_WORDPRESS_DATABASE_COLLATE:-utf8mb4_unicode_ci}

PHP_WORDPRESS_URL=${PHP_WORDPRESS_URL:-}
PHP_WORDPRESS_TITLE=${PHP_WORDPRESS_TITLE:-$PHP_WORDPRESS_URL}
PHP_WORDPRESS_ADMIN_EMAIL=${PHP_WORDPRESS_ADMIN_EMAIL:-}
PHP_WORDPRESS_ADMIN_USER=${PHP_WORDPRESS_ADMIN_USER:$PHP_WORDPRESS_ADMIN_EMAIL}
PHP_WORDPRESS_ADMIN_PASSWORD=${PHP_WORDPRESS_ADMIN_PASSWORD:-}
PHP_WORDPRESS_SKIP_EMAIL=${PHP_WORDPRESS_SKIP_EMAIL:-no}

PHP_MAX_UPLOAD_SIZE="${PHP_MAX_UPLOAD_SIZE%m}"
PHP_MAX_UPLOAD_SIZE="${PHP_MAX_UPLOAD_SIZE%M}"
PHP_MAX_TIME="${PHP_MAX_TIME%s}"
PHP_MAX_TIME="${PHP_MAX_TIME%S}"
PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT%M}"
PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT%m}"

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
    echo "Download / Configure / Install Wordpress"
    if ! /usr/local/bin/wp-cli --allow-root --path=/var/www/html core is-installed >> /var/www/wordpress.log ; then
      if /usr/local/bin/wp-cli --allow-root --path=/var/www/html core download >> /var/www/wordpress.log ; then
        if /usr/local/bin/wp-cli --allow-root --path=/var/www/html config create --dbname="$PHP_WORDPRESS_DATABASE" --dbuser="$PHP_WORDPRESS_DATABASE_USER" --dbpass="$PHP_WORDPRESS_DATABASE_PASSWORD" --dbhost="$PHP_WORDPRESS_DATABASE_HOST" --dbprefix="$PHP_WORDPRESS_DATABASE_PREFIX" --dbcharset="$PHP_WORDPRESS_DATABASE_CHARSET" --dbcollate="$PHP_WORDPRESS_DATABASE_COLLATE" --locale="$PHP_WORDPRESS_LOCALE"  >> /var/www/wordpress.log ; then
          if [ "$PHP_WORDPRESS_SKIP_EMAIL" == "no" ] || [ "$PHP_WORDPRESS_SKIP_EMAIL" != "false" ] || [ "$PHP_WORDPRESS_SKIP_EMAIL" != "off" ] || [ "$PHP_WORDPRESS_SKIP_EMAIL" != "0" ] ; then
            this_skip_email="--skip-email"
          else
            this_skip_email=""
          fi
          if /usr/local/bin/wp-cli --allow-root --path=/var/www/html core install --url="$PHP_WORDPRESS_URL" --title="$PHP_WORDPRESS_TITLE" --admin_user="$PHP_WORDPRESS_ADMIN_USER" --admin_password="$PHP_WORDPRESS_ADMIN_PASSWORD" --admin_email="$PHP_WORDPRESS_ADMIN_EMAIL" $this_skip_email >> /var/www/wordpress.log ; then
            echo "SUCCESS"
          fi
        fi
      fi
    fi
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
