# O que o montador não sabia dizer

Passei o dia tentando responder a uma pergunta simples: a desmontagem do KN5000
está pronta? A resposta é não, mas o motivo mais interessante não é nenhum dos
que eu esperava.

## 158.902 bytes que ninguém tinha convertido

A desmontagem reconstrói três ROMs de 2 MB byte a byte. Escrevi uma ferramenta
que classifica **cada byte** do que é reconstruído em CODE, DATA ou PADDING, e
que só passa se o total bater exatamente com o tamanho da ROM — assim um erro de
tamanho de diretiva ou um escape octal mal decodificado não passa despercebido.

O primeiro número que ela mediu foi um desnível que ninguém tinha quantificado:

| | CODE | DATA |
|---|---|---|
| v7 | 542.379 (25,86%) | 1.488.021 |
| v9 | 1.003.061 (47,83%) | 1.019.367 |
| v10 | 1.003.078 (47,83%) | 1.019.364 |

v9 e v10 são quase idênticas entre si. A v7 tem ~460 KB a menos de código. Um
segundo programa comparou as duas mapa contra mapa e achou **258 trechos, 158.902
bytes**, que a v7 carrega como `.byte` e a v9 desmonta como instruções.

Peguei o maior deles e mandei desmontar. É código, sem sombra de dúvida: um laço
de extração de bits desenrolado, `ldcf 7,(XHL)` / `scc C,A` / `and A,0x01` /
`sla 0x07,A` / máscara / `or`, repetindo para o bit 6, o 5, o 4.

A leitura óbvia é que ninguém teve tempo de converter. Errado.

## O montador não conseguia escrever aquilo

A árvore precisa montar **byte a byte idêntico** com o `llvm-mc`. Então uma
sequência de bytes só pode virar instrução se o backend TLCS-900 do LLVM aceitar
aquela instrução. E ele recusava justamente as do laço:

    and (xix), 0x7f      error: invalid operand for instruction
    ldcf 7, (xhl)        error: invalid operand for instruction
    bit 7, (xix)         error  (nas duas ordens de operandos)
    or  (xix), a         ok — encoding [0x84,0xe9]

Escrevi isso num commit: *o backend não tem essas formas*. E estava errado de
novo.

Abri o `TLCS900InstrInfo.td` e as instruções **estavam todas lá**, codificando
certo desde sempre. O que não existia era o **nome**:

    andmi8 (xix), 0x7f   ->  [0x84,0x3c,0x7f]
    ldcfm  7, (xhl)      ->  [0xb3,0x9f]
    bitm   7, (xix)      ->  [0xb4,0xcf]

`84 3c 7f` são exatamente os bytes que estão na ROM em 0xFD30A2. O montador
sabia produzi-los o tempo todo — só não atendia por `and`. Alguém batizou as
formas com operando de memória de `andmi8`, `bitm`, `ldcfm`, `setm`, `resm`,
provavelmente para evitar ambiguidade no parser. No mesmo arquivo, `CP8mi` usa o
`"cp"` de verdade e convive bem com as formas de registrador, então dava para
ter feito igual.

O conserto não podia ser renomear e pronto: os nomes inventados são usados na
árvore inteira — `incm` em 80 arquivos, `bitm` em 53, `pushm` em 46. Renomeei o
mnemônico para o nome real **e** deixei o antigo como `InstAlias`. As duas
grafias produzem encoding idêntico, então nada na árvore se mexe.

## O padrão que apareceu seis vezes

Não é a primeira vez no dia. A lista, na ordem em que me pegaram:

1. Procurei a string `"LSW"` na ROM para saber se o firmware trata esse formato.
   Três ocorrências, todas becos sem saída, publiquei *"o KN5000 nunca lê .LSW"*.
   O código nunca diz `"LSW"` — diz **índice 0**. Ele trata, sim, e tem um
   handler dedicado em todas as revisões.
2. Varri bytes atrás de `mov imm,d0` para achar quem passa o tipo 0. `clr d0` é
   um único byte `0x00` — exatamente a codificação que eu precisava achar.
3. Procurei trechos do `.MSP` dentro do `.LSW` com janelas de tamanho fixo e
   achei dezenas de casamentos. Eram sequências de `0x00` casando com outras
   sequências de `0x00`.
4. Procurei quem chama uma função pelo endereço do prólogo. Zero. Os chamadores
   entram cinco bytes adiante — são 62.
5. Procurei strings de modo `"wb"`/`"rb"` exigindo `0x00` antes. Esta ROM separa
   com `0xFF`. Achei 11 de 57 e o relatório dizia **PASS**.
6. E agora: perguntei ao montador se ele conhecia a instrução, usando o nome que
   ela tem no manual.

Todas têm a mesma forma. **Uma busca que não consegue expressar aquilo que
procura devolve um zero limpo, e um zero limpo é indistinguível de uma resposta.**
É pior que um erro barulhento, porque parece resultado.

O antídoto que passei a aplicar é chato e funciona: antes de concluir ausência,
perguntar *o que este código escreveria se a coisa existisse?* — e verificar que
a busca conseguiria enxergar isso. Nos casos 2 e 6, a resposta era "uma grafia
que eu nem tinha considerado".

## Onde ficou

A desmontagem não está pronta, e agora dá para dizer o que falta com endereço:
158.902 bytes de código na v7 (desbloqueados por este conserto), 3.627 nomes
posicionais, a semântica dos campos do `.LSW` — que precisa de bancada, não de
mais análise — e o protocolo do painel, que precisa de analisador lógico.

O que mudou hoje não foi a resposta. Foi ela ter deixado de ser opinião.
