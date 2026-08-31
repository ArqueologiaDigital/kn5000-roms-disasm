# A negativa que resolveu

*Rascunho, 30 de agosto de 2026. Desmontagem do Technics SX-WSA1R.*

Na rodada 9, uma faixa procurou uma instrução que carregasse a constante 0xA9 —
o código de classe do evento de botão de painel — e não achou nenhuma em 2 MB de
ROM. Ela registrou isso como um resultado, com a busca declarada:

> Não existe nenhum *post* com a forma `ld DE,0x00A9` em nenhuma das quatro
> imagens, então o evento provavelmente é montado copiando bytes de uma fila, e
> não a partir de imediatos.

E parou ali. Podia ter chutado um mapeamento — havia pressão para isso, porque
esse único fato bloqueava dar nome a 124 rotinas de uma vez. Não chutou.

Na rodada seguinte, aquela frase foi o que resolveu o problema.

## As duas numerações

O painel fala com a CPU por um fio: `[0xC0|segmento][máscara de bits]`. A rodada
9 resolveu essa camada inteira lendo a matriz de teclas do manual de serviço —
segmento é a coluna, bit é a linha, 58 teclas.

Mas as tabelas de 32 entradas que cada tela usa **não** são indexadas por esse
número. São indexadas por um código de 5 bits que aparece dentro de um evento de
classe 0xA9. E a rodada 9 mostrou por aritmética que os dois não podiam ser a
mesma coisa: 32 códigos não enumeram 58 teclas.

Duas numerações, e a árvore vinha confundindo as duas.

## Por que a busca por imediato tinha de falhar

A resposta é um conjunto de **tabelas na ROM**. O byte 0xA9 é um *dado* dentro
delas, copiado para o evento — nunca carregado como imediato por instrução
nenhuma. Uma busca por `ld DE,0x00A9` estava condenada a não achar nada, e o
"nada" que ela achou era a informação: *se ninguém carrega a constante, alguém a
copia*. Isso mandou a rodada 10 procurar o **consumidor da fila**, pelo que ele
lê, em vez de pela constante.

A cadeia, cada elo lido da ROM: `SC1_RxOp0_ThreeByte` enfileira
`[fio][valor][máscara de mudança]`; `sub_F8A088` drena, traduz fio → grupo e
enfileira de novo; `sub_F8A824` percorre e, por grupo, busca uma lista em
`PanelGroupEventLists_Variant1/2`. **Essas listas são a tabela.** O registro tem
quatro bytes, terminado em 0xFF: `[classe][código][deslocamento][máscara]`.

E o formato de 4 bytes não é suposto — é fixado por **geometria**: todos os 39
vãos do conjunto compartilhado são 1 mod 4, a última lista termina exatamente no
byte anterior à tabela de ações, e as quatro tabelas encostam umas nas outras.

## A objeção da rodada 9 se dissolve, e não por eu ter desistido dela

"32 códigos não enumeram 58 teclas" estava certo — e a saída não é que a conta
estivesse errada, é que **um código cobre um PAR de bits da matriz**. Noventa das
104 entradas de bit único caem na posição 0 ou 1 de um campo de dois bits. 32 × 2
= 64 ≥ 58.

E isso fecha, de quebra, uma correção que a própria rodada 9 tinha deixado em
aberto. Ela havia riscado a glosa "bit 7 = botão SOLTO" — mostrando que não podia
ser um sinalizador de soltura, porque dois lugares independentes usam esse bit
para escolher entre máscaras e entre o item *i* e o item *i+8* — e escreveu
honestamente que **o que o bit 7 significa não está estabelecido**, anotando que
a forma *i / i+8* lembrava as teclas do LCD mas que era só uma semelhança.

O bit 7 escolhe qual membro do par. A semelhança que ela se recusou a afirmar era
exatamente a pista.

## E a rodada 10 levou uma correção também

Uma afirmação que eu vinha repetindo desde a rodada 7 — "tabelas de 32 entradas"
— é falsa. Cada uma das cinco tem **23 ponteiros consecutivos**, e o 24º *long*
não é endereço de ROM em nenhuma delas. O teste que decide não é a contagem: é a
vizinha. Entre 0xFA176E e 0xFA17CF há 97 bytes; 32 entradas precisam de 128 e
invadiriam a tabela seguinte em 31 bytes, enquanto 23 precisam de 92 e param 5
bytes antes.

O 32 tinha sido transplantado de outros objetos, esses sim de 32 entradas, que a
rodada 7 documentou corretamente. **Um número verdadeiro sobre um objeto não é
verdadeiro sobre o vizinho por contiguidade.**

    python3 notes/wave7-verify-probes/wave7_r10_screen_table_entry_count.py --selftest

Onze verificações. E o limite real está em `sub_F55019`, que rejeita índice bruto
acima de 0x1F e então **remapeia** 0x11..0x19 para 0..8 — o que é, por si só, um
resultado sobre a camada 2: as tabelas por tela não são indexadas pelo código
bruto do evento.

## O fio

Um resultado negativo bem declarado não é o fim de uma investigação. Se ele diz
**o que foi procurado**, ele diz onde não adianta procurar de novo — e às vezes,
como aqui, a forma exata da ausência é a própria resposta.

Restam buracos, e eles ficaram escritos em vez de tapados: os grupos 0x03 e 0x04
emitem listas byte a byte idênticas, então o mesmo código chega por fios
diferentes e não se pode nomear a partir dele; ninguém produz o código 0x0E; e a
numeração de grupo discorda da de segmento para o dial. Nenhum dos dois mapas foi
editado para esconder isso.
