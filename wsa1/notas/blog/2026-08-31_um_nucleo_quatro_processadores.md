# Um núcleo, quatro processadores, dois produtos

*Rascunho, 31 de agosto de 2026. Desmontagem do Technics SX-WSA1R.*

O SX-WSA1R tem dois processadores TLCS-900/H, cada um com sua EPROM de programa.
Fazia tempo que os dois pareciam rodar o mesmo escalonador multitarefa — as
mesmas rotinas, na mesma ordem, com endereços diferentes. "Parecem o mesmo" não é
um resultado. Este texto é sobre o que foi preciso para transformar isso em um,
sobre o instrumento errado que usamos primeiro, e sobre o erro que eu cometi
depois de acertar.

## A prova é o build, não a semelhança

Uma faixa juntou os dois trechos num único fonte, `kernel/kernel.s`, e o fez
montar **duas vezes**: 2.180 bytes dentro do prom_a e 2.180 bytes dentro do
prom_c, os dois byte a byte idênticos às EPROMs reais. Essa dupla montagem *é* a
prova. Se uma única constante estivesse errada, uma das duas imagens deixaria de
bater, e o portão de identidade de bytes — a única coisa que certifica esta
árvore — ficaria vermelho.

O que sobra é a medida interessante. Sobre a união dos dois trechos há 941
posições de instrução: 735 não precisaram de nenhuma reconciliação, 129 diferiam
só no estilo da grafia, e **81 carregam um valor por CPU — que se revelaram 21
constantes**, não 81 remendos: doze endereços de RAM, seis tamanhos de vetor,
três ponteiros de ROM. Nenhum `.if/.else` no arquivo inteiro. O corpo é
genuinamente compartilhado e cada diferença tem nome próprio, uma vez só
(`notes/kernel_join_probe.py --selftest`, 28 verificações).

## O instrumento errado, e por que era o errado

A pergunta seguinte era se esse mesmo núcleo roda também no KN5000, o irmão de
outra família de teclados. Uma ferramenta antiga já tinha respondido: **zero
correspondências byte a byte para 23 rotinas em todas as 41 imagens do KN5000.**

Essa resposta está agora **retratada** — não como fato, mas como resposta. Ela é
verdadeira a respeito de *bytes* e falsa a respeito da *pergunta*, e o que prova
isso é o parágrafo anterior: dois processadores do **mesmo produto**, do **mesmo
build**, rodando o **mesmo fonte**, diferem em 81 das 941 posições. Um terceiro,
em outro produto, montado anos depois, teria de diferir pelo menos isso. Procurar
identidade de bytes era garantir a resposta "não" antes de perguntar.

## A pista veio dos nomes — e os nomes não valem como prova

Fui olhar os rótulos. O sub-CPU do KN5000 tem 40 rótulos `TaskSched_*`, 11
`TaskMsgQ_*`, mais `TaskEvent_*` e `TaskSem_*`, e eles pareavam um a um com o
núcleo do WSA1: `Kernel_Dispatch` com `TaskSched_Dispatch`, `Kernel_ResumeTask`
com `TaskSched_ContextRestore`, `MsgQueue_Send` com `TaskMsgQ_Send`. Os corpos
batiam instrução por instrução, e o deslocamento `+4` do TCB onde se salva o
ponteiro de pilha era idêntico nos dois.

Registrei como **pista, não como prova**, por um motivo específico: as duas
árvores foram nomeadas por agentes deste mesmo projeto. Concordância de nomes
pode estar medindo um hábito de nomenclatura compartilhado, não código
compartilhado. Foi a decisão certa, e a próxima seção mostra o quanto.

## O controle que decide: rode a mesma busca no que *não* é o núcleo

A medição de verdade normaliza a sequência de mnemônicos, apaga os operandos e
compara forma de fluxo de controle. Mas o número que convence não é o do núcleo —
é o do **contraste**. Rodamos a busca idêntica em 26 rotinas do prom_c que **não**
são o núcleo, cortadas no mesmo comprimento:

