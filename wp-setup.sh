#!/bin/sh
function plugin_install(){
  cd /tmp
  /usr/bin/wget http://downloads.wordpress.org/plugin/$1
  /usr/bin/unzip /tmp/$1 -d /var/www/vhosts/$2/wp-content/plugins/
  /bin/rm /tmp/$1
}

SERVERNAME=$1
DATABASE=$2
INSTANCEID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
PUBLICNAME=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-hostname`
AZ=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/`
TZ="America\/Sao_Paulo"

/bin/cp /tmp/wp-gc-model/etc/motd /etc/motd

if [ "$AZ" = "eu-west-1a" -o "$AZ" = "eu-west-1b" -o "$AZ" = "eu-west-1c" ]; then
  REGION=eu-west-1
elif [ "$AZ" = "sa-east-1a" -o "$AZ" = "sa-east-1b" ]; then
  REGION=sa-east-1
elif [ "$AZ" = "us-east-1a" -o "$AZ" = "us-east-1b" -o "$AZ" = "us-east-1c" -o "$AZ" = "us-east-1d" -o "$AZ" = "us-east-1e" ]; then
  REGION=us-east-1
elif [ "$AZ" = "ap-northeast-1a" -o "$AZ" = "ap-northeast-1b" -o "$AZ" = "ap-northeast-1c" ]; then
  REGION=ap-northeast-1
elif [ "$AZ" = "us-west-2a" -o "$AZ" = "us-west-2b" -o "$AZ" = "us-west-2c" ]; then
  REGION=us-west-2
elif [ "$AZ" = "us-west-1a" -o "$AZ" = "us-west-1b" -o "$AZ" = "us-west-1c" ]; then
  REGION=us-west-1
elif [ "$AZ" = "ap-southeast-1a" -o "$AZ" = "ap-southeast-1b" ]; then
  REGION=ap-southeast-1
else
  REGION=unknown
fi

cd /tmp/

/bin/mv /etc/localtime /etc/localtime.bak
/bin/ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
/bin/cp /tmp/wp-gc-model/etc/motd /etc/motd
/bin/cp /tmp/wp-gc-model/etc/sysconfig/i18n /etc/sysconfig/i18n
  
/bin/cp -Rf /tmp/wp-gc-model/etc/nginx/* /etc/nginx/
#sed -e "s/\$host\([;\.]\)/$INSTANCEID\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf
#sed -e "s/\$host\([;\.]\)/$INSTANCEID\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.backend.conf > /etc/nginx/conf.d/default.backend.conf
if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /sbin/service nginx stop
  /bin/rm -Rf /var/log/nginx/*
  /bin/rm -Rf /var/cache/nginx/*
  /sbin/service nginx start
else
  #ALterei Jow
  #sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME www.$SERVERNAME $DATABASE.gcampaner.com.br/" | sed -e "s/\(\\s*\)\(include     \/etc\/nginx\/phpmyadmin;\)/\1#\2/" > /etc/nginx/conf.d/$SERVERNAME.conf
  #sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.backend.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME www.$SERVERNAME $DATABASE.gcampaner.com.br/" > /etc/nginx/conf.d/$SERVERNAME.backend.conf
  sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME www.$SERVERNAME/" | sed -e "s/\(\\s*\)\(include \/etc\/nginx\/phpmyadmin;\)/\1#\2/" > /etc/nginx/conf.d/$SERVERNAME.conf
  sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/wp-gc-model/etc/nginx/conf.d/default.backend.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME www.$SERVERNAME/" > /etc/nginx/conf.d/$SERVERNAME.backend.conf

  /usr/sbin/nginx -s reload
fi

if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /sbin/service php-fpm stop
  sed -e "s/\date\.timezone = \"UTC\"/date\.timezone = \"$TZ\"/" /tmp/wp-gc-model/etc/php.ini > /etc/php.ini
  /bin/cp -Rf /tmp/wp-gc-model/etc/php.d/* /etc/php.d/
  /bin/cp /tmp/wp-gc-model/etc/php-fpm.conf /etc/
  /bin/cp -Rf /tmp/wp-gc-model/etc/php-fpm.d/* /etc/php-fpm.d/
  /bin/rm -Rf /var/log/php-fpm/*
  /sbin/service php-fpm start
fi

echo "WordPress install ..."
/usr/bin/wget http://br.wordpress.org/latest-pt_BR.tar.gz > /dev/null 2>&1
/bin/tar xvfz /tmp/latest-pt_BR.tar.gz > /dev/null 2>&1
/bin/rm /tmp/latest-pt_BR.tar.gz

/bin/mv /tmp/wordpress /var/www/vhosts/$SERVERNAME
if [ -f /tmp/wp-gc-model/wp-setup.php ]; then
  /usr/bin/php /tmp/wp-gc-model/wp-setup.php $SERVERNAME $INSTANCEID $PUBLICNAME $
fi
/bin/chown -R nginx:nginx /var/log/nginx
plugin_install "nginx-champuru.1.1.5.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "head-cleaner.1.4.2.10.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "wp-total-hacks.1.0.2.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "jetpack.2.0.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "worker.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "w3-total-cache.0.9.2.4.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "wp-optimize.0.9.4.zip" "$SERVERNAME" > /dev/null 2>&1
plugin_install "login-lockdown.1.5.zip" "$SERVERNAME" > /dev/null 2>&1
echo "... WordPress installed"

/bin/chown -R nginx:nginx /var/log/nginx
/bin/chown -R nginx:nginx /var/log/php-fpm
/bin/chown -R nginx:nginx /var/cache/nginx
/bin/chown -R nginx:nginx /var/tmp/php
/bin/chown -R nginx:nginx /var/www/vhosts/$SERVERNAME
