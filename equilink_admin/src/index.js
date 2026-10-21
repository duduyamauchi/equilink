// Worker do painel: serve o build estático e encaminha `/api/*` para a API.
//
// Por que o proxy existe: o cookie de sessão é `HttpOnly` + `SameSite=Strict`.
// Chamar `equilink-api.quarto-de-milha.workers.dev` direto de `equilink-admin.quarto-de-milha.workers.dev` é
// requisição cross-site, e o navegador **não envia** um cookie `Strict` nesse
// caso — o login parecia funcionar e o acervo vinha sem os dados privados.
// Servindo a API sob o mesmo host do painel, o cookie volta a ser first-party.
//
// Ganho colateral: some o CORS e o cookie não fica exposto a bloqueio de
// cookie de terceiros (Safari e Chrome já bloqueiam em vários contextos).

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/api' || url.pathname.startsWith('/api/')) {
      const destino = new URL(request.url);
      destino.pathname = url.pathname.slice('/api'.length) || '/';

      // Preserva método, corpo e cabeçalhos; o `Host` é reescrito pelo binding.
      const encaminhada = new Request(destino.toString(), {
        method: request.method,
        headers: request.headers,
        body: ['GET', 'HEAD'].includes(request.method) ? undefined : request.body,
        redirect: 'manual',
      });

      const resposta = await env.API.fetch(encaminhada);

      // O `Set-Cookie` do login precisa chegar ao navegador como se fosse
      // deste host. Copia cabeçalho a cabeçalho, sem `Access-Control-*`
      // (mesma origem não precisa) e sem `cache-control` do proxy.
      const cabecalhos = new Headers();
      for (const [chave, valor] of resposta.headers) {
        const k = chave.toLowerCase();
        if (k.startsWith('access-control-')) continue;
        cabecalhos.append(chave, valor);
      }
      return new Response(resposta.body, {
        status: resposta.status,
        headers: cabecalhos,
      });
    }

    return env.ASSETS.fetch(request);
  },
};
