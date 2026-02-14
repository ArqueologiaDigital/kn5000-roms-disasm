// license:BSD-3-Clause
// copyright-holders:Felipe Sanches
/***************************************************************************

    TOSHIBA TLCS900 - TMP94C241 SERIAL

***************************************************************************/

#include "emu.h"
#include "tmp94c241.h"
#include "tmp94c241_serial.h"

#include "logmacro.h"

DEFINE_DEVICE_TYPE(TMP94C241_SERIAL, tmp94c241_serial_device, "tmp94c241_serial", "TMP94C241 Serial Channel")

tmp94c241_serial_device::tmp94c241_serial_device(const machine_config &mconfig, const char *tag, device_t *owner, uint8_t channel, uint32_t clock) :
	device_t(mconfig, TMP94C241_SERIAL, tag, owner, clock),
	m_channel(channel),
	m_serial_control(0),
	m_serial_mode(0), /* I/O interface mode and clock source at TO2 trigger */
	m_baud_rate(0),
	m_hz(0),
	m_rx_clock_count(8),
	m_rx_shift_register(0),
	m_rx_buffer(0),
	m_rxd(0),
	m_rxd_prev(0),
	m_sioclk_state(0),
	m_tx_clock_count(0),
	m_tx_shift_register(0),
	m_txd(1),  // Idle state is HIGH for serial lines
	m_sclk_out(0),
	m_tx_skip_first_falling(false),
	m_tx_needs_trailing_edge(false),
	m_txd_cb(*this),
	m_sclk_in_cb(*this),
	m_sclk_out_cb(*this),
	m_tx_start_cb(*this)
{
}

void tmp94c241_serial_device::device_start()
{
	m_timer = timer_alloc(FUNC(tmp94c241_serial_device::timer_callback), this);
	m_cpu = dynamic_cast<tmp94c241_device *>(owner());

	save_item(NAME(m_serial_control));
	save_item(NAME(m_serial_mode));
	save_item(NAME(m_baud_rate));
	save_item(NAME(m_hz));
	save_item(NAME(m_rx_clock_count));
	save_item(NAME(m_rx_shift_register));
	save_item(NAME(m_rx_buffer));
	save_item(NAME(m_rxd));
	save_item(NAME(m_rxd_prev));
	save_item(NAME(m_sioclk_state));
	save_item(NAME(m_tx_clock_count));
	save_item(NAME(m_tx_shift_register));
	save_item(NAME(m_txd));
	save_item(NAME(m_sclk_out));
	save_item(NAME(m_tx_skip_first_falling));
	save_item(NAME(m_tx_needs_trailing_edge));

	m_sclk_out_cb(m_sclk_out);
	m_txd_cb(m_txd);
}

void tmp94c241_serial_device::device_reset()
{
	m_serial_control &= 0x80;
	m_serial_mode &= 0x80;
	m_baud_rate = 0x00;
	m_tx_skip_first_falling = false;
	m_tx_needs_trailing_edge = false;
}

void tmp94c241_serial_device::TO2_trigger(int state)
{
	// In TMP94C241 "TO2 trigger" mode (SC1MOD bits 1:0 = 0), the TO2 event
	// acts as a transfer trigger/gate — it does NOT directly provide the
	// serial clock.  The baud rate generator (BR1CR) provides the actual
	// SCLK, which is why the firmware writes BR1CR at each TX state machine
	// step even in mode 0.
	//
	// Previously this function called sioclk(state) directly, which made
	// TO2 act as a second clock source alongside the baud rate timer,
	// causing double-clocking and data corruption (garbled LED commands).
	//
	// The TO2 trigger mechanism (starting transfers on TO2 events) is not
	// currently emulated — transfers start immediately on SC1BUF writes,
	// matching mode 1 behavior.  This simplification works because the
	// firmware always writes SC1BUF before the clock edges are needed.
	//
	// For SC0 (UART mode), this function is already a no-op because
	// (serial_mode & 3) != 0.
}

