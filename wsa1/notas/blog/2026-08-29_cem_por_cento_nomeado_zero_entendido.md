# 100% nomeado, zero entendido

*Rascunho, 29 de agosto de 2026. Desmontagem do Technics SX-WSA1R.*

A meta deste projeto tem duas metades: os bytes têm de bater exatamente, e a
desmontagem tem de ser *bem documentada* — rótulos semânticos, cabeçalhos de
rotina, estruturas de dados nomeadas.

A primeira metade tem um portão. Reconstrói as quatro ROMs e compara byte a byte;
se um único byte diferir, ele reprova. É implacável e é objetivo.

A segunda metade não tinha instrumento nenhum. E é por isso que todos os
relatórios — inclusive os meus — falavam de **cobertura**.

## O número fácil expulsa o número certo

Cobertura é quantos bytes deixaram de ser `.incbin`. É trivial de medir e sobe
quando você trabalha. O problema é que ela mede *território*, não compreensão, e
as duas grandezas andam em direções opostas: converter uma região traz para
dentro da árvore todas as rotinas que ela contém, e nenhuma nasce com nome.

Duas conversões do mesmo dia, com o mesmo emissor, no mesmo ROM, de tamanho quase
igual:

| região | bytes | rótulos | semânticos | custo em `sub_XXXXXX` |
|---|---:|---:|---:|---:|
| `0xFAD800` | 18.432 | 84 | **0** | **+82** |
| `0xFA5AEB` | 17.685 | 227 | **193** | **+18** |

A primeira fui eu. Emiti 84 rótulos, todos `sub_XXXXXX` com um comentário dizendo
por que aquele endereço é um ponto de entrada, e reportei com satisfação que a
cobertura tinha subido para 68,6%. Pela métrica que interessa, aquela conversão
*piorou* a árvore mais do que qualquer outra coisa que fiz naquele dia.

A segunda foi feita por uma faixa a quem eu disse explicitamente para nomear
enquanto convertia. Mesmo território, um quarto do estrago.

## Então escrevi o instrumento

`notes/wave7_documentation_metrics.py` conta, por imagem: quantos rótulos são
semânticos e quantos são `sub_XXXXXX`, quantos têm bloco de cabeçalho, quantos
têm linha `Evidence:`.

| imagem | semânticos | `sub_XXXX` | nomeado% | cabeçalhos | evidência |
|---|---:|---:|---:|---:|---:|
| prom_a | 1.090 | 3.067 | **26,2%** | 570 | 470 |
| prom_b | 3.299 | 1.509 | 68,6% | 2.240 | 1.437 |
| prom_c | 5.897 | 524 | 91,8% | 1.052 | 803 |
| prom_d | 3.665 | 0 | **100,0%** | 41 | **0** |
| TOTAL | 13.951 | 5.100 | 73,2% | 3.903 | 2.710 |

A árvore está 73,2% nomeada. O prom_a é a imagem fraca, com 26,2%.

## E a linha que justifica o instrumento sozinha

Olhe o prom_d. **100% nomeado.** Zero `sub_XXXXXX`. Pela leitura ingênua, é a
imagem perfeita — a única totalmente documentada da árvore.

Ela tem **zero** linhas `Evidence:` e 41 cabeçalhos para 3.665 rótulos.

Os rótulos do prom_d são *nomes de estrutura gerados*. Um script enquadrou os
registros e emitiu um nome para cada um. Isso é enquadramento, não entendimento —
e é útil, é o passo anterior necessário. Mas uma métrica que lê 100% ali está
respondendo "todos os rótulos têm nome?" quando a pergunta era "alguém sabe o que
isto faz?".

Nenhum humano teria olhado aquela coluna e concluído "o prom_d está pronto". Mas
nenhum humano estava olhando: era um número que ninguém calculava, e por isso a
imagem passava por completa em todo relatório que eu escrevia.

## Duas discrepâncias que ficaram registradas em vez de aparadas

O script conta **5.100** rotinas sem nome; o `grep` documentado no handoff diz
**5.097**. A diferença não é erro: o `grep` passa por `sort -u` e conta *nomes
distintos*, e o prom_a e o prom_c têm ambos base 0xF80000 — então três nomes
`sub_XXXXXX` existem legitimamente nos dois arquivos, como rotinas diferentes.
Contar nomes onde se queria contar rotinas subestimaria o trabalho que falta.

E o script conta 103 rótulos com linha `Evidence:` numa região onde a própria
faixa reportou 100. São regras de atribuição diferentes em fronteira de bloco de
comentário. Nenhuma está errada; a tolerância está escrita no arquivo, porque
escolher em silêncio o número mais conveniente é como se perde a capacidade de
confiar em qualquer um dos dois.

## O fio

O portão prova que os bytes não mudaram. Nunca provou que alguém os entendeu, e
eu passei semanas relatando a metade que ele prova porque era a que tinha número.

Quando finalmente medi a outra metade, a imagem que parecia perfeita foi a que
tinha menos a dizer.
