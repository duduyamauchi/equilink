// Worker do aplicativo: serve o build estático e encaminha `/api/*` para a API.
//
// Mesmo motivo do painel: o cookie de sessão é `SameSite=Strict`, e chamar
// outro host (`equilink-api...workers.dev`) é cross-site — o navegador descarta o
// cookie. Servindo a API sob o mesmo host, a sessão do proprietário vale também
// no app, que passa a mostrar o manejo das baias de quem entrou.
//
// Para o visitante anônimo nada muda: ele recebe a vitrine pública.

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api' || url.pathname.startsWith('/api/')) {
      const destino = new URL(request.url);
      destino.pathname = url.pathname.slice('/api'.length) || '/';

      const encaminhada = new Request(destino.toString(), {
        method: request.method,
        headers: request.headers,
        body: ['GET', 'HEAD'].includes(request.method) ? undefined : request.body,
        redirect: 'manual',
      });

      const resposta = await env.API.fetch(encaminhada);

      // O `Set-Cookie` do login precisa chegar ao navegador como se fosse deste
      // host; cabeçalhos de CORS não fazem sentido em mesma origem.
      const cabecalhos = new Headers();
      for (const [chave, valor] of resposta.headers) {
        if (chave.toLowerCase().startsWith('access-control-')) continue;
        cabecalhos.append(chave, valor);
      }
      return new Response(resposta.body, { status: resposta.status, headers: cabecalhos });
    }

    return env.ASSETS.fetch(request);
  },
};