| | n | máx | mediana | ≥ 0,70 |
|---|---:|---:|---:|---:|
| rotinas do núcleo (≥ 20 instruções) | 20 | 1,000 | **0,909** | **20** |
| iscas: prom_c fora do núcleo | 26 | **0,333** | 0,212 | **0** |

As duas distribuições não se tocam, e há um vão de 0,41 entre elas.

Dois controles fecham as saídas óbvias. O prom_b — **mesmo produto, mesmo
compilador, sem núcleo** — chega no máximo a 0,28, então o instrumento não está
medindo o compilador. E embaralhar a ordem dos símbolos da consulta derruba o
escore para 0,29–0,45, então ele está medindo **ordem**, não vocabulário.

Dois instrumentos que não usam limiar nenhum concordam: tomadas na ordem da ROM,
as 26 rotinas caem no KN5000 numa **sequência crescente de 21** (200.000
permutações aleatórias nunca passaram de 14; p ≤ 5e-6), e o mapa de RAM
recuperado é **monótono** — 0x90→0x1044, 0x91→0x1046, 0x0100→0x1048 — mesma ordem
de vetores, tamanhos diferentes (3, 4 e 5 tarefas).

A resposta é sim, e é maior que a pergunta: o núcleo está no **payload do
sub-CPU** do KN5000 **e**, como um build separado — verificado adversarialmente,
esses bytes não estão no payload do sub-CPU —, na sua **ROM de programa
principal**. Um núcleo, quatro processadores, dois produtos.
(`notes/kernel_structural_match.py`, 14 verificações; `notes/FINDINGS-kernel-in-the-kn5000.md`.)

## O erro foi meu, e foi exatamente onde eu tinha avisado

A tabela de pares que montei a partir dos nomes acertou a **região** e errou os
**detalhes**. O sítio do KN5000 que de fato casa com `MsgQueue_Send` chama-se
`TaskSched_Wait`. O de `Kernel_SemaSignal` chama-se `TaskEvent_Wait`. E na CPU
principal do KN5000, o sítio que casa com `Kernel_StartTask` com escore 0,978
chama-se **`Show_ScreenGroup_Entry`**, com a imagem do contador de semáforos
dentro de um rótulo chamado `TaskSched_ScreenGroupTable`.

Ou seja: **vários rótulos do núcleo no KN5000 estão com nome errado** — o que é
uma pista nova, e boa, para uma faixa de renomeação. Mas o ponto para este texto é
outro: a cautela que eu registrei junto com a pista era necessária, e não por
prudência genérica. Os nomes apontaram o instrumento para o lugar certo, que é
tudo o que uma pista deve ser autorizada a fazer, e teriam mentido sobre o resto.
O arquivo `notes/kernel_kn5000_lead.py` continua no repositório com a refutação
escrita no seu próprio cabeçalho, em vez de sumir ou de continuar de pé como
tabela errada.

Uma segunda correção, menor, na mesma direção: eu tinha recomendado comparar
*fonte com fonte* e construir um mapa de dialetos entre as duas grafias. Era
desnecessário e a razão que dei era errada — a ferramenta decodifica **bytes**
com um só desmontador dos dois lados, e aí `9c 00 23` é uma instrução só,
independentemente de como cada árvore a escreve.

## O que continua em aberto, dito como tal

Não ficou estabelecido **quem escreveu** o núcleo, nem que os fontes sejam
idênticos. `Kernel_Dispatch` marca só 0,742: a versão do KN5000 não tem o laço de
drenagem de ticks, e a profundidade de trava saiu do registrador de controle
0x3C — porque o TMP94C241 não tem esse registrador. São o mesmo programa, não o
mesmo arquivo. E seis rotinas curtas demais para medir estão posicionadas pela
restrição de ordem, não medidas: isso está dito no relatório, não escondido nele.

Placar honesto do dia: uma resposta afirmativa com controle, uma resposta antiga
retratada, uma tabela minha refutada e mantida no repositório com a refutação em
cima, e uma pista de renomeação que nasceu de um erro.
