-- Réveillon 2027 — esquema inicial
-- O app não tem login: qualquer pessoa com o link lê e edita (papel anon).

create extension if not exists unaccent with schema extensions;

-- ---------------------------------------------------------------
-- config: uma linha só, com valores gerais da viagem
-- ---------------------------------------------------------------
create table public.config (
  id            smallint primary key default 1 check (id = 1),
  reserva       numeric(10,2) not null default 150 check (reserva >= 0),
  chacara_total numeric(10,2) check (chacara_total is null or chacara_total > 0),
  updated_at    timestamptz not null default now()
);

insert into public.config (id, reserva, chacara_total) values (1, 150, null);

-- ---------------------------------------------------------------
-- refeicoes: cardápio da viagem
-- ---------------------------------------------------------------
create table public.refeicoes (
  id         text primary key,
  ordem      smallint not null,
  dia        text not null,
  semana     text not null,
  refeicao   text not null,
  nome       text not null,
  emoji      text not null default '🍽️',
  bg         text not null,
  itens      text[] not null default '{}',
  descricao  text not null default '',
  valor      numeric(10,2) check (valor is null or valor >= 0),
  foto_url   text,
  updated_at timestamptz not null default now()
);

insert into public.refeicoes (id, ordem, dia, semana, refeicao, nome, emoji, bg, itens, descricao, valor) values
  ('m1', 1, '31/12', 'Qui', 'Jantar', 'Ceia de Ano Novo', '🥂', 'linear-gradient(135deg,#3b2a6b,#b8860b)',
    array['A definir com a família', 'Brinde da meia-noite 🥂'],
    'A grande noite da virada! Cardápio em aberto — cada um capricha no seu prato.', null),
  ('m2', 2, '01/01', 'Sex', 'Almoço', 'Sobras do Ano Novo', '♻️', 'linear-gradient(135deg,#1e3a5f,#2f855a)',
    array['Tudo o que sobrou da ceia', 'Arroz fresquinho', 'Salada'],
    'Recarga pós-virada: tudo o que sobrou da ceia, requentado com carinho. Custo zero!', 0),
  ('m3', 3, '01/01', 'Sex', 'Jantar', 'Hambúrguer artesanal', '🍔', 'linear-gradient(135deg,#7c2d12,#f59e0b)',
    array['Pão de hambúrguer', 'Blend de carne bovina', 'Queijo', 'Alface', 'Tomate', 'Molho especial', 'Batata rústica'],
    'Blend na chapa com queijo derretido, alface, tomate, molho especial da casa e batata rústica.', 120),
  ('m4', 4, '02/01', 'Sáb', 'Almoço', 'Estrogonofe de frango', '🍛', 'linear-gradient(135deg,#78350f,#d97706)',
    array['Estrogonofe de frango', 'Arroz branco', 'Batata palha', 'Salada'],
    'Cremoso, com arroz branco soltinho, batata palha crocante e salada fresca.', 100),
  ('m5', 5, '02/01', 'Sáb', 'Jantar', 'Churrasco', '🔥', 'linear-gradient(135deg,#7f1d1d,#ea580c)',
    array['Linguiça', 'Frango', 'Carne bovina', 'Pão de alho', 'Vinagrete', 'Farofa'],
    'Linguiça, frango e carne bovina na brasa, com pão de alho, vinagrete e farofa. O evento principal!', 300),
  ('m6', 6, '03/01', 'Dom', 'Almoço', 'Macarronada de forno', '🍝', 'linear-gradient(135deg,#9a3412,#facc15)',
    array['Macarrão', 'Presunto', 'Queijo', 'Molho de tomate', 'Requeijão'],
    'Massa gratinada com presunto, queijo, molho de tomate e requeijão.', 130),
  ('m7', 7, '03/01', 'Dom', 'Jantar', 'Torta de frango', '🥧', 'linear-gradient(135deg,#854d0e,#fbbf24)',
    array['Massa caseira', 'Recheio de frango', 'Salada'],
    'Torta caseira de frango para fechar a viagem com chave de ouro.', 100);

-- ---------------------------------------------------------------
-- pessoas: convidados, perfil do quiz e pagamentos
-- ---------------------------------------------------------------
create table public.pessoas (
  id            uuid primary key default gen_random_uuid(),
  nome          text not null check (char_length(btrim(nome)) between 2 and 40),
  nome_chave    text not null unique,  -- nome sem acento/maiúscula, preenchido por trigger
  idade         smallint check (idade between 0 and 120),
  tipo          text not null default 'adulto' check (tipo in ('adulto', 'crianca', 'isento')),
  perfil        text check (perfil in ('super', 'fome', 'sono', 'festa')),
  pagou_comida  boolean not null default false,
  pagou_chacara boolean not null default false,
  foto_url      text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------
-- triggers: nome_chave e updated_at
-- ---------------------------------------------------------------
create or replace function public.pessoas_nome_chave()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.nome := regexp_replace(btrim(new.nome), '\s+', ' ', 'g');
  new.nome_chave := lower(extensions.unaccent(new.nome));
  return new;
end $$;

create trigger pessoas_nome_chave
  before insert or update of nome on public.pessoas
  for each row execute function public.pessoas_nome_chave();

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger config_touch    before update on public.config    for each row execute function public.touch_updated_at();
create trigger refeicoes_touch before update on public.refeicoes for each row execute function public.touch_updated_at();
create trigger pessoas_touch   before update on public.pessoas   for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------
-- RLS: acesso aberto (sem login), mas config/refeicoes só editáveis
-- ---------------------------------------------------------------
alter table public.config    enable row level security;
alter table public.refeicoes enable row level security;
alter table public.pessoas   enable row level security;

create policy "config: ler"      on public.config    for select to anon, authenticated using (true);
create policy "config: editar"   on public.config    for update to anon, authenticated using (true) with check (true);

create policy "refeicoes: ler"    on public.refeicoes for select to anon, authenticated using (true);
create policy "refeicoes: editar" on public.refeicoes for update to anon, authenticated using (true) with check (true);

create policy "pessoas: ler"      on public.pessoas   for select to anon, authenticated using (true);
create policy "pessoas: criar"    on public.pessoas   for insert to anon, authenticated with check (true);
create policy "pessoas: editar"   on public.pessoas   for update to anon, authenticated using (true) with check (true);
create policy "pessoas: apagar"   on public.pessoas   for delete to anon, authenticated using (true);

-- ---------------------------------------------------------------
-- Realtime: todo mundo vê as mudanças na hora
-- ---------------------------------------------------------------
alter publication supabase_realtime add table public.config, public.refeicoes, public.pessoas;

-- ---------------------------------------------------------------
-- Storage: fotos de pessoas e pratos (público, só imagens, até 5 MB)
-- ---------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']);

create policy "fotos: enviar"  on storage.objects for insert to anon, authenticated with check (bucket_id = 'fotos');
create policy "fotos: trocar"  on storage.objects for update to anon, authenticated using (bucket_id = 'fotos') with check (bucket_id = 'fotos');
create policy "fotos: apagar"  on storage.objects for delete to anon, authenticated using (bucket_id = 'fotos');
