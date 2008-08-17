<%--
  Easy as 1, 2, 3:

  1. Modify the "YOUR ..." sections below, including the secret key,
     account id, and website id.
  2. Place this file within your web application, a good location would be:
     /WEB-INF/jsp/errorlytics.jsp
  3. Add an error-page for 404 directive to your web.xml deployment descriptor,
     it should look something like this:

     <error-page>
         <error-code>404</error-code>
         <location>/WEB-INF/jsp/errorlytics.jsp</location>
     </error-page>
--%>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.BufferedWriter" %>
<%@ page import="java.io.InputStreamReader" %>

<%@ page import="java.io.IOException" %>
<%@ page import="java.io.OutputStreamWriter" %>
<%@ page import="java.io.PrintWriter" %>
<%@ page import="java.io.UnsupportedEncodingException" %>

<%@ page import="java.net.URL" %>
<%@ page import="java.net.URLConnection" %>
<%@ page import="java.net.URLEncoder" %>

<%@ page import="java.security.MessageDigest" %>
<%@ page import="java.security.NoSuchAlgorithmException" %>

<%@ page import="javax.servlet.ServletContext" %>
<%@ page import="javax.servlet.ServletException" %>

<%@ page import="javax.servlet.http.HttpServlet" %>
<%@ page import="javax.servlet.http.HttpServletRequest" %>
<%@ page import="javax.servlet.http.HttpServletResponse" %>

<%@ page import="java.text.SimpleDateFormat" %>

<%@ page import="java.util.Date" %>
<%@ page import="java.util.regex.Matcher" %>
<%@ page import="java.util.regex.Pattern" %>

<%!
    String ERRORLYTICS_URL = "http://www.errorlytics.com";
    final String SECRET_KEY = "YOUR SECRET KEY HERE";
    final String ACCOUNT_ID = "YOUR ACCOUNT ID HERE";
    final String WEBSITE_ID = "YOUR WEBSITE ID HERE";

    String ENCODING = "UTF-8";
    SimpleDateFormat SDF = new SimpleDateFormat("yyyy-MM-dd'T'kk:mm:ss'Z'");
    Pattern RESP_CODE_PATTERN = Pattern.compile("<response-code>(.+)</response-code>");
    Pattern URI_PATTERN = Pattern.compile("<uri>(.+)</uri>");

    public String createErrorlyticsContent(HttpServletRequest req, String errorlyticsPath, String requestUri)
            throws NoSuchAlgorithmException, UnsupportedEncodingException {
        StringBuilder content = new StringBuilder();
        // TODO: is host correct if behind apache?
        content.append("error[http_host]=" + e(req.getHeader("Host")));
        // getRequestURI will give us the URI of this error page, thus the
        // the passing of the PageContext around and requestUri to this method
        content.append("&error[request_uri]=" + e(requestUri));
        content.append("&error[http_user_agent]=" + e(req.getHeader("User-Agent")));
        content.append("&error[remote_addr]=" + e(req.getRemoteAddr()));
        content.append("&error[http_referer]=" + e(req.getHeader("Referer")));
        String occurredAt = SDF.format(new Date());
        content.append("&error[client_occurred_at]=" + e(occurredAt));
        content.append("&signature=" + e(sha1(occurredAt + errorlyticsPath + SECRET_KEY)));
        content.append("&error[fake]=false");
        content.append("&format=xml");
        return content.toString();
    }

    public String getErrorlyticsResponse(HttpServletRequest req, PageContext pageContext)
            throws IOException, NoSuchAlgorithmException {
        String path = "/accounts/" + ACCOUNT_ID + "/websites/" + WEBSITE_ID + "/errors";
        URL url = new URL(ERRORLYTICS_URL + path);
        URLConnection urlCon = url.openConnection();
        urlCon.setDoInput(true);
        urlCon.setDoOutput(true);
        urlCon.setUseCaches(false);
        urlCon.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        String requestUri = pageContext.getAttribute("javax.servlet.error.request_uri", PageContext.REQUEST_SCOPE).toString();
        String content = createErrorlyticsContent(req, path, requestUri);
        PrintWriter out = new PrintWriter(new BufferedWriter(new OutputStreamWriter(urlCon.getOutputStream())));
        out.print(content);
        out.flush();
        out.close();
        BufferedReader br = new BufferedReader(new InputStreamReader(urlCon.getInputStream()));
        StringBuilder response = new StringBuilder();
        String line;
        while ((line = br.readLine()) != null) response.append(line);
        return response.toString();
    }

    public String e(String value) throws UnsupportedEncodingException {
        return (value == null) ? "" : URLEncoder.encode(value, ENCODING);
    }

    public String sha1(String value) throws NoSuchAlgorithmException {
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
%>
<%
    if (ERRORLYTICS_URL.endsWith("/")) ERRORLYTICS_URL = ERRORLYTICS_URL.substring(0, ERRORLYTICS_URL.length() - 1);
    if (ERRORLYTICS_URL != null && SECRET_KEY != null && ACCOUNT_ID != null && WEBSITE_ID != null) {
        String errorlyticsResponse;
        try {
            errorlyticsResponse = getErrorlyticsResponse(request, pageContext);
        } catch (IOException exc) {
            throw new IOException(exc);
        }
        Matcher rcm = RESP_CODE_PATTERN.matcher(errorlyticsResponse);
        Matcher um = URI_PATTERN.matcher(errorlyticsResponse);
        if (rcm.find() && um.find()) {
            int responseCode = Integer.parseInt(rcm.group(1));
            String uri = um.group(1);
            response.setStatus(responseCode);
            response.setHeader("Location", uri);
        }
    }
%>
<html>
    <head>
        <title>404 Not Found</title>
    </head>
    <body>
        <p>The requested URL <%= pageContext.getAttribute("javax.servlet.error.request_uri", PageContext.REQUEST_SCOPE).toString() %> was not found on this server.</p>
    </body>
</html>
