# O bloco já estava documentado (e eu contei três vezes)

*Rascunho — não publicado.*

A auditoria de blocos binários deste projeto responde a uma pergunta simples:
*este arquivo carrega alguma estrutura que um formato melhor exporia?* Ela lê os
bytes, mede, e devolve OPACO ou não.

Passei o dia brigando com o que ela deixa passar — 45 regiões com cara de tabela
de ponteiros dentro de blocos aprovados. No fim da tarde, tentando decidir se uma
região específica era mesmo uma tabela plana, olhei para o lado errado do
problema e achei a coisa mais útil do dia.

## O que estava escrito ao lado do arquivo

A região em disputa tem 768 bytes dentro de `naka_widget_names_charmap.bin`.
Metade das palavras resolvia para símbolos reais, metade não — o tipo de número
que não decide nada. Fui procurar quem indexa aquela região, e a resposta estava
no mesmo arquivo `.s` que faz o `.incbin`:

```asm
	.equ IconName_i5,            NakaData_WidgetNames + 0x4C02
	.equ IconName_i4,            NakaData_WidgetNames + 0x4C06
	.equ IconName_Default,       NakaData_WidgetNames + 0x4C1A
	.equ IconBitmapNamePtrTable, NakaData_WidgetNames + 0x4C28
```

Oito desses caem dentro dos 768 bytes. A região **não é** uma tabela plana de
ponteiros: são nomes de ícones em passo 4 a partir de `+0x4C02`, e depois uma
tabela que as fontes já chamam, por extenso, de `IconBitmapNamePtrTable`. Se eu
tivesse convertido tudo como `.long`, teria descrito errado a primeira metade — e
nenhum portão do projeto reclamaria, porque os bytes seriam idênticos.

E aí a pergunta maior: quantos desses nomes existem? Para esse bloco, 674. No
total, 3.709 nomes para o interior de 24 blocos.

**A auditoria chama esses arquivos de OPACOS — "merece o rótulo de binário
verdadeiro com base nesta evidência" — enquanto milhares de nomes para o conteúdo
deles estão no arquivo ao lado.** Ela lê bytes e só bytes. Não é que a estrutura
seja desconhecida; é que ela mora num `.equ` em vez de morar num rótulo posicionado
dentro do bloco. E um `.equ` que nomeia um deslocamento *é* uma descrição legível.

## Onde eu errei, e por 3x exatos

Publiquei o número como **11.394**. É 3.709.

O motivo é bobo e vale escrever: as mesmas declarações `.equ` existem na v7, na v9
e na v10. A linha de comando que produziu o número varreu os três diretórios e
somou tudo, contando cada nome três vezes. Exatamente 3x — o que, olhando agora, é
a assinatura mais óbvia possível de um projeto com três revisões.

O detalhe que me deixou passar: o número por bloco que eu tinha citado logo acima,
674, estava certo. Aquele veio de ler um único arquivo da v7. Um número certo ao
lado de um número inflado, e nenhum contraste entre eles que chamasse atenção.

O 11.394 já tinha entrado numa mensagem de commit, numa nota de achados e no
placar do projeto antes de qualquer verificação. Só apareceu porque a regra do
projeto obriga a commitar o script que produziu cada número citado — e ao
transformar a linha de comando em script commitado, o script deu 3.709.

Não foi um teste que pegou. Foi a exigência de tornar o número reproduzível.

## O que fica

O achado continua de pé, com o número certo: esses blocos são muito melhor
documentados do que a auditoria acredita, e os 3.709 deslocamentos nomeados são
as **fronteiras corretas** para qualquer fatiamento futuro — infinitamente melhor
fundadas que a minha varredura por janelas, que se alinha a 0x100 e não sabe nada
sobre registros.

E as 30 regiões que sobraram continuam sem converter. Elas carregam endereços a
13–29x o nulo, mas "carrega endereços" não é "é uma tabela de endereços", e o
caso do `IconBitmapNamePtrTable` mostra que pelo menos uma delas é heterogênea.
Converter mesmo assim somaria 13.056 bytes ao placar e passaria em todos os
portões — porque aqui nada pune uma descrição errada, só um byte errado.

---

Reprodução: `scripts/analysis/l3_named_offsets_into_blobs.py` (com `--base NOME`
para listar os deslocamentos de um bloco e o histograma de intervalos, onde um
passo de registro aparece).
