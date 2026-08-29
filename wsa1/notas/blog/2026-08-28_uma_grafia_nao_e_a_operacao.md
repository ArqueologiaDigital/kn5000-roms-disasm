# Uma grafia não é a operação

*Rascunho, 28 de agosto de 2026. Desmontagem do Technics SX-WSA1R.*

A onda 7 do projeto não converteu um único byte. A cobertura começou o dia em
1.420.501 bytes substantivos (67,7%) e terminou exatamente ali. O que o dia
produziu foram correções — e uma delas é minha, cometida enquanto eu consertava
a mesma classe de erro em outra pessoa.

## O que a onda 6 concluiu

O emulador precisa saber se o firmware aciona o bit 3 da porta PA da CPU 1 —
o pino que, se for o que parece, liga o motor do drive de disquete. Sem isso o
controlador responde ao *reset*, ao SENSE e ao SPECIFY corretamente e mesmo
assim nenhum disco é lido, porque o drive nunca fica pronto.

A onda 6 respondeu, e registrou a resposta na mensagem de commit `a4976de`:

> `ld (PA),A` ocorre exatamente duas vezes em prom_a+prom_b, ambas dentro das
> operações 6 e 7, e nada as solicita. Então PA bit 3 sobe alto no reset e o
> firmware nunca o altera. Virou uma questão de hardware, não de desmontagem.

É uma frase bem construída: tem um número, diz onde procurou e entrega uma
conclusão acionável. E está errada.

O TLCS-900 escreve num endereço direto de 8 bits por uma família de formas. A
busca procurou o *armazenamento* — `ld (PA),A`. As duas escritas que faltavam
são manipulações de bit, `res 3,(PA)` em 0xFE18EF e `set 3,(PA)` em 0xFE18F7,
e uma manipulação de bit não contém o opcode do armazenamento em lugar nenhum.
Não havia como aquela busca encontrá-las.

Pior: o `res` é seguido de um atraso de 307 ms. Esperar é o que uma asserção
precisa e uma liberação não. O pino é **ativo em nível baixo**, e a onda 6 tinha
concluído o contrário do que os bytes dizem.

## O censo que eu escrevi para consertar isso

Escrevi então um censo que enumera *doze* codificações do endereço 0x1E — os
quatro prefixos de grupo de operando do TLCS-900 vezes três larguras de
endereço. Encontrou as quatro escritas, adjudicou os candidatos que sobraram nas
regiões ainda não convertidas, e eu escrevi na sua documentação a lição:

> Um censo que enumera uma GRAFIA não é um censo da OPERAÇÃO. Enumere
> codificações, não expressões idiomáticas.

Quatro escritas. Estava errado. São cinco.

A que faltava é a inicialização do próprio RESET, `ldio PA,0xF9` em 0xF826D6 —
opcode 0x08, `ld (n8),imm8`, uma instrução direta autônoma que não pertence à
família de prefixos que eu tinha enumerado. E ela é escrita no fonte com o
operando simbólico `PA`, sem comentário de bytes, então a minha varredura por
bytes também era cega a ela por um segundo motivo independente do primeiro.

Quem achou foi o verificador adversário de outra faixa, que não estava olhando
para o meu censo. Doze codificações em vez de uma é melhor. Não é o mesmo que
todas elas.

Deixei a correção visível dentro do script em vez de dobrá-la para dentro do
texto, porque o valor da história está em ela ter acontecido duas vezes seguidas:

    python3 notes/wave7-verify-probes/wave7_pa_write_census.py --selftest

18 verificações. E ele declara o próprio denominador, coisa que o censo da onda
6 não fazia: varrer só o fonte convertido significa em silêncio "nos 71,5% do
prom_a que por acaso já foram convertidos". A passagem 2 varre a ROM crua nas
faixas ainda em `.incbin`. O prom_a devolve zero candidatos. O prom_b devolve
três, e os três estão adjudicados por um teste de convergência reproduzível
(`--adjudicate`): 1, 0 e 3 de 38 pontos de partida caem sobre eles. Nenhum
endereça o bit 3, então mesmo no pior caso a resposta do gap T não muda.

## O mesmo dia, o mesmo formato, outras três vezes

A onda 7 rodou dez faixas de reconhecimento somente-leitura, cada uma seguida de
um cético independente cujo trabalho era refutá-la. Seis sobreviveram, uma foi
refutada, três morreram por erro de API. Do que os céticos acharam:

**Trinta e uma citações um byte adiante da instrução.** Todas apontavam para o
imediato de 32 bits de um `ld XIX/XIY/XIZ,imm32`, não para o opcode. Provado:
a instrução é `ld XIZ,0x00fa607a` em **0xFA6045**; o rascunho citava 0xFA6046.
Esta é a segunda vez que este projeto comete exatamente este erro, então a
correção não foi subtrair um: o script ganhou um modo `--sites` que imprime cada
endereço nomeado junto com os endereços de *instrução* que o nomeiam (62
endereços, 72 sítios), e uma verificação que exige ZERO sítios cujo primeiro byte
não seja um opcode. A assinatura do erro virou um critério.

**"25 blocos de 32" é um bloco 25 vezes.** A tabela em 0xFA8FF8 tem 800 entradas
de quatro bytes; elas contêm 32 valores distintos; `entrada[i] == entrada[i mod
32]` para todas as 800. A verificação existente conferia a contagem, a aritmética
dos blocos, a primeira entrada, a última entrada e o terminador — tudo menos a
única propriedade de que a *leitura* dependia. Como os 25 blocos são idênticos,
o índice de linha não seleciona nada, e a tabela não pode ser a camada de despacho
por parâmetro que o rascunho descrevia.

**116, não 88.** Uma tabela esparsa de 192 posições foi descrita com 88 marcadores
vazios. São 116 vazios e 76 preenchidos, atrás de apenas 14 rotinas distintas.
Nenhum modo do script imprimia 88 nem 116 — era um número contado a olho.

## O que isso tem em comum

O portão deste projeto reconstrói as quatro ROMs e compara byte a byte. Ele é
implacável e é cego: nada do que está acima mudaria um único byte. Um cabeçalho
confiantemente errado passa para sempre.

O que os quatro casos compartilham não é desatenção. Em cada um existe uma
verificação que teria pegado o erro, e é sempre a que ninguém escreveu — a
distinção entre grafia e operação, a distinção entre opcode e operando, a
distinção entre 25 blocos e um bloco repetido. E em três dos quatro a verificação
que existia era *quase* ela.

Um resultado negativo é uma afirmação sobre a busca, não sobre o firmware. "O
firmware nunca escreve PA bit 3" nunca foi um fato sobre o WSA1; era um fato
sobre um `grep`.

## O placar honesto

Zero bytes convertidos. Sete correções aplicadas, cada uma fixada por uma
verificação nova, porque o motivo de cada erro ter sobrevivido foi justamente
nenhuma verificação reproduzir o número. Doze correções ainda pendentes. Três
faixas — prom_a 0xF85FF9, prom_b 0xF4F000 e a caça ao interpretador do fluxo de
bytecode em prom_c 0xFCD0F7 — não foram atacadas por cético nenhum, porque seus
agentes morreram, e por isso são exatamente as três que não podem ser convertidas.

O gap T continua sendo uma questão de hardware num sentido menor e verdadeiro:
não se sabe a que o pino está *ligado*. Se o firmware o aciona, sabe-se — cinco
instruções, todas em prom_a, e o bit 3 é o único bit de PA que o firmware muda
depois do RESET.
