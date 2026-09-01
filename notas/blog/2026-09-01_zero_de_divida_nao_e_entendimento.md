# Dívida zero não é entendimento

*Rascunho, 1 de setembro de 2026. Desmontagem do Technics SX-WSA1R, ROM `prom_d`.*

A `prom_d` do SX-WSA1R está **100% coberta**: os 524.288 bytes todos saem de fonte de verdade,
nenhum `.incbin`, nenhum `sub_XXXXXX`. O portão de byte-match confirma. É o primeiro número redondo
desta empreitada e, sozinho, ele engana.

## Onde estão os bytes

O que a medição por classe de diretiva mostra:

```
  byte        258.838 B  (17.647 diretivas)
  fill        193.767 B  (      1 diretiva)   <- flash apagada, NÃO é conteúdo decodificado
  short        40.010 B  ( 5.669 diretivas)
  ascii        30.385 B  ( 2.274 diretivas)
  long          1.288 B  (   322 diretivas)
  TOTAL       524.288 B
```

**37% da imagem é flash apagada.** Uma única diretiva `.fill` cobre 193.767 bytes de `0xFF`. Somar
isso a um número de "cobertura" e anunciar 100% seria verdade aritmética e mentira prática — o
trabalho de decodificação corresponde a 330.521 bytes, não a 524.288. É por isso que a ferramenta
imprime cada classe na sua própria linha e diz, no cabeçalho, que elas nunca devem ser somadas numa
única cifra sem declarar quais entraram.

E não há uma única instrução na imagem: passando tudo por `llvm-mc`, **zero encodings**. A `prom_d` é
dados do começo ao fim, o que é consistente com o que já se sabia (ela não tem tabela de vetores e a
análise de alcance nem a percorre). "Desmontagem completa" aqui significa *tipagem* completa, não
código lido.

## A correção: a região apagada não é a cauda

Eu tinha registrado que os 193.767 bytes eram "a cauda de flash apagada no fim da imagem". Fui
verificar contra a ROM: **a imagem não termina em `0xFF` nenhum.**

Procurando toda corrida de `0xFF` de 1 KiB ou mais, existe exatamente uma, em
**`0x050B09`–`0x07FFF0`**, do tamanho exato da diretiva. Depois dela vêm **16 bytes de conteúdo**: os
últimos bytes da imagem são o ASCII `wsad_54.ssf` e enchimento com zeros — um registro solitário
sentado depois de 189 KB de flash apagada.

Não muda o total. Muda a descrição, e a descrição é o que a próxima pessoa vai ler.

## O instrumento estava errado, e meu diagnóstico também

A primeira versão da sonda dizia 484.280 de 524.288 bytes — faltavam 40.008. Eu olhei para essa
diferença e escrevi que ela significava que os três arquivos medidos **não eram a imagem inteira**, e
mandei procurar o que cobria o resto.

Estava errado. Era um bug de acumulador: o balde do `.short` era *sobrescrito* em vez de somado, e só
os 2 bytes da última linha sobreviviam. Consertado o balde, a conta fecha exatamente em 524.288 — os
três arquivos sempre foram a imagem inteira.

Duas coisas valem a pena aqui. A primeira é que uma diferença numa medição tem sempre pelo menos duas
explicações — o mundo está diferente do esperado, ou o instrumento está quebrado — e eu pulei direto
para a primeira, que era a mais interessante e a errada. A segunda é que quem achou o bug foi quem
recebeu o número, não quem o produziu: eu entreguei a sonda junto com a minha interpretação, e a
interpretação é que estava furada.

## A sonda que sobreviveu por acidente

Detalhe de processo que virou regra: essa sonda existia **apenas em scratch de sessão**, que é
volátil, e a lane que a escreveu ainda não tinha feito commit nenhum. Estava a um reboot de sumir —
com ela, o único jeito de reproduzir qualquer número deste texto.

O `--selftest` agora afirma o defeito ausente: a conta tem que fechar em 524.288 exatos e as classes
`.short` e `.fill` têm que ter os tamanhos medidos. Se o balde voltar a ser sobrescrito, ele fica
vermelho.

*Sonda: `wsa1/notes/sound/prom_d_debt_probe.py`. Correção da região apagada e do diagnóstico errado:
`wsa1/notes/sound/README.md`.*
