#!/bin/bash

# Affiche les variables pour débogage
echo "MYSQL_DB: $MYSQL_DB"
echo "MYSQL_USER: $MYSQL_USER"
echo "MYSQL_PASSWORD: $MYSQL_PASSWORD"
echo "DOMAIN_NAME: $DOMAIN_NAME"

# wp-cli installation
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

cd /var/www/wordpress
chmod -R 755 /var/www/wordpress/
chown -R www-data:www-data /var/www/wordpress

ping_mariadb_container() {
    nc -zv mariadb 3306 > /dev/null
    return $?
}

start_time=$(date +%s)
end_time=$((start_time + 60)) # Augmenté à 60 secondes

while [ $(date +%s) -lt $end_time ]; do
    ping_mariadb_container
    if [ $? -eq 0 ]; then
        echo "[========MARIADB IS UP AND RUNNING========]"
        break
    else
        echo "[========WAITING FOR MARIADB TO START...========]"
        sleep 5 # Attend 5 secondes avant d'essayer à nouveau
    fi
done

if [ $(date +%s) -ge $end_time ]; then
    echo "[========MARIADB IS NOT RESPONDING========]"
    exit 1
fi

# Test de connexion MySQL
mysql_ready() {
    mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" > /dev/null 2>&1
}

until mysql_ready; do
    echo "[========WAITING FOR MYSQL TO BE READY========]"
    sleep 5
done

echo "[========MYSQL IS READY========]"

# Nettoyer les fichiers WordPress existants
if [ -f wp-config.php ]; then
    echo "Removing existing WordPress files..."
    rm -rf /var/www/wordpress/*
fi

# Téléchargement et configuration de WordPress
wp core download --allow-root
wp core config --dbhost=mariadb:3306 --dbname="$MYSQL_DB" --dbuser="$MYSQL_USER" --dbpass="$MYSQL_PASSWORD" --allow-root
wp core install --url="$DOMAIN_NAME" --title="$WP_TITLE" --admin_user="$WP_ADMIN_N" --admin_password="$WP_ADMIN_P" --admin_email="$WP_ADMIN_E" --allow-root
wp user create "$WP_U_NAME" "$WP_U_EMAIL" --user_pass="$WP_U_PASS" --role="$WP_U_ROLE" --allow-root

# Configuration de PHP
sed -i '36 s@/run/php/php7.4-fpm.sock@9000@' /etc/php/7.4/fpm/pool.d/www.conf
mkdir -p /run/php
/usr/sbin/php-fpm7.4 -F
