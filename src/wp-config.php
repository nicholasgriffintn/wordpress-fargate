<?php
 define('WP_ALLOW_MULTISITE', true);

define( 'SUNRISE', true );
 // ** MySQL settings ** //

define('DB_NAME', '');
define('DB_USER', '');
define('DB_PASSWORD', '');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

define('DISALLOW_FILE_EDIT', true);
define('WP_DEBUG', false);

define('SECRET_KEY', 'SOMETHING'); // Change this to a unique phrase.
define('AUTH_KEY', 'SOMETHING'); // Change this to a unique phrase.
define('SECURE_AUTH_KEY', 'SOMETHING'); // Change this to a unique phrase.
define('LOGGED_IN_KEY', 'SOMETHING'); // Change this to a unique phrase.


define( 'NONCE_KEY', 'SOMETHING' );
define( 'AUTH_SALT', 'SOMETHING' );
define( 'SECURE_AUTH_SALT', 'SOMETHING' );
define( 'LOGGED_IN_SALT', 'SOMETHING' );
define( 'NONCE_SALT', 'SOMETHING' );

// You can have multiple installations in one database if you give each a unique prefix
$table_prefix  = 'wp_';

define ('WPLANG', 'en_GB');

define('WP_POST_REVISIONS','1'); 

define('WP_HOME','http://example-stg.fargate.example.com');
define('WP_SITEURL','http://example-stg.fargate.example.com');

define( 'MULTISITE', true );
define( 'SUBDOMAIN_INSTALL', true );
$base = '/';
define( 'DOMAIN_CURRENT_SITE', 'example-stg.fargate.example.com' );
define( 'PATH_CURRENT_SITE', '/' );
define( 'SITE_ID_CURRENT_SITE', 1 );
define( 'BLOG_ID_CURRENT_SITE', 1 );

define('AUTOMATIC_UPDATER_DISABLED', true);
define('DISABLE_WP_CRON', false);
define('DISALLOW_FILE_EDIT', true);

if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
	$_SERVER['HTTPS'] = 'on';
}

/* That's all, stop editing! Happy blogging. */

define('ABSPATH', dirname(__FILE__).'/');
define('WP_CACHE', true);
require_once(ABSPATH.'wp-settings.php');
?>