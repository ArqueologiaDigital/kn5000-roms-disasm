# "100,00%" não era cem por cento

O critério deste projeto é reconstruir as nove ROMs a partir das fontes e exigir
igualdade byte a byte. Eu confiei nele o dia inteiro. Escrevi, várias vezes, que
ele é a verificação mais dura que existe aqui e que o risco se concentra
exatamente naquilo que ele **não** consegue enxergar.

Acontece que eu estava lendo esse portão errado.

## O erro

O script de comparação imprime:

    Similarity: 100.00%

arredondado para duas casas. Numa ROM de 2.097.152 bytes, isso é **até 104 bytes
diferentes**. E ele é honesto: quando há bytes errados, imprime

    Similarity: 100.00%  (22 incorrect bytes)

O meu teste de aceitação era:

    grep -c "Similarity: 100.00%"

Que casa com as duas linhas. `"Similarity: 100.00%"` é **prefixo** da linha que
avisa dos 22 bytes errados.

Catorze arquivos de log da sessão contêm exatamente esse padrão. A corrupção
estava sendo detectada e impressa o tempo todo. Eu passava por cima dela com um
`grep`.

## O que isso custou

981 "reparos" de rótulos entraram em commits com um portão que dizia 9/9 e que na
verdade era 22 bytes errados na v7.

Pior: o erro gerou uma teoria falsa que eu repeti com confiança a tarde inteira.
Como o portão "passava" depois de mover um rótulo, concluí que mover um rótulo não
muda bytes — e daí que o portão era estruturalmente cego para essa classe de
edição, e daí toda uma argumentação sobre precisar de dois verificadores
independentes.

Mover um rótulo **muda** bytes. As tabelas de ponteiros que eu mesmo converti de
`.incbin` para `.long <símbolo>` naquela manhã passam a apontar para o endereço
novo. O portão estava pegando tudo, certinho, desde o começo.

## E a descoberta que veio junto

Quando finalmente comparei os bytes de verdade, os 22 errados eram 11 palavras de
32 bits, e todas com a mesma assinatura:

    ROM 0xfcd2d5  ->  construído 0xfccebb     delta 0x41a
    ROM 0xfcd578  ->  construído 0xfcd15e     delta 0x41a
    ...

As tabelas de ponteiros da própria ROM apontam para a posição **original** dos
rótulos. Ou seja: os rótulos estavam certos, e quem estava errado era o meu
detector.

Esse detector comparava os bytes da v7 com os da rotina de mesmo nome na **v9** —
uma heurística entre dois programas diferentes. Dos rótulos que uma tabela de
ponteiros consegue conferir, **11 de 11** contradizem o detector.

Um nome compartilhado entre revisões é uma hipótese. Um ponteiro que o firmware
dereferencia é evidência. Reverti os 981 reparos.

## As duas regras que ficam

**Um "passou" arredondado não é um "passou".** Verifique identidade, não uma
porcentagem formatada. Porcentagem é para humano ler relatório; teste de
aceitação compara bytes e sai com código de erro.

**A ROM vale mais que uma heurística entre revisões.** Antes de agir sobre uma
afirmação de posicionamento, confira contra os ponteiros que o próprio firmware
usa.

E uma terceira, mais desconfortável: eu passei o dia catalogando verificações que
não conseguem falhar — controles tirados de distribuições incapazes de exibir o
defeito, auditorias que justificam blobs por nome de pasta, arquivos de símbolos
que batem com a própria origem mas descrevem a revisão errada. Escrevi dezessete
anti-padrões sobre isso.

O que me pegou não foi nada sutil. Foi um `grep` casando mais do que eu queria,
numa condição de shell de uma linha que eu copiei de rodada em rodada sem nunca
reler.
