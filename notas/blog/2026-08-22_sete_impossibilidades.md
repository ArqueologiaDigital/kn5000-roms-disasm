# Sete impossibilidades

Passei um dia inteiro medindo se a desmontagem do KN5000 está pronta. Ela não
está. Mas o resultado mais útil do dia não é o placar — é que **sete coisas que
eu tinha declarado impossíveis não eram**, e todas erraram do mesmo jeito.

## A lista

| eu escrevi | o que era |
|---|---|
| "o firmware do KN5000 nunca lê `.LSW`" | lê — é o tipo de arquivo 0, com handler em toda revisão |
| "o backend não tem essas instruções" (4×) | tinha; eram grafias que eu não havia tentado |
| "3.627 nomes posicionais pendentes" | zero sem significado; 3.285 são sub-rótulos legítimos |
| "um erro de nome confirmado" | o nome estava certo |
| "aptidão de nome é indecidível" | é decidível para uma classe; achou quatro erros reais |
| "os campos do `.LSW` precisam da bancada" | 168 nomes de som saíram da ROM |
| "o lado do painel não pode ser especificado" | é derivável quase todo |

Sete afirmações, sete medições corretas por baixo, e em cima de cada uma uma
conclusão que ia longe demais.

## O formato da falha

Em nenhum dos casos o número estava errado. `3.627` era exatamente quantos
símbolos terminam em `_0xHEX`. O firmware realmente escreve 3.648 bytes de
`.LSW` enquanto os disquetes têm 22.528. A auditoria de `fopen` realmente achou
um candidato que não se sustentou.

O erro estava sempre no passo seguinte: **generalizar de uma medição para uma
impossibilidade.** "Minha auditoria não decidiu isso" virou "isso é indecidível".
"Este firmware não escreveu esses arquivos" virou "esses arquivos são de outro
formato" — e eles são o mesmo formato, numa revisão diferente, com os 37 rótulos
alinhados na mesma ordem em todos os sete disquetes.

Uma afirmação de impossibilidade é ela própria uma verificação. E, como qualquer
verificação, pode estar cega para o próprio assunto.

## O que quebrou cada uma

Não foi esperteza. Foi tentar.

* **`.LSW` tipo 0**: o código nunca diz `"LSW"`, diz o índice `0`. Uma busca
  pela string não podia encontrá-lo.
* **As grafias**: uma linha de assembly refutava cada alegação em segundos.
  `and (xix), 0x7f` não existia; `andmi8 (xix), 0x7f` existia e sempre produziu
  os bytes certos.
* **Os nomes**: olhar o que os 3.627 realmente são, em vez de contá-los.
* **A aptidão**: 512 rótulos declaram o valor de retorno como um *número*. Isso
  é uma afirmação verificável sobre o código. `MainGetEvent_ReturnZero` cai em
  `lds hl, 1` e retorna 1.
* **Os campos**: a área de painel é ela mesma um fluxo TLV, e o esquema é uma
  tabela na ROM — com tipo, máscara, mínimo, máximo e default por campo. O
  seletor de som tem `min=0 max=167 default=21`, e o slot 21 se chama
  `Jazz Ac.Guitar`.
* **O painel**: o driver do bootloader e a pilha em execução são *a mesma
  implementação em dois endereços de link*. Um lado conhecido restringe o outro
  muito mais do que eu admitia.

## O que ainda não dá

Vale dizer o que sobrou, porque uma lista só de vitórias mentiria pelo recorte:

* As opções 128–167 do seletor de som **não têm nome em ROM nenhuma** — são
  memórias de usuário em RAM com bateria.
* Dez dos 24 bytes do registro por-parte estão mortos: `+10` não tem descritor
  nem código, e nove outros são declarados e nunca tocados.
* Quatro coisas do protocolo do painel realmente precisam de hardware. Agora
  estão nomeadas, o que é melhor que "precisa de analisador lógico".
* O verificador que licenciou parte disso tinha um portão frouxo — janela de
  ±12 linhas em vez de escopo de rotina — e passava por sorte de layout. Está
  anotado no próprio arquivo.

## Placar

Cinco dos oito níveis passam com testes que podem falhar. Os três que faltam
ficaram menores e mais precisos hoje, e dois deles encolheram porque eu estava
errado sobre serem intransponíveis daqui.

A desmontagem não está pronta. Mas "não está pronta" agora vem com endereços.
