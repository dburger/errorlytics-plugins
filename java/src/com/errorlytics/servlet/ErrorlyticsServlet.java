package com.errorlytics.servlet;

/*
    example web.xml setup:

    <servlet>
        <servlet-name>ErrorlyticsServlet</servlet-name>
        <servlet-class>com.errorlytics.servlet.ErrorlyticsServlet</servlet-class>
        <init-param>
            <param-name>url</param-name>
            <param-value>http://www.errorlytics.com</param-value>
        </init-param>
        <init-param>
            <param-name>secretKey</param-name>
            <param-value>umpCU49zCGpuGkrKNwM1LjzBVrrTXZX3DcC8N2Yc</param-value>
        </init-param>
        <init-param>
            <param-name>accountId</param-name>
            <param-value>12</param-value>
        </init-param>
        <init-param>
            <param-name>websiteId</param-name>
            <param-value>15</param-value>
        </init-param>
    </servlet>

    <servlet-mapping>
        <servlet-name>ErrorlyticsServlet</servlet-name>
        <url-pattern>/404</url-pattern>
    </servlet-mapping>

    to compile, needs servlet-api.jar on the classpath
*/

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;

import java.net.URL;
import java.net.URLConnection;
import java.net.URLEncoder;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ErrorlyticsServlet extends HttpServlet {

    private final String ENCODING = "UTF-8";
    private final SimpleDateFormat SDF =
            new SimpleDateFormat("yyyy-MM-dd'T'kk:mm:ss'Z'");

    Pattern RESP_CODE_PATTERN = Pattern.compile("<response-code>(.+)</response-code>");
    Pattern URI_PATTERN = Pattern.compile("<uri>(.+)</uri>");

    private ServletContext _servletContext;

    private String _url;
    private String _secretKey;
    private String _accountId;
    private String _websiteId;

    public void init() throws ServletException {
        _servletContext = getServletContext();
        _url = getInitParameter("url", "http://www.errorlytics.com");
        if (_url.endsWith("/")) _url = _url.substring(0, _url.length() - 1);
        _secretKey = getInitParameter("secretKey", null);
        _accountId = getInitParameter("accountId", null);
        _websiteId = getInitParameter("websiteId", null);
    }

    protected void service(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        PrintWriter out = res.getWriter();
        if (_url == null || _secretKey == null || _accountId == null
                || _websiteId == null) {
            out.println("not configured");
        } else {
            String response;
            try {
                response = getErrorlyticsResponse(req);
            } catch (NoSuchAlgorithmException exc) {
                throw new IOException(exc);
            }

            Matcher rcm = RESP_CODE_PATTERN.matcher(response);
            Matcher um = URI_PATTERN.matcher(response);
            if (rcm.find() && um.find()) {
                String responseCode = rcm.group(1);
                String uri = um.group(1);
                out.println("was " + responseCode + " and " + uri);
            } else {
                out.println("didn't match");
            }
        }
    }

    private String getInitParameter(String name, String defaultValue) {
        String value = super.getInitParameter(name);
        if (value == null) value = defaultValue;
        return value;
    }

    private String getErrorlyticsResponse(HttpServletRequest req)
            throws IOException, NoSuchAlgorithmException {
        String path = "/accounts/" + _accountId + "/websites/" + _websiteId
                + "/errors";
        URL url = new URL(_url + path);
        URLConnection urlCon = url.openConnection();
        urlCon.setDoInput(true);
        urlCon.setDoOutput(true);
        urlCon.setUseCaches(false);
        urlCon.setRequestProperty("Content-Type",
                "application/x-www-form-urlencoded");
        String content = createErrorlyticsContent(req, path);
        PrintWriter out = new PrintWriter(new BufferedWriter(
                new OutputStreamWriter(urlCon.getOutputStream())));
        out.print(content);
        out.flush();
        out.close();
        BufferedReader br = new BufferedReader(new InputStreamReader(
                urlCon.getInputStream()));
        StringBuilder response = new StringBuilder();
        String line;
        while ((line = br.readLine()) != null) response.append(line);
        return response.toString();
    }

    private String createErrorlyticsContent(HttpServletRequest req, String path)
            throws NoSuchAlgorithmException, UnsupportedEncodingException {
        StringBuilder content = new StringBuilder();
        // TODO: is host correct if behind apache?
        content.append("error[http_host]=" + e(req.getHeader("Host")));
        content.append("&error[request_uri]=" + e(req.getRequestURI()));
        content.append("&error[http_user_agent]=" + e(req.getHeader("User-Agent")));
        content.append("&error[remote_addr]=" + e(req.getRemoteAddr()));
        content.append("&error[http_referer]=" + e(req.getHeader("Referer")));
        String occurredAt = SDF.format(new Date());
        content.append("&error[client_occurred_at]=" + e(occurredAt));
        content.append("&signature=" + e(sha1(occurredAt + path + _secretKey)));
        content.append("&error[fake]=false");
        content.append("&format=xml");
        return content.toString();
    }

    private String e(String value) throws UnsupportedEncodingException {
        return (value == null) ? "" : URLEncoder.encode(value, ENCODING);
    }

    private String sha1(String value) throws NoSuchAlgorithmException {
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        md.update(value.getBytes());
        byte[] digest = md.digest();
        StringBuilder hexDigest = new StringBuilder();
        for (int i = 0; i < digest.length; i++) {
            String digits = Integer.toHexString(0x00FF & digest[i]);
            if (digits.length() == 1) digits = "0" + digits;
            hexDigest.append(digits);
        }
        return hexDigest.toString();
    }

}
