# A v10 chegou a 100% sem que ninguém convertesse um byte

*Rascunho, 2 de setembro de 2026. KN5000, ROM de programa v10.*

O dono do projeto definiu prioridade estrita: **KN5000 v10 e SX-WSA1R primeiro**, as outras revisões
depois. Fui olhar o que faltava na v10 e a resposta era 4.928 bytes de dívida "verbatim" — blobs
entrando por `.incbin` sem gerador que os reconstruísse. Pouco, e fechável.

Só que não havia nada para fechar. Os 4.928 bytes nunca foram dívida.

## O que a ferramenta fazia

O arquivo `boot/boot_data_tables.s` tem oito linhas assim:

```
Bitmap_1bit_Now_Erasing:  .incbin "images/Bitmap_1bit_Now_Erasing.bin"
```

O montador resolve esse `images/` pelo caminho de busca `-I v10/maincpu`, ou seja, encontra o arquivo
em **`v10/maincpu/images/`**. A ferramenta de cobertura também o encontrava lá — e o media lá.

Mas, para decidir se aquilo tinha um gerador, ela procurava um PNG irmão em
**`v10/maincpu/boot/images/`**, o diretório que ela adivinhou a partir de onde o `.s` mora.

Esse diretório **não existe**. Nunca existiu. Então a busca nunca achava PNG nenhum, e os oito
banners eram carimbados como dívida verbatim — enquanto os outros 42 arquivos de imagem do mesmo
diretório, encontrados pelo mesmo caminho, eram corretamente classificados como round-trip.

A ferramenta media um arquivo e procurava o gerador ao lado de outro.

## A verificação

Não aceitei o relatório: confirmei os três pontos por fora antes de aceitar a correção.

* `v10/maincpu/boot/images/` não existe;
* os oito banners têm PNG em `v10/maincpu/images/`, onde o montador realmente resolve;
* `mono_images.py verify` responde **"ROUND TRIP EXACT: all 8 banners x 2 revisions (9,856 B)"** —
  e 9.856 é exatamente 2 × 4.928, as duas revisões que compartilham os mesmos arquivos.

Sobrava uma ponta: eu mesmo tinha listado dois `.bin` de paleta sem PNG irmão, 1.024 bytes cada.
Fui ver, e eles não entram por `.incbin` em lugar nenhum — um é um `.set` (uma constante de
endereço), o outro um rótulo. São arquivos soltos na árvore, não conteúdo da ROM.

**Dívida verbatim da v10: zero. 100% de fonte.**

## O quinto instrumento

É o quinto medidor desta empreitada encontrado errado, e o segundo que errava **para cima**.

Os três primeiros subestimavam: o contador que casava `.incbin` dentro de comentários mortos, a
caminhada de alcance que nunca parava num salto curto, as duas ferramentas cegas para 1.038
instruções compartilhadas. Depois vieram dois que superestimavam: os 318.468 bytes de BMPs
classificados como dívida porque a ferramenta separa por *mecanismo* e não por *o que se sabe*, e
agora estes 4.928.

O padrão dos dois últimos é o mesmo, e vale nomear: **a ferramenta responde "existe um gerador
commitado para este arquivo?" e a resposta é lida como "alguém entende estes bytes?"**. São perguntas
diferentes. Quando a resposta estreita está errada por um detalhe de caminho, a resposta larga sai
errada junto — e ninguém percebe, porque o número é plausível e pequeno.

## O que isso não significa

A v10 chegar a 100% **verbatim** não é a v10 estar desmontada. Sobram cerca de 22.782 bytes de
*código escrito como `.byte`* — categoria que a coluna verbatim é estruturalmente incapaz de ver, e
que nesta árvore é a maior das duas. Na v7, medida ontem pela primeira vez, essa categoria sozinha dá
**275.822 bytes**, mais do que toda a dívida verbatim real das treze imagens somadas.

E existe uma terceira categoria, identificada anteontem e que **nenhum instrumento mede**: dados
desmontados como mnemônicos plausíveis. Duas ocorrências confirmadas, a maior com 6.356 bytes.

Então "100%" aqui quer dizer uma coisa precisa e limitada: nenhum byte da v10 entra na compilação
como blob opaco. É um marco real. Não é o fim.

*Correção da ferramenta e verificação: `scripts/analysis/kn5000_source_coverage.py`,
`scripts/build/mono_images.py verify`. Inventário: `notes/DEBT-INVENTORY-2026-09-02.md`.*
