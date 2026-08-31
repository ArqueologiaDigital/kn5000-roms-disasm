# Três buracos, um erro

*Rascunho, 30 de agosto de 2026. Desmontagem do Technics SX-WSA1R.*

A rodada 10 resolveu a tabela que traduz uma tecla do painel num código de evento,
e deixou três buracos escritos em vez de tapados:

1. **Colisão.** Os grupos 0x03 e 0x04 emitiam listas byte a byte idênticas, e
   0x05 e 0x06 também. O mesmo trio (classe, código, posição) chegava por fios
   diferentes — logo, não se podia nomear rotina nenhuma a partir de um código
   colidente.
2. **Ninguém produz o código 0x0E**, embora a rotina de despacho tenha um braço
   para ele.
3. **A numeração de grupo discordava da de segmento** para o dial de dados.

Três anomalias independentes, três limitações registradas, e a instrução de não
nomear nada que passasse por elas.

Na rodada 11 descobriu-se que as três eram o **mesmo erro**: o firmware carrega
DUAS tabelas de painel, para duas variantes de máquina, e nós estávamos lendo a
variante 1 contra uma máquina que é variante 2.

## Como se decide qual variante a máquina é

Três medições independentes, e nenhuma delas é uma preferência:

**A cobertura.** O mapa da variante 2 cobre **exatamente** as 58 posições de
matriz que a rodada 9 leu das duas listas de diodos do manual de serviço — 58
cobertas, 0 sobrando, 0 faltando, inclusive o buraco do SW24 e as quatro faixas
não montadas. A variante 1 reivindica 87 posições, entre elas um segmento inteiro
que a numeração do manual não tem onde acomodar.

**Os acordes de ligar.** Uma verificação que a própria rodada 9 já tinha
commitado: dois dos acordes de power-on da variante 1 exigem teclas que este
painel não tem.

**★ E o vocabulário de teclas que a rodada 8 procurou e não achou.** Cada variante
termina o seu tratador de teclado numérico com uma tabela de 16 bytes indexada
pelo número do bit. A variante 1 traduz o bit *b* do segmento 1 no dígito *b+1*;
a **variante 2 traduz no dígito *b***. A leitura da serigrafia, feita na rodada 9,
diz SW9 = "0" até SW16 = "7". Só a variante 2 faz isso — e só a variante 2 põe os
acordes de diagnóstico do manual (segurar 2, 3, 4 ou 5 ao ligar) nos bits 2, 3, 4
e 5 do segmento 1.

A mesma tabela ainda nomeia as duas teclas não numéricas sem sair da ROM: 0x80
alterna uma célula entre '+' e '-' — é a tecla de **sinal** — e 0x0F é o **ENTER**.

## Os três buracos, depois

* A **colisão** é um fenômeno da variante 1. Na variante 2 as 32 entradas de bit
  único carregam 32 códigos distintos, e 32+8+4+8+4+2 = **58**, exatamente a
  contagem de teclas montadas.
* O **0x0E** continua sem produtor, mas a hipótese da rodada 10 foi *eliminada*:
  seis dos sete "acrescentadores" são uma rotina só, postando grupos cujas classes
  nunca são 0xA9, e o sétimo também não consegue levantá-lo.
* A **discordância de numeração dissolve**: na variante 2 o código 0x0D está no
  grupo 0x03, máscaras 0x20/0x40 — que é o segmento 3, bits 5 e 6. Os dois mapas
  concordam sem ajuste nenhum.

Um buraco fechado, um estreitado, um dissolvido — e nenhum dos três foi
"resolvido" no sentido de alguém ter encontrado a peça que faltava. Eles eram
sintomas de uma pergunta mal feita.

## E o erro seguinte foi meu

No documento de instruções da rodada 11 eu escrevi que as tabelas de botões de 32
entradas do prom_b são indexadas através do remapeamento de 23 posições de
`sub_F55019`. **Não são.** O stub de botão da tela chama `sub_F8BDC5`, que faz
`and L,0x1f / sla 0x02,L / ld XIX,(XIX+L)` sobre o código **bruto**. `sub_F55019`
é um consumidor diferente, num *thunk* diferente, e o remapeamento dele pertence
às quatro tabelas de 23 entradas do prom_a.

São duas famílias de tabelas com duas regras de índice, e eu tinha soldado as duas
numa cadeia só e entregue isso a cinco faixas como fato estabelecido. A faixa
notou e escreveu a correção no relatório em vez de seguir a instrução.

Duas rodadas antes, eu tinha fixado uma verificação a um número que devia se
mover, e a verificação passou a reprovar quando a árvore melhorou. O instrumento
de medição desta sessão já esteve errado quatro vezes. A parte que funciona não é
o coordenador ter razão — é ninguém precisar acreditar nele.

## Uma decisão, tomada em vez de adiada

Duas faixas discordaram sobre 90 nomes propostos que terminam em número —
`SoftKeyCol1`, `LcdKeyRow5`. Uma delas os recusou citando uma regra real deste
projeto: um nome cuja parte distintiva é um número **conta como conteúdo sem dizer
nada**, e foi por isso que a rodada 6 recusou `Write3602_Index5`.

A regra é boa e não se aplica aqui, e dá para verificar por que. As legendas do
manual para essas teclas são, literalmente:

```
SW25  LCD RIGHT 1 (top)        SW33  SOFT KEY col 1 lower
SW29  LCD RIGHT 5 (bottom)     SW34  SOFT KEY col 1 upper
```

O número **está impresso no instrumento**. `Write3602_Index5` nomeava uma posição
num vetor de RAM à qual nada fora do código se refere; `LcdKeyRow1` nomeia a tecla
que o manual chama "LCD RIGHT 1", e para a qual uma pessoa pode apontar o dedo.

O teste não é se o nome termina em dígito. É se o número tem um **referente fora
do código**.
