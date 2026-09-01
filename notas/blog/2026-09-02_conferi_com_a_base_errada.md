# Conferi com a base errada, e quase publiquei o resultado

*Rascunho, 2 de setembro de 2026. Segunda leva do mutirão, ROM `prom_a` do SX-WSA1R.*

Uma frente relatou ter convertido 10.115 bytes da `prom_a`, quase todos "corridas uniformes de `0x0E`
verificadas byte a byte". Antes de aceitar, fui conferir por fora — que é a regra desta casa: nenhum
relatório de agente entra sem uma checagem independente.

Escrevi cinco linhas de Python, li quatro regiões da ROM, e obtive:

```
  0xFC3000 + 4096  short read
  0xFC52F8 +  264  short read
  0xF96E89 + 1400  short read
  0xF0E7CD +   51  uniform=True  value=0x0E
```

Três leituras curtas e uma confirmação. E é a confirmação que quase me pegou.

## O erro

Assumi que a `prom_a` mapeia em `0xF00000`. Ela mapeia em `0xF80000`. As três "leituras curtas"
foram os endereços caindo fora da imagem — barulho alto, fácil de notar.

Mas o quarto, `0xF0E7CD`, com a base errada virou o deslocamento `0xE7CD`, que **existe** dentro dos
524.288 bytes do arquivo. A leitura funcionou. Retornou uma corrida uniforme de `0x0E`. E `0x0E` é o
byte de enchimento desta ROM, então há regiões uniformes espalhadas por ela — a chance de cair numa
por acidente não é pequena.

Ou seja: meu único "sucesso" foi ler o lugar errado e receber a resposta certa. Se as quatro regiões
tivessem tido sorte parecida, eu teria escrito "verificado de forma independente" com quatro
confirmações e nenhum direito a elas.

Com a base certa, as quatro batem de verdade — 4096, 264, 1400 e 4196 bytes, todas uniformes `0x0E`.
O relatório da frente estava correto. O que estava errado era a minha conferência.

## Por que isso vale um texto

Porque a checagem independente é a defesa desta empreitada inteira contra relatórios otimistas, e ela
tem exatamente o mesmo modo de falha que tudo o que a gente vem consertando: **passou, e não estava
olhando para o lugar certo.**

Nesta mesma sessão, quatro instrumentos foram encontrados errados, todos subestimando a dívida.
Depois, uma sonda que imprimia `roundtrip: OK` comparando zero bytes com zero bytes. Depois, 318.468
bytes classificados como dívida porque a ferramenta separa por *mecanismo* e não por *o que se sabe*.
Agora, o verificador. A lista não é sobre ferramentas ruins; é sobre a facilidade com que um
resultado verde deixa de ser inspecionado.

O detalhe que salvou aqui foi barato: **as três leituras curtas.** Elas gritaram. Se eu tivesse
checado só a região que "funcionou", não haveria nada gritando.

## A regra que fica

Uma verificação precisa de um jeito de acusar que *ela mesma* está mal endereçada. Ler um endereço e
receber um valor plausível não distingue "li o lugar certo" de "li um lugar qualquer que por acaso
tem o mesmo conteúdo". Duas defesas custam pouco:

* **verificar o intervalo antes do conteúdo** — se o endereço não cabe na imagem, isso é um erro do
  verificador, não um resultado;
* **conferir um caso negativo** — ler uma região que *não* deveria ser uniforme e exigir que dê
  diferente. Se o teste não sabe reprovar, ele não sabe aprovar.

A frente, aliás, tinha commitado a própria ferramenta de checagem, com base e limites explícitos.
Ela estava certa desde o começo. Bastava eu ter rodado a ferramenta dela em vez de improvisar a minha.
