# Réveillon 2027 🎆

App da família para a virada na chácara (31/12 a 03/01): portaria com quiz de perfil, cardápio dos 4 dias, divisão de custos (comida + chácara), pagamentos, fotos e conquistas — tudo sincronizado ao vivo entre os celulares.

## Como funciona

- **Front-end:** um único `index.html` (HTML + CSS + JS puro), sem build.
- **Banco:** Supabase (projeto `ano_novo`).
  - `config` — reserva para imprevistos e valor total da chácara (uma linha só).
  - `refeicoes` — cardápio; só `valor` e `foto_url` podem ser editados pelo app.
  - `pessoas` — convidados, idade, tipo (adulto/criança/isento), perfil do quiz, pagamentos e foto. Nome único (ignora acento e maiúscula).
  - Bucket público `fotos` — fotos de pessoas e pratos (JPEG/PNG/WebP, até 5 MB).
  - Realtime ligado nas 3 tabelas: quando alguém paga, entra ou troca um valor, todo mundo vê na hora.
- **Sessão:** cada aparelho guarda no `localStorage` só o id da pessoa logada.

O app não tem login de verdade: qualquer pessoa com o link pode ver e editar. As regras do banco (RLS + permissões por coluna) limitam o que pode ser alterado.

## Hospedar

É um site estático: basta publicar a pasta (Vercel, Netlify, GitHub Pages…). Não precisa de variáveis de ambiente — a chave usada no `index.html` é a *publishable* (pública).

## Banco de dados

As migrations ficam em `supabase/migrations/`. Para aplicar em um projeto novo:

```bash
supabase login
supabase link --project-ref <ref-do-projeto>
supabase db push
```

Depois troque `SUPA_URL`, `SUPA_KEY` no `index.html` e o domínio nas constraints `*_foto_url_bucket`.

## Rodar localmente

```bash
python3 -m http.server 8000
# abra http://localhost:8000
```
