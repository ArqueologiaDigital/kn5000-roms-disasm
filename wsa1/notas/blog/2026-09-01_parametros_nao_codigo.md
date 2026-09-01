# Parâmetros, não código — e como decidir isso sem chutar

*Rascunho, 1 de setembro de 2026. Desmontagem do Technics SX-WSA1R.*

O SX-WSA1R é um sintetizador de **modelagem física**, e o dispositivo em `0x00104000` é o melhor
candidato a ser a seção de modelagem: é o único dispositivo de síntese por canal que a CPU 2
comanda e que **não tem contrapartida** no irmão PCM, o KN5000. (Isso é o que está estabelecido;
que ele seja *portanto* a modelagem é inferência declarada, não prova — nenhuma ROM do WSA1R nomeia
peça alguma.)

Antes de escrever um dispositivo para ele no MAME, uma pergunta precisa de resposta, e ela decide
que dispositivo escrever: **o firmware está carregando um PROGRAMA nesse chip, ou escrevendo
registradores?** Um carregador de microcódigo e um banco de registradores são objetos diferentes, e
chutar errado constrói o errado.

## O método é uma comparação controlada

A tentação é olhar o tráfego e opinar. O problema é que "parece parâmetro" e "parece código" são
impressões, e este projeto já apanhou o bastante de impressões.

Acontece que **este firmware contém um caminho de upload de código conhecido**: o microcódigo de
efeito do DSP sai da CPU 2 pela porta P7, um byte de cada vez. Então existe um grupo de controle
dentro da própria máquina, e cada discriminante pode ser pontuado nas duas colunas.

```
discriminante                    P7 (upload de código)      0x104000
-------------------------------------------------------------------------------
fluxo de bytes opaco             sim -- ld (0x0013),(XIZ+d)   não
handshake / strobe / timeout     sim -- P5, PB, poll 0x1F40   não
micro-DMA apontado para ele      (movido por canal)           NENHUM CANAL, NUNCA
endereços de destino             uma porta, repetidamente     conjunto fixo de registradores
numeração                        n/a                          bloco*0x40 + canal
valores vêm de                   um buffer de bytes           um *part record* empacotado
```

Oito números de bloco distintos — 0x00C0, 0x0100, 0x0140, 0x0180, 0x01C0, 0x0200, 0x0240, 0x0280 —
e **todos os intervalos são exatamente 0x40**. Treze rotinas `Pack104_SetInputs_*` empacotam um
registro de parte nesses registradores. Nenhum canal de micro-DMA jamais aponta para lá.

**Veredito: parâmetros.** Um banco de registradores, não um carregador de programas.

## O que essa resposta NÃO diz

Aqui está a parte que importa mais do que o veredito, e que foi escrita no cabeçalho da ferramenta
antes de qualquer outra coisa:

> Nenhum payload executável atravessa `0x00104000`.

Isso **não** é prova de que o chip não contenha elemento programável. Um motor de modelagem com
microcódigo fixo em ROM no próprio die, expondo apenas coeficientes, produziria exatamente este
tráfego. A afirmação é sobre o **barramento**, não sobre o silício, e as duas coisas são fáceis de
confundir quando o resultado é o que a gente esperava.

Escrever o limite junto com a conclusão custa uma frase. Não escrever custa a próxima pessoa
acreditar numa coisa mais forte do que foi medido.

## O teste que fica vermelho

O `--selftest` da ferramenta afirma os **defeitos ausentes**, não os números:

* nenhum canal de micro-DMA aponta para 0x104000 — *se isso falhar, apareceu um caminho em bloco e a
  pergunta se reabre*;
* os números de registrador são um conjunto fixo, não um contador crescente;
* os intervalos entre eles são múltiplos de 0x40;
* existe um empacotador alimentando-o a partir de um registro, e não um buffer de bytes.

Um contador crescente seria a assinatura de um stream. Um conjunto fixo espaçado por 0x40 é a
assinatura de `bloco*0x40 + canal`. A diferença entre as duas é a pergunta inteira, e é medível.

## E o grupo de controle é o achado

Vale separar o método do resultado. O resultado — parâmetros — era o palpite provável desde o
começo. O que o torna afirmável é que a mesma varredura, nos mesmos termos, foi aplicada a um
caminho que **sabidamente** carrega código, e ele pontuou diferente em todos os seis
discriminantes.

Sem esse controle, eu teria escrito "parece parâmetros" com a mesma confiança e sem nenhum direito
a ela.
