export default {
  async fetch(request, env) {
    return handleRequest(request, env);
  }
}

async function handleRequest(request, env) {
  const TARGET_DOMAIN = env.TARGET_DOMAIN;
  const SPECIFIC_PATH = (env.SPECIFIC_PATH || '/').endsWith('/') ? (env.SPECIFIC_PATH || '/') : (env.SPECIFIC_PATH || '/') + '/';
  const REDIRECT_DOMAIN = env.REDIRECT_DOMAIN;
  const CUSTOM_404_PAGE = env.CUSTOM_404_PAGE;
  const REMOTE_404_URL = env.REMOTE_404_URL;

  const url = new URL(request.url);
  const trimmedSpecificPath = SPECIFIC_PATH.slice(0, -1);
  
  if (url.pathname === trimmedSpecificPath) {
    return Response.redirect(url.origin + SPECIFIC_PATH, 302);
  }

  if (url.pathname.startsWith(SPECIFIC_PATH)) {
    const proxiedPath = url.pathname.slice(SPECIFIC_PATH.length);
    const fixedPath = proxiedPath.startsWith('/') ? proxiedPath : `/${proxiedPath}`;

    const targetUrl = (TARGET_DOMAIN.startsWith('http://') || TARGET_DOMAIN.startsWith('https://'))
      ? `${TARGET_DOMAIN}${fixedPath}${url.search}`
      : `https://${TARGET_DOMAIN}${fixedPath}${url.search}`;

    const modifiedRequest = new Request(targetUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body,
      redirect: 'follow'
    });
    const response = await fetch(modifiedRequest);

    const responseHeaders = new Headers(response.headers);
    responseHeaders.delete('location');
    responseHeaders.set('Access-Control-Allow-Origin', '*');

    if (response.headers.get('content-type')?.includes('text/html')) {
      let modifiedHtml = await response.text();
      modifiedHtml = modifiedHtml.replace(/(href|src)="\/([^"]*)"/g, `$1="${TARGET_DOMAIN.startsWith('http') ? TARGET_DOMAIN : 'https://' + TARGET_DOMAIN}/$2"`);

      return new Response(modifiedHtml, {
        status: response.status,
        headers: responseHeaders,
      });
    } else {
      return new Response(response.body, {
        status: response.status,
        headers: responseHeaders,
      });
    }
  } else {
    if (REDIRECT_DOMAIN) {
      const redirectUrl = new URL(REDIRECT_DOMAIN.includes('http') ? REDIRECT_DOMAIN : `https://${REDIRECT_DOMAIN}`);
      return Response.redirect(redirectUrl.toString(), 302);
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
    } else if (CUSTOM_404_PAGE) {
      return new Response(CUSTOM_404_PAGE, {
        status: 404,
        headers: { "Content-Type": "text/html" },
      });
    } else {
      return new Response('404 Not Found', { status: 404 });
    }
  }
}
