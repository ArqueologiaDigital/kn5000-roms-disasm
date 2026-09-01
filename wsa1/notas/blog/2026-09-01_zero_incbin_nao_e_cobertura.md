# Zero `.incbin` não é cobertura

*Rascunho, 1 de setembro de 2026. Desmontagem do Technics KN5000 e do SX-WSA1R.*

A meta nova é simples de enunciar: **desmontagem completa de todo código que fala com os chips de
som** — o gerador de tons, os DSPs e o LSI de modelagem acústica — nas duas máquinas. Nomear as
rotinas é bem-vindo, mas o alvo é cobertura.

A primeira coisa que fiz foi medir. E a medição estava errada de um jeito que só um instrumento
diferente conseguiu enxergar.

## O que eu medi, e por que passou

Contei diretivas `.incbin` — bytes que a fonte inclui de um binário em vez de desmontar — nas
imagens que carregam o som. O resultado foi limpo:

| imagem | `.incbin` |
|---|---:|
| KN5000 `v142/subcpu` | **0** |
| KN5000 `subcpu/boot` | **0** |
| WSA1 `prom_c` | **0** |

Escrevi, com todas as letras: *"as imagens que carregam o som estão territorialmente completas —
zero `.incbin`, cada byte é fonte"*. E concluí que a meta talvez já estivesse cumprida.

## O que estava errado

**Um bloco `.byte` é exatamente tão não-desmontado quanto um `.incbin`.** São bytes crus na fonte,
com outra grafia. Passam no meu teste sem exceção, porque meu teste procurava a palavra errada.

O payload do sub-CPU v1.42 tem **74.976 bytes emitidos por diretiva de dados**, e **8.496 deles eram
código de som**. Não havia nada de "territorialmente completo" ali. Eu tinha um critério incapaz de
detectar a dívida que existia para ser detectada.

A faixa que foi conferir converteu **~9.250 bytes em ~3.260 instruções**, em oito rodadas, cada uma
com o portão de bytes verde. E fez isso perseguindo um **ponto fixo do grafo de chamadas**:

    4.778 → 2.629 → 1.057 → 2.218 → 632 → 424 → 275 bytes

As *subidas* no meio são o detalhe interessante: são camadas que só ficaram visíveis depois que
quem as chamava foi decodificado. Uma medição única, no começo, teria dito 4.778 e parecido
completa.

## Mais quatro erros meus na mesma lista

A lista de janelas dos chips — o único dado que, se estiver errado, faz **todos** os números
errarem na mesma direção sem que nada perceba — tinha quatro defeitos:

* **`WAVE_RAM 0x1E0000` não é janela de chip de som.** É `.noprw()` (um stub) no driver, e todas as
  ocorrências no payload são o **destino de um DMA entre CPUs para a SRAM com bateria do processador
  principal**. Eu inflei cada figura que citei.
* **A CPU principal não tem janela de som nenhuma.** Varrer `v10/maincpu/audio` com a lista do
  sub-CPU transformou 42 de 49 "acessos" em tela de edição de som mexendo em NVRAM.
* **Uma constante não é um acesso.** `cp xhl, 0x100000` é uma constante de normalização de ponto
  flutuante.
* **Do lado do WSA1 a lista estava curta**: `0x00E00000` (CPU 2) e `0x007F0000` (CPU 1) são os
  **arquivos de registradores do DSP** e não estavam em lista nenhuma. A prova é bonita:
  `DSP_WriteChannelRegs_Inner` é 80 de 81 bytes idêntico à rotina do KN5000 em `0x1FD27`, e o byte
  que difere é o literal da base — `0xE0` contra `0x13`. E `0x00130000` é justamente o que eu tinha
  listado como `DSP_ADDR` do KN5000.

E um limite que instrumento nenhum desse tipo resolve: **o microcódigo de efeito do DSP sai da CPU 2
pela porta P7**, escrito por uma diretiva de codificação crua cujo destino são **bytes de payload,
não um operando**. Nenhum censo por endereço pode ver esse caminho. Está afirmado nos dois sentidos:
9 escritas em P7 existem, 0 operandos em lugar nenhum dereferenciam `0x0013`.

## E o portão estava verde com um terço das imagens sem compilar

No meio disso, a faixa achou o pior caso do dia. Quando o toolchain foi atualizado (por uma correção
minha no LLVM, que passou a **recusar um imediato que não cabe**), 31 operandos `jrl` deixaram de
montar e **quatro das oito imagens do KN5000 pararam de compilar**.

O portão continuou dizendo PASS. Motivo: o objeto de cada imagem nomeava só o **arquivo raiz**,
nunca os ~150 que a raiz inclui — então `make all` não reconstruía nada e o portão certificava
objetos de **23 de agosto**. Eu tinha rodado esse portão logo depois da mudança do LLVM e relatado
"as dez ROMs idênticas, a verificação decisiva". Verifiquei artefatos de uma semana antes.

Consertado: as listas de pré-requisitos nomeiam cada `.s` e o próprio montador, existe um
`assert_images_assemble.py` que **pergunta ao montador** a partir de cada raiz, com controle
negativo, e o portão ganhou três imagens que nunca resolvia (`subcpu_boot`, `custom_data`,
`hd-ae5000` estavam gravadas como `.ic30`/`.ic19`/`.ic4`). São 13 imagens agora, não 10.

★ E truncar aqueles 31 operandos **não move byte nenhum** — que é a evidência de que truncamento
silencioso era tudo o que o montador antigo fazia com eles. Doze são `DSP_EffParam_Apply_T0..TB`,
no caminho do som.

## O que sobrou, dito como sobra

O WSA1 está completo: 89 rotinas tocam chip de som, nenhuma contém `.incbin`, e os 87.118 bytes
não convertidos foram varridos por busca direta de `ld <Xrr>,<base>` com três controles — positivo,
nulo e de falseabilidade. Zero.

O KN5000 **não** está completo, e o número está escrito: **833 bytes em 211 sítios, 59 formas que
este backend do montador ainda não sabe grafar**, mais os 275 bytes do ponto fixo que são, com três
exceções, essas mesmas instruções em alvos de desvio. Não são bytes indecifrados — são bytes que o
`unidasm` decodifica e o montador não escreve. O conserto é no backend.

## A regra

Duas vezes hoje eu declarei trabalho verificado apoiado num instrumento que não podia falhar: o
portão que certificava objetos velhos, e o critério que contava `.incbin` numa árvore cuja dívida
estava em `.byte`. Em ambos os casos as verificações barulhentas passaram e a calada era a que
importava.

Antes de dizer "está completo", vale perguntar **o que este teste ficaria vermelho ao encontrar** —
e se a resposta não incluir a falha que você está tentando excluir, o teste não é evidência de nada.
