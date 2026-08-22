# O auditor que não podia reprovar

Este projeto tem uma especificação do que significa uma desmontagem estar
"pronta", e um placar que mede cada critério. Hoje o placar andou **para trás**:
uma linha que estava marcada como aprovada passou a reprovada.

É o movimento mais útil que ele fez o dia inteiro.

## A linha

O critério §3 diz, com estas palavras: *todo `.incbin` restante está na lista de
LEGÍTIMOS, **com seu formato documentado***. A ideia é séria — um bloco binário
incluído na montagem só se justifica se ele for mesmo um binário opaco, sem uma
forma melhor e legível por humanos.

O script de auditoria roda, percorre 873 diretivas e conclui: **0 bytes de
blob ilegítimos**. Verde.

Só que 790 dessas 873 são justificadas por uma única regra:

    (('generated/', 'romslices/'), 'slice gerada ou commitada sem fonte')

Isso é um teste de **prefixo de caminho**. Um blob é legítimo porque está numa
pasta com determinado nome. Para 790 diretivas — 90% do total — a verificação
**não tem como reprovar**.

E há uma segunda metade da frase que ninguém estava testando: *"com seu formato
documentado"*. Não havia verificação nenhuma para isso. A linha media metade do
que dizia medir, e a metade que media, media por nome de pasta.

## O que aparece quando se mede os blocos

Troquei o teste de caminho por um classificador que olha os bytes. Com dois
controles negativos, porque o primeiro que escrevi não servia (ele rodava sobre
ruído uniforme e passava limpo justamente porque ruído uniforme não consegue
exibir o defeito que eu tinha).

O controle que funciona embaralha os bytes dos próprios blocos: mesma
distribuição, nenhum arranjo. Só uma classe sobrevive a isso — tabelas de
ponteiros:

    PTR_TABLE    real 61 arquivos / 8.440 B      embaralhado 0 / 0

Oito mil e quatrocentos bytes de **endereços de ROM guardados como bytes
opacos**, com nomes como `Naka_MainDispatch_Table`. A forma melhor existe e é
óbvia: `.long <símbolo>`, que de quebra revela o grafo de chamadas.

Então a linha reprova. Não porque a auditoria piorou — porque ela passou a
existir.

## O detalhe que dói

A especificação deste projeto tem uma seção chamada *"Anti-padrões que fingem
completude"*. Hoje eu acrescentei quatro, e o de número 12 é:

> **O portão que não pode passar.** De cada categoria de recusa, pergunte: algo
> neste balde poderia algum dia ser aceito?

Uma hora depois de escrever isso, encontrei o anti-padrão dentro da auditoria
de completude do próprio projeto. O verificador de completude continha o defeito
que o verificador de completude existe para pegar.

## O mesmo padrão, do outro lado

O conversor que transforma blocos `.byte` em instruções chegou hoje a um ponto
fixo de verdade: uma rodada que ganhou exatamente zero bytes. É tentador
escrever "convergiu" e passar adiante.

Mas convergiu não é terminou. Naquele mesmo relatório:

    159 faixas decodificam para um `ret` limpo e remontam byte a byte — e são recusadas
    recusadas  23  "faixa se estende além dos seus blocos"

Doze mil bytes que decodificam **corretamente**, verificados byte a byte, e
mesmo assim recusados — pela etapa de reescrita, não pela decodificação. E
aquele `23` ficou em exatamente 23 nas dez rodadas de duas execuções
diferentes, enquanto tudo em volta mudava.

Um contador de recusas que não se mexe enquanto o resto do mundo se mexe é a
mesma assinatura de um bug que hoje custou 18.412 bytes: uma condição que
recusava faixas perfeitamente boas com a mesma mensagem que uma faixa quebrada
produz.

## A moral

Um placar que só anda para a frente não é um placar, é um material de
divulgação. A pergunta que faltava não era "quantos critérios eu passei", e sim
**"qual dos meus critérios seria incapaz de me reprovar?"**

Essa pergunta, hoje, rendeu mais que qualquer avanço.
