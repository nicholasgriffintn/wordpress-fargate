#!/bin/bash
set -e

if [ -n "$MYSQL_PORT_3306_TCP" ]; then
	if [ -z "$WORDPRESS_DB_HOST" ]; then
		WORDPRESS_DB_HOST='mysql'
	else
		echo >&2 'warning: both WORDPRESS_DB_HOST and MYSQL_PORT_3306_TCP found'
		echo >&2 "  Connecting to WORDPRESS_DB_HOST ($WORDPRESS_DB_HOST)"
		echo >&2 '  instead of the linked mysql container'
	fi
fi

if [ -z "$WORDPRESS_DB_HOST" ]; then
	echo >&2 'error: missing WORDPRESS_DB_HOST and MYSQL_PORT_3306_TCP environment variables'
	echo >&2 '  Did you forget to --link some_mysql_container:mysql or set an external db'
	echo >&2 '  with -e WORDPRESS_DB_HOST=hostname:port?'
	exit 1
fi

# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${WORDPRESS_DB_USER:=root}
if [ "$WORDPRESS_DB_USER" = 'root' ]; then
	: ${WORDPRESS_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${WORDPRESS_DB_NAME:=wordpress}

if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
	echo >&2 'error: missing required WORDPRESS_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e WORDPRESS_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be WORDPRESS_DB_USER and WORDPRESS_DB_NAME.)'
	exit 1
fi

if ! [ -e index.php -a -e wp-includes/version.php ]; then
	echo >&2 "WordPress not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	tar cf - --one-file-system -C /usr/src/wordpress . | tar xf -
	echo >&2 "Complete! WordPress has been successfully copied to $(pwd)"
	if [ ! -e .htaccess ]; then
		# NOTE: The "Indexes" option is disabled in the php:apache base image
		cat > .htaccess <<-'EOF'
			# BEGIN WordPress
			RewriteEngine On
			RewriteBase /
			RewriteRule ^index\.php$ - [L]

			# add a trailing slash to /wp-admin
			RewriteRule ^wp-admin$ wp-admin/ [R=301,L]

			RewriteCond %{REQUEST_FILENAME} -f [OR]
			RewriteCond %{REQUEST_FILENAME} -d
			RewriteRule ^ - [L]
			RewriteRule ^(wp-(content|admin|includes).*) $1 [L]
			RewriteRule ^(.*\.php)$ $1 [L]
			RewriteRule . index.php [L]
			# END WordPress
		EOF
		chown www-data:www-data .htaccess
	fi
fi

# TODO handle WordPress upgrades magically in the same way, but only if wp-includes/version.php's $wp_version is less than /usr/src/wordpress/wp-includes/version.php's $wp_version

if [ ! -e wp-config.php ]; then
		# NOTE: The "Indexes" option is disabled in the php:apache base image
		cat > wp-config.php <<-'EOF'
			<?php
 				define('WP_ALLOW_MULTISITE', true);

				define( 'SUNRISE', false );

 				// ** MySQL settings ** //
				define('DB_NAME', '');
				define('DB_USER', '');
				define('DB_PASSWORD', '');
				define('DB_HOST', 'localhost');
				define('DB_CHARSET', 'utf8');
				define('DB_COLLATE', '');
		
				// ** WordPress settings ** //
				define('AUTOMATIC_UPDATER_DISABLED', true);
				define('DISABLE_WP_CRON', false);
				define('DISALLOW_FILE_EDIT', true);
				define('WP_DEBUG', false);

				define('SECRET_KEY', 'put your unique phrase here'); // Change this to a unique phrase.
				define('AUTH_KEY', 'put your unique phrase here'); // Change this to a unique phrase.
				define('SECURE_AUTH_KEY', 'put your unique phrase here'); // Change this to a unique phrase.
				define('LOGGED_IN_KEY', 'put your unique phrase here'); // Change this to a unique phrase.


				define( 'NONCE_KEY', 'put your unique phrase here' );
				define( 'AUTH_SALT', 'put your unique phrase here' );
				define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
				define( 'LOGGED_IN_SALT', 'put your unique phrase here' );
				define( 'NONCE_SALT', 'put your unique phrase here' );

				$table_prefix  = 'wp_';

				define ('WPLANG', 'en_GB');

				define('WP_POST_REVISIONS','1'); 

				define('WP_HOME','http://example-stg.fargate.example.com');
				define('WP_SITEURL','http://example-stg.fargate.example.com');

				define( 'ADMIN_COOKIE_PATH', '/' );
    			define( 'COOKIE_DOMAIN', '' );
    			define( 'COOKIEPATH', '' );
    			define( 'SITECOOKIEPATH', '' );
				define( 'NOBLOGREDIRECT', 'http://example-stg.fargate.example.com' );

				define( 'MULTISITE', true );
				define( 'SUBDOMAIN_INSTALL', true );
				define( 'DOMAIN_CURRENT_SITE', 'example-stg.fargate.example.com' );
				define( 'PATH_CURRENT_SITE', '/' );
				define( 'SITE_ID_CURRENT_SITE', 1 );
				define( 'BLOG_ID_CURRENT_SITE', 1 );

				// ** HTTPS settings ** //
				if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
					$_SERVER['HTTPS'] = 'on';
				}

				/* That's all, stop editing! Happy blogging. */

				define('ABSPATH', dirname(__FILE__).'/');
				define('WP_CACHE', true);
				require_once(ABSPATH.'wp-settings.php');
			?>
		EOF
		chown www-data:www-data wp-config.php
	fi

