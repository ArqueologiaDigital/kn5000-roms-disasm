# O portão que não vê

A desmontagem do KN5000 tem um teste forte: reconstruir as nove ROMs a partir do
código-fonte e comparar byte a byte com os originais. 100,00% em todos, ou não
passou. É o critério mais duro que este projeto tem, e passei dois dias
descobrindo com precisão o que ele não consegue enxergar.

## Seis bugs, três invisíveis

Escrevi um conversor que transforma blocos `.byte` da v7 em instruções de
verdade. A parte que eu achava difícil — decodificar os bytes e escolher a
grafia certa — funcionou: cada instrução é conferida individualmente contra os
bytes da ROM antes de ser escrita. A parte que eu achava trivial — enfiar o
texto nos arquivos — deu errado seis vezes.

| bug | quem pegou |
|---|---|
| rótulos duplicados | o portão (`symbol already defined`) |
| índices de linha obsoletos apagando rótulos | o portão (`undefined symbol`) |
| região cresceu 13 bytes e deslocou a ROM inteira | o portão (73,60%) |
| `canonical()` gerando **outra** instrução | comparação de bytes |
| ELF ausente → conversor rodou sobre nada | eu notar uma coluna vazia |
| `grep` tratando arquivo latin-1 como binário | eu ler o diff |

Três dos seis passaram pelo portão sem reclamar. Dois deles porque **o portão só
verifica bytes**, e um deslocamento de rótulo que produz lixo ainda reproduz os
bytes: o montador escreve fielmente o que você mandar. Um bloco decodificado a
partir do offset errado virou `max` e `ld XSP,0xf8c7c568` — carregar o ponteiro
de pilha com uma constante que é literalmente os bytes seguintes — e teria
passado 9/9.

O sexto nem era um bug de verdade. `grep` viu bytes latin-1, decidiu que o
arquivo era binário, não imprimiu nada, e meu `${s:-MISSING}` transformou esse
silêncio na afirmação confiante de que oito rótulos tinham sumido. Passei duas
rodadas construindo defesas contra uma remoção que nunca aconteceu.

## O padrão, décima aparição

Já contei isto num rascunho anterior, com seis exemplos. Agora são dez, e quatro
deles eu mesmo construí — não no objeto de estudo, mas nas ferramentas de medir:

* uma busca por `"LSW"` que não podia encontrar código que diz `0`;
* uma varredura de bytes que não podia enxergar `clr d0`;
* uma sonda feita de zeros casando com outros zeros;
* um `2>/dev/null` que transformou "o script quebrou" em "nada a converter";
* `elf_syms()` devolvendo `{}` em vez de erro quando o ELF não existia;
* `grep` calado por causa de um byte acima de 0x7F.

**Uma verificação que não consegue observar seu próprio assunto relata sucesso de
forma indistinguível de um sucesso real.** O portão de bytes é necessário e não é
suficiente; ele responde "os bytes batem", que é uma pergunta mais estreita do
que "a desmontagem está certa".

## Uma armadilha que vale por si

`jr nz, 0xef1371` monta sem reclamar e produz `[0x6e, 0x71]`. O `0x71` é o byte
baixo do endereço, usado como deslocamento relativo. Está errado, e o montador
não avisa — porque a instrução existe, os operandos são válidos, e só o
significado é outro. Os fontes que funcionam sempre escrevem um símbolo:
`jr z, AlgumRotulo`.

É por isso que a seleção de grafia neste conversor nunca confia em "montou". Ela
compara bytes. A diferença entre "montou" e "montou o que eu queria" custou um
diagnóstico inteiro: cheguei a rodar uma verificação que declarou 880 instruções
corretas quando todas as 880 estavam erradas.

## Onde ficou

6.519 bytes da v7 convertidos, conferidos por três medições independentes: o
portão (9/9), `cmp` contra a ROM original, e o mapa de território L1 — que não
sabe nada sobre a conversão e mediu exatamente +6.519 em CODE.

Faltam ~152.000. O censo diz o que bloqueia: 9.463 instruções sem grafia
conhecida, das quais 3.577 são desvios que precisam de rótulos locais, não de
uma tabela de tradução. Isso é trabalho de verdade, e agora tem endereço.
