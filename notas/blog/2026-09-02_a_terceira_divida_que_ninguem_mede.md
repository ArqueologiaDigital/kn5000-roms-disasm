# A terceira dívida, que nenhum instrumento mede

*Rascunho, 2 de setembro de 2026. Todas as treze imagens.*

Esta árvore sempre contou dívida de desmontagem de dois jeitos, e passou meses achando que eram os
únicos:

* **verbatim** — bytes devolvidos por `.incbin` de um blob sem gerador;
* **código escrito como `.byte`** — instruções reais soletradas como dados.

O segundo é o maior: só a v7 tem 275.822 bytes dele, mais do que toda a dívida verbatim real das
treze imagens somadas. Descobrir isso já tinha sido desagradável.

Existe uma terceira, descoberta esta semana, e ela é pior porque **nenhuma ferramenta desta árvore
consegue vê-la**: dados desmontados como mnemônicos plausíveis.

## Por que é invisível por construção

Um contador de diretivas procura `.byte` e `.incbin`. Numa região dessas ele encontra `ld`, `call`,
`jr` — mnemônicos — e segue em frente. Não há nada para contar.

E o portão de byte-match não pode reclamar, porque **remontar uma interpretação errada reproduz
exatamente os mesmos bytes**. O portão prova que os bytes não mudaram; nunca provou que a leitura
está certa. É a mesma cegueira que já apareceu no sentido inverso, e agora aparece neste.

## Os dois casos confirmados

**309 bytes**, dentro de uma função *com nome*, na ROM do HD-AE5000. Estavam desmontados como umas 35
instruções lixo, encadeadas por cinco rótulos locais que não referenciavam nada fora do próprio
trecho. É a string de versão do firmware: *"Technics Software section    M. Kitajima"*, uma data e um
par de números de versão. Remontava byte a byte o tempo inteiro.

**6.356 bytes** — `HDAE5000_RECORD_TABLE`, no endereço `0x29C0AA`, escrito como cerca de 6.150 linhas
de mnemônicos TLCS-900. É dado, e dá para provar: suas únicas referências **carregam o endereço**,
nunca chamam nem saltam para lá — zero sítios de `call` ou `jp` em toda a árvore, conferido — e os
comentários do próprio projeto já descrevem a região como 13 registros de 24 bytes.

Vinte vezes o tamanho do primeiro caso, no mesmo arquivo, despercebido.

## Os sinais que servem de detector

Dos dois casos saem quatro sinais, e nenhum depende de a região decodificar bem:

1. **Nenhum fluxo de controle externo chega ali.** Rótulos internos que só referenciam uns aos outros
   são o indício mais forte.
2. **A região é referenciada como endereço**, carregada num registrador, usada como base de tabela.
3. **A decodificação não combina com o nome nem com a vizinhança** — cadeias de lixo, misturas
   implausíveis, um `halt` no meio.
4. **Os bytes crus leem como texto ou como tabela de passo fixo**, quando você para de olhar os
   mnemônicos.

Um exemplo mínimo do mesmo problema apareceu hoje noutro contexto, e cabe aqui porque é o caso mais
barato de entender: `.byte 0x30, 0x00, 0xff` decodifica como `ldw wa, 65280`. Instrução perfeitamente
plausível, três bytes de um registro de dados comum.

## O que isso faz com todos os números anteriores

Nenhuma das treze imagens foi medida nesta categoria. Portanto:

> **Toda cifra de dívida restante desta árvore é um LIMITE INFERIOR.**

Isso está agora escrito no inventário, ao lado de cada número. Duas frentes estão levantando o censo
— uma para a v10, outra para as quatro ROMs do WSA1R — e ambas têm instrução explícita de calcular o
**nulo** antes de acreditar em qualquer contagem: rodar os mesmos sinais sobre rotinas sabidamente de
código e reportar a taxa de falso positivo ao lado do achado. Uma pontuação sem controle não é
evidência nesta casa, e já custou caro aprender isso.

## A parte que me incomoda

As duas ocorrências confirmadas foram achadas **por acaso**, por frentes que procuravam outra coisa.
Ninguém foi atrás delas. E a categoria não é exótica: desmontar dados como código é o erro clássico
de qualquer desmontagem, e esta árvore tem ferramenta para quase tudo — menos para o erro mais óbvio
da própria disciplina.

A explicação mais provável é chata e conhecida: existia um portão verde, e o portão respondia uma
pergunta estreita com muita confiança. Quem tem um verificador forte para uma coisa tende a parar de
procurar as outras.

*Casos e sinais em `notes/DEBT-INVENTORY-2026-09-02.md`, seção "data-as-code".*
