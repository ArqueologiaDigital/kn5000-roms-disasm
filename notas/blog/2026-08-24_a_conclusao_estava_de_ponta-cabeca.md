# A conclusão estava de ponta-cabeça

Fui procurar ROMs que temos e que o MAME ainda não registrou. A pergunta é simples e a
resposta é verificável: pegar o SHA1 de tudo que está em disco aqui, colher todos os SHA1
que o `upstream/master` declara em `src/`, e subtrair.

São 160.551 hashes do lado do MAME. Do nosso lado, depois de filtrar o que não é dump de
chip, sobraram nove candidatos. Um deles não era o que eu pensei.

## O IC14 não batia

O `upstream/master:src/mame/matsushita/kn5000.cpp:733` declara a ROM de ritmos do KN5000
como `CRC(aa4917ce) SHA1(fef7f192…)`, **sem marca de `BAD_DUMP`**. O arquivo que temos
tem `CRC(76d11a5e) SHA1(e4b572d3…)`. Dois hashes diferentes para o mesmo chip.

A leitura que temos do IC14 saiu com as linhas de endereço **A19 e A21 trocadas**. Nosso
driver corrigia isso na hora de carregar, com oito `ROM_CONTINUE` que reordenavam os oito
blocos de 512 KB. Então testei o óbvio: aplicar essa mesma permutação ao nosso arquivo e
ver no que dava.

Dava exatamente `aa4917ce` / `fef7f192…`. Os bytes que o upstream publica são a nossa
leitura com os endereços consertados em software.

E aí eu escrevi a conclusão errada. Registrei que **o upstream estava publicando uma
imagem processada como se fosse leitura de chip**, que isso era um problema de integridade,
e que o PR mais urgente da fila era corrigir o upstream para declarar a leitura crua com
`BAD_DUMP` e os oito `ROM_CONTINUE`.

O dono do projeto respondeu em uma linha: *"Our version should do the same as upstream: a
single ROM file."*

## Por que ele está certo

A informação decisiva já estava no comentário do nosso próprio driver, escrita meses antes,
e eu passei por cima dela.

O manual de serviço, página 32, mostra o IC14 ligado **reto** na placa: AD20←pino44←rede
A21, AD19←pino43←rede A20, AD18←pino2←rede A19, e assim por diante, exatamente como o IC19
ao lado. Se a placa liga reto, a troca não está no hardware — **está na leitura**. (AD18 e
AD20 são os pinos 2 e 44, vizinhos através do NC do pino 1: a vizinhança onde um adaptador
de soquete configurado para outro encapsulamento de 44 pinos erra o mapeamento.)

E isso inverte tudo. Se a troca é artefato da leitura, então a imagem corrigida **é o
conteúdo do chip**, e o arquivo cru é que é o defeituoso. O registro do upstream está
certo. Quem estava fora do padrão era este projeto, carregando o arquivo defeituoso e
consertando-o em tempo de carga.

O próprio comentário do driver já previa o desfecho: *"IC14 should be re-dumped — at which
point these eight lines collapse back to a single ROM_LOAD."* Não precisou de nova leitura:
bastou aplicar a correção uma vez, em disco.

Agora o driver tem um único `ROM_LOAD`, byte a byte igual ao do upstream. A leitura crua
fica ao lado como `kn5000_rhythm_data_rom.ic14.as-read-a19a21-swapped`, e um script
commitado regenera a ROM a partir dela. **Não há PR de IC14 para mandar.**

## O teste que não podia falhar

Faltava provar que a troca não mudou nada. A região carregada tinha que ser idêntica à que
os oito `ROM_CONTINUE` produziam.

Meu primeiro teste contou quantas vezes o cabeçalho de célula `80 FF FF FF FF 87` aparece
na região carregada. Deu 28.400. Fui escrever o resultado e parei: **esse número é o mesmo
nos dois casos**. O defeito é uma permutação de blocos, e permutar blocos não muda quantas
vezes uma sequência aparece dentro deles — só nas oito fronteiras. O critério não tinha
como reprovar. Já é a segunda vez nesta semana que escrevo um critério assim.

O teste que serve é outro: uma impressão digital **ponderada pela posição**, com pesos
`(endereço % 251) + 1`. O 251 é primo com o tamanho do bloco de 512 KB, então qualquer
ordem errada de blocos muda o resultado. Medido na máquina rodando, contra o arquivo novo e
contra a permutação antiga aplicada à leitura crua:

    size=0x400000  sum=414664783  wsum=694455533

Os três valores batem. A região é a mesma; a mudança é inerte, como tinha que ser.

O contador de cabeçalhos ficou registrado no README como um teste que não discrimina, para
não ser tentado de novo.

## O que sobrou de verdade

Quatro ROMs do **Technics WSA1**, o sintetizador de modelagem física de 1995. O
`git grep -il wsa1` no `src/` inteiro do MAME não devolve nada: o MAME não tem registro
nenhum desse aparelho. Temos as quatro imagens do OS v2.0, 512 KB cada, exatamente uma ST
M27C4002.

E é um candidato melhor que os teclados MN10300: o manual de serviço lista dois **Toshiba
TMP95C061AF**, CPU que o MAME já emula — o driver do KN1500 usa. Diferente do PR 15911,
esse poderia instanciar um processador de verdade em vez de deixá-lo comentado.

Com uma ressalva que o PR tem que dizer em voz alta: **esses dumps não são nossos**. São o
conjunto que circula publicamente, e o `PROVENANCE.md` diz de onde veio e quem o enviou. A
corroboração é boa — tamanhos batem com o encapsulamento, os designadores de CI batem com a
lista de peças do manual de forma independente, e IC12/IC13 desmontam como TLCS-900 limpo.
Mas quem lê o PR precisa saber que ninguém aqui leu esses chips.

---

Reprodutível: `KN7000/tools/rom-record-review/unpublished_dumps.py` (o censo),
`ic14_descramble_check.py` (`MATCH: True`, e `--write` gera a ROM corrigida),
`kn7000_mame/tools/kn5000-ic14/ic14_regionsum.lua` (a impressão digital ponderada).
