# `Lsw` não é `LSW`

Durante meses a documentação deste projeto afirmou, em negrito:

> **Nenhum código do KN5000 foi mostrado lendo ou escrevendo o CONTEÚDO de um
> `.LSW`** — apenas nomeando a extensão, procurando por ela num caminho de
> teste, e carregando um evento batizado com esse nome.

A frase é falsa. A ROM lê e escreve esses arquivos, e sempre leu.

## A causa

A busca foi feita por `LSW`, em maiúsculas. A ROM escreve `Lsw`.

    0x0E1F726  PostLswSave
    0x0E1F732  PreLswSave
    0x0E1F73E  PostLswLoad
    0x0E1F74A  PreLswLoad

Quatro nomes, numa tabela de teste de fábrica, a poucos bytes um do outro.
Qualquer um deles teria derrubado a afirmação. A busca por maiúsculas devolveu
zero — e zero, aqui, não significava "não existe": significava "eu não sei
soletrar o que estou procurando".

Esse é o mesmo padrão que já apareceu várias vezes neste projeto: o `grep`
recursivo que pula 47% dos arquivos por causa de bytes acima de 127; o
backend do LLVM que codifica a instrução certa mas só atende por um nome
inventado. Em todos os casos a ferramenta responde com um zero limpo, e um
zero limpo se parece muito com um resultado.

## O que o firmware realmente faz

O KN5000 **escreve** 0xE40 bytes em quatro pedaços, sem cabeçalho intermediário
e sem empacotamento: 0x20 de cabeçalho a partir de `0xF980`, o bloco TLV 0
(0x3C0) a partir de `0xF9A0`, o bloco TLV 1 (0x260) a partir de `0xFD60`, e
0x800 a partir de `0x1E7800`.

E **valida**: `FileIO_CheckRegionSignature(0)` exige `"HK"` no offset 4 do
arquivo, pela tabela em `0xEA0104`. A prova mais bonita disso está na própria
ROM — a imagem de painel padrão de fábrica, em `0xEDB3DC`, começa com

    5A 5A 00 00 48 4B        ZZ..HK

ou seja, a área de painel viva do instrumento **é** um `.LSW` que passa no teste
do próprio carregador.

## Os 24 blocos são memórias de painel

Eu tinha escrito que essa leitura era "não apenas sem suporte, mas contradita",
porque `.PMT` ("PANEL MEMORY") existe como um tipo de arquivo separado na mesma
tabela, e os disquetes não trazem nenhum `.PMT`.

O argumento é plausível e está errado. Uma extensão dedicada a salvar **uma**
memória de painel não impede que o arquivo de painel atual carregue **todas**
elas. Eu tratei "existe um tipo separado" como se fosse "logo, não pode estar
aqui dentro" — que não se segue.

O importador decide a questão: lê 0x300 por vez para `0x1ED400 + 960*j`, entre
chamadas cujos nomes são `PrePmLoad` e `PostPmLoad`. E 960 = 0x3C0 = exatamente
o tamanho do bloco TLV 0, com `(0x200000 - 0x1ED400) / 960 = 80` exato.

Isso também explica o buraco que estava aberto: o firmware move 0x640 + 0x800
bytes, mas os arquivos têm 0x5800. Os sete disquetes têm cabeçalho `"M60"`, que
o carregador classifica como formato 2 e importa por um conversor — por isso um
`"HK"` que falha não interrompe a carga.

## O que continua em aberto, sem maquiagem

O formato 2 importa **10** das 24 memórias, e o `0x000A` é um literal no código
(o formato 1 usa `0x0018`). O byte +7 do cabeçalho vale 0x0A = 10, o que é
tentador — mas o firmware **não lê esse byte**, então ele não está demonstrado
como sendo uma contagem. Resolver isso exige um arquivo de formato 1, que é um
disquete que não temos: falta um disco, não falta análise.

A leitura "24 palavras de 16 bits" para um dos vãos foi testada e **não se
sustentou**: em `02BOSSA_.LSW` os slots 15..23 duplicam os 5..13, e as palavras
não. Fica registrada como refutada, não como pendente.

O script que prova tudo isso
(`analysis/disk-format-probes/lsw_region_to_block_map.py`) falha quando
perturbado em três direções — tag de slot corrompida, byte de cabeçalho
alterado, imediato esperado da ROM alterado. Um teste que não pode falhar não
é um teste.