void tmp94c241_serial_device::sioclk(int state)
{
	if (m_sioclk_state == state)
		return;

	m_sioclk_state = state;

	// Always forward SCLK to the connected device.  We do NOT gate on PFFC
	// here because that causes clock desync: during PFFC-off phases, TO2
	// toggles our internal m_sioclk_state without forwarding to the slave,
	// so the slave's state becomes stale and it misses edges when PFFC is
	// re-enabled.  Instead, phantom bytes (written with PFFC disabled) are
	// signaled via tx_start_cb so the slave can skip them at the byte level.

	if (state)
	{
		// Rising edge: Sample RXD BEFORE forwarding clock to slave.
		// The slave's rising-edge handler may complete an RX byte and call
		// send_byte(), which pre-outputs bit 0 via m_txd_cb — changing our
		// m_rxd before we can sample it. Capture the value first.
		uint8_t rxd_sample = m_rxd;

		m_sclk_out_cb(state);

		logerror("sioclk state=%d rxd=%d m_rx_clock_count=%d m_tx_clock_count=%d\n", m_sioclk_state, rxd_sample, m_rx_clock_count, m_tx_clock_count);

		// Handle deferred INTTX from the last falling edge.  The receiver
		// (cpanel) just sampled bit 7 on this rising edge via sclk_out_cb.
		// Now it's safe to fire INTTX — the ISR may write SC1BUF which
		// pre-outputs bit 0 of the next byte, but bit 7 has already been
		// sampled.  On real TMP94C241 hardware, the 8th rising edge occurs
		// 4µs after the last falling edge (at 250 kHz SCLK), well before
		// the ISR can write SC1BUF.  In MAME's event-driven scheduler,
		// CPU instructions run between timer ticks, so without this deferral
		// the ISR would write SC1BUF (pre-outputting bit 0) BEFORE the
		// trailing rising edge — corrupting bit 7 of every byte.
		if (m_tx_needs_trailing_edge)
		{
			m_tx_needs_trailing_edge = false;
			logerror("Trailing rising edge: firing INTTX\n");
			m_cpu->m_int_reg[(m_channel == 0) ? INTES0 : INTES1] |= 0x80;
			m_cpu->m_check_irqs = 1;
		}

		if (m_rx_clock_count){
			m_rx_clock_count--;

			m_rx_shift_register >>= 1;
			m_rx_shift_register |= (rxd_sample << 7);

			if (m_rx_clock_count == 0)
			{
				m_rx_clock_count = 8;
				m_rx_buffer = m_rx_shift_register;
				logerror("RX byte received: %02X\n", m_rx_buffer);
				m_cpu->m_int_reg[(m_channel == 0) ? INTES0 : INTES1] |= 0x08;
				m_cpu->m_check_irqs = 1;
			}
		}
	}
	else
	{
		// Falling edge: Forward clock to slave, then output our TXD.
		m_sclk_out_cb(state);

		logerror("sioclk state=%d rxd=%d m_rx_clock_count=%d m_tx_clock_count=%d\n", m_sioclk_state, m_rxd, m_rx_clock_count, m_tx_clock_count);

		if (m_tx_clock_count){
			if (m_tx_skip_first_falling) {
				// Skip this falling edge - bit 0 was pre-output in scNbuf_w
				// and we need to give the receiver a rising edge to sample it
				logerror("skipping first falling edge (bit 0 already on line)\n");
				m_tx_skip_first_falling = false;
			} else {
				// Normal operation: shift out the next bit
				m_tx_shift_register >>= 1;
				logerror("send bit #%d: %d\n", 8-m_tx_clock_count, m_tx_shift_register & 1);

				m_txd_cb(m_tx_shift_register & 1);
				if (--m_tx_clock_count == 0) {
					// Byte shift-out complete.  Defer INTTX to the next
					// rising edge so the receiver can sample bit 7 before
					// the ISR writes the next byte (which pre-outputs bit 0).
					logerror("Finished sending byte (deferring INTTX to trailing edge).\n");
					m_tx_needs_trailing_edge = true;
				}
			}
		}
	}
}

