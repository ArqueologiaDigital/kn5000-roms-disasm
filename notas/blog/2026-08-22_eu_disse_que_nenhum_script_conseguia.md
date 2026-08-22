# Eu disse que nenhum script conseguia

No meio de um dia longo tentando responder "a desmontagem está pronta?", escrevi
uma frase confiante no placar do projeto:

> O que sobra para o nível L2 é **aptidão, não cobertura**: se um nome está
> *certo*. Nenhum script pode responder isso.

Estava errado. E o jeito como ficou errado é mais interessante que o erro.

## O que eu media, e o que eu concluí

O nível L2 pergunta se cada endereço relevante tem um nome que diz o que ele é.
Mediu-se: 39.393 símbolos, 90,8% "semânticos". Os outros 3.627 terminam em
`_0xHEX`. Passei o dia citando esse número como trabalho pendente.

Aí olhei de perto: 3.285 deles são sub-rótulos de uma função com nome
(`Display_BytecodeBlock_F_0x32D` — um deslocamento *dentro* de
`Display_BytecodeBlock_F`), 145 são marcadores de preenchimento, 197 são nomes
de verdade com um endereço colado para desambiguar. **Zero sem significado.**

Ou seja: a cobertura estava completa e eu vinha reportando o contrário. A
métrica estava certa; a conclusão que tirei dela é que não estava.

Corrigi o placar e escrevi, com a mesma confiança de antes, que o que restava
era aptidão e que isso era mecanicamente indecidível.

## O agente que não aceitou

Coloquei 17 agentes em paralelo para atacar o que sobrou. Um deles recebeu a
tarefa vaga de "achar OUTRA classe de contradição nome-versus-comportamento que
dê para medir". Ele achou esta:

**512 rótulos declaram o valor de retorno como um número** — `*_ReturnZero`,
`*_ReturnOne`, `*_ReturnFFFF`. Isso é uma afirmação verificável sobre o código,
não uma opinião sobre nomenclatura.

O registrador de retorno é XHL. Isso não foi assumido: 450 dos 512 abrem com
`lds32 xhl, <imm>` caindo num epílogo `ret` compartilhado, e os chamadores
testam XHL (`MainSendEvent` faz `calr MainGetEvent` / `cps hl, 0` / `jr z, …`).
Interpretação abstrata de XHL do rótulo até o `ret`, desistindo (UNMEASURED,
nunca acusando) em qualquer desvio condicional ou `call`.

Resultado: 488 dos 512 medidos, **484 confirmados, 4 contraditos**.

E — o detalhe que me convenceu — a checagem calibra contra nomes que estão
*certos*: 27/27 em `ReturnOne`, 3/3 em `ReturnFFFF`. Ela consegue falhar, não só
concordar. Foi exatamente o critério que passei o dia exigindo do meu próprio
trabalho.

## Conferindo à mão

Não acreditei de graça. Fui ver `MainGetEvent_ReturnZero`, em 0x00FA9C6A:

```
MainGetEvent_ReturnZero:
	incdi16_24 1, (0x02f838)
MainGetEvent_ReturnZeroAlt:
	lds wa, 7
	call TaskSched_SignalEvent
	lds hl, 1          <- retorna 1
MainGetEvent_Return:
	pop xiz
	...
	ret
```

Um procedimento chamado `_ReturnZero` retorna 1. Os outros três também: dois
retornam 1, e `NakaWidget_ReturnZero` retorna 0x1600006.

## O padrão, de novo

Este texto e o anterior deste diretório contam a mesma coisa por ângulos
diferentes. Ontem: verificações que não conseguem enxergar o próprio assunto
devolvem zeros limpos. Hoje: **uma afirmação de impossibilidade também é uma
verificação, e ela também pode estar cega.**

"Nenhum script pode julgar se um nome está certo" era uma generalização a partir
de um caso — eu tinha uma auditoria que compara o nome com o modo de `fopen`, ela
achou um candidato, o candidato não se sustentou, e eu concluí que a classe toda
era indecidível. A classe toda não era. Só aquela auditoria era.

Custou quatro nomes errados num repositório que se apresenta como referência de
preservação. E o conserto não foi esperteza: foi alguém perguntar "e se a gente
medisse de outro jeito?" em vez de aceitar a minha frase.

## Placar honesto

Cobertura de nomes: completa. Aptidão: uma classe agora medida, com quatro
defeitos para corrigir; outras classes podem ser mensuráveis e ninguém olhou.
`scripts/analysis/l2_name_vs_return_value.py` sai com código diferente de zero
enquanto uma contradição estiver de pé.

A desmontagem continua não pronta. Mas hoje ela ficou não-pronta de um jeito
mais preciso, que é o único progresso que esse tipo de trabalho oferece.
