# Outreach writing: one blog, in English

**2026-09-02.** This file replaces the two Portuguese draft directories that used to live at
`notas/blog/` and `wsa1/notas/blog/`. Both are gone. What follows is the part of their READMEs that
was not itself a blog post: the policy, the drafting convention, and the record of where each draft
ended up.

## The policy

There is **one** blog, in **English**, at `~/compartilhado/mame-blog`, with this project's posts under
`posts/kn7000/` and indexed by `posts/kn7000/posts.json` (JSON, `indent=1`, entries
`{file, title, date, summary}`).

New outreach text about this project is written **in English, directly in that repository**. Do not
start a second draft tree here, in any language. Two of them existed at once, which is how the second
one went unnoticed for a day.

Numbering convention, worked out from the existing directory rather than assumed: the **part number**
is the next free integer at the time of writing, and the **date in the filename and in `posts.json`**
is the date of the *work being described*, not the date of publication. That is why parts 157-174 are
dated August while parts 150-156 are dated September.

## The drafting convention, which survives the move

* A number quoted in an outreach text must have a **committed script that reproduces it**, and the
  text must cite that script's path. A claim whose evidence lives only in scratch is a claim nobody
  can check.
* If a text asserts something that later turns out to be false, the **correction goes into that text**
  — as Part 153's "Correction, September 2" does — not into a separate erratum nobody will find.

## Where each draft went

`wsa1/notas/blog/`, eleven drafts, all marked *Não publicado / Aguarda revisão*:

| draft | English post |
|---|---|
| `2026-08-28_uma_grafia_nao_e_a_operacao.md` | **Part 205**, "A spelling is not the operation" (its PA bit 3 conclusion had already reached Part 153 from the driver side) |
| `2026-08-29_contar_a_grandeza_errada.md` | **Part 206**, "Territory up, meaning down" |
| `2026-08-29_cem_por_cento_nomeado_zero_entendido.md` | **Part 207**, "A hundred percent named, zero evidence" |
| `2026-08-30_o_mapa_estava_na_pagina_32.md` | **Part 208**, "The map was on page 32" |
| `2026-08-30_a_negativa_que_resolveu.md` | **Part 209**, "The negative result that solved it" |
| `2026-08-30_tres_buracos_um_erro.md` | **Part 210**, "Three holes, one mistake" |
| `2026-09-01_zero_incbin_nao_e_cobertura.md` | **Part 211**, "Zero .incbin is not coverage" (its stale-object-gate section was already **Part 152**) |
| `2026-09-01_o_portao_verde_e_o_teste_calado.md` | **Part 212**, "The defect the instrument called noise" |
| `2026-08-31_um_nucleo_quatro_processadores.md` | already published as **Part 150**, "One kernel, four processors, two products" |
| `2026-09-01_o_montador_aceitou_nao_e_evidencia.md` | already published as **Part 151**, "The assembler that said yes" |
| `2026-09-01_parametros_nao_codigo.md` | already published as **Part 154**, "Parameters, not code" |

`notas/blog/`, one draft:

| draft | English post |
|---|---|
| `2026-09-02_os_instrumentos_mentiam_para_o_lado_seguro.md` | already published as **Part 156**, "Four instruments, all wrong the same way" |

An earlier consolidation, recorded in the old root README and kept here so the history is not lost:
24 drafts from `notas/blog/` that did not duplicate published material were translated and entered
the English blog as **parts 157-180**.
