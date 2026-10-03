#!/bin/bash
# name_wsa1_ram_checkers.sh -- do the read-only WSA1 checker scripts say the same thing before and
# after a RAM-naming commit?  name_wsa1_ram.py rewrites operands, and a checker that parsed a numeric
# operand out of the source would silently change its answer.  The 43 below are the read-only ones
# (no file writes, no --apply, not a gen_* generator) among the wsa1/notes scripts that mention a
# named address and the prom_a / prom_b sources.
# Runs each with its default arguments in a detached worktree at BASE and in the working tree, and
# compares output and exit status.  rc=1 on both sides is a pre-existing failure, not a regression.
#
#   scripts/tools/name_wsa1_ram_checkers.sh <base-commit>
set -u
BASE="${1:?base commit}"
REPO="$(git rev-parse --show-toplevel)"
WORK="${TMPDIR:-$HOME/compartilhado/tmp}/wsa1-ramcheck-$$"
OUT="${WORK:?}-out"
CHECKS="prom_b_sc1_states audit_wave6_round2_probes lcd_layer_census prom_a_byte_checks
        prom_a_drumnames_checks prom_a_panel_control_map prom_b_dl_stack_sites prom_b_f4f000_layout
        prom_b_f5b800_checks prom_b_f6d002_touches prom_b_msgline wave7_panel_button_codes
        wave7_panel_names_round11 wave7_review_wa3_prom_a_names
        prom_a_boot_checks prom_a_ctrl_checks prom_a_disk_format_checks prom_a_disk_cmd_layer_checks
        prom_a_fa5aeb_layout prom_a_pa3_census prom_a_portb_and_blockdev_census prom_a_uiblock_checks
        prom_a_uiscreen_checks prom_b_sc1_census prom_b_smf_reader prom_b_songstore_checks
        wave7_panel_event_index wave7-verify-probes/wave7_r10_promb_review
        sysex-probes/sysex_bulkdump_tx sysex-probes/sysex_command_map sysex-probes/sysex_dump_categories
        sysex-probes/sysex_handshake_gate sysex-probes/sysex_model_variant
        sysex-probes/sysex_sequencer_layout sysex-probes/sysex_third_region_wire
        sysex-probes/sysex_user_settings prom_b_var_screens prom_b_dl_length_audit
        prom_a_fdc_checks prom_a_fdc_operation_census prom_a_unit1_backend_check prom_a_fdc_callgraph prom_a_addr_census"
git -C "$REPO" worktree add --detach "${WORK:?}" "$BASE" > /dev/null
run() {  # tree outdir
    mkdir -p "$2"
    for s in $CHECKS; do
        o="$2/$(echo "$s" | tr / _).out"
        (cd "$1/wsa1" && timeout 600 python3 "notes/$s.py" > "$o" 2>&1; echo "rc=$?" >> "$o")
    done
}
run "${WORK:?}" "${OUT:?}/before"
# a traceback prints the script's path: make the worktree's look like the working tree's
for f in "${OUT:?}"/before/*.out; do sed -i "s#${WORK:?}#${REPO:?}#g" "$f"; done
run "$REPO" "${OUT:?}/after"
diffs=0
for s in $CHECKS; do
    f="$(echo "$s" | tr / _).out"
    if cmp -s "${OUT:?}/before/$f" "${OUT:?}/after/$f"; then
        echo "SAME $s $(tail -1 "${OUT:?}/after/$f")"
    else
        echo "DIFF $s"; diffs=$((diffs + 1))
    fi
done
git -C "$REPO" worktree remove --force "${WORK:?}" && git -C "$REPO" worktree prune
rm -rf -- "${OUT:?}"
echo "$diffs checker(s) changed"
[ "$diffs" -eq 0 ]
