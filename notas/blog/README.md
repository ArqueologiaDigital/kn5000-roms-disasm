# Rascunhos de divulgação

Textos escritos para leitores de fora do projeto — não são transcrição nem
documentação interna. Ficam aqui em rascunho até o dono decidir se e onde
publicar.

Os números citados nos textos têm sempre um script commitado que os reproduz;
o texto cita o caminho. Se um rascunho afirma algo que depois se mostrou falso,
a correção entra no próprio rascunho, não numa errata separada.

| Rascunho | Assunto | Estado |
|---|---|---|
| `2026-08-22_dois_processos_um_arquivo.md` | Pedi mais agentes em paralelo e o paralelismo achou um bug meu: o conversor usava um arquivo temporário de caminho fixo, então dois processos desmontavam os bytes um do outro. O portão de byte-match impediu que algo errado entrasse, mas os censos e contagens que orientam o trabalho não passam por portão nenhum. Mais o `inc`, cujo texto impresso corresponde a cinco codificações, e o controle negativo que reprova a leitura óbvia em 20.113 de 20.360 sítios | **Não publicado.** Aguarda revisão |
| `2026-08-22_sete_impossibilidades.md` | Sete coisas que declarei impossíveis num único dia e não eram — do "o firmware nunca lê .LSW" ao "o lado do painel não pode ser especificado". Em todas, a medição estava certa e a conclusão ia longe demais. Inclui o que de fato continua impossível, para o recorte não mentir | **Não publicado.** Aguarda revisão |
| `2026-08-22_eu_disse_que_nenhum_script_conseguia.md` | Escrevi no placar que nenhum script podia julgar se um nome de função está *certo*. Um agente em paralelo achou uma classe decidível — 512 rótulos que declaram o valor de retorno — e encontrou quatro nomes errados, um deles conferido à mão. Uma afirmação de impossibilidade também é uma verificação, e também pode estar cega | **Não publicado.** Aguarda revisão |
| `2026-08-22_o_portao_que_nao_ve.md` | O teste de byte-match reconstrói as nove ROMs e é o critério mais duro do projeto — e pegou só três dos seis bugs de um conversor novo. Os outros produziram bytes idênticos e desmontagem errada. Mais a décima aparição do padrão do dia: verificações que não conseguem enxergar o próprio assunto | **Não publicado.** Aguarda revisão |
| `2026-08-21_o_que_o_montador_nao_sabia_dizer.md` | Os 158.902 bytes da v7 que continuavam `.byte` não eram descuido: o backend TLCS-900 do LLVM codificava as instruções corretamente mas só atendia por nomes inventados (`andmi8`, `bitm`, `ldcfm`). Mais o padrão que apareceu seis vezes no dia — buscas que não conseguem expressar o que procuram devolvem zeros limpos | **Não publicado.** Aguarda revisão |
