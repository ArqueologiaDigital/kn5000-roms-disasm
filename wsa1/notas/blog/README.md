# Rascunhos de divulgação

Textos escritos para leitores de fora do projeto — não são transcrição nem
documentação interna. Ficam aqui em rascunho até o dono decidir se e onde
publicar.

Mesma convenção do irmão `../../../kn5000-roms-disasm/notas/blog/`: os números
citados nos textos têm sempre um script commitado que os reproduz, e o texto cita
o caminho. Se um rascunho afirma algo que depois se mostrou falso, a correção
entra no próprio rascunho, não numa errata separada.

| Rascunho | Assunto | Estado |
|---|---|---|
| `2026-08-28_uma_grafia_nao_e_a_operacao.md` | A onda 6 concluiu que o firmware nunca aciona PA bit 3 e mandou o gap T para o hardware; ela tinha procurado `ld (PA),A`, e as duas escritas que faltavam são `res`/`set`, manipulações de bit que não contêm o opcode do armazenamento — o `res` seguido de 307 ms mostra que o pino é ativo em nível BAIXO, o contrário do que ficou registrado. **Contém o mesmo erro cometido por mim ao consertá-lo:** escrevi um censo com doze codificações e ainda perdi o `ldio PA,0xF9` do RESET (opcode 0x08, fora da família, e simbólico no fonte) — são cinco escritas, não quatro, e quem achou foi o verificador de outra faixa. Mais três casos do mesmo formato no mesmo dia: 31 citações um byte adiante da instrução (`ld XIZ,0x00fa607a` está em 0xFA6045, não 0xFA6046), uma tabela de "25 blocos de 32" que é um bloco 25 vezes, e 88 marcadores vazios que são 116. Em todos, a verificação que teria pegado o erro é a que ninguém escreveu. Placar honesto: zero bytes convertidos | **Não publicado.** Aguarda revisão |