void tmp94c241_serial_device::rxd(int state)
{
	if (m_rxd != state)
	{
		m_rxd = state;
	}
}

uint8_t tmp94c241_serial_device::scNbuf_r()
{
	return m_rx_buffer;
}

void tmp94c241_serial_device::scNbuf_w(uint8_t data)
{
	bool was_idle = (m_tx_clock_count == 0);
	logerror("buf write: %02X (sioclk_state=%d, was_idle=%d)\n", data, m_sioclk_state, was_idle);

	m_tx_shift_register = data;
	m_tx_clock_count = 7;  // 7 more bits to send (bits 1-7) after pre-outputting bit 0

	// Signal start of new transmission when we were idle.
	// Pass the PFFC state so the slave knows whether this byte is "real"
	// (PFFC enabled, SCLK pin driven → data reaches panel on real hardware)
	// or "phantom" (PFFC disabled, pin is high-impedance → data never
	// reaches the panel on real hardware, but MAME still forwards SCLK).
	if (was_idle)
	{
		bool pffc_sclk = (m_cpu->m_port_function[PORT_F] & (1 << (m_channel == 0 ? 2 : 6))) != 0;
		m_tx_start_cb(pffc_sclk ? 1 : 0);
	}

	// Pre-output first bit immediately so slave can sample it on the first rising edge
	logerror("pre-output bit #0: %d\n", m_tx_shift_register & 1);
	m_txd_cb(m_tx_shift_register & 1);

	// Only skip the first falling edge if clock is currently HIGH AND we were idle.
	// If clock is HIGH: next edge = falling (skip it to avoid outputting bit 1 before receiver samples bit 0)
	// If clock is LOW: next edge = rising (receiver samples bit 0), then falling outputs bit 1 (no skip needed)
	// If we weren't idle: the slave is mid-byte, don't disrupt its counting
	m_tx_skip_first_falling = was_idle && (m_sioclk_state == 1);
	logerror("skip_first_falling = %d\n", m_tx_skip_first_falling);
}

uint8_t tmp94c241_serial_device::scNcr_r()
{
	return m_serial_control;
}

void tmp94c241_serial_device::scNcr_w(uint8_t data)
{
	m_rx_clock_count = 8;
	m_serial_control = data;
}

uint8_t tmp94c241_serial_device::scNmod_r()
{
	return m_serial_mode;
}

void tmp94c241_serial_device::scNmod_w(uint8_t data)
{
	switch((data >> 2) & 3)
	{
		case 0: logerror("I/O interface mode\n"); break;
		case 1: logerror("7-bit uart mode (Not implemented yet)\n"); break;
		case 2: logerror("8-bit uart mode (Not implemented yet)\n"); break;
		case 3: logerror("9-bit uart mode (Not implemented yet)\n"); break;
	}
	switch(data & 3)
	{
		case 0: logerror("clk source: TO2 trigger\n"); break;
		case 1: logerror("clk source: Baud rate generator (Not implemented yet)\n"); break;
		case 2: logerror("clk source: Internal clock at ϕ1 (Not implemented yet)\n"); break;
		case 3: logerror("clk source: external clock (SCLK%d) (Not implemented yet)\n", m_channel); break;
	}
	m_serial_mode = data;

	// Do NOT fire INTTX here.  On real TMP94C241 hardware, writing SC1MOD
	// configures the serial mode — it does not trigger a transmit-complete
	// interrupt.  The firmware writes SC1MOD at the start of every TX
	// sequence (SM_StartTX).  A spurious INTTX would cause the TX state
	// machine to advance prematurely (thinking byte 1 finished before it
	// started), corrupting specific command bytes and causing wrong LED
	// states.
}

uint8_t tmp94c241_serial_device::brNcr_r()
{
	return m_baud_rate;
}

