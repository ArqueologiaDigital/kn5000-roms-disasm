# A parte verificável da documentação

*Rascunho, 1 de setembro de 2026. Site de documentação dos teclados Technics.*

Documentação não roda. É por isso que ela apodrece em silêncio: nenhum teste fica vermelho quando
uma página passa a descrever uma árvore que não existe mais. Mas uma parte dela **é** verificável
mecanicamente — todo caminho `entre/crases.ext` que uma página cita ou resolve no repositório ou não
resolve. Isso dá para checar em trinta linhas de Python.

Rodei nas 133 páginas do site: **123 caminhos mortos entre 784 citados.**

## O apodrecimento tem tipos, e só um deles é "o arquivo mudou de lugar"

A página `source-map.md` — o mapa da árvore, uma das mais consultadas — tinha **33 caminhos mortos
entre 182**. O interessante é que os 33 não vieram de uma causa só. Vieram de quatro:

1. **Renomeação semântica.** Dezesseis arquivos de `ui_widgets/` deixaram nomes derivados de
   endereço (`e0e974_e15b20.s`) e ganharam nomes que dizem o que são
   (`performance_style_screens.s`).
2. **Mudança de lugar.** Doze blocos de parâmetro saíram de `includes/` para
   `style_ui/paramblock/`.
3. **Mudança de linguagem.** Esses mesmos doze, mais quatro de screendata e a tabela do gerador de
   tons, **deixaram de ser assembly e viraram C**. O caminho estava errado e a extensão também. A
   página descrevia a árvore como mais assembly do que ela é.
4. **Mudança de entendimento.** E este é o caso que interessa.

## O arquivo que não era de áudio

`audio/audio_cmd_encoder.s`, descrito na página como *"Audio command encoder — printf-like formatter
for SubCPU commands"*.

O arquivo hoje se chama `audio/sprintf_core.s`. As rotinas foram identificadas como `Sprintf_*`, não
`Audio_CommandEncoder`/`AudioCmd_*`: é um formatador de strings de uso geral. Não tem nada de áudio.
Continua morando em `audio/` por acidente histórico.

Repare no que a descrição antiga fazia. Ela **já dizia** "printf-like formatter" — a observação certa
estava lá, ao lado do nome errado, e o nome errado é que virou a identidade do arquivo. A página não
estava desinformada; estava meio informada, que é uma condição bem mais difícil de detectar do que a
ignorância.

## O que um teste verde aqui não significa

Escrevi isso no cabeçalho da ferramenta antes de qualquer outra coisa, porque é o limite que importa:

> Isto verifica EXISTÊNCIA, não correção.

Uma página pode citar um caminho que resolve perfeitamente e mentir sobre o que tem lá dentro. O caso
do sprintf é exatamente isso: durante meses o caminho resolvia. A ferramenta teria dito verde.

E a resolução é **generosa de propósito**: um caminho conta como vivo se o basename existir em
qualquer lugar do repositório. Ou seja, um arquivo que mudou de diretório continua "resolvendo". Isso
subestima o apodrecimento — que é a direção segura para uma ferramenta cuja saída são pistas, não
veredictos.

O `--selftest` afirma o defeito ausente: um caminho inexistente **tem** que ser reportado, e um
existente **não** pode ser. Um verificador que não consegue ficar vermelho não é evidência, por mais
verde que esteja — lição que este projeto já pagou três vezes esta semana.

## Por que trinta linhas encontraram 123 defeitos

Não porque a ferramenta seja esperta. Porque ninguém tinha olhado.

A documentação não tem portão. O código tem: aqui, o portão de byte-match reconstrói treze imagens e
compara com os dumps, e nada entra na árvore sem passar por ele. A documentação vinha sendo revisada
por leitura, que é caro, e por isso raramente.

A lição transferível não é "escreva mais testes". É: **em qualquer artefato não executável, ache o
subconjunto que é mecanicamente checável e cheque-o.** Não é a parte mais importante — o que a página
*afirma* importa mais do que os caminhos que ela *cita*. Mas é a parte que custa trinta linhas, e a
parte cara fica para os olhos humanos depois que essa já saiu da frente.

*Ferramenta: `kn5000-docs/tools/check_doc_paths.py` (commit 69bd860). Correções da `source-map.md`:
commit 6c638d4.*
