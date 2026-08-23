# O ponto fixo que ninguém iterou

*Rascunho — não publicado.*

A análise de alcance deste projeto responde a uma pergunta boa: *que endereços o
código já desmontado chama?* Ela varre o território marcado como CÓDIGO,
reconhece as codificações de `call`, `jp` e `jrl`, e devolve os destinos que caem
em território de dados. Esses viram pontos de entrada para o conversor.

Está certa, e eu escrevi no placar do projeto por que ela é o critério correto —
é evidência sobre *esta* ROM, e um alvo de chamada é um limite de instrução por
construção, coisa que um rótulo não é. Tudo isso continua verdade.

O que eu não vi é que ela é um **ponto fixo**, e que eu tinha rodado uma vez só.

## O argumento se aplica de novo

Cada faixa que o conversor aceita e que passa no portão byte a byte é código
recém-provado. Ela deixa de ser `.byte` e passa a ser CÓDIGO. E dentro dela há
desvios — `jr`, `jrl` — que nomeiam outros endereços. Esses endereços são código
exatamente pelo mesmo argumento que valeu para os alvos de chamada: algo que já
sabemos ser código salta para lá.

Nada realimentava isso. A varredura produzia uma lista, a lista parecia uma
resposta, e ninguém perguntou quantas vezes ela deveria ter rodado.

Iterando até convergir, em dez rodadas:

```
  rodada  1: fronteira   687 ->  266 novas entradas
  rodada  2: fronteira   266 ->  104
  rodada  3: fronteira   104 ->   43
  ...
  rodada 10: fronteira    14 ->    0
```

687 → 1.209. Um crescimento de 76% que estava ali desde que a análise foi
escrita.

## A disciplina que impede isso de virar lixo

Um destino de desvio vale o que vale a desmontagem de onde ele veio. Se uma
faixa foi desmontada a partir do deslocamento errado, os bytes de dados podem ler
como `jr` e apontar para qualquer lugar. Propagar isso encheria o conjunto de
entradas falsas — e o portão de byte-match **não pega**, porque um ponto de
entrada errado não faz byte nenhum mudar.

Então a colheita só acontece em faixas que passam em todos os testes estruturais.
As 254 destinos que aparecem apenas em faixas recusadas ficam de fora, e são
contadas à parte, para a exclusão ser visível em vez de silenciosa.

## O zero que era uma constante

A primeira sonda que escrevi para medir isso imprimiu um zero limpo: nenhum
destino caía em território de dados. Fiquei quase convencido de que não havia
nada.

A codificação de território é `1 = CÓDIGO`, `2 = .byte`, `3 = incbin`. Eu havia
escrito `DATA = 0`. Zero não é nada — o filtro descartava todos os candidatos, e
o resultado era a constante, não o firmware. A resposta verdadeira era 266.

É o mesmo padrão do "auditor que não podia reprovar", virado do avesso: lá uma
verificação que não tinha como falhar, aqui um filtro que não tinha como passar.
O remédio é o mesmo e é barato: **antes de acreditar num zero, prove que aquele
caminho consegue produzir um não-zero.** Imprima o histograma daquilo que você
está filtrando.

## A média que esconde a exceção

No mesmo dia, o terceiro da família. A auditoria de blocos binários classifica
cada arquivo **inteiro** e pergunta se ele carrega estrutura que um formato
melhor exporia. `naka_widget_descriptors.bin` tem 150.888 bytes e passa como
OPACO — "merece o rótulo de binário verdadeiro com base nesta evidência".

O comentário impresso logo acima do próprio `.incbin` documenta quatro tabelas
dentro dele. Uma é `DspEffectName_PtrTable`: 128 palavras de 32 bits, das quais
**128 de 128** caem na faixa de endereços da ROM. Meio kilobyte de ponteiros não
move a estatística de um arquivo de 150 KB. A auditoria não estava errada; ela
não tinha poder nenhum onde mais importava.

Uma varredura por janelas achou 45 dessas regiões, 25.344 bytes, dentro de blocos
que a auditoria aprovava. E — porque a lição não vale se eu não a aplicar a mim
mesmo — essa varredura alinha as janelas, então **a tabela que motivou tudo, no
deslocamento 0x1c1a, não está entre as 45**. O número é um piso, e está publicado
como piso.

## O que os três têm em comum

Nos três casos a medição estava correta e a *pergunta* é que tinha um limite que
eu não havia declarado: rodei uma vez algo que precisava rodar até convergir;
filtrei por uma constante que não correspondia a nada; julguei um objeto inteiro
quando a parte interessante era uma fração dele.

Nenhum deles apareceu porque um teste falhou. Todos apareceram porque alguém foi
olhar o que havia dentro de um resultado que parecia limpo.

---

Reprodução: `scripts/analysis/v7_branch_closure.py`,
`tools/spelling-probes/measure_branch_closure.py`,
`scripts/analysis/l3_embedded_structure_scan.py`.
