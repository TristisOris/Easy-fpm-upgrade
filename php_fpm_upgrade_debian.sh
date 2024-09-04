#!/bin/bash

# -e - Enable interpretation of backslash escapes
# \e[ - Begin the color modifications
# COLORm - Code + ‘m’ at the end
# ${NOCOLOR} - End the color modifications
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
NOCOLOR='\033[0m'

# Choose versions
echo -n 'New PHP version?: (e.g. 8.3) '
read -r NEW_VERSION
echo -n 'Old PHP version?: (e.g. 8.1) '
read -r OLD_VERSION

# Write modules to list
apt list --installed | grep php$OLD_VERSION 2>/dev/null | awk -F'/' 'NR>0{print $1}' > /opt/php-modules.txt;
# Change php-fpm version to new
sed -i "s/$OLD_VERSION/$NEW_VERSION/" /opt/php-modules.txt;
# empty echo here because sed can't write to empty file. for clean isntallations.
echo "" > /opt/php-modules.txt;
# Add basic packages
sed -i "1i ca-certificates\napt-transport-https\nsoftware-properties-common\nlsb-release" /opt/php-modules.txt;
sed -i "1i php$NEW_VERSION\nphp$NEW_VERSION-fpm\nphp$NEW_VERSION-cli" /opt/php-modules.txt;
# Add php repo
add-apt-repository -y ppa:ondrej/php && apt update;

# Cleanup list
# Remove duplicate lines    
awk -i inplace '!NF || !seen[$0]++' /opt/php-modules.txt;
# `php*-fpm` installation will fail if `php*-json` been installed before: `Package 'php*-json' has no installation candidate`:
# There is no JSON module for anything >= PHP 8.0, since it's included into core now. So we remove `php*-json` package from list, since i don't care about PHP<8.0.
sed -i '/-json/d' /opt/php-modules.txt;

# Install new modules
sed 's/.*/&/;$!s/$/ /' /opt/php-modules.txt | tr -d '\n' | xargs apt install; echo -e;
while true; do
    read -p "Continue installation: y\n " yn; echo -e;
    if [[ "$yn" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        sed 's/.*/&/;$!s/$/ /' /opt/php-modules.txt | tr -d '\n' | xargs apt install -y; echo -e;
        break;
    else
        echo -e "${RED}Nothing to do${NOCOLOR}"; echo -e;
        echo -e ${GREEN}$(rm -v /opt/php-modules.txt)${NOCOLOR};
        exit;
fi
done

# Move custom configs from /etc/php/*/fpm/pool.d/ - x\y\z*.conf
while true; do
    read -p "Move custom configs to new version? (x\y\z*.conf): y\n " yn; echo -e;
    if [[ "$yn" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        echo -e "${GREEN}Move old configs:${NOCOLOR}"; cp -v /etc/php/$OLD_VERSION/fpm/pool.d/{x*.conf,y*.conf,z*.conf} /etc/php/$NEW_VERSION/fpm/pool.d/; echo -e;
    # QOL section
        echo -e ${GREEN}$(systemctl enable php$NEW_VERSION-fpm --now && systemctl reload php$NEW_VERSION-fpm)${NOCOLOR}; echo -e;
        # Validate php-fpm conf
        echo -e "${RED}Looking for PHP-FPM errors:${NOCOLOR}"; echo grep -m 10 "max_children" /var/log/php*-fpm.log*; echo -e;
        echo -e "${GREEN}Validate PHP-FPM config:${NOCOLOR}"; php-fpm$NEW_VERSION -t; echo -e;
        # Validate nginx conf if installed
        if dpkg -l nginx >/dev/null; then echo -e "${GREEN}Validate nginx conf & show enabled sites:${NOCOLOR}"; nginx -T | grep "server_name "; echo -e;
        echo -e "${GREEN}Edit socket at:${NOCOLOR} ${YELLOW}/etc/nginx/conf.d/*.conf${NOCOLOR}"; fi; echo -e;
        # [Debian] Validate apache2 conf if installed
        if dpkg -l apache2 >/dev/null; then echo -e "${GREEN}Validate apache2 conf & show enabled sites:${NOCOLOR}"; apache2ctl configtest; echo -e; grep 'ServerName\|DocumentRoot' /etc/apache2/sites-enabled/*; echo -e;
        echo -e "${GREEN}Activate PHP-FPM with:${NOCOLOR}"; echo -e "${YELLOW}a2enmod proxy_fcgi setenvif && a2enconf php8.3-fpm${NOCOLOR}"; fi; echo -e;
        # Reminders
        echo -e "${GREEN}To switch php version, execute:${NOCOLOR}"; echo -e "${YELLOW}update-alternatives --config php${NOCOLOR}"; echo -e;
        exit;
    else
        echo -e "${RED}Nothing to do${NOCOLOR}"; echo -e;
        echo -e ${GREEN}$(rm -v /opt/php-modules.txt)${NOCOLOR};
        exit;
fi
done