void tmp94c241_serial_device::brNcr_w(uint8_t data)
{
	m_baud_rate = data;
	uint8_t divisor = data & 0x0f;
	uint8_t input_clocks[] = {0, 2, 8, 32};
	uint8_t shift_amount = (((data >> 4) & 3) + 1) * 2;
	logerror("baud rate: Divisor=%d  Internal Clock T%d\n", divisor, input_clocks[(data >> 4) & 3]);
	if (divisor)
	{
		long int fc = 16'000'000; // TODO: set this from the cpu.
		m_hz = (fc >> shift_amount) / divisor;
		m_timer->adjust(attotime::from_hz(m_hz), 0, attotime::from_hz(m_hz));
		logerror("timer set to %d Hz.\n", m_hz);
	} else {
		m_timer->reset(attotime::never);
		m_hz = 0;
		logerror("timer disabled.\n");
	}
	//if (m_channel == 1) machine().debug_break();
}

/*
	0x3f means m_port_function[PORT_F]

reset:
...
ef03d8: 08 3f 73              ld (0x3f),0x73	; disable ch.0 (bit 2) / enable ch.1 (bit 6)


Reached from which routine ?:
...
fc4068: c1 8f 8d 3e 50        or (0x8d8f),0x50	; enable channel 1 (bit 6)
fc406d: c1 8f 8d 21           ld A,(0x8d8f)
fc4071: f0 3f 41              ld (0x3f),A


SERIAL_METHOD_2:      ; FC45A8
...
fc45ab: c1 8f 8d 3e 50        or (0x8d8f),0x50	; enable channel 1 (bit 6)
fc45b0: c1 8f 8d 21           ld A,(0x8d8f)
fc45b4: f0 3f 41              ld (0x3f),A

SERIAL_METHOD_4:       ; FC460D
...
fc4610: c1 8f 8d 3e 50        or (0x8d8f),0x50	; enable channel 1 (bit 6)
fc4615: c1 8f 8d 21           ld A,(0x8d8f)
fc4619: f0 3f 41              ld (0x3f),A


*/

TIMER_CALLBACK_MEMBER(tmp94c241_serial_device::timer_callback)
{
	// In TO2 trigger mode (mode 0), IOC=1 means the clock comes from an
	// external device (cpanel's self-clock via SCLK pin after INTA).
	// Don't drive from the baud rate timer — that would inject extra
	// edges and corrupt data during INTA-driven reception.
	//
	// In baud rate generator mode (mode 1), the baud rate timer is the
	// clock source regardless of IOC.  The AW VM uses mode=1 with IOC=1,
	// so we must NOT block the timer in that combination.
	if ((m_serial_mode & 3) == 0 && BIT(m_serial_control, 0))
		return;

	// Keep clocking while TX is in progress, RX hasn't completed its byte,
	// or we need a trailing rising edge for the receiver to sample bit 7.
	//
	// The trailing edge is critical: without it, the baud rate timer stops
	// after TX's last falling edge (tx_clock_count=0).  Between timer ticks,
	// the CPU processes the INTTX1 interrupt and writes the next byte to
	// SC1BUF, pre-outputting bit 0 on TXD.  The next rising edge (from the
	// new byte's timer) would then sample bit 0 of the NEW byte as bit 7
	// of the OLD byte — corrupting every byte's MSB.  The trailing edge
	// ensures bit 7 is sampled correctly before INTTX1 fires.
	//
	// Note: we do NOT gate on PFFC here.  On real TMP94C241 hardware,
	// PFFC controls whether the SCLK pin is driven externally, but the
	// internal serial clock (baud rate generator) always runs.  The shift
	// register must complete even during "phantom" bytes (PFFC off) so
	// that INTTX1 fires and the firmware's TX state machine advances.
	// Phantom bytes are filtered at the cpanel level via tx_start_cb:
	// tx_start(0) sets accept_next_byte=false, so the cpanel assembles
	// but rejects phantom bytes.  See sioclk() comments for why we also
	// don't gate sclk_out_cb on PFFC (clock desync issues).
	bool need_clock = (m_tx_clock_count > 0) || m_tx_skip_first_falling || (m_rx_clock_count != 8) || m_tx_needs_trailing_edge;
	if (m_hz && need_clock)
	{
		sioclk(m_sioclk_state ^ 1);
	}
}

