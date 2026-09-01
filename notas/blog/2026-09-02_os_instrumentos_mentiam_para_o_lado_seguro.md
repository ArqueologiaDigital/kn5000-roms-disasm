# Os instrumentos mentiam — e todos para o lado confortável

*Rascunho, 2 de setembro de 2026. Mutirão de desmontagem: onze frentes em paralelo, KN5000 e SX-WSA1R.*

A ideia era simples: paralelizar a conversão do que falta desmontar. O resultado principal não foi
território convertido. Foi que **quatro instrumentos diferentes estavam errados, e os quatro erravam
na direção que deixa a gente satisfeito.**

## O que cada um dizia

**1. O medidor de cobertura contava graficos duas vezes.** Ele reportava, para a ROM do HD-AE5000:
`ROM 524.288 · incbin 626.152 · fonte -101.864 (-19,4%)`. Um total de `.incbin` **maior que a ROM** e
uma fonte **negativa** — impossível, e visível havia tempos.

A causa: a expressão regular casava `.incbin` dentro de comentários mortos do tipo
`; Was: .incbin "...", ...`, deixados como registro histórico acima de cada diretiva viva. Os mesmos
313.076 bytes de gráficos entravam duas vezes: 313.076 × 2 = 626.152, exato. Duas frentes chegaram a
esse diagnóstico de forma independente, com o mesmo número.

**2. A caminhada de alcance nunca parava num salto curto.** O padrão de fim de fluxo era
`jp<espaço>` e `jr<espaço>0x`. Só que o `unidasm` escreve **toda** instrução de salto do TLCS-900 com
condição explícita: até o incondicional sai como `jr T,0xaddr`. Então `jr<espaço>0x` **nunca casava**
— e a caminhada seguia adiante depois de qualquer salto curto, decodificando o que viesse como se
fosse mais código. E `jp<espaço>` casava demais: encerrava a caminhada em saltos **condicionais**,
escondendo o caminho de queda.

Corrigido, a dívida conhecida **sobe**: 1.702 → 2.071 bytes alcançáveis e não convertidos.

**3. Duas ferramentas eram cegas para 1.038 instruções.** Elas reconheciam só o formato de comentário
de imagem única; as 941 instruções do kernel compartilhado e as 97 do driver de DSP compartilhado
usam o formato de endereço duplo. Ficavam invisíveis. Pior: a cegueira era **deliberadamente
espelhada** entre as duas, para que pudessem ser comparadas linha a linha — então a comparação
concordava perfeitamente, sobre um corpus incompleto.

**4. E os 100% não eram 100%.** Pedi explicitamente que uma frente tentasse **refutar** a afirmação de
cobertura total das duas ROMs do sub-CPU. Ela refutou: **1.230 bytes de código TLCS-900 real**
estavam escritos como `.byte`, e agora estão convertidos com prova de ida e volta — desmonta,
remonta aquele texto exato, exige os mesmos bytes.

## O padrão

Nenhum desses erros deixava o portão de byte-match vermelho. Não podiam: o portão prova que os bytes
não mudaram, nunca que a interpretação está certa.

E todos erravam para o mesmo lado — **subestimando a dívida**. Um instrumento que superestima incomoda
até alguém consertar. Um que subestima é confortável, e por isso sobrevive.

O caso mais bonito é do HD-AE5000: 309 bytes desmontados como umas 35 instruções lixo, encadeadas por
cinco rótulos locais que não referenciam nada fora do próprio trecho. Uma ilusão de código
autocontida, invisível ao portão. É a string de versão do firmware — *"Technics Software section
M. Kitajima"*. Remonta byte a byte de qualquer jeito, porque é isso que o portão garante.

## O que "cobertura" quer dizer, afinal

Duas frentes fecharam em 100% e ambas tiveram que explicar o número:

* a `prom_d` do WSA1R fecha 524.288 de 524.288 — e **37% é flash apagada**, uma diretiva `.fill` de
  193.767 bytes, mais nenhuma instrução na imagem inteira;
* a ROM de boot do sub-CPU fecha 100% — sobre **3,4%** da imagem, porque os outros **96,6% são flash
  apagada**.

Nenhum dos dois números está errado. Os dois enganam se a classe "apagado" for somada à cobertura, e
é por isso que a regra virou: cada classe na sua própria linha, sempre.

## O que também aconteceu: alguém desistiu de um número

Uma frente converteu 153.600 bytes de papel de parede de `.incbin` para 9.645 linhas de `.byte`, e
reportou a dívida caindo de 1.113.121 para 959.521. Só que o próprio cabeçalho do arquivo dizia que o
PNG continuava sendo a fonte de verdade.

Perguntei o que o leitor entende depois da mudança que não entendia antes. A resposta foi "nada", e a
frente **reverteu o próprio trabalho** — argumentando, com razão, que um PNG é visualizável e um diff
de um pixel é legível, enquanto 29.469 linhas de hexadecimal não são nem uma coisa nem outra.

É o mesmo erro do item 1, pelo avesso: lá, dívida real escondida em `.byte` porque o contador só via
`.incbin`; aqui, dado legítimo empurrado para `.byte` porque o contador só via `.incbin`. A métrica
errada distorce nos dois sentidos.

## Onde ficou

Com o medidor consertado, o número honesto para as treze imagens: **556.939 bytes sem fonte real, de
12.386.304 — 95,5% de fonte.** O que sobra concentra-se em duas ROMs (dados de tabela, 60%; v7, 22%),
e o portão de treze imagens segue verde, rodado de forma centralizada depois de cada junção.

*Ferramentas: `scripts/analysis/kn5000_source_coverage.py` (reescrito, com `--selftest`),
`wsa1/notes/reachability.py`, `scripts/lanes/convert_lane_sub_byte_code.py`,
`scripts/analysis/table_data_debt.py`. Inventário completo em
`notes/coverage-instrument-fix-2026-09-01.md`.*
