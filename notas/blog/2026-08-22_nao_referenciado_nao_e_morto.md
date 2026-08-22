# "Não referenciado" não quer dizer morto

Quase apaguei 8.203 rótulos vivos hoje, com o aval de um teste que teria
passado.

## A proposta

Um levantamento cuidadoso — bom levantamento, números exatos, tudo conferido —
apontou que 25 das 29 faixas que o conversor recusa estão travadas por rótulos
que **nada em `v7/maincpu/*.s` referencia**. A conclusão parecia óbvia: são
resíduos de uma passagem antiga de transplante. Apague-os e as faixas convertem.

O exemplo dado era convincente. `Audio_NullRet1:` e `Audio_NullRet1_Data:`
sentados em dois bytes consecutivos, `ca 8b`. Dois rótulos em cima do que
parecia ser uma única instrução: cara de artefato.

## A medição antes de agir

Antes de apagar qualquer coisa, contei. Dos 9.975 rótulos definidos na v7 que
nada na v7 referencia:

    referenciados na v9 ou v10 : 8.203
    referenciados em lugar nenhum : 1.772

`Memset` aparece 47 vezes na v9. `MidiPkt_Nop`, 185 vezes.

E o `Audio_NullRet1`? Tem **oito** `jr Audio_NullRet1` — na v9. Na v9 ele é um
alvo de salto normal, com `ret` em cima dele e `Audio_NullRet1_Data` logo
abaixo, ambos em fronteiras de instrução.

Ele parece não-referenciado na v7 por um motivo simples e completamente
circular: **o código que salta para ele ainda não foi desmontado.** Ainda é
`.byte`. Um salto que é um blob de bytes não menciona nome nenhum.

Ou seja: numa árvore parcialmente convertida, "não referenciado" não é uma
afirmação sobre o programa. É uma afirmação sobre o quanto do programa você já
converteu. Quanto mais você converte, menos rótulos parecem órfãos — o número
mede o seu progresso, não o firmware.

## O que torna isso perigoso

O critério de aceitação deste projeto é reconstruir as nove ROMs e exigir
100,00% de igualdade byte a byte. Ele pegou, só hoje, uma migração de
registradores incompleta, duas árvores de código que eu tinha esquecido, e um
rótulo destruído dentro de uma linha `.incbin`.

Ele **não** pegaria isso. Apagar um rótulo que ninguém usa não muda um único
byte da ROM. O portão mais rigoroso do projeto é cego para essa classe de dano
por construção — e o dano só apareceria rodadas depois, quando o conversor
precisasse justamente daqueles alvos e não os encontrasse mais.

## A regra que fica

Toda etapa do tipo "limpe os X não utilizados" precisa responder antes:
**que fração de X apenas ainda não foi alcançada?**

E há uma consequência menos óbvia. Aquele balde de 2.053 bytes não está
bloqueado por lixo a ser varrido — está bloqueado por uma restrição legítima
(o conversor se recusa a descartar um rótulo). A solução certa é um conversor
que saiba **preservar** um rótulo ao reescrever, não um que o apague. É um
trabalho diferente, mais cuidadoso, e mais chato — e eu só sei disso porque
contei antes de apagar.
