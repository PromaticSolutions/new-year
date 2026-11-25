-- O app é aberto (sem login), então limitamos o que o papel anon pode escrever
-- às colunas que a interface realmente edita. Assim ninguém consegue, por
-- exemplo, trocar o "bg" de um prato por um CSS malicioso.

-- config: só os valores
revoke insert, update, delete on public.config from anon, authenticated;
grant update (reserva, chacara_total) on public.config to anon, authenticated;

-- refeicoes: só valor e foto
revoke insert, update, delete on public.refeicoes from anon, authenticated;
grant update (valor, foto_url) on public.refeicoes to anon, authenticated;

-- pessoas: tudo que a interface usa (nome_chave/updated_at vêm de trigger)
revoke insert, update on public.pessoas from anon, authenticated;
grant insert (id, nome, idade, tipo, perfil, pagou_comida, pagou_chacara, foto_url) on public.pessoas to anon, authenticated;
grant update (nome, idade, tipo, perfil, pagou_comida, pagou_chacara, foto_url) on public.pessoas to anon, authenticated;

-- fotos só podem apontar para o bucket público "fotos" deste projeto
alter table public.pessoas add constraint pessoas_foto_url_bucket
  check (foto_url is null or foto_url ~ '^https://emdwczkmizndqeivdusi\.supabase\.co/storage/v1/object/public/fotos/[A-Za-z0-9/_.-]+$');
alter table public.refeicoes add constraint refeicoes_foto_url_bucket
  check (foto_url is null or foto_url ~ '^https://emdwczkmizndqeivdusi\.supabase\.co/storage/v1/object/public/fotos/[A-Za-z0-9/_.-]+$');
