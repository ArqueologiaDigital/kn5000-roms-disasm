# A dívida que não era dívida

*Rascunho, 2 de setembro de 2026. Segunda leva do mutirão de desmontagem, KN5000.*

O maior item da lista de pendências da árvore eram **318.468 bytes** — 62% de toda a dívida
"verbatim" das treze imagens. Seis arquivos na ROM de dados de tabela, entrando por `.incbin`, sem
gerador que os reconstruísse. O plano que eu tinha escrito, com todas as letras, era: *"o conserto
aqui é um gerador de ida e volta"*.

Estava errado. Não há nada para consertar.

## O que os seis arquivos são

`FTBMP01` a `FTBMP06`. São **BMPs do Windows**, de verdade: assinatura `BM`, cabeçalho DIB de 40
bytes, sem compressão, paleta de 256 cores no deslocamento declarado, e o campo de tamanho do
cabeçalho batendo exatamente com o tamanho do arquivo. Verifiquei os seis, um a um.

| arquivo | bytes | dimensões | conteúdo |
|---|---:|---|---|
| FTBMP01 | 77.878 | 320x240 | logotipo Technics + globo terrestre |
| FTBMP02 | 42.678 | 320x130 | subwoofers |
| FTBMP03 | 39.478 | 320x120 | disquetes |
| FTBMP04 | 39.478 | 320x120 | disquete entrando no drive |
| FTBMP05 | 41.078 | 320x125 | setas, som surround |
| FTBMP06 | 77.878 | 320x240 | nome KN5000 + cometa colorido |

Abrir o `FTBMP01` num visualizador qualquer, sem nenhuma ferramenta do projeto, mostra um mapa-múndi
sob a palavra "Technics". É uma imagem legítima, não dado mal enquadrado.

## Por que o gerador não faria sentido

O padrão de ida e volta com PNG existe nesta árvore e é bom — mas ele ganha o que custa quando
converte um **blob de pixels sem cabeçalho**, opaco para qualquer ferramenta genérica, em algo
visualizável, com um passo de `verify` provando que os bytes voltam idênticos.

Aqui não existe essa lacuna. O `.BMP` commitado já é completo, padrão e visualizável — e é
exatamente o arquivo que o `.incbin` lê. Não há forma crua para reconstruir. Um gerador PNG
adicionaria maquinaria (reproduzir campos arbitrários de cabeçalho e paleta) com **ganho zero de
legibilidade**, e jogaria fora o artefato genuíno como saiu da ferramenta da própria Technics.

O `docs/COMPLETENESS-STATUS.md` já dizia isso, aliás, numa seção que eu não tinha lido antes de
escrever o plano.

## O erro é de categoria, não de conta

O medidor não errou nenhum número. Os 318.468 bytes estão lá, e realmente entram por `.incbin` sem
gerador. O que ele faz é **classificar por MECANISMO** — "`.incbin` sem gerador" — e chamar isso de
dívida.

Só que dívida deveria significar *tem coisa aqui que a gente não entende*. E não tem: sabemos que são
seis BMPs, sabemos as dimensões, a profundidade de cor, a paleta, e dá para olhar as imagens. O
mecanismo é o mesmo de um blob opaco; o estado de conhecimento é o oposto.

Corrigido, o número honesto muda bastante:

* dívida verbatim contada: **544.138 B** (95,6% de fonte)
* dívida verbatim **real**: **225.670 B** (98,2% de fonte)
* e o maior bloco genuíno da árvore deixa de ser a ROM de tabelas e passa a ser a **v7**, com
  123.927 B de fatias transplantadas.

## De novo, e de novo

Este é o quarto instrumento desta empreitada cuja **categoria** foi confundida com um **fato** — e o
segundo em que quem confundiu fui eu. Antes, eu tinha citado a coluna "verbatim" como se fosse a
dívida total, sendo que ela é estruturalmente cega a código escrito como `.byte`.

O padrão é sempre o mesmo: a ferramenta responde uma pergunta estreita e bem definida, o resumo dela
vira um rótulo, e o rótulo é lido como se respondesse a pergunta larga. "`.incbin` sem gerador" virou
"não entendemos esses bytes". Ninguém mentiu; ninguém conferiu.

## E a sonda que passava sem comparar nada

No mesmo dia, resgatando uma ferramenta do scratch, rodei-a e li:

```
0 instructions decoded
whole-stream roundtrip: OK (reasm 0B vs raw 0B)
```

Ela comparava **zero bytes com zero bytes** e imprimia OK — justamente nas regiões que existe para
investigar, que são as que o desmontador não decodifica. Um verificador que não consegue ficar
vermelho não é evidência. Agora imprime `VACUOUS`, que é o achado verdadeiro: aquela região é
indecodificável por esta toolchain.

A recomendação que sobra é chata e serve para as duas histórias: **antes de acreditar num rótulo,
pergunte qual pergunta a ferramenta realmente respondeu.**

*Ferramentas: `scripts/analysis/verbatim_bmp_header_audit.py`, `notes/llvm_roundtrip_probe.py`.
Inventário corrigido em `notes/DEBT-INVENTORY-2026-09-02.md`.*