set_config() {
	key="$1"
	value="$2"
	php_escaped_value="$(php -r 'var_export($argv[1]);' "$value")"
	sed_escaped_value="$(echo "$php_escaped_value" | sed 's/[\/&]/\\&/g')"
	sed -ri "s/((['\"])$key\2\s*,\s*)(['\"]).*\3/\1$sed_escaped_value/" wp-config.php
}

set_config 'DB_HOST' "$WORDPRESS_DB_HOST"
set_config 'DB_USER' "$WORDPRESS_DB_USER"
set_config 'DB_PASSWORD' "$WORDPRESS_DB_PASSWORD"
set_config 'DB_NAME' "$WORDPRESS_DB_NAME"

# get access keys for content upload from ssm parameter store
output=$(aws ssm get-parameter --name ${SSM_USER_UPLOAD_KEY_PARAM} --query Parameter.Value)
secret_key=$(echo "${output}" | sed -e 's/^"//' -e 's/"$//')
output=$(aws ssm get-parameter --name ${SSM_USER_UPLOAD_SAK_PARAM} --query Parameter.Value)
secret_access_key=$(echo "${output}" | sed -e 's/^"//' -e 's/"$//')

# allow any of these "Authentication Unique Keys and Salts." to be specified via
# environment variables with a "WORDPRESS_" prefix (ie, "WORDPRESS_AUTH_KEY")
UNIQUES=(
	AUTH_KEY
	SECURE_AUTH_KEY
	LOGGED_IN_KEY
	NONCE_KEY
	AUTH_SALT
	SECURE_AUTH_SALT
	LOGGED_IN_SALT
	NONCE_SALT
)
for unique in "${UNIQUES[@]}"; do
	eval unique_value=\$WORDPRESS_$unique
	if [ "$unique_value" ]; then
		set_config "$unique" "$unique_value"
	else
		# if not specified, let's generate a random value
		current_set="$(sed -rn "s/define\((([\'\"])$unique\2\s*,\s*)(['\"])(.*)\3\);/\4/p" wp-config.php)"
		if [ "$current_set" = 'put your unique phrase here' ]; then
			set_config "$unique" "$(head -c1M /dev/urandom | sha1sum | cut -d' ' -f1)"
		fi
	fi
done

TERM=dumb php -- "$WORDPRESS_DB_HOST" "$WORDPRESS_DB_USER" "$WORDPRESS_DB_PASSWORD" "$WORDPRESS_DB_NAME" <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)

$stderr = fopen('php://stderr', 'w');

list($host, $port) = explode(':', $argv[1], 2);

$maxTries = 10;
do {
	$mysql = new mysqli($host, $argv[2], $argv[3], '', (int)$port);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($argv[4]) . '`')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

$mysql->close();
EOPHP

exec "$@"