<?php

/*
The MIT License

Copyright (c) 2008 Accession Media, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

define('ERRORLYTICS_PLUGIN_VERSION', '1.1.1');
define('ERRORLYTICS_API_VERSION', '1.0');

# escape the process if we are handling a 404 request that we generated
if ($_GET['__errorlytics__']) {
    echo '<h1>HTTP/1.1 404 Not Found</h1>';
    return;
}

function curl_get_file_contents($URL) {
    $url_with_param = $URL . "?__errorlytics__=true";
    $c = curl_init();
    curl_setopt($c, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($c, CURLOPT_URL, $url_with_param);
    $contents = curl_exec($c);
    curl_close($c);

    if ($contents) return $contents;
        else return FALSE;
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
    $params['plugin_type'] = 'php';
    $params['plugin_version'] = ERRORLYTICS_PLUGIN_VERSION;
    $params['api_version'] = ERRORLYTICS_API_VERSION;
    return $params;
}

# Config options
$host = '$ERRORLYTICS_URL$';
$path = '$YOUR_ERRORLYTICS_PATH$';
$secret_key = '$YOUR_SECRET_KEY$';

$params = errorlytics_params($path, $secret_key);

# Make the request
$ch = curl_init();
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 3);
curl_setopt($ch, CURLOPT_URL, $host.$path);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $params);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
curl_close($ch);

# Act on response (bit of a hack for now but will work)
preg_match('/<response-code>(.+)<\/response-code>/', $response, $matches);
$response_code = html_entity_decode($matches[1]);

preg_match('/<uri>(.+)<\/uri>/', $response, $matches);
$uri = html_entity_decode($matches[1]);

switch($response_code) {
case 404:
    header('HTTP/1.1 404 Not Found');
    $uri_content = @curl_get_file_contents($uri);
    if (!$uri_content)
        echo "<h1>Page Not Found</h1>";
    else
        echo $uri_content;
   break;
case 301:
case 302:
    header('Location: '.$uri, true, $response_code);
    break;
default:
    echo 'Unexpected response code received.';
}
?>
