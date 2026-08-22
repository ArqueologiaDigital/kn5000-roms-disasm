# O maior bloqueio não era do montador — era meu

Passei o dia caçando "grafias que faltam": formas de instrução que o backend
TLCS-900 do LLVM não sabe escrever, e que por isso travam o conversor que
transforma blocos `.byte` em instruções de verdade. É um trabalho real, e rendeu
alguns milhares de bytes.

Aí um censo — feito com o cuidado de tirar um retrato dos arquivos antes de
medir, porque o conversor estava reescrevendo as fontes durante a medição —
respondeu à pergunta que eu não tinha feito: **quanto vale cada bloqueio?**

| | faixas | bytes |
|---|---:|---:|
| passam / puladas | 193 | 12.930 |
| **`fixup` — nunca podem passar** | **361** | **18.412** |
| divergência real de bytes | 22 | 0 |

Dezoito mil bytes — cerca de **sete vezes** toda a lista de grafias pendentes —
estavam parados atrás de uma verificação **que não tinha como dar certo**.

## O defeito

Um desvio para um símbolo externo não vira bytes na hora da montagem: vira um
*fixup*, um espaço reservado que o ligador preenche depois. O `llvm-mc` devolve
isso como `; encoding: [0x6e,A]` — aquele `A` é um marcador, e é lido como
`0x0A`.

O conversor sabe disso. A função que resolve desvios diz, no próprio comentário,
que o deslocamento é tarefa do montador e que só o portão final pode fechar o
laço. E mesmo assim, algumas linhas depois, o bloco inteiro ia para uma
comparação byte a byte contra a ROM.

A condição era `if not br_labels:` — "se não há rótulos de desvio". Só que
`br_labels` guarda apenas os rótulos **locais**, os `.Lc_` criados para alvos
dentro da própria faixa. Um desvio que sai da faixa e aterrissa num símbolo
externo não acrescenta nada a essa lista. Resultado: a faixa parecia limpa de
desvios, caía na comparação, e era rejeitada por não bater com um valor que era
um marcador de ligação.

A condição certa é "não existe desvio nenhum no bloco", não "não existe rótulo
local".

## Por que isso passou tanto tempo despercebido

Porque o sintoma era indistinguível do sintoma legítimo. As faixas apareciam no
relatório como *"a remontagem do bloco não reproduziu os bytes"* — exatamente a
mensagem que uma faixa genuinamente mal decodificada produz. A rejeição estava
funcionando como projetado; era o critério que estava errado.

E eu passei o dia atacando a categoria que o relatório listava em segundo lugar,
porque essa eu sabia como atacar.

## Dois defeitos no backend, esses de verdade

O mesmo censo achou dois erros no `TLCS900InstrInfo.td`, e esses eu corrigi:

**1. `stb_dri` e `lda_dri` estavam trocados.** A ROM decide: `f3 07 e4 e0 31` é
`lda XBC,XBC+WA`, e `0x31 = 0x30 | registrador`. Logo `0x30` é LDA e `0x40` é a
escrita de byte — o que os vizinhos `stw_dri`=0x50 e `stl_dri`=0x60 já
indicavam. Antes da correção era preciso escrever `stb_dri` para obter um LDA, e
**4.693 pontos da desmontagem chamavam de "escrita" uma instrução que calcula um
endereço**. Os bytes estavam certos; o nome estava errado — que é precisamente o
tipo de erro que uma desmontagem não pode se permitir, porque o nome é o produto.

**2. `st_rrw` e `st_rrl` emitiam o sub-opcode de BYTE.** As três definições
carregavam `0x40`, com um comentário dizendo que "OpSize seleciona a faixa de
sub-opcode". O emissor só aplica esse ajuste quando o opcode é menor que `0xF0`,
e o prefixo aqui é `0xF3`. Então as três emitiam a mesma coisa, silenciosamente.

## A migração que o portão pegou

Trocar os dois mnemônicos quebrou a compilação na hora — e ainda bem. `stb_dri`
recebia registrador de 8 bits, então aqueles 4.693 pontos estavam escritos com
**nomes de registrador de 8 bits** para destinos LDA de 32 bits.

O mapeamento eu não adivinhei; medi, encodando os dezesseis nomes:

    W↔XWA(0)  A↔XBC(1)  B↔XDE(2)  C↔XHL(3)
    D↔XIX(4)  E↔XIY(5)  H↔XIZ(6)  L↔XSP(7)

Assim `stb_dri A` (antes, `0x31`) vira `lda_dri XBC` (agora, `0x31`) — o mesmo
byte, com o nome correto. Uma segunda passada pegou 81 nomes em minúsculas que
minha expressão regular sensível a maiúsculas tinha deixado passar.

O critério de aceitação é o de sempre, e é o único que vale: reconstruir as nove
ROMs e exigir 100,00% de igualdade em todas.
