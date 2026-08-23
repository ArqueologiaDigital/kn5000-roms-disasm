# O critério que reprovava tudo

*Rascunho — não publicado.*

Os blocos binários deste projeto passam por uma auditoria que pergunta: *este
arquivo carrega alguma estrutura que um formato melhor exporia?* Se não carrega,
ele merece continuar sendo bytes. A auditoria classificava **cada arquivo
inteiro**, e é aí que ela não tinha poder nenhum.

`naka_widget_descriptors.bin` tem 150.888 bytes e passava como OPACO. O
comentário impresso logo acima do próprio `.incbin` documenta quatro tabelas
dentro dele. Uma é uma tabela de 128 ponteiros de 32 bits, e **128 de 128** caem
na faixa de endereços da ROM. Meio kilobyte não move a estatística de 150 KB.

Uma varredura por janelas achou 45 regiões desse tipo. Este texto é sobre as
três vezes seguidas em que, ao tentar decidir quais delas eram convertíveis, eu
escrevi um critério que reprovava **todas** — e sobre a única pergunta que
detectou os três.

## Três reprovações limpas, nenhuma culpa dos dados

**Primeira.** Para saber se um bloco podia ser fatiado, contei em quantos lugares
ele é incluído: se for um só, há um lugar para editar. Deu zero em 45. O motivo
é que eu varri `v7/maincpu/**/*.s` e `*/**/*.s` na mesma lista, e o segundo
padrão já casa com todos os arquivos do primeiro. Todo bloco parecia incluído
duas vezes.

**Segunda.** Resolvi as palavras contra a tabela de símbolos… da v7, para blocos
da v7, v9 e v10. A mesma região dava 100% numa revisão e 54,7% nas outras. v7, v9
e v10 são ligações diferentes; resolver um ponteiro da v9 no espaço de endereços
da v7 é um erro de categoria que responde "não é tabela" para tabelas que são.

**Terceira.** Exigi que os ponteiros estivessem em ordem **crescente**. A tabela
que resolve 100% dos símbolos deu 0% nesse teste — porque ela é **decrescente**,
exatamente como a `DspEffectName_PtrTable` que a própria documentação do projeto
descreve como armazenada em ordem decrescente de efeito.

Os três imprimiram números confiantes. Nenhum era sobre o firmware.

O que os pegou foi sempre a mesma observação: **quando um critério reprova a
população inteira, desconfie do critério.** É o mesmo hábito que já tinha achado,
mais cedo no mesmo dia, uma constante `DATA = 0` num território codificado
`1/2/3` — um filtro que não tinha como deixar nada passar, e que por isso
imprimia um zero impecável.

## A quarta vez foi diferente, e é a interessante

Corrigidos os três, sobrou um piso que parecia sólido: só converter uma região se
90% das palavras resolverem para um símbolo real. O nulo é 1,9% — um endereço
qualquer da faixa acerta um símbolo com essa frequência —, então 90% é evidência
forte de verdade.

A maior região do conjunto reprovava com **0%**.

`naka_effects_seq.bin`, 2.560 bytes, 640 palavras, nenhuma acertando símbolo
nenhum. Pelo critério, não é uma tabela de ponteiros.

Só que eu já tinha olhado o que havia no destino delas. Os alvos começam com
`1f 00 60 01`, `2b 00 60 01` — e a assinatura `XX 00 60 01` é literalmente o que
a macro `naka_header` deste projeto emite. São registros de widget.

Medindo por conteúdo em vez de por símbolo: **83% dos 640 alvos carregam a
assinatura, contra um nulo de 0,173%** em deslocamentos aleatórios da ROM. Um
enriquecimento de 479 vezes.

A tabela é real. O critério é que era cego a uma classe inteira — e cego por
construção, não por descuido: **os alvos são endereços no interior de outros
blocos `.incbin`, e o interior de um bloco não tem símbolo nenhum.** Nunca ia
resolver. Um piso de resolução simbólica excluiria para sempre a tabela mais
clara do conjunto, e pareceria rigoroso fazendo isso.

Um teste que não pode passar reprova com a mesma cara de quem reprova com razão.

## O que entrou

Duas vias independentes de qualificação: resolução simbólica (nulo 1,9%) **ou**
assinatura de registro no destino (nulo 0,17%). Com as duas, 12.288 bytes de
tabelas de ponteiros saíram de dentro dos blocos opacos. 1.107 de 1.152 palavras
da primeira leva viraram nomes; a região de 512 bytes em
`naka_widget_names_charmap` hoje se lê `IconName_i11` … `IconName_i128`.

O que é fatiado é a **diretiva**, não o arquivo: `.incbin "f", skip, count`. O
`.bin` continua byte a byte o despejo que sempre foi, porque o arquivo é o
artefato e a diretiva é só a nossa descrição dele.

E uma verificação minha que não podia falhar quase entrou junto: antes de
escrever, eu comparava os bytes reconstruídos com os do bloco — só que eu montava
os reconstruídos a partir das mesmas palavras que tinha lido do bloco. Comparava
o bloco com ele mesmo. Agora a conferência passa pelo texto que vai ser escrito,
resolvendo cada **nome** de símbolo de volta pelo ELF.

---

Reprodução: `scripts/analysis/l3_embedded_structure_scan.py`,
`tools/spelling-probes/qualify_embedded_ptr_regions.py`,
`scripts/converters/convert_embedded_ptr_regions.py --controls`
(este último remede os dois nulos: 0,173% e 1,879%, n=200.000).
