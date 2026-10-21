# EquiLink — painel administrativo

Painel web do EquiLink: CRUD do acervo, baias, provas, analytics e inspeção da
fonte de dados. Compartilha o núcleo (`equilink_core`) e as primitivas visuais
(`equilink_ui`) com o aplicativo do usuário.

## Versão publicada

**https://equilink-admin.quarto-de-milha.workers.dev**

O acesso exige login. O Worker serve o build e encaminha `/api/*` para a API;
é esse proxy de mesma origem que faz o cookie de sessão `SameSite=Strict`
funcionar.

## Rodar localmente

```bash
flutter run -d chrome
```

Sem argumentos de build o painel usa a fonte em memória (acervo de
demonstração), sem login.

## Publicar

```bash
flutter build web --release --base-href=/ --no-web-resources-cdn \
  --dart-define=EQUILINK_FONTE=http \
  --dart-define=EQUILINK_API=/api
npx -y wrangler@latest deploy
```

`--no-web-resources-cdn` mantém o Canvaskit local, exigência do CSP.
