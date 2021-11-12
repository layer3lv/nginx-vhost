NGINX_CONFIG='/etc/nginx/sites-available'
NGINX_SITES_ENABLED='/etc/nginx/sites-enabled'
WEB_DIR='/var/www'
SED=`which sed`
CURRENT_DIR=`dirname $0`

if [ -z $1 ]; then
        echo "No domain name given"
        exit 1
fi
DOMAIN=$1

# check the domain is roughly valid!
PATTERN="^([[:alnum:]]([[:alnum:]\-]{0,61}[[:alnum:]])?\.)+[[:alpha:]]{2,6}$"
if [[ "$DOMAIN" =~ $PATTERN ]]; then
        DOMAIN=`echo $DOMAIN | tr '[A-Z]' '[a-z]'`
        echo "Creating hosting for:" $DOMAIN
else
        echo "invalid domain name"
        exit 1
fi

#Replace dots with underscores
SITE_DIR=`echo $DOMAIN | $SED 's/\././g'`

# Now we need to copy the virtual host template
CONFIG=$NGINX_CONFIG/$DOMAIN
sudo cp $CURRENT_DIR/virtual_host.template $CONFIG
sudo $SED -i "s/DOMAIN/$DOMAIN/g" $CONFIG
sudo $SED -i "s!ROOT!$WEB_DIR/$SITE_DIR!g" $CONFIG

# set up web root
sudo mkdir -p $WEB_DIR/$SITE_DIR/htdocs
sudo mkdir -p $WEB_DIR/$SITE_DIR/log
sudo mkdir -p $WEB_DIR/$SITE_DIR/errors
sudo touch $WEB_DIR/$SITE_DIR/errors/404.html
sudo touch $WEB_DIR/$SITE_DIR/errors/50x.html
sudo touch  $WEB_DIR/$SITE_DIR/log/access.log
sudo touch  $WEB_DIR/$SITE_DIR/log/error.log
sudo mkdir -p $WEB_DIR/$SITE_DIR/tmp
sudo chown www-data:www-data -R $WEB_DIR/$SITE_DIR/htdocs
sudo chown www-data:www-data -R $WEB_DIR/$SITE_DIR/log
sudo chown www-data:www-data -R $WEB_DIR/$SITE_DIR/tmp
sudo chown www-data:www-data -R $WEB_DIR/$SITE_DIR/errors
sudo chmod 777 $WEB_DIR/$SITE_DIR/tmp
sudo chmod 600 $CONFIG

# create symlink to enable site
sudo ln -s $CONFIG $NGINX_SITES_ENABLED/$DOMAIN

# reload Nginx to pull in new config
sudo service nginx reload

# put the template index.html file into the new domains web dir
sudo cp $CURRENT_DIR/index.html.template $WEB_DIR/$SITE_DIR/htdocs/index.html
sudo $SED -i "s/SITE/$DOMAIN/g" $WEB_DIR/$SITE_DIR/htdocs/index.html
sudo chown www-data:www-data $WEB_DIR/$SITE_DIR/htdocs/index.html

echo "Site Created for $DOMAIN"
