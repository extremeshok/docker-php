#!/bin/bash

## enable case insensitve matching
shopt -s nocaseglob

PHP_REDIS_HOST=${PHP_REDIS_HOST:-redis}
PHP_REDIS_PORT=${PHP_REDIS_PORT:-6379}

if [ -d "/etc/nginx/conf.d" ] && [ -w "/etc/nginx/conf.d" ] ; then

  if [ ! -z "$SMTP_HOST" ] && [ ! -z "$SMTP_USER" ] && [ ! -z "$SMTP_PASS" ] ; then
    # Generating Remote SMTP config
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

  exit 0


  if [ ! -z "$PHP_EXTRA_EXTENSIONS" ] ; then
    for extension in ${PHP_EXTRA_EXTENSIONS//,/ } ; do
      extension="${extension#php7-}"
      extension=${extension#php-}
      echo "Installing php extension: ${extension}"
      apk-install "php-${extension}@php"
    done
  fi

  if [ ! -z "$PHP_MAX_SIZE" ] ; then
    PHP_MAX_SIZE="${PHP_MAX_SIZE%M}"
    sed -i "s/upload_max_filesize = 32M/upload_max_filesize = ${PHP_MAX_SIZE}M/" /etc/php7/conf.d/zzz.ini
    sed -i "s/post_max_size = 32M/post_max_size = ${PHP_MAX_SIZE}M/" /etc/php7/conf.d/zzz.ini
  fi
  if [ ! -z "$PHP_TIMEOUT" ] ; then
    PHP_TIMEOUT="${PHP_TIMEOUT%s}"
    sed -i "s/max_execution_time = 300/max_execution_time = ${PHP_TIMEOUT}M/" /etc/php7/conf.d/zzz.ini
    sed -i "s/max_input_time = 300/max_input_time = ${PHP_TIMEOUT}M/" /etc/php7/conf.d/zzz.ini
  fi
  if [ ! -z "$PHP_MEMORY_LIMIT" ] ; then
    PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT%M}"
    sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEMORY_LIMIT}M/" /etc/php7/conf.d/zzz.ini
  fi


  if [ "$PHP_REDIS_SESSIONS" == "yes" ] || [ "$PHP_REDIS_SESSIONS" == "true" ] || [ "$PHP_REDIS_SESSIONS" == "on" ] || [ "$PHP_REDIS_SESSIONS" == "1" ] ; then
    PHP_REDIS_HOST=${PHP_REDIS_HOST:-redis}
    PHP_REDIS_PORT=${PHP_REDIS_PORT:-6379}

    echo "Enabling redis sessions"
    cat << EOF > /etc/php7/conf.d/zz-redis.ini
  session.save_handler = redis
  session.save_path = "tcp://${PHP_REDIS_HOST}:${PHP_REDIS_PORT}"
EOF
  fi
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
