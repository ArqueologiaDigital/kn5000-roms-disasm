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
| `2026-08-29_contar_a_grandeza_errada.md` | Converti 18.432 bytes com o portão verde e a cobertura foi de 67,7% para 68,6% — e no mesmo commit as rotinas ainda sem nome foram de 4.997 para 5.079. Território sobe, significado desce, e é aritmética, não acidente: converter importa rotinas anônimas mais rápido do que nomear as aposenta. Mais o resultado negativo que foi a melhor parte do dia: das 19 propostas de transporte de nomes do KN5000, 15 já estavam aplicadas e as 4 restantes **não devem ser importadas** — cada uma nomeia um sub-objeto de uma estrutura que esta árvore modela inteira (duas são os bytes 4 e 5 de um registro de 6; duas caem nas linhas 8 e 11 de um pool de passo 0x66, com resto exatamente zero). Identidade de bytes diz que o código é o mesmo, não que o nome do irmão é melhor | **Não publicado.** Aguarda revisão |
| `2026-08-28_uma_grafia_nao_e_a_operacao.md` | A onda 6 concluiu que o firmware nunca aciona PA bit 3 e mandou o gap T para o hardware; ela tinha procurado `ld (PA),A`, e as duas escritas que faltavam são `res`/`set`, manipulações de bit que não contêm o opcode do armazenamento — o `res` seguido de 307 ms mostra que o pino é ativo em nível BAIXO, o contrário do que ficou registrado. **Contém o mesmo erro cometido por mim ao consertá-lo:** escrevi um censo com doze codificações e ainda perdi o `ldio PA,0xF9` do RESET (opcode 0x08, fora da família, e simbólico no fonte) — são cinco escritas, não quatro, e quem achou foi o verificador de outra faixa. Mais três casos do mesmo formato no mesmo dia: 31 citações um byte adiante da instrução (`ld XIZ,0x00fa607a` está em 0xFA6045, não 0xFA6046), uma tabela de "25 blocos de 32" que é um bloco 25 vezes, e 88 marcadores vazios que são 116. Em todos, a verificação que teria pegado o erro é a que ninguém escreveu. Placar honesto: zero bytes convertidos | **Não publicado.** Aguarda revisão |
