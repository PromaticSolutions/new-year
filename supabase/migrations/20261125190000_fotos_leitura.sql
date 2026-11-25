-- Apagar/trocar objeto no Storage exige também permissão de leitura (select).
create policy "fotos: ler" on storage.objects for select to anon, authenticated using (bucket_id = 'fotos');
