export default {
  async fetch(request, env) {
    return handleRequest(request, env);
  }
}

async function handleRequest(request, env) {
  const TARGET_DOMAIN = env.TARGET_DOMAIN;
  const SPECIFIC_PATH = env.SPECIFIC_PATH;
  const TARGET_PROTOCOL = env.TARGET_PROTOCOL || 'https';
  const REDIRECT_OPTION = env.REDIRECT_OPTION;
  const REDIRECT_DOMAIN = env.REDIRECT_DOMAIN;
  const CUSTOM_404_PAGE = env.CUSTOM_404_PAGE;
  const REMOTE_404_URL = env.REMOTE_404_URL;

  const url = new URL(request.url);

  if (url.pathname.startsWith(SPECIFIC_PATH)) {
    const proxiedPath = url.pathname.slice(SPECIFIC_PATH.length);
    const fixedPath = proxiedPath.startsWith('/') ? proxiedPath : `/${proxiedPath}`;

    const targetUrl = `${TARGET_PROTOCOL}://${TARGET_DOMAIN}${fixedPath}${url.search}`;
    const modifiedRequest = new Request(targetUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body,
      redirect: 'follow'
    });
    const response = await fetch(modifiedRequest);
    const responseHeaders = new Headers(response.headers);
    responseHeaders.delete('location');

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: responseHeaders
    });
  } else {
    if (REDIRECT_OPTION) {
      const redirectUrl = new URL(request.url);
      redirectUrl.hostname = REDIRECT_DOMAIN;
      return Response.redirect(redirectUrl.toString(), 302);
    } else {
      if (CUSTOM_404_PAGE) {
        return new Response(CUSTOM_404_PAGE, {
          status: 404,
          headers: { "Content-Type": "text/html" },
        });
      } else if (REMOTE_404_URL) {
        try {
          const remoteResponse = await fetch(REMOTE_404_URL);
          const remote404Content = await remoteResponse.text();
          return new Response(remote404Content, {
            status: 404,
            headers: { "Content-Type": "text/html" },
          });
        } catch (error) {
          return new Response('404 Not Found', { status: 404 });
        }
      } else {
        return new Response('404 Not Found', { status: 404 });
      }
    }
  }
}
