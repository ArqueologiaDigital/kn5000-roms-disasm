# Contar a grandeza errada

*Rascunho, 29 de agosto de 2026. Desmontagem do Technics SX-WSA1R.*

Converti hoje o maior bloco `.incbin` que restava no prom_a — 18.432 bytes,
0xFAD800 a 0xFB2000, com o portão de byte-match verde. A cobertura substantiva do
projeto foi de 67,7% para 68,6%. É o tipo de número que se coloca no topo de um
relatório.

Ao lado dele, no mesmo commit, está este: as rotinas ainda chamadas apenas
`sub_XXXXXX` foram de 4.997 para **5.079**.

O território subiu e o significado desceu. Não é um efeito colateral estranho: é
aritmética. Converter uma região traz para dentro da árvore todas as rotinas que
ela contém, e nenhuma delas nasce com nome. As 84 etiquetas que o meu emissor
produziu são todas `sub_XXXXXX` com um comentário dizendo por que aquele endereço
é um ponto de entrada — uma fatia de thunk, uma entrada de tabela de ponteiros,
uma chamada vinda de código já convertido. Isso é honesto e é pouco.

A meta do projeto não é cobertura. É uma desmontagem que reconstrói os bytes
**e** explica o que eles fazem. Medir a primeira metade é fácil e por isso ela
domina os relatórios; a segunda metade é a que está para trás, e o único número
que a mede está indo na direção errada.

## O emissor, que é a parte que dá para reaproveitar

O que tornou a conversão segura não foi cuidado, foi mecânica. O emissor:

* re-deriva o *layout* do script de layout a cada execução e **recusa-se a emitir**
  se a contagem de segmentos, o ladrilhamento ou o número de conflitos mudou desde
  a auditoria;
* monta a região inteira que está prestes a imprimir e compara byte a byte com a
  ROM, e **recusa-se a imprimir** se diferir.

Ou seja: o texto já reconstruiu o bloco antes de você o ver. Nada chega ao `.s`
por confiança. Sessenta e três segmentos, zero regiões `unknown`:

    python3 notes/gen_prom_a_fad800_module.py --stats

E o portão, que é o único critério que certifica a árvore, ficou verde.

## A parte mais interessante do dia foi um resultado negativo

A meta pede também referência cruzada com as outras desmontagens de teclados
Technics, para achar chips, protocolos e trechos de código em comum. O WSA1 e o
KN5000 são ambos TLCS-900, e cerca de 29 mil bytes do prom_c do WSA1 são
byte-idênticos ao payload do sub-CPU do KN5000. Existe uma ferramenta que propõe
transportar os nomes do irmão para cá, verificando byte a byte cada proposta.

Fui ver o que faltava aplicar. Das 19 nomes distintos propostos, 15 já eram
etiquetas aqui. Sobravam quatro — e a conclusão certa foi **não importar
nenhum**.

Os quatro são nomes que a árvore do KN5000 dá a *sub-objetos* de estruturas que
esta árvore modela inteiras:

| nome do irmão | onde cai aqui |
|---|---|
| `DSP_AlgoChannel_SelectorByte4` | byte 4 do registro 0 de uma tabela de 12 registros de 6 bytes |
| `DSP_AlgoChannel_SelectorByte5` | byte 5 do mesmo registro |
| `DSP_ChanFreq_Dispatch1_Curves` | **linha 8**, resto zero, de um pool de 12 linhas de 51 u16, passo 0x66 |
| `DSP_ChanFreq_Packet1_Curve` | **linha 11**, resto zero, do mesmo pool |

Os dois deslocamentos dividem pelo passo com resto exatamente zero, o que
transforma isso de impressão em conclusão. E o cabeçalho do pool já dizia, escrito
antes de eu chegar: *"endereçado com três bases de linha diferentes no irmão"*. O
lado do KN5000 nomeia três bases; este lado nomeia um pool e o seu passo, e
registra que o irmão o divide.

Importar aqueles quatro nomes teria partido uma estrutura documentada para ganhar
uma etiqueta menos informativa. O transporte não estava incompleto: estava
terminado, e a sobra era a diferença entre dois modelos do mesmo bytes.

**Identidade de bytes diz que o CÓDIGO é o mesmo. Não diz que o NOME do irmão é o
melhor.** É a mesma cautela que o próprio banner da ferramenta já traz um nível
abaixo — identidade de bytes estabelece que o código é igual, não que a máquina ao
redor é — só que aplicada ao modelo em vez de à máquina.

    python3 notes/wave7_kn5000_transplant_residue.py --selftest

Dez verificações. Uma delas pegou o meu primeiro rascunho afirmando 16 nomes já
aplicados quando são 15: eu tinha contado um nome duplicado.

## O fio comum

Um transporte "incompleto" pela contagem de nomes pode estar completo pelo
significado. Uma conversão que sobe a cobertura pode baixar a compreensão. Nos
dois casos o erro não é medir — é medir a grandeza que dá para medir e tratá-la
como se fosse a grandeza que interessa.
