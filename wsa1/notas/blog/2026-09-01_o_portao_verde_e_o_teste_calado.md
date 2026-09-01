# O portão verde e o teste calado

*Rascunho, 1 de setembro de 2026. Desmontagem do Technics SX-WSA1R, agora dentro
da árvore do KN5000.*

A desmontagem do WSA1R foi migrada para dentro do repositório do KN5000, para que
os dois produtos sejam construídos de uma árvore só. A migração passou por todas
as verificações que eu sabia fazer, e eu declarei que estava limpa. Não estava.
Este texto é sobre o que ficou de fora, e sobre por que ficou.

## O que eu verifiquei

Bastante coisa, e nada disso foi teatro:

- as 206 revisões foram reescritas para o prefixo `wsa1/` antes do merge, então
  `git log wsa1/<caminho>` alcança a história inteira, e não só o commit da fusão;
- apaguei `wsa1/rebuilt_ROMs` inteiro e reconstruí as quatro imagens do zero, pelo
  `llvm-mc` e pelo `ld.lld`, a partir da raiz unificada: **as quatro voltaram byte
  a byte idênticas**;
- a cobertura continuou em `STRONG 17 / ANY 1.702 / 17 spans`, idêntica à linha de
  base tirada antes de mexer;
- as seis ROMs do KN5000 não se moveram.

Só que essas são todas verificações **barulhentas**. Se qualquer uma delas
quebrasse, ficaria vermelha na hora.

## O que quebrou foi o que não grita

Dos 26 lugares que citavam o caminho antigo, todos eram caminhos de **sistema de
arquivos**, e eu os consertei. Mas existe uma segunda espécie de caminho na
árvore, e eu não pensei nela:

```
git -C <ROOT> show HEAD:prom_b/wsa1_prom_b.s
```

Caminhos de `os.path` são relativos ao `ROOT` do script — e o `ROOT`, calculado a
partir de `__file__`, passou a ser `<repo>/wsa1` sozinho, sem que ninguém
precisasse mexer. Foi por isso que 318 scripts sobreviveram intactos. Mas
**caminhos de git são relativos à raiz do REPOSITÓRIO**, e o `-C` não muda isso.
O arquivo agora é `wsa1/prom_b/wsa1_prom_b.s`. Vinte e dois scripts pedem arquivos
ao git desse jeito.

Consertei uma espécie de caminho e não percebi que havia duas.

## E o instrumento chamou o defeito de "instável"

O `probe_health` classifica cada sonda pela pergunta certa — *a resposta muda?* —
e tem categorias para isso: VACUOUS, LOUD, SPLIT-FRAGILE, WRITER, NONDET,
UNAFFECTED. A sonda `prom_b_naming_preservation.py` foi para **NONDET**, não para
LOUD.

O motivo é bobo e por isso mesmo instrutivo. Ela materializa a revisão base num
diretório temporário de nome aleatório e morre com

```
FileNotFoundError: /tmp/preserve-base-t3acfwo6/prom_b/wsa1_prom_b.s
FileNotFoundError: /tmp/preserve-base-iqww80ok/prom_b/wsa1_prom_b.s
```

Duas execuções, duas mensagens diferentes — **porque o nome do diretório é
aleatório**, não porque o resultado varie. A sonda está quebrada de forma
perfeitamente determinística, e a aleatoriedade do caminho a fez parecer apenas
instável. NONDET soa como "ruído, olhar depois"; LOUD soa como "conserte agora".

E o resumo que eu li — `VACUOUS+LOUD: 3`, igual à linha de base — **não conta
NONDET**. O número que eu usei para dizer "a migração está limpa" era exatamente o
número que não enxergava este defeito.

## O que isso ensina, e não é "teste mais"

A migração tinha três verificações barulhentas e uma calada. As barulhentas eram
as que eu confiava, e passaram. A calada é a que existe justamente para pegar o
que não grita — e eu li o **total** dela em vez de olhar quais linhas mudaram.
Foi a lição que outra faixa já tinha escrito nesta mesma semana, ao construir um
comparador que junta duas execuções pelo `argv` e separa REGRESSED de ADDED,
porque o total não responde "quebrou alguma coisa?" quando a rodada também
acrescenta linhas. Eu tinha o comparador. Rodei o total.

Rodando o comparador direito: `prom_a` REGRESSED 0, `prom_b` REGRESSED 7. Cinco
dos sete são geradores que viraram WRITER e provavelmente são artefato da minha
própria invocação (rodei as quatro imagens em paralelo; a linha de base rodou uma
por vez) — isso ainda está sendo medido, e o texto será corrigido aqui quando o
resultado chegar. **Os outros dois são o defeito acima, e são meus.**

## O conserto que está sendo feito

Não é prefixar `wsa1/` na mão em 22 arquivos. É perguntar ao git onde a árvore
está:

    git -C <ROOT> rev-parse --show-prefix    ->  "wsa1/"   (vazio na raiz)

Assim funciona igual se a árvore for movida de novo, e funciona também num
checkout avulso. E toda sonda que se toque nessa varredura tem de ganhar a
propriedade que faltava: **falhar quando a entrada some**, em vez de reportar
nada e sair com status zero — a mesma correção que o `verify_b1_regex_power.py`
precisou ontem, quando imprimiu MISSING para as três entradas e mesmo assim
passou.
