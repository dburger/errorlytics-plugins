<?php
/*
Plugin Name: Errorlytics
Plugin URI: http://www.errorlytics.com
Description: Interface to the Errorlytics service.
Author: Accession Media
Version: 1.0
Author URI: http://www.errorlytics.com
*/

// constants
define('ERRORLYTICS_DEFAULT_URL', 'http://www.errorlytics.com');
define('ERRORLYTICS_URL_OPT_NAME', 'errorlytics_url');
define('ERRORLYTICS_SECRET_KEY_OPT_NAME', 'errorlytics_secret_key');
define('ERRORLYTICS_ACCOUNT_ID_OPT_NAME', 'errorlytics_account_id');
define('ERRORLYTICS_WEBSITE_ID_OPT_NAME', 'errorlytics_website_id');
define('ERRORLYTICS_PLUGIN_VERSION', '1.0');
define('ERRORLYTICS_API_VERSION', '1.0');

function errorlytics_settings() {
    $errorlytics_url = get_option(ERRORLYTICS_URL_OPT_NAME);
    if (!$errorlytics_url) $errorlytics_url = ERRORLYTICS_DEFAULT_URL;
    include('settings.php');
}

function errorlytics_add_menu() {
    add_submenu_page('options-general.php', 'Errorlytics', 'Errorlytics', 8, __FILE__, 'errorlytics_settings');
}

function errorlytics_params($path, $secret_key) {
    $params = array();
    foreach ($_SERVER as $key => $value) {
        if (!preg_match("/cookie/i", $key)) {
            $params['error[' . strtolower($key) . ']'] = $value;
        }
    }
    $client_occurred_at = gmdate('Y-m-d\TH:i:s\Z');
    $params['error[client_occurred_at]'] = $client_occurred_at;
    $params['signature'] = sha1($client_occurred_at . $path . $secret_key);
    $params['error[fake]'] = 'false';
    $params['format'] = 'xml';
    $params['plugin_type'] = 'wordpress_2.x';
    $params['plugin_version'] = ERRORLYTICS_PLUGIN_VERSION;
    $params['api_version'] = ERRORLYTICS_API_VERSION;

    return $params;
}

function errorlytics_post($url, $secret_key, $account_id, $website_id) {
    $path = '/accounts/' . $account_id . '/websites/' . $website_id . '/errors';
    $params = errorlytics_params($path, $secret_key);
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url . $path);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $params);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($ch);
    curl_close($ch);
    return $response;
}

function errorlytics_404() {
    if (is_404()) {
        // the options get trimmed on both ends during storage, so don't worry
        // about that, but make sure to take the / of the tail of the url
        $url = get_option(ERRORLYTICS_URL_OPT_NAME);
        if ($url) $url = chop($url, '/');
        $secret_key = get_option(ERRORLYTICS_SECRET_KEY_OPT_NAME);
        $account_id = get_option(ERRORLYTICS_ACCOUNT_ID_OPT_NAME);
        $website_id = get_option(ERRORLYTICS_WEBSITE_ID_OPT_NAME);

        // if missing settings let fall through to default 404 page
        if (!$url || !$secret_key || !$account_id || !$website_id) return;

        $response = errorlytics_post($url, $secret_key, $account_id, $website_id);

        preg_match('/<response-code>(.+)<\/response-code>/', $response, $matches);
        $response_code = $matches[1];

        preg_match('/<uri>(.+)<\/uri>/', $response, $matches);
        $uri = $matches[1];

        switch ($response_code) {
            case '404':
                // falling through to default wordpress 404 page for now
                // this is probably a better idea than taking the 404
                // page from the return
                break;
            case '301':
            case '302':
                header('Location: ' . $uri, true, $response_code);
                break;
        }
    }
}

add_action('admin_menu', 'errorlytics_add_menu');
add_action('template_redirect', 'errorlytics_404');
?>
