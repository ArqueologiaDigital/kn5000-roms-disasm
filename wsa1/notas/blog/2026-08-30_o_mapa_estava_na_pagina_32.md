# O mapa estava na página 32

*Rascunho, 30 de agosto de 2026. Desmontagem do Technics SX-WSA1R.*

Havia um fato que travava mais trabalho do que qualquer outro nesta árvore.

O firmware indexa tabelas de 32 entradas por um **número de botão de painel**.
Isso ficou provado: cada tabela é a palavra +8 de um objeto de tela (18 de 18),
o único leitor mascara com `and L,0x1f`, e a rotina para onde ele salta mascara
os **mesmos cinco bits**. Duas máscaras de 5 bits independentes sobre tabelas de
128 bytes.

O que ninguém tinha era o mapa: qual índice é qual botão físico. E a conta desse
buraco foi medida — ele sozinho impedia nomear **124 das 210 rotinas** de um
único trecho. A rotina que decodifica os botões nomeia exatamente três códigos:
0x0D (o dial de dados), 0x0E e 0x0F. A tela de serviço que naturalmente teria uma
lista de teclas desenha *"Please push a any button."* e mais nada.

## Nove rodadas procurando dentro da ROM

O manual de serviço do SX-WSA1R estava no repositório o tempo todo. Ninguém o
tinha aberto, e há um motivo técnico banal para isso: ele **não tem camada de
texto**. `pdftotext` devolve zero linhas. É um PDF de imagens escaneadas, então
toda busca por palavra-chave que qualquer agente tentasse sobre ele devolvia
nada — o mesmo padrão que este projeto já documentou duas vezes, um resultado
negativo que era um fato sobre a busca e não sobre o material.

Lidas como imagens, as páginas entregam tudo:

* **página 32** — o diagrama da placa CP1/CP2, com a matriz de teclas completa,
  SW1 a SW77, e a legenda de cada uma;
* **página 31** — a serigrafia da placa, que imprime a legenda ao lado de cada
  SWnn e posiciona as que não têm legenda;
* **página 5** — o arranjo do painel.

A regra que sai daí é simples: **segmento = a COLUNA da matriz, bit = a LINHA**,
e o número da tecla no manual é `SW = 8*segmento + bit + 1`. Cinquenta e oito
teclas montadas, todas mapeadas. As listas de diodos dizem quais posições não são
montadas (SW24, SW49-56, SW61-64, SW67-72, SW78+).

## A confirmação é a melhor coisa que este projeto já produziu

Um mapa lido de um desenho poderia estar alinhado errado por uma coluna inteira e
continuar parecendo plausível. Não é o caso, e a prova não veio do manual.

O manual, na página I-11, lista quatro modos de autodiagnóstico: segurar a tecla
**2** do teclado numérico ao ligar entra no teste da CPU do CP1; **3**, no teste
da ROM de ondas; **4**, no teste dos LEDs do painel; **5**, no teste do LCD.

Na ROM, `sub_F953CD` lê a sombra do segmento 1 e pede as telas 0xD9, 0xDA, 0xDB e
0xDC a partir dos bits **2, 3, 4 e 5**. Essas telas resolvem, através dos *thunks*
do prom_b, para `Paint_PanelCpuCheck`, `Paint_SineWaveCheckMode` e
`Paint_PanelSwLedCheck`.

**Esses três nomes foram derivados nesta árvore meses atrás, a partir do texto que
as próprias telas desenham, sem nenhum conhecimento desta pergunta.** Linha por
linha com o manual. Um segundo ponto de ancoragem, três segmentos adiante,
concorda de forma independente: o manual desenha o GENERATOR IC OUTSEL CHECK com
quatro caixas na borda direita do LCD, e `sub_F954AA` mascara o segmento 3 com
0x0F e despacha de quatro maneiras.

## E a metade que continua aberta

Existem **duas** numerações, e a árvore vinha confundindo as duas.

A camada do fio — `[0xC0|segmento][máscara de bits]`, vinda do CP1 — está
resolvida. A camada do evento não: o índice de 5 bits que as tabelas de 32
entradas realmente usam **não é** a mesma numeração, e a razão é aritmética.
Trinta e dois códigos não enumeram cinquenta e oito teclas.

Ficou registrado como aberto, com o caminho mais curto ainda não percorrido
apontado pelo nome. Não é uma decepção: é a diferença entre um mapa e um palpite
que se pareceria com um mapa, e um palpite errado se propagaria em 124 nomes de
rotina de uma vez — onde o portão de bytes não veria nada.

## Três negativas medidas, para ninguém gastar outra rodada nelas

* **A ROM não tem tabela de nomes de teclas.** "COMPARE" aparece zero vezes nas
  quatro imagens, e o texto da própria tela de teste de LEDs diz que quem responde
  é o microcontrolador do CP1 — por isso o firmware principal nunca precisa dos
  nomes.
* **O mapa do KN7000 não transfere**, e é estruturalmente diferente.
* **O KN5000 compartilha o número de peça do microcontrolador do painel**
  (M37471M2196S) e o chassi — e **nenhuma** atribuição transfere. Um par
  segmento/bit endereça uma posição de matriz numa placa específica. É a
  armadilha que este projeto mediu na rodada 2, na forma exata: 68 nomes de
  registrador em comum entre as duas árvores e **exatamente um** endereço.

## O fio

Nove rodadas procuraram a resposta dentro dos 2 MB de ROM. Ela estava num
desenho de placa, num arquivo que já estava no repositório, invisível para toda
ferramenta de busca porque era uma imagem.

O documento que responde à pergunta nem sempre é o que você está lendo.
