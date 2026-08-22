# A janela da busca não é uma propriedade dos dados

Três vezes no mesmo dia, neste projeto, um resultado negativo documentado
acabou sendo o alcance da busca — não uma característica do firmware. Vale
escrever as três juntas, porque isoladamente cada uma parece azar, e juntas
parecem o que são: um modo de falhar.

## 1. `LSW` em maiúsculas

A documentação afirmava que nenhum código do KN5000 lia ou escrevia o conteúdo
de um arquivo `.LSW`. A busca tinha sido por `LSW`. A ROM escreve `Lsw`:
`PreLswLoad`, `PostLswLoad`, `PreLswSave`, `PostLswSave`, quatro nomes juntos
em `0x0E1F726`.

## 2. A janela `0x4000..0x4FFF`

Os tags `0x44`, `0x45` e `0x46` estavam registrados assim: *"nenhum dos três
carrega um descritor de parâmetro"*. O varredor de descritores olhava a faixa
de identificadores `0x4000..0x4FFF`.

Os três carregam **48 identificadores**, em `0x8200`, `0x8600` e `0x8A00` — um
espaço de nomes por parte do teclado, com passo exato de `0x400`.

São os **DRAWBARS**, os registros de órgão: `0x44` = RIGHT 1, `0x45` = RIGHT 2,
`0x46` = LEFT. Nove campos com máximo 8 ladrilham o payload `+3..+7` em pares
de nibbles, e a página que os edita se chama, na própria ROM, `DRAWBAR
SETTING`, com a fileira de pés logo abaixo:

    16'  5 1/3'  8'  4'  2 2/3'  2'  1 3/5'  1 1/3'  1'

O default de fábrica dos três é `00 00 00 88 80 80 00 00 00 00` — ou seja
`16'=8, 8'=8, 4'=8, 2'=8` e o resto zerado, que é um registro de órgão
perfeitamente plausível.

## 3. Qualquer inteiro abaixo de `0x100000`

Essa foi minha, hoje. Escrevi um classificador para responder a uma pergunta
legítima: dos blocos binários incluídos na montagem, quantos escondem uma
estrutura que mereceria um formato melhor? A regra de "isso é uma tabela de
ponteiros" aceitava qualquer valor de 32 bits dentro das faixas de ROM — e eu
tinha incluído `0x000000..0x0FFFFF` entre elas.

Essa faixa aceita **todo inteiro pequeno**: contadores, offsets, flags.
Resultado publicado: 98 arquivos, 174.097 bytes. Resultado correto, só com
faixas de ponteiro de código: **61 arquivos, 8.440 bytes**. Vinte vezes menor.

## O erro que interessa é o do controle

Eu tinha um controle negativo, e ele passou limpo o tempo todo: rodar o mesmo
classificador sobre bytes de `os.urandom`, do mesmo tamanho. Deu 100%
justificado, 7 bytes em 3,2 MB. Parecia validação.

Não era. Um `u32` uniformemente aleatório cai abaixo de `0x100000` com
probabilidade 1/4096 — o controle **não tinha como** exibir o defeito. Dados
reais são cheios de inteiros pequenos; ruído uniforme não é.

O controle que morde é outro: **embaralhar os bytes dos próprios blocos
reais**. Preserva exatamente a distribuição de bytes e destrói só o arranjo.

| classe | real | embaralhado | veredito |
|---|---|---|---|
| PTR_TABLE | 61 | **0** | estrutura de verdade |
| WORD_TABLE | 46 | 32 | quase tudo artefato |
| SPARSE | 17 | **32** | artefato puro |
| TEXT | 6 | 6 (idêntico) | artefato puro |

`SPARSE` aparece **mais** depois de embaralhar. `TEXT` sai byte a byte igual —
e de fato os dois maiores "textos" são as imagens 320×240 do HD-AE5000, cujos
índices de paleta calham de cair na faixa ASCII imprimível.

## A moral

Uma busca que não encontra nada produz um zero limpo, e um zero limpo se
parece muito com um resultado. A diferença entre "não existe" e "não procurei
onde estava" não aparece na saída — só aparece se alguém escrever qual era a
janela.

E um controle negativo só vale se ele **pudesse** ter falhado. Um controle
tirado de uma distribuição incapaz de exibir o defeito não é uma verificação;
é uma cerimônia tranquilizadora.
