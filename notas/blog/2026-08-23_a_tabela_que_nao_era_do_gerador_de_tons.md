# A tabela que não era do gerador de tons

*Rascunho — não publicado.*

A pergunta que abriu o dia não era minha. O dono do projeto está com uma
implementação parada do gerador de tons e lembrou de um incômodo:

> não sabíamos bem como lidar com uma inicialização de um bloco grande de dados
> que a gente copiava direto da ROM, o que soava como atravessar fronteira de
> chip

O incômodo é justo, e vou chegar nele. Mas o primeiro resultado do dia foi
descobrir que a tabela mais óbvia para se olhar nessa investigação não tem nada
a ver com o gerador de tons.

## `ToneGen_ParamTable`

Está em `0x00E0E407`, tem 1.389 bytes e sub-rótulos de 0x48 em 0x48 — passo
regular, tamanho respeitável, nome inequívoco. É exatamente o formato de uma
tabela de parâmetros por timbre, e é exatamente o que alguém procurando "um
bloco grande copiado da ROM para o gerador de tons" abriria primeiro.

Fui ver quem a referencia. São nove pontos, todos no mesmo arquivo, todos com a
mesma forma:

```
	lda_24 xde, (ToneGen_ParamTable_0x1E)
	exts   XBC
	add    XBC,XDE
	ld     XHL,(XBC)
	call   (XHL)
```

A última linha resolve a questão. Isso carrega um **ponteiro** de dentro da
tabela e **chama** o que ele aponta. Não é uma tabela de parâmetros: é uma
tabela de saltos, indexada por uma seleção de interface, e os nove sítios estão
todos em `sound_editor_ui.s` — o editor de timbres da tela, não o chip. Nenhum
registrador do gerador de tons é tocado por ela.

O nome está errado, e erra na direção mais cara possível: aponta para o chip
justamente quem está investigando o chip.

## Por que nenhum script meu pega isso

Passei a semana escrevendo verificações de nomes, e uma delas foi comemorada
aqui mesmo neste diretório: 512 rótulos que declaram o próprio valor de retorno
podem ser julgados por máquina, e quatro estavam errados. A lição de agora é o
outro lado da mesma moeda.

`ToneGen_ParamTable` não declara nada verificável. Não promete um valor de
retorno, não abre arquivo em modo nenhum, não afirma uma contagem. Só sugere um
assunto. Não existe teste automático para "esse nome sugere o assunto errado",
e é por isso que ele sobreviveu a todas as passagens de auditoria enquanto
nomes muito menos enganosos eram corrigidos.

É o mesmo caso do `FileIO_ReadHeader`, que monta um caminho e não lê cabeçalho
nenhum. A parte verificável dos nomes já está medida; a parte que engana o
leitor humano continua inteira.

## E a busca por ponteiros mentiu junto

Antes de ler as referências, procurei a tabela do jeito mecânico: os quatro
bytes do endereço, em little-endian, dentro da ROM. Doze ocorrências. Por um
minuto pareceu que meio firmware apontava para lá.

Nenhuma é um ponteiro. `07 e4 e0` é o padrão de bytes de endereçamento da
instrução `ld (XBC+WA),imm` — modo `0x07`, base `0xE4` = XBC, índice `0xE0` =
WA. Desmontando a partir de qualquer um dos doze offsets aparece uma escrita
comum:

```
f0e47e: f3 07 e4 e0 00 20   ld (XBC+WA),0x20
```

Uma busca por padrão de bytes numa ROM de 2 MB acha o padrão. Se ele também é
uma instrução frequente, os acertos são ruído com a cara do que se procura. O
custo de confirmar é desmontar os doze — dois minutos — e eu quase pulei.

## O incômodo da fronteira de chip

Sobra a pergunta original, e ela tem uma resposta que este projeto já
encontrou duas vezes, com outro nome.

Quando o emulador precisa de um bloco que só existe na ROM do processador
principal, e o chip que consome esse bloco não tem como ler essa ROM, uma das
duas coisas é verdade. Ou o hardware real de fato lê — e aí é um fato elétrico,
que se confirma no esquemático, não no código. Ou o firmware lê, deriva o que
interessa e **publica** o resultado nos registradores do chip; e então o bloco
já está inteiro nas escritas, e copiá-lo da ROM é atravessar uma fronteira que
não precisava ser atravessada.

O registro do projeto tem o caso resolvido, e a palavra usada na época é boa:

> BLOQUEIO 2 (rotina nota→altura) — **dissolvido, não revertido.** Mesmo truque
> do KN7000: o firmware calcula a altura e publica. O inicializador de registro
> `0x48493D80` escreve `+0x08 = 0x80|(altura16>>8)`, `+0x0A` altura base, `+0x0C`
> altura da nota — campo a campo o layout do KN7000 no mesmo passo de 0xB4.

E há um segundo caso, com a mesma forma: os parâmetros de onda por voz em
`0x8000–0x9000` não são lidos da ROM pelo chip, são montados numa área sombra
que a cópia de blocos consome.

Então o trabalho de desmontagem que responde à pergunta é específico e o
resultado é binário: achar, para o bloco em questão, a rotina que o percorre e
escreve nos registradores do gerador de tons. Se ela existe, a fronteira some —
o emulador passa a consumir as escritas, como já faz para a altura das notas.
Se ela não existe, isso é a descoberta interessante, e vira uma pergunta para o
esquemático.

O que eu ainda não tenho é qual bloco é. `ToneGen_ParamTable` era o palpite
óbvio e é uma tabela de saltos do editor de timbres. Descartar o palpite óbvio
não responde à pergunta, mas é a parte que economiza o dia de quem for
responder.

---

Reprodução: `scripts/analysis/v7_tonegen_paramtable_is_a_jumptable.py` —
conta as referências, mostra que nove são despacho, e desmonta os doze falsos
ponteiros.
