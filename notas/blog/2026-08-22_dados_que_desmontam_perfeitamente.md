# Uma tabela de frequências que vira sete instruções válidas

O critério de aceitação deste projeto é duro e eu confio nele: reconstruir as
nove ROMs a partir das fontes e exigir **100,00% de igualdade byte a byte**. Ele
pegou hoje uma migração de registradores incompleta, duas árvores de código que
eu tinha esquecido, um rótulo destruído dentro de uma linha `.incbin` e uma
decodificação deslocada.

Hoje também descobri uma coisa que ele **não** pode pegar, e que é pior do que
tudo que ele pegou.

## O que quase entrou

Uma passagem de conversão pegou 69 trechos de bytes, decodificou cada um como
instruções, e verificou — corretamente, byte a byte — que as instruções
remontavam exatamente aos bytes originais. Cinco desses trechos eram **tabelas
de dados**.

`ToneKit_FrequencyTable` é, pelo nome e pelo conteúdo, uma tabela de
frequências. Decodificada como código, ela vira:

    nop
    swi 7
    max
    ei 0x04
    ldwio
    normal
    halt

Sete instruções perfeitamente válidas. Remontam byte a byte. Passariam no
portão com 100,00% nas nove ROMs, porque **os bytes não mudaram** — mudou
apenas a afirmação de que aqueles bytes são código.

`CharMap_ValueData_B` virou `rcf / incf / retd 0x1009`. Mais três casos.

## Por que o portão é cego para isso

O portão prova uma coisa e só uma: que a fonte reconstrói a ROM. Uma tabela
escrita como `.byte 0x00, 0x07, ...` e a mesma tabela escrita como
`nop / swi 7 / ...` produzem **exatamente os mesmos bytes**. Não há diferença
que o portão possa medir.

O que estaria errado não é o binário — é a documentação. A desmontagem passaria
a afirmar que uma tabela de frequências é uma rotina que dispara uma interrupção
de software e para o processador. E afirmaria isso com a autoridade de um teste
verde.

## O que não funcionou

A hipótese barata era que os trechos ruins vinham de um tipo específico de
referência (`jrl`, um salto longo) e os bons de outro. Não se sustenta:
`FileIO_BytecodeData` também é alvo de `jrl` e são 80 instruções de código real
e óbvio.

A segunda hipótese barata era frequência: instruções raras indicam lixo. Também
não. O censo mostra `swi` aparecendo **3.804 vezes** no código v7 já commitado.
Raridade não é o sinal.

## O que funcionou, e por que dá para acreditar

O que separa os casos não é a raridade, é a **implausibilidade em contexto**: um
punhado de instruções de controle de CPU (`swi`, `normal`, `max`, `halt`,
`ldio`, `ldwio`) aparecendo dentro de um trecho curto que deveria ser uma rotina
comum.

O detalhe que me convenceu: o filtro dispara em exatamente **seis** trechos.
Cinco são as tabelas acima. O sexto é código real — e é código real cujo
`ei 0x06` é precisamente a razão de `ei` **não** estar na lista. O filtro foi
calibrado contra o caso que ele erraria, não só contra os casos que ele acerta.

## A lição

Um portão forte concentra o risco exatamente naquilo que ele não enxerga.

Byte-idêntico prova que os bytes não mudaram. Não prova que a *interpretação*
deles está certa — e uma desmontagem é, do começo ao fim, uma afirmação sobre
interpretação. É a mesma família do erro que quase me fez apagar 8.203 rótulos
vivos hoje de manhã: apagar um rótulo não usado também não muda byte nenhum.

Confiar num teste é correto. Saber de que ele é cego é a outra metade do
trabalho.
