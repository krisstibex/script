export default {
  async fetch(request, env) {
    return handleRequest(request, env);
  }
}

async function handleRequest(request, env) {
  const TARGET_DOMAIN = env.TARGET_DOMAIN;
  const SPECIFIC_PATH = env.SPECIFIC_PATH.endsWith('/') ? env.SPECIFIC_PATH : env.SPECIFIC_PATH + '/'; // 确保 SPECIFIC_PATH 以 '/' 结尾
  const REDIRECT_DOMAIN = env.REDIRECT_DOMAIN;
  const CUSTOM_404_PAGE = env.CUSTOM_404_PAGE;
  const REMOTE_404_URL = env.REMOTE_404_URL;

  const url = new URL(request.url);

  // 处理鉴权路径等价性：/x 和 /x/ 等价
  const trimmedSpecificPath = SPECIFIC_PATH.slice(0, -1); // 去掉末尾的 '/'
  if (url.pathname === trimmedSpecificPath) {  // 如果请求路径是 /x（没有斜杠）
    return Response.redirect(url.origin + SPECIFIC_PATH, 302); // 重定向到 /x/
  }

  // 检查路径是否以特定路径开头
  if (url.pathname.startsWith(SPECIFIC_PATH)) {
    // 处理目标路径并确保有前导斜杠
    const proxiedPath = url.pathname.slice(SPECIFIC_PATH.length);
    const fixedPath = proxiedPath.startsWith('/') ? proxiedPath : `/${proxiedPath}`;

    // 自动识别协议头：检查 TARGET_DOMAIN 是否包含协议头
    const targetUrl = (TARGET_DOMAIN.startsWith('http://') || TARGET_DOMAIN.startsWith('https://'))
      ? `${TARGET_DOMAIN}${fixedPath}${url.search}`  // 如果包含协议头，直接使用
      : `https://${TARGET_DOMAIN}${fixedPath}${url.search}`;  // 如果不包含协议头，默认使用 https://

    const modifiedRequest = new Request(targetUrl, {
      method: request.method,
      headers: request.headers,
      body: request.body,
      redirect: 'follow'
    });
    const response = await fetch(modifiedRequest);

    // 获取所有响应头并将它们转发到客户端
    const responseHeaders = new Headers(response.headers);
    responseHeaders.delete('location'); // 删除原始Location头
    responseHeaders.set('Access-Control-Allow-Origin', '*'); // 添加CORS头，允许所有来源

    // 检查响应类型，如果是HTML，修复相对路径问题
    if (response.headers.get('content-type')?.includes('text/html')) {
      let modifiedHtml = await response.text();

      // 修改：将相对路径转换为绝对路径，以适应代理后的目标域名
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
    // 配置优先级处理
    if (REDIRECT_DOMAIN) {
      // 如果设置了重定向域名，则跳转到指定域名
      const redirectUrl = new URL(REDIRECT_DOMAIN.includes('http') ? REDIRECT_DOMAIN : `https://${REDIRECT_DOMAIN}`);
      return Response.redirect(redirectUrl.toString(), 302);
    } else if (REMOTE_404_URL) {
      // 如果设置了404页面的远程URL，则获取其内容并返回
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
      // 如果设置了404页面的内容，直接返回
      return new Response(CUSTOM_404_PAGE, {
        status: 404,
        headers: { "Content-Type": "text/html" },
      });
    } else {
      return new Response('404 Not Found', { status: 404 });
    }
  }
}
