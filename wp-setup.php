<?php
$mysql_db = $mysql_user = $mysql_pwd = $public_name = $instance_id = $site_name = "";
switch($argc) {
    case 1:
        echo "please input site name!\n";
        exit();
    default:
        $mysql_pwd   = isset($argv[5]) ? $argv[5] : '';
        $mysql_user  = isset($argv[4]) ? $argv[4] : '';
        $public_name = isset($argv[3]) ? $argv[3] : '';
        $instance_id = isset($argv[2]) ? $argv[2] : '';
        $site_name   = $argv[1];
}
$dbuser = explode('.', $site_name) ;
$mysql_db   = $site_name !== 'default' ? $dbuser[0] : 'wordpress';
$mysql_user = $dbuser[0];
$mysql_pwd  = 'Muitosucesso';

$DB_NAME = $mysql_db ;
$DB_USER = 'gcmysql' ;
$DB_PASSWORD  = 'Muitosucesso' ;
$DB_HOST = 'mysql.gcampaner.com.br' ;

// make user and database
$link = mysql_connect($DB_HOST, $DB_USER, $DB_PASSWORD);
if ( !$link )
    die('MySQL connect error!!: '.mysql_error());
if ( !mysql_select_db('mysql', $link) )
    die('MySQL select DB error!!: '.mysql_error());
if ( !mysql_query("create database {$mysql_db} default character set utf8 collate utf8_general_ci;") )
    die('MySQL create database error!!: '.mysql_error());
#if ( !mysql_query("grant all privileges on {$mysql_db}.* to {$DB_NAME}@localhost identified by '{$DB_PASSWORD}';") )
#    die('MySQL create user error!!: '.mysql_error());
    
mysql_close($link);

// make wp-config.php
$wp_cfg = "/var/www/vhosts/{$site_name}/wp-config-sample.php";
if ( file_exists($wp_cfg) ) {
    $wp_cfg = file_get_contents($wp_cfg);
}

$wp_cfg = preg_replace('/define\([\s]*[\'"]DB_NAME[\'"][\s]*,[\s]*[\'"][^\'"]*[\'"][\s]*\)/i', "define('DB_NAME', '{$DB_NAME}')", $wp_cfg);
$wp_cfg = preg_replace('/define\([\s]*[\'"]DB_USER[\'"][\s]*,[\s]*[\'"][^\'"]*[\'"][\s]*\)/i', "define('DB_USER', '{$DB_USER}')", $wp_cfg);
$wp_cfg = preg_replace('/define\([\s]*[\'"]DB_PASSWORD[\'"][\s]*,[\s]*[\'"][^\'"]*[\'"][\s]*\)/i', "define('DB_PASSWORD', '{$DB_PASSWORD}')", $wp_cfg);
$wp_cfg = preg_replace('/define\([\s]*[\'"]DB_HOST[\'"][\s]*,[\s]*[\'"][^\'"]*[\'"][\s]*\)/i', "define('DB_HOST', '{$DB_HOST}')", $wp_cfg);

$salts  = preg_split('/[\r\n]+/ms', file_get_contents('https://api.wordpress.org/secret-key/1.1/salt/'));
foreach ( $salts as $salt ) {
    if ( preg_match('/define\([\s]*[\'"](AUTH_KEY|SECURE_AUTH_KEY|LOGGED_IN_KEY|NONCE_KEY|AUTH_SALT|SECURE_AUTH_SALT|LOGGED_IN_SALT|NONCE_SALT)[\'"][\s]*,[\s]*[\'"]([^\'"]*)[\'"][\s]*\);/i', $salt, $matches) ) {
        $wp_cfg = preg_replace(
            '/define\([\'"]'.preg_quote($matches[1],'/').'[\'"],[\s]*[\'"][^\'"]*[\'"]\);/i',
            str_replace('$','\$',$matches[0]),
            $wp_cfg);
    }
    unset($matches);
}

$wp_cfg = preg_replace(
    '/(table_prefix[\s]*\=[\s]*[\'"][^\'"]*[\'"];)/i',
    '$1'."\n\ndefine('NCC_CACHE_DIR', '/var/cache/nginx/proxy_cache');\n\n",
    $wp_cfg);

if ( $instance_id === $site_name ) {
    $wp_cfg = preg_replace(
        '/(table_prefix[\s]*\=[\s]*[\'"][^\'"]*[\'"];)/i',
        '$1'."\n\n".sprintf("//define('WP_SITEURL','http://%1\$s');\n//define('WP_HOME','http://%1\$s');", $public_name),
        $wp_cfg);
}

$wp_cfg = str_replace("\r\n", "\n", $wp_cfg);

echo "\n--------------------------------------------------\n";
echo " file_put_contents\n";
echo "--------------------------------------------------\n";

var_dump(file_put_contents("/var/www/vhosts/{$site_name}/wp-config.php", $wp_cfg));

$ngx_champuru = "/var/www/vhosts/{$site_name}/wp-content/plugins/nginx-champuru/nginx-champuru.php";
if ( file_exists($ngx_champuru) ) {
    $ngx_champuru_php = str_replace('"/var/cache/nginx"','"/var/cache/nginx/proxy_cache"', file_get_contents($ngx_champuru));
    file_put_contents($ngx_champuru, $ngx_champuru_php);
}

echo "\n--------------------------------------------------\n";
echo " MySQL DataBase: {$mysql_db}\n";
echo " MySQL User:     {$mysql_user}\n";
echo " MySQL Password: {$mysql_pwd}\n";
echo "--------------------------------------------------\n";

echo "\n";
printf ("Success!! http://%s/\n", $instance_id === $site_name ? $public_name : $site_name);
echo "--------------------------------------------------\n";
