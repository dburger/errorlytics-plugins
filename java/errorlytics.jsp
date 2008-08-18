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
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Map.Entry" %>
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

    public String formUrlEncode(HashMap map) throws UnsupportedEncodingException {
        StringBuilder buf = new StringBuilder();
        for (Iterator i = map.entrySet().iterator(); i.hasNext();) {
            Entry e = (Entry)i.next();
            String key = e.getKey().toString();
            if ("Cookie".equals(key)) continue;
            Object value = e.getValue();
            buf.append(key + "=" + encode(value));
            if (i.hasNext()) buf.append("&");
        }
        return buf.toString();
    }

    public HashMap createErrorlyticsContentMap(HttpServletRequest req,
            String errorlyticsPath, String requestUri)
            throws NoSuchAlgorithmException, UnsupportedEncodingException {
        HashMap contentMap = new HashMap();

	for (Enumeration e = req.getHeaderNames(); e.hasMoreElements();) {
            String headerName = (String)e.nextElement();
            contentMap.put("error[" + headerName.replace('-', '_').toLowerCase()
                    + "]", req.getHeader(headerName));
        }

        // XXX: start java fixups, appears many of the environment variables
        // available in php's $_SERVER may not be directly available from
        // an HttpServletRequest
        // 1. "HTTP_HOST" is in the header "HOST"
        contentMap.put("error[http_host]", req.getHeader("Host"));
        // 2. getRequestUri() gives the URI of this error page, which is why
        //    we pass in the requestUri from the original request
        contentMap.put("error[request_uri]", requestUri);
        // 3. "HTTP_USER_AGENT" is in the header "User-Agent"
        contentMap.put("error[http_user_agent]", req.getHeader("User-Agent"));
        // 4. getRemoteAddr() gives remote address, not in headers
        contentMap.put("error[remote_addr]", req.getRemoteAddr());
        // 5. "HTTP_REFERER" is in the header "Referer"
	contentMap.put("error[http_referer]", req.getHeader("Referer"));
        // XXX: end java fixups

        String occurredAt = SDF.format(new Date());
        contentMap.put("error[client_occurred_at]", occurredAt);
        String signature = sha1(occurredAt + errorlyticsPath + SECRET_KEY);
        contentMap.put("signature", signature);
        contentMap.put("error[fake]", "false");
        contentMap.put("format", "xml");
        return contentMap;
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
        String content = formUrlEncode(createErrorlyticsContentMap(req, path, requestUri));
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

    public String encode(Object value) throws UnsupportedEncodingException {
        return (value == null) ? "" : URLEncoder.encode(value.toString(), ENCODING);
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
            // TODO: 422 :unprocessable_entity will cause an IOException
            // should still let this fall through to the 404 page below
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
        <h1>404 Not Found</h1>
        <p>The requested URL <%= pageContext.getAttribute("javax.servlet.error.request_uri", PageContext.REQUEST_SCOPE).toString() %> was not found on this server.</p>
    </body>
</html>
