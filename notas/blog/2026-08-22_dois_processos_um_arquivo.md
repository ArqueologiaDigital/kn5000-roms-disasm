# Dois processos, um arquivo

Ontem pedi mais agentes em paralelo. O paralelismo achou um bug — no meu
próprio código, e de um tipo que só aparece quando há mais de um processo.

## O defeito

O conversor de faixas (`scripts/converters/convert_reachable_ranges.py`)
desmonta um trecho da ROM assim: escreve os bytes num arquivo temporário,
chama o `unidasm` sobre esse arquivo, lê o texto de volta. O caminho do
arquivo era **fixo** — sempre `<tmp>/_range.bin`.

Com um processo só, isso funciona há semanas. Com vários, é uma corrida:
o processo A escreve os bytes dele, o processo B sobrescreve o mesmo arquivo
antes de A chegar a ler, e A desmonta os bytes de B acreditando que são os
seus.

Foi exatamente o que aconteceu. Um censo rodado por um agente reportou

    0xF04E98    inc 1,WA

onde a ROM, naquele endereço, tem `1d 09` — uma chamada, não um `inc`. O
texto era real; o endereço era real; a associação entre os dois era lixo.

## Por que nada errado entrou na árvore

O conversor não aceita uma desmontagem porque ela "parece certa". Ele
re-codifica o texto e compara byte a byte com a ROM; se não bater, a faixa é
recusada. Uma desmontagem contaminada não bate com os bytes que ela alega
descrever, então o portão a rejeita.

Isso é verdade e é o motivo de nenhuma conversão ruim ter sido gravada. Mas
não é o mesmo que dizer que o bug era inofensivo. A desmontagem é a **entrada**
de tudo o que vem depois: os censos que dizem quais formas bloqueiam o
conversor, as contagens que priorizam o trabalho, as tabelas que eu cito.
Nada disso passa pelo portão de byte-match. Rodei esse conversor em paralelo
com agentes várias vezes ontem, e os números que saíram daí orientaram
escolhas.

Corrigido com um diretório por processo (`tempfile.mkdtemp`), verificado em
execução.

## O `inc` que é cinco instruções

O bloqueio número um do conversor, por número de faixas, era a forma `inc`.
O motivo é que um único texto impresso corresponde a mais de uma codificação:

    inc 1,WA   ==   d8 61   E TAMBÉM   d7 e0 61

São 352 textos assim, cobrindo 94% dos sítios. O texto sozinho não decide;
os bytes decidem. É por isso que a regra oferece várias grafias candidatas e
deixa a comparação com a ROM escolher — o conversor nunca "sabe" qual é a
certa, ele descobre.

A verificação está em `tools/spelling-probes/verify_inc_reg.py`: 6.336
codificações geradas a partir do **espaço de codificação**, não deste
firmware — 3.048 exatas, 3.288 sem grafia, **0 erradas** — e depois uma
varredura por quatro ROMs, 20.360 de 20.360 sítios byte-exatos.

## O controle negativo que valeu o esforço

O comentário do próprio backend do LLVM sugere que a contagem do `inc` é
codificada como `0x60+(n-1)`. É uma leitura plausível: eu teria adotado.

O probe transforma essa leitura num **controle negativo** — roda a mesma
varredura assumindo `n-1` e mede. Falha em 20.113 dos 20.360 sítios. A regra
correta é literal: o número impresso é o número codificado.

Um controle negativo não é burocracia. É a diferença entre "minha regra
acertou 20.360" e "minha regra acertou 20.360 e a alternativa óbvia erra
quase tudo". Só a segunda frase exclui a possibilidade de o teste estar
passando por acidente.

## E um comentário meu que era falso

No conversor, escrito por mim, estava:

    # ld/inc have no _erpb equivalent found yet.

É falso para o `inc`. As formas `_erp` existem, e as fontes da v9 que estão
no repositório **já continham** 76 `inc1b_erp`, 36 `inc1w_erp` e um
`incb_erp` — a evidência contra a minha própria frase estava versionada, em
arquivos que eu tinha aberto várias vezes.

Um comentário errado no código não dispara nenhum teste. Ele só ensina a
próxima pessoa — que hoje era eu — a não tentar.
