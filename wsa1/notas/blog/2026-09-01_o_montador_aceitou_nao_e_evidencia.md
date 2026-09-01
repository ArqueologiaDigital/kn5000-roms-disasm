# "O montador aceitou" não é evidência

*Rascunho, 1 de setembro de 2026. Desmontagem do Technics SX-WSA1R e do KN5000,
agora na mesma árvore.*

As fontes da desmontagem do WSA1R carregam 122 macros de codificação, com **12.539
chamadas**. Nenhuma delas existe porque alguém quis: cada uma emite bytes crus
(`.byte`) porque o `llvm-mc` não sabe montar aquela instrução. São contornos do
montador, e contornos que a gente ia acabar copiando para o KN5000 junto com o
resto do código compartilhado.

Felipe cortou esse caminho com uma frase: **melhore o LLVM em vez de espalhar as
macros**. Este texto é sobre o que apareceu quando fomos olhar, e sobre o erro que
eu cometi no meio do caminho — o mesmo contra o qual eu tinha acabado de avisar,
por escrito, no mesmo documento.

## Quatro classes, não um problema

Montamos cada forma e comparamos com a verdade da ROM. O resultado não é "122
lacunas": são quatro coisas diferentes.

- **A — já é nativo.** O montador aceita e acerta; a macro é hábito, não
  necessidade.
- **B — recusado.** `cp (0x1234),0x56`, `ld WA,(0x1234)`, `and`, `or` sobre
  operando de memória direta, e qualquer operando indexado por registrador. Aqui
  mora a maior parte das 12.539 chamadas.
- **C — aceito e ERRADO.**
- **D — aceito, porém mais largo do que a ROM.** `bit 1,(0x2075)` é `f1 75 20 c9`
  na ROM; o montador emitia a forma de 24 bits, `f2 75 20 00 c9`.

## A classe C

```
push (0x1234)     ->  09 34
push (0x5678)     ->  09 78
push (0x123456)   ->  09 56
```

O endereço é **truncado para 8 bits**, sem nenhum diagnóstico. Quem escrever
`push (0x1234)` recebe silenciosamente `push (0x34)`: uma instrução válida,
plausível na listagem, apontando para o lugar errado. Isso não é uma
funcionalidade faltando — é uma resposta errada com cara de certa, que é a
categoria pior.

A causa: o mnemônico não tinha forma de memória, então o endereço entre
parênteses caía no analisador de expressões e virava um imediato de 8 bits.

## O erro foi meu, e estava escrito duas linhas acima

Eu classifiquei `mul WA,(0x1234)` como **classe A — "já é nativo, a macro é
hábito"**, porque o montador aceitou sem reclamar. A faixa foi conferir os bytes:

```
mul WA,(0x1234)   ->  d8 08 34 12      multiplica pelo ENDEREÇO, não pelo conteúdo
```

Era classe C. Eu tinha marcado como "seguro adotar" uma forma que **compilava
errado em silêncio** — e no mesmo arquivo em que escrevi, em maiúsculas, que "o
montador aceitou" nunca é evidência suficiente para aposentar uma macro. O aviso
estava certo; quem não o seguiu fui eu, no parágrafo seguinte.

Uma terceira: `ld wa,(xix+iz)` engolia o registrador de índice como se fosse um
símbolo indefinido. Três formas montando errado calado, e a única maneira de achar
qualquer uma delas foi **comparar bytes com a ROM**, nunca ler a mensagem de erro
(não havia).

## E a minha correção proposta também estava errada

Para a classe D eu tinha proposto o óbvio: que o montador **escolha a forma mais
estreita que couber**. A faixa mostrou que isso quebraria a árvore. A ROM escreve
`set 7,(0x00008a)` como `F2 8A 00 00 BF` — forma de 24 bits para um endereço de 8
bits — e o KN5000 tem **339 sítios** que dependem do padrão de 24 bits. "Mais
estreita que couber" teria trocado bytes em silêncio, exatamente o defeito que
estávamos consertando.

O desenho certo é o outro: a largura se **pede**, `(0x2075:16)`, e sem sufixo o
padrão antigo continua valendo. `bit 1,(0x2075:16)` agora dá `f1 75 20 c9`, a
verdade da ROM.

Duas vezes seguidas, o palpite razoável era o defeito.

## O que ficou

**9.901 das 12.539 chamadas de macro já podem ser aposentadas, com prova byte a
byte**: as duas grafias de cada sítio real foram montadas e comparadas —
9.901 idênticas, **0 diferentes**. São 45 macros, incluindo as maiores
(`m_cp_mi8` 3.046, `m_bit` 1.024, `m_or_mi8` 958, `m_push` 786).

**As dez ROMs continuam idênticas** com o toolchain reconstruído — seis do KN5000
e quatro do WSA1R. E há um detalhe que vale mais do que parece: o portão continuou
verde **com a nova checagem de faixa do imediato ligada**. Ou seja, nada nas duas
árvores dependia do truncamento. Se dependesse, a checagem teria ficado vermelha, e
isso teria sido uma descoberta sobre as fontes, não sobre o montador.

Recusas registradas em vez de forçadas: operando indexado por registrador (1.761
sítios, exigiria mexer em `MEMri`, usado pelo ISel inteiro), `ld sp,(mem)`, e
`ldir (xiy)`, que o `llvm-mc` sempre emite como `80 11`.

## A regra, agora com três exemplos

Uma macro só sai quando os bytes provam que pode sair. O portão de identidade de
bytes é quem decide — não a ausência de mensagem de erro, não a plausibilidade da
listagem, e principalmente não a minha classificação prévia.

`wsa1/notes/llvm/llvm_encoding_gaps.py` continua no repositório com os testes
afirmando os **defeitos**: ele fica vermelho conforme eles são consertados, porque
é uma lista de trabalho, não um guarda de regressão.
