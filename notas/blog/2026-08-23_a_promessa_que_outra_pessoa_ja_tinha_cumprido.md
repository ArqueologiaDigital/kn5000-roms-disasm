# A promessa que outra pessoa já tinha cumprido

O PR 15911 entrou no MAME em 23 de agosto de 2026: registros de ROM para a série
Technics SX-KN, cinco modelos, nenhuma CPU instanciada. A descrição explica por quê —
*"MAME currently lacks an MN10300 execution core"* — e promete o próximo passo:
**"an initial MN10300 CPU core"**.

Fui planejar esse próximo passo e a primeira coisa que verifiquei foi a premissa.

O MAME tem um desmontador MN10300 desde **22 de março de 2025**. Está em
`src/devices/cpu/mn10300/mn103dasm.cpp` e `.h`, foi escrito pelo AJR no commit
`e95cdde8e96` mais seis correções, está registrado em `src/tools/unidasm.cpp:136` e
`:562`, e o `scripts/src/cpu.lua:4329-4336` o compila sob um comentário que diz
exatamente o que ele é: `-- Panasonic MN10300, disassembler only`.

Nosso overlay tem uma cópia. `git diff upstream/master kn7000-base --
src/devices/cpu/mn10300/` devolve vazio: **byte a byte a mesma coisa**. Nunca
escrevemos aquele arquivo. Nós o usamos — o núcleo de execução chama
`std::make_unique<mn10300_disassembler>()` e não acrescenta uma linha a ele.

Metade da promessa já estava cumprida havia dezessete meses, por outra pessoa, e
ninguém no projeto tinha reparado.

## O que sobrou é uma linha

Se o desmontador já existe, a pergunta vira: temos alguma coisa a dar a ele?

Temos, e está pronta desde 20 de julho. `disassemble_f4` lê o segundo byte da
instrução com `opcodes.r8(pc + 1)`, formata os dois operandos a partir dele — e
devolve comprimento **1**.

A verificação que importa não é "parece errado", é se `return 1` pode ser
convenção. Neste arquivo ele aparece também em `disassemble_f0`, `f1` e `f2`. Fui
ler: nos três é o braço de *sub-opcode desconhecido*, o caminho que cai fora do
`switch` sem consumir nada. O `f4` não tem esse braço. Todo caminho dele decodifica
o postbyte. E o gêmeo estrutural `disassemble_f3` — mesmo formato, mesmo
`r8(pc + 1)`, mesmo par de operandos — devolve **2**, assim como `f5` e `f6`.

O efeito é que qualquer desmontagem linear perde o sincronismo depois de **toda**
instrução F4: o postbyte é relido como opcode e uma instrução vira duas ou três
fantasmas, até o fluxo se realinhar por acaso. Só na região principal de código da
ROM do KN7000 são **3.440** instruções F4. A janela de desmontagem do depurador
sofre o mesmo sempre que rola a partir de um ponto acima de uma delas.

A correção é um caractere. O arquivo de patch está em
`kn7000_mame/notes/upstream-patches/mn10300-01-dasm-f4-length.patch`, datado de
20 de julho, e continuava sem ser enviado um mês depois. Confirmei hoje contra o
`upstream/master` em `4a49edce7b3`: ainda não corrigido, e o diretório inteiro
está intocado desde março de 2025.

O arnês que achou o bug está commitado: `kn7000_mame/tests/mn10300_length.cpp` com
`tests/validate_lengths.sh`. Ele compara comprimento a comprimento contra o
`unidasm` sobre as duas regiões de código do KN7000 — **656.050 instruções legais,
0 divergências** depois da correção.

## E o núcleo de execução?

Esse é o item grande, e é aqui que fui obrigado a rebaixar nossa própria evidência.

O núcleo existe: 2.031 linhas em `kn7000_mame/src/devices/cpu/mn10300/`. Ele roda o
firmware comercial até uma interface funcional, o que não é pouco. Mas ele não está
em **nenhum** ramo do repositório do MAME — enumerei todas as referências, e cada
ramo tem exatamente os dois arquivos do desmontador do AJR. O ramo do PR não existe.
E a integração de build não é um diff versionado: é um script Python que reescreve o
`cpu.lua` na hora de compilar.

Além disso o cabeçalho chama o núcleo de "AM33" e implementa **0 das 453**
codificações estendidas do AM33 (e 0 das 144 do AM33-2). O endereço de reset é
`m_pc = 0x48400000` com o SP que o firmware do KN7000 estabelece — estado de placa
dentro de um dispositivo de CPU. Os vetores de interrupção são entregues pelo driver,
quando o chip tem IVR0..IVR6 próprios.

As duas correções que doem mais são de proveniência, não de código:

**O comentário do `bsch` está errado.** Ele diz "Semantics from the GDB simulator", e
para `mulq`, `mulqu`, `sat16`, `sat24`, `getx` e `putx` isso confere linha a linha
com o `mn10300.igen` do binutils. Mas o `bsch` do GDB (`mn10300.igen:3919-3935`) é
`temp = Dm << (Dn & 0x1f); PSW.C = (temp != 0)` — **não escreve registrador nenhum**,
só mexe no carry. O nosso calcula `Dn = 31 - clz(Dm & 0xffff)`. São instruções
diferentes. A nossa é justificada empiricamente — o decodificador JPEG do firmware
produz o quadro de abertura pixel a pixel igual a uma decodificação de referência —
mas a proveniência declarada é falsa justo na única operação onde ela importa, e
qualquer revisor que abra o binutils vai ver.

**E o número que eu não posso mais citar.** O `INTEGRATION.md` fala em 4,59 milhões
de instruções de boot conferidas entre o núcleo do MAME e um simulador em Python. Fui
ler o simulador: `kn7000_disassembly/tools/mn10300_sim.py:9-10` diz que ele
"implements the same instruction subset as the MAME CPU core draft". Mesmo autor,
mesmo entendimento, duas implementações. Isso é consistência interna, não validação
cruzada. Pelo mesmo motivo o "100% de byte-match" do `kn7000_disassembly` é *por
construção* — esqueleto de `.incbin_range` — e valida o par montador/desmontador, não
a execução.

Para o TLCS-900 do KN5000 nós temos desmontagem com byte-match real. Para o MN10300
não temos nada equivalente, e eu vinha tratando os dois como se fossem a mesma coisa.

## O que muda

O plano de submissão passou a começar por um patch de uma linha que já estava escrito.
Não é a ordem que eu tinha imaginado, e é a ordem certa: é a única coisa da fila que
está pronta, verificada, e num arquivo cujo autor é um mantenedor ativo.

A promessa do PR 15911 continua de pé — mas ela é um núcleo de execução inteiro, com
o estado de placa removido de dentro dele, e não o passo inicial barato que a palavra
"initial" sugeria a quem a escreveu. Inclusive a mim.

---

Números reproduzíveis: `kn7000_mame/tests/validate_lengths.sh` (656.050 / 0);
`kn7000_mame/notes/upstream-patches/mn10300-01-dasm-f4-length.patch` (o exemplo em
`0x484357C7`); o plano completo, com citações arquivo:linha, em
`KN7000/MAME-PR-PLAN-2026-08-23.md`, gerado por
`KN7000/tools/mame-pr-planning/assess-pr-candidates.wf.js`.
