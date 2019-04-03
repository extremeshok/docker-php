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

PHP_WORDPRESS=${PHP_WORDPRESS:-no}

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
  fi
fi

#wordpress specific, wp-cli
if [ "$PHP_WORDPRESS" == "yes" ] || [ "$PHP_WORDPRESS" == "true" ] || [ "$PHP_WORDPRESS" == "on" ] || [ "$PHP_WORDPRESS" == "1" ] ; then
  if [ ! -f "/usr/local/bin/wp-cli" ] ; then
    echo "Installing WP-CLI"
    wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp-cli
    chmod +x /usr/local/bin/wp-cli
    if ! wp --info | grep -q "WP-CLI version" ; then
      echo "ERROR: WP-CLI install failed"
      rm -f /usr/local/bin/wp-cli
      sleep 1d
      exit 1
    fi
    if [ ! -f "/etc/bash_completion.d/wp-completion" ] ; then
      wget https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash -O /etc/bash_completion.d/wp-completion
    fi
  fi
  # allow root to use wp-cli
  if ! grep -q "alias wp='/usr/local/bin/wp-cli --allow-root'" /root/.bash_aliases ; then
    echo "alias wp='wp --allow-root'" >> /root/.bash_aliases
  fi
  # allow sudo for nobody user
  if ! grep -q "alias su-nobody='su nobody -s /bin/bash'" /root/.bash_aliases ; then
    echo "alias su-nobody='su nobody -s /bin/bash'" >> /root/.bash_aliases
  fi
  # ensure wp-cli is updated
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

if [ "$PHP_REDIS_SESSIONS" == "yes" ] || [ "$PHP_REDIS_SESSIONS" == "true" ] || [ "$PHP_REDIS_SESSIONS" == "on" ] || [ "$PHP_REDIS_SESSIONS" == "1" ] ; then
  # wait for redis to start
  while ! echo PING | nc ${PHP_REDIS_HOST} ${PHP_REDIS_PORT} ; do
    echo "waiting for redis ${PHP_REDIS_HOST}:${PHP_REDIS_PORT}"
    sleep 5s
  done
fi
