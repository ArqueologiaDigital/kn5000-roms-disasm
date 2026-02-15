// license:GPL2+
// copyright-holders:Felipe Sanches
/***************************************************************************

	KN5000 control panel HLE

	Emulates the two Mitsubishi M37471M2196S MCUs on the control panel.

	Protocol Summary:
	-----------------
	- Commands are 2-byte sequences from main CPU
	- Bits 7-5 of command byte select panel (0-3=left, 4-7=right)
	- Response packets have type encoded in bits 5-3:
	    Type 0,1: Button state (bits 7:6 select panel: 00=right, 11=left)
	    Type 2: Encoder delta
	    Type 3-5: Sync/ACK
	    Type 6,7: Multi-byte data

	See: https://felipesanches.github.io/kn5000-docs/control-panel-protocol/

***************************************************************************/

#include "emu.h"
#include "kn5000_cpanel.h"

#define LOG_COMMANDS (1U << 1)
#define LOG_SERIAL   (1U << 2)
#define LOG_BUTTONS  (1U << 3)
#define LOG_LEDS     (1U << 4)

#define VERBOSE (LOG_COMMANDS | LOG_SERIAL | LOG_BUTTONS | LOG_LEDS)
#include "logmacro.h"

DEFINE_DEVICE_TYPE(KN5000_CPANEL, kn5000_cpanel_device, "kn5000_cpanel", "KN5000 Control Panel HLE")

kn5000_cpanel_device::kn5000_cpanel_device(const machine_config &mconfig, const char *tag, device_t *owner, uint32_t clock) :
	device_t(mconfig, KN5000_CPANEL, tag, owner, clock),
	m_timer(nullptr),
	m_idle_detect_timer(nullptr),
	m_self_clock_timer(nullptr),
	m_baud_rate(0),
	m_rx_clock_count(8),
	m_rx_shift_register(0),
	m_rxd(1),
	m_sioclk_state(0),
	m_tx_clock_count(0),
	m_tx_shift_register(0xff),
	m_tx_skip_first_falling(false),
	m_cmd_index(0),
	m_initialized(false),
	m_self_clocking(false),
	m_inta_asserted(false),
	m_accept_next_byte(false),
	m_tx_output_enabled(true),
	m_next_accept(false),
	m_next_tx_output_enabled(true),
	m_rx_waiting_for_start(true),
	m_self_clock_bytes_sent(0),
	m_scan_retry_count(0),
	m_txd_cb(*this),
	m_sclk_out_cb(*this),
	m_inta_cb(*this),
	m_cpl_leds(*this, "cpl_led_%u", 0U),
	m_cpr_leds(*this, "cpr_led_%u", 0U)
{
	std::fill(std::begin(m_cmd_buffer), std::end(m_cmd_buffer), 0);
	std::fill(std::begin(m_last_button_state), std::end(m_last_button_state), 0);
	std::fill(std::begin(m_pending_button_state), std::end(m_pending_button_state), 0);
	std::fill(std::begin(m_cpl_ports), std::end(m_cpl_ports), nullptr);
	std::fill(std::begin(m_cpr_ports), std::end(m_cpr_ports), nullptr);
}

void kn5000_cpanel_device::device_start()
{
	m_timer = timer_alloc(FUNC(kn5000_cpanel_device::timer_callback), this);
	m_idle_detect_timer = timer_alloc(FUNC(kn5000_cpanel_device::idle_detect_callback), this);
	m_self_clock_timer = timer_alloc(FUNC(kn5000_cpanel_device::self_clock_callback), this);
	m_button_scan_timer = timer_alloc(FUNC(kn5000_cpanel_device::button_scan_callback), this);

	// Resolve LED outputs
	m_cpl_leds.resolve();
	m_cpr_leds.resolve();

	// Save state
	save_item(NAME(m_baud_rate));
	save_item(NAME(m_rx_clock_count));
	save_item(NAME(m_rx_shift_register));
	save_item(NAME(m_rxd));
	save_item(NAME(m_sioclk_state));
	save_item(NAME(m_tx_clock_count));
	save_item(NAME(m_tx_shift_register));
	save_item(NAME(m_tx_skip_first_falling));
	save_item(NAME(m_cmd_buffer));
	save_item(NAME(m_cmd_index));
	save_item(NAME(m_initialized));
	save_item(NAME(m_self_clocking));
	save_item(NAME(m_inta_asserted));
	save_item(NAME(m_accept_next_byte));
	save_item(NAME(m_tx_output_enabled));
	save_item(NAME(m_next_accept));
	save_item(NAME(m_next_tx_output_enabled));
	save_item(NAME(m_rx_waiting_for_start));
	save_item(NAME(m_self_clock_bytes_sent));
	save_item(NAME(m_scan_retry_count));
	save_item(NAME(m_last_button_state));
	save_item(NAME(m_pending_button_state));
	save_item(NAME(m_debounce_until));

	// Initial state - line idle high
	m_txd_cb(1);
}

void kn5000_cpanel_device::device_reset()
{
	m_baud_rate = 0;
	m_rx_clock_count = 8;
	m_tx_clock_count = 0;
	m_tx_skip_first_falling = false;
	m_cmd_index = 0;
	m_initialized = false;
	m_self_clocking = false;
	m_inta_asserted = false;
	m_accept_next_byte = false;
	m_tx_output_enabled = true;
	m_next_accept = false;
	m_next_tx_output_enabled = true;
	m_rx_waiting_for_start = true;
	m_self_clock_bytes_sent = 0;
	m_scan_retry_count = 0;

	// Clear TX queue
	while (!m_tx_queue.empty())
		m_tx_queue.pop();

	m_idle_detect_timer->reset(attotime::never);
	m_self_clock_timer->reset(attotime::never);

	// Proactive button scan: real panel MCUs continuously monitor their
	// button matrices and push change notifications via INTA.  The
	// firmware's steady-state polling only queries one segment (E0 13 =
	// right panel segment 3), relying on MCU-initiated INTA for changes
	// on other segments.  7ms (~143 Hz) is responsive enough for UI use
	// and coprime with likely command cycle times to avoid phase-lock.
	m_button_scan_timer->adjust(attotime::from_msec(7), 0, attotime::from_msec(7));

	std::fill(std::begin(m_last_button_state), std::end(m_last_button_state), 0);
	std::fill(std::begin(m_pending_button_state), std::end(m_pending_button_state), 0);
	m_debounce_until = attotime::zero;
}

void kn5000_cpanel_device::set_baudrate(uint16_t br)
{
	m_baud_rate = br;
	LOGMASKED(LOG_SERIAL, "Baud rate set to %d\n", br);

	if (br)
	{
		m_timer->adjust(attotime::from_hz(m_baud_rate), 0, attotime::from_hz(m_baud_rate));
	}
	else
	{
		m_timer->reset(attotime::never);
	}
}

void kn5000_cpanel_device::rxd(int state)
{
	m_rxd = state;
}

void kn5000_cpanel_device::tx_start(int state)
{
	// Called when CPU starts transmitting a new byte.
	// state=1: real byte (PFFC enabled — SCLK pin driven on real hardware)
	// state=0: phantom byte (PFFC disabled — pin high-Z, data wouldn't reach us)
	//
	// Reset RX counter to sync byte boundaries.  Track whether to accept
	// or skip the byte once it's fully received.
	LOGMASKED(LOG_SERIAL, "cpanel tx_start: state=%d (%s byte) rx_count=%d\n",
		state, state ? "real" : "phantom", m_rx_clock_count);

	// Store the new accept/output state as PENDING.  In MAME's synchronous
	// execution model, tx_start fires one edge too early: INTTX1 sets the
	// flag for byte N+1 BEFORE rising edge 8 completes byte N's reception.
	// If we applied immediately, byte N would see byte N+1's accept state
	// (e.g., byte 2 would be rejected because phantom 1's tx_start(0)
	// fires before byte 2's last rising edge).
	//
	// The pending values are applied at the next byte boundary — when
	// rx_clock_count returns to 8 after process_received_byte.  If we're
	// already at a boundary (rx_count==8, between bytes), apply immediately.
	m_next_accept = (state != 0);
	m_next_tx_output_enabled = (state != 0);

	// Allow RX counting to begin for the new byte.  This prevents
	// "orphan" clock edges (driven by the CPU's baud rate timer for
	// internal RX completion after TX finishes) from being counted as
	// data bits.  The cpanel waits at rx_clock_count=8 with this flag
	// set after completing each byte, ignoring edges until the CPU
	// signals a new byte via tx_start.
	m_rx_waiting_for_start = false;

	if (m_rx_clock_count == 8)
	{
		// At byte boundary — apply immediately (no mid-byte race)
		m_accept_next_byte = m_next_accept;
		m_tx_output_enabled = m_next_tx_output_enabled;
	}

	// Do NOT cancel idle_detect here for any byte type.
	//
	// Previously, real bytes (state=1) cancelled idle_detect under the
	// assumption that the CPU would clock out the response directly.
	// But the original firmware's TX state machine chains commands
	// (SM_TXComplete → SM_StartTX), so the next command's real bytes
	// cancel the idle_detect that would deliver the PREVIOUS command's
	// response.  This prevents INTA from ever firing during active
	// command sequences → "buttons and LEDs do not work."
	//
	// The sliding window in sioclk() (line ~214) handles this correctly:
	// it re-arms idle_detect on every edge if we have pending data,
	// and fires 250µs after the LAST edge when the baud rate timer
	// stops.  No cancellation needed here.
	//
	// For the AW VM: dummy 0xFF bytes drain the TX queue before
	// idle_detect fires, so the guard (tx_count > 0 || !queue.empty())
	// in sioclk prevents spurious INTA.
}

void kn5000_cpanel_device::sioclk(int state)
{
	if (m_sioclk_state == state)
		return;

	m_sioclk_state = state;

	// Retrigger idle_detect on every clock edge while we have pending
	// response data and aren't already self-clocking.  This creates a
	// sliding window that fires after the LAST external clock edge —
	// including phantom bytes from the firmware's TX state machine
	// (SM_TXComplete writes a phantom byte after each real command).
	//
	// 50µs timeout chosen so that INTA fires and self-clocking completes
	// (~140µs for 2 bytes) before the firmware's WaitTXReady delay loop
	// (~375µs) checks PE.5.  The phantom bytes' edges (4µs apart at
	// 250kHz SCLK) retrigger within 50µs, so the timeout fires only
	// after the last phantom byte finishes.
	if (!m_self_clocking && (m_tx_clock_count > 0 || !m_tx_queue.empty()))
	{
		m_idle_detect_timer->adjust(attotime::from_usec(50));
	}

	LOGMASKED(LOG_SERIAL, "cpanel sioclk state=%d rxd=%d rx_count=%d tx_count=%d\n",
		state, m_rxd, m_rx_clock_count, m_tx_clock_count);

	if (state)
	{
		// Rising edge: Sample RXD (receive bit from CPU)
		// Skip RX during self-clocking: the CPU serial's TXD line holds
		// the MSB of the last transmitted byte (often 0), so we'd assemble
		// 0x00 bytes and misinterpret them as LED commands, queuing infinite
		// sync responses that prevent self-clocking from ever completing.
		//
		// Skip RX while waiting for tx_start: after completing a byte, the
		// CPU's baud rate timer may drive "orphan" edges for internal RX
		// completion.  On real hardware, PFFC is disabled so these edges
		// don't reach the panel.  In MAME, they reach us but must not be
		// counted — otherwise they shift byte boundaries and garble all
		// subsequent commands.
		if (!m_self_clocking && !m_rx_waiting_for_start && m_rx_clock_count > 0)
		{
			m_rx_shift_register >>= 1;
			m_rx_shift_register |= (m_rxd << 7);
			m_rx_clock_count--;

			LOGMASKED(LOG_SERIAL, "cpanel RX bit: %d, shift_reg=%02X, count=%d\n",
				m_rxd, m_rx_shift_register, m_rx_clock_count);

			if (m_rx_clock_count == 0)
			{
				// Full byte received
				m_rx_clock_count = 8;
				process_received_byte(m_rx_shift_register);

				// Apply deferred tx_start flags now that we're at a byte
				// boundary.  This compensates for the MAME timing race:
				// tx_start for byte N+1 fires before byte N's last rising
				// edge, so we defer its effects until byte N is processed.
				m_accept_next_byte = m_next_accept;
				m_tx_output_enabled = m_next_tx_output_enabled;

				// Wait for next tx_start before counting another byte.
				// This prevents orphan edges from starting a new byte.
				m_rx_waiting_for_start = true;
			}
		}
	}
	else
	{
		// Falling edge: Output TXD (transmit bit to CPU)
		// This prepares the bit for the CPU to sample on the next rising edge.
		// Gate on m_tx_output_enabled: during phantom byte clock edges
		// (PFFC off, tx_start(0)), we must NOT output response bits.
		// The response data must remain frozen in the shift register and
		// queue until self-clocking delivers it after INTA.
		if (!m_tx_output_enabled)
		{
			// Phantom byte edge — suppress TX, keep response data intact
		}
		else if (m_tx_skip_first_falling)
		{
			// Skip this falling edge - bit 0 was pre-output and we need to give
			// CPU a rising edge to sample it before we output bit 1
			LOGMASKED(LOG_SERIAL, "cpanel skipping first falling edge (bit 0 already on line)\n");
			m_tx_skip_first_falling = false;
		}
		else if (m_tx_clock_count > 0)
		{
			if (m_tx_clock_count == 8)
			{
				// First bit of a chained byte (loaded from queue) — output bit 0 without shifting
				LOGMASKED(LOG_SERIAL, "cpanel TX bit 0 (chained): %d, shift_reg=%02X\n",
					m_tx_shift_register & 1, m_tx_shift_register);
				m_txd_cb(m_tx_shift_register & 1);
				m_tx_clock_count--;
			}
			else
			{
				// Normal operation: shift out the next bit
				m_tx_shift_register >>= 1;
				LOGMASKED(LOG_SERIAL, "cpanel TX bit: %d, shift_reg=%02X, count=%d\n",
					m_tx_shift_register & 1, m_tx_shift_register, m_tx_clock_count);
				m_txd_cb(m_tx_shift_register & 1);
				m_tx_clock_count--;
			}

			if (m_tx_clock_count == 0)
			{
				// Track bytes sent during self-clocking for packet-pause.
				// Must count HERE (tx_clock_count==0, before queue refill
				// sets it to 8) — self_clock_callback's rising-edge check
				// would never see 0 for intermediate bytes.
				if (m_self_clocking)
					m_self_clock_bytes_sent++;

				// Byte sent, check for more
				if (!m_tx_queue.empty())
				{
					m_tx_shift_register = m_tx_queue.front();
					m_tx_queue.pop();
					m_tx_clock_count = 8;  // Full 8 bits — don't pre-output yet

					LOGMASKED(LOG_SERIAL, "cpanel TX next byte queued: %02X (no pre-output)\n",
						m_tx_shift_register);

					// Don't pre-output: bit 7 of previous byte is still on the line
					// and needs to be sampled by CPU on the next rising edge.
					// Bit 0 of new byte will be output on the next falling edge.
				}
				else
				{
					// Transmission complete — leave the last bit on the line.
					// Do NOT call m_txd_cb(1) here: that would overwrite bit 7
					// of the last byte before the CPU samples it on the next
					// rising edge. The line will be updated when send_byte()
					// pre-outputs the next byte's bit 0.
					LOGMASKED(LOG_SERIAL, "cpanel TX done, holding last bit\n");
				}
			}
		}
	}
}

void kn5000_cpanel_device::send_byte(uint8_t data)
{
	LOGMASKED(LOG_SERIAL, "cpanel send_byte(%02X) tx_count=%d queue_size=%zu sioclk_state=%d\n",
		data, m_tx_clock_count, m_tx_queue.size(), m_sioclk_state);

	if (m_tx_clock_count == 0 && !m_tx_skip_first_falling)
	{
		// Start sending immediately
		m_tx_shift_register = data;
		m_tx_clock_count = 7;  // 7 more bits to send after pre-outputting bit 0

		// Pre-output first bit immediately so CPU can sample it on the first rising edge
		m_txd_cb(m_tx_shift_register & 1);
		LOGMASKED(LOG_SERIAL, "cpanel TX start: byte=%02X, pre-output bit=%d\n",
			data, data & 1);

		// Only skip the first falling edge if clock is currently HIGH.
		// If clock is HIGH: next edge = falling (skip it)
		// If clock is LOW: next edge = rising (CPU samples), then falling outputs bit 1 (no skip)
		m_tx_skip_first_falling = (m_sioclk_state == 1);
		LOGMASKED(LOG_SERIAL, "cpanel TX skip_first_falling=%d\n", m_tx_skip_first_falling);
	}
	else
	{
		// Queue for later
		m_tx_queue.push(data);
		LOGMASKED(LOG_SERIAL, "cpanel TX queued: byte=%02X\n", data);
	}
}

void kn5000_cpanel_device::process_received_byte(uint8_t data)
{
	LOGMASKED(LOG_SERIAL, "RX byte: %02X (cmd_index=%d, accept=%d)\n",
		data, m_cmd_index, m_accept_next_byte);

	// Skip bytes that weren't signaled as "real" via tx_start(1).  This
	// rejects phantom bytes (PFFC-off phases in firmware TX state machine)
	// and stale bytes assembled from continuous clock edges when no actual
	// transmission is in progress.
	//
	// Note: we do NOT consume (clear) accept_next_byte here.  The flag is
	// managed exclusively by tx_start via the deferred mechanism — pending
	// values are applied at byte boundaries in sioclk().  This avoids the
	// MAME timing race where tx_start for byte N+1 fires before byte N is
	// consumed (which would cause byte N to eat byte N+1's accept state).
	if (!m_accept_next_byte)
	{
		LOGMASKED(LOG_SERIAL, "cpanel: skipping unsolicited/phantom byte %02X\n", data);
		return;
	}

	// Ignore 0xFF when it appears as a command byte (first byte of pair).
	// In synchronous serial mode, the CPU must send dummy bytes to clock in
	// response data. These dummy 0xFF bytes are not valid commands — without
	// this filter they would be paired with the next real command byte,
	// misaligning the 2-byte command parser and potentially triggering
	// unintended LED commands or sync responses.
	if (m_cmd_index == 0 && data == 0xFF)
	{
		LOGMASKED(LOG_SERIAL, "cpanel: ignoring dummy byte 0xFF as command\n");
		return;
	}

	m_cmd_buffer[m_cmd_index++] = data;

	if (m_cmd_index >= 2)
	{
		// Full 2-byte command received
		process_command();
		m_cmd_index = 0;
	}
}

void kn5000_cpanel_device::process_command()
{
	uint8_t cmd = m_cmd_buffer[0];
	uint8_t param = m_cmd_buffer[1];

	// Panel selection: bits 7-5 >= 4 means right panel
	bool is_right_panel = (cmd & 0xe0) >= 0x80;

	LOGMASKED(LOG_COMMANDS, "Command: %02X %02X (%s panel)\n",
		cmd, param, is_right_panel ? "right" : "left");

	switch (cmd)
	{
	// Initialization commands — respond with sync.
	// These are sent one at a time during boot (not in rapid batches
	// like LED commands), so response accumulation isn't an issue.
	// The firmware checks for the sync response; without it, the
	// "ERROR in CPU data transmission" dialog appears.
	case 0x1f:  // Init sequence (left)
	case 0x1d:
	case 0x1e:
	case 0xdd:  // Setup mode
		LOGMASKED(LOG_COMMANDS, "Init command\n");
		send_sync_packet();
		m_initialized = true;
		break;

	// Query commands
	// The param byte encodes a segment index in bits 3-0.  Bit 4 is a mode
	// flag used by the panel MCUs (e.g., 0x10 = segment 0 scan mode, 0x13 =
	// segment 3 scan mode).  The HLE extracts the segment via param & 0x0F.
	// Param 0x00 (no flag, segment 0) is a sync/ping — everything else with
	// a valid segment (0-11) returns button data.
	case 0x20:  // Query left panel
	case 0x25:  // Query left panel (variant used in CPanel_ReadAllButtons)
	{
		int segment = param & 0x0f;
		if (param == 0x00)
		{
			send_sync_packet();
		}
		else if (segment <= 0x0b)
		{
			// Segment 0x0B is a hardware status register — return
			// WITHOUT panel flag so firmware stores at offset 11.
			send_button_packet(segment, (segment <= 0x0a));
		}
		else
		{
			send_sync_packet();
		}
		break;
	}

	case 0xe0:  // Query right panel
	case 0xe2:  // Query right panel (variant used in CPanel_ReadAllButtons)
	case 0xe3:  // Query right panel (variant used in CPanel_InitButtonState)
	{
		int segment = param & 0x0f;
		if (param == 0x00)
		{
			send_sync_packet();
		}
		else if (segment <= 0x0b)
		{
			send_button_packet(segment, false);  // right panel
		}
		else
		{
			send_sync_packet();
		}
		break;
	}

	case 0x2b:  // Init button state array (left)
		send_all_button_states(true);
		break;

	case 0xeb:  // Init button state array (right)
		send_all_button_states(false);
		break;

	// LED control commands - right panel
	// No response needed.  The firmware sends LED commands in rapid batches
	// (SM_TXComplete chains directly to SM_StartTX when more data exists).
	// If we queued sync responses, they'd accumulate because idle_detect
	// never fires during continuous clocking.  When finally delivered via
	// INTA, they'd conflict with the firmware's next TX command: INTA sets
	// IOC=1, blocking the baud rate timer and deadlocking the TX state
	// machine.  Real hardware panels process LED commands silently.
	case 0x00:
	case 0x01:
	case 0x02:
	case 0x03:
	case 0x04:
	case 0x08:
	case 0x0a:
	case 0x0b:
	case 0x0c:
		process_led_command(cmd, param);
		break;

	// LED control commands - left panel (same reasoning — no response)
	case 0xc0:
	case 0xc1:
	case 0xc2:
	case 0xc3:
	case 0xc4:
	case 0xc8:
		process_led_command(cmd, param);
		break;

	default:
		// Unknown command — do not respond.
		// Many panel commands (LCD display, encoder config, 7-segment
		// updates, etc.) are "fire and forget" — the real panel MCU
		// processes them silently without sending a response.  Sending
		// spurious sync responses here triggers INTA delivery, which
		// disrupts the firmware's serial state machine and can cause
		// wrong LED initialization (firmware skips LED commands or
		// takes different code paths due to unexpected RX data).
		LOGMASKED(LOG_COMMANDS, "Unknown command %02X %02X (no response)\n", cmd, param);
		break;
	}

	// Start idle detection for INTA-based response delivery.
	// sioclk() retriggers on every edge, creating a sliding 50µs window
	// that fires after the LAST clock edge (including SM_TXComplete's
	// phantom byte).  50µs ensures INTA + self-clocking (~140µs for 2
	// bytes) completes before WaitTXReady's ~375µs delay ends.
	//
	// For AW VM: dummy bytes clock out the response via CPU edges;
	// the retrigger keeps pushing the window forward, so idle_detect
	// only fires after SCLK goes idle (response already delivered).
	if (!m_self_clocking && (m_tx_clock_count > 0 || !m_tx_queue.empty()))
	{
		m_idle_detect_timer->adjust(attotime::from_usec(50));
	}
}

void kn5000_cpanel_device::send_sync_packet()
{
	// Type 3 sync packet: bits 5-3 = 011 = 0x18
	send_byte(0x18);
	send_byte(0x00);
}

uint8_t kn5000_cpanel_device::read_button_segment(int segment, bool is_left_panel)
{
	if (segment < 0 || segment > 10)
		return 0;

	ioport_port *port = is_left_panel ? m_cpl_ports[segment] : m_cpr_ports[segment];
	if (port)
	{
		return port->read() & 0xff;
	}
	return 0;
}

void kn5000_cpanel_device::send_button_packet(int segment, bool is_left_panel)
{
	// Button packet format (matching real panel MCU encoding):
	// Byte 0: [ Panel | Type | Segment ]
	//   - Bits 7:6: Panel select (00=right, 11=left)
	//   - Bits 5-3: Type (000/001 for button packets)
	//   - Bits 3-0: Segment index
	// Byte 1: Button state bitmap
	//
	// The firmware's event dispatcher translates headers via a ROM
	// lookup table at 0xEDA03C.  The table maps:
	//   Right (bits 7:6=00): segment 0-10 → event indices 0x0B-0x15
	//   Left  (bits 7:6=11): segment 0-10 → event indices 0x00-0x0A
	// Headers with bits 7:6=01 (old encoding) fall in a dead zone
	// (all map to 0x1F), causing left panel events to bypass LED dispatch.
	//
	// Note: the firmware's CPanel_RX_ButtonPacket internally uses bit 6
	// to route packets through different STATE_OF_CPANEL_BUTTONS paths.
	// Right (bit 6=0) → indices 0-10, Left (bit 6=1) → indices 16-26.
	// This internal naming is reversed from physical panels but correct.

	uint8_t state = read_button_segment(segment, is_left_panel);

	uint8_t header = (segment & 0x0f);
	if (is_left_panel)
		header |= 0xC0;  // Left panel: bits 7:6 = 11

	send_byte(header);
	send_byte(state);

	LOGMASKED(LOG_BUTTONS, "Button packet: seg=%d left=%d state=%02X\n",
		segment, is_left_panel, state);

	// Track state for change detection
	int state_idx = is_left_panel ? (segment + 11) : segment;
	m_last_button_state[state_idx] = state;
	m_pending_button_state[state_idx] = state;
}

void kn5000_cpanel_device::send_all_button_states(bool is_left_panel)
{
	// Send all 11 segments for the requested panel
	for (int seg = 0; seg <= 10; seg++)
	{
		send_button_packet(seg, is_left_panel);
	}
}

void kn5000_cpanel_device::queue_button_changes()
{
	// Currently unused — piggybacking removed in favor of per-segment
	// confirmation in button_scan_callback.  Kept for potential future use.
	//
	// Previously, this scanned all segments during command handlers to
	// piggyback change packets on the same INTA delivery.  This was
	// removed because it bypassed the per-segment confirmation logic,
	// allowing single-scan ghost toggles to be reported as real changes.
}

void kn5000_cpanel_device::process_led_command(uint8_t row, uint8_t data)
{
	LOGMASKED(LOG_LEDS, "LED command: row=%02X data=%02X\n", row, data);

	switch (row)
	{
	// Right panel LED rows
	case 0x00:
		m_cpr_leds[1] = BIT(data, 0);  // D101 - EFFECT: SUSTAIN
		m_cpr_leds[2] = BIT(data, 1);  // D102 - EFFECT: DIGITAL EFFECT
		m_cpr_leds[3] = BIT(data, 2);  // D103 - EFFECT: DSP EFFECT
		m_cpr_leds[4] = BIT(data, 3);  // D104 - EFFECT: DIGITAL REVERB
		m_cpr_leds[5] = BIT(data, 4);  // D105 - EFFECT: ACOUSTIC ILLUSION
		m_cpr_leds[6] = BIT(data, 5);  // D106 - SEQUENCER: PLAY
		m_cpr_leds[7] = BIT(data, 6);  // D107 - SEQUENCER: EASY REC
		m_cpr_leds[8] = BIT(data, 7);  // D108 - SEQUENCER: MENU
		break;

	case 0x01:
		m_cpr_leds[9] = BIT(data, 0);   // D109 - PIANO
		m_cpr_leds[10] = BIT(data, 1);  // D110 - GUITAR
		m_cpr_leds[11] = BIT(data, 2);  // D111 - STRINGS & VOCAL
		m_cpr_leds[12] = BIT(data, 3);  // D112 - BRASS
		m_cpr_leds[13] = BIT(data, 4);  // D113 - FLUTE
		m_cpr_leds[14] = BIT(data, 5);  // D114 - SAX & REED
		m_cpr_leds[15] = BIT(data, 6);  // D115 - MALLET & ORCH PERC
		m_cpr_leds[16] = BIT(data, 7);  // D116 - WORLD PERC
		break;

	case 0x02:
		m_cpr_leds[17] = BIT(data, 0);  // D117 - ORGAN & ACCORDION
		m_cpr_leds[18] = BIT(data, 1);  // D118 - ORCHESTRAL PAD
		m_cpr_leds[19] = BIT(data, 2);  // D119 - SYNTH
		m_cpr_leds[20] = BIT(data, 3);  // D120 - BASS
		m_cpr_leds[21] = BIT(data, 4);  // D121 - DIGITAL DRAWBAR
		m_cpr_leds[22] = BIT(data, 5);  // D122 - ACCORDION REGISTER
		m_cpr_leds[23] = BIT(data, 6);  // D123 - GM SPECIAL
		m_cpr_leds[24] = BIT(data, 7);  // D124 - DRUM KITS
		break;

	case 0x03:
		m_cpr_leds[25] = BIT(data, 0);  // D125 - PANEL MEMORY 1
		m_cpr_leds[26] = BIT(data, 1);  // D126 - PANEL MEMORY 2
		m_cpr_leds[27] = BIT(data, 2);  // D127 - PANEL MEMORY 3
		m_cpr_leds[28] = BIT(data, 3);  // D128 - PANEL MEMORY 4
		m_cpr_leds[29] = BIT(data, 4);  // D129 - PANEL MEMORY 5
		m_cpr_leds[30] = BIT(data, 5);  // D130 - PANEL MEMORY 6
		m_cpr_leds[31] = BIT(data, 6);  // D131 - PANEL MEMORY 7
		m_cpr_leds[32] = BIT(data, 7);  // D132 - PANEL MEMORY 8
		break;

	case 0x04:
		m_cpr_leds[33] = BIT(data, 0);  // D133 - PART SELECT: LEFT
		m_cpr_leds[34] = BIT(data, 1);  // D134 - PART SELECT: RIGHT 2
		m_cpr_leds[35] = BIT(data, 2);  // D135 - PART SELECT: RIGHT 1
		m_cpr_leds[36] = BIT(data, 3);  // D136 - ENTERTAINER
		m_cpr_leds[37] = BIT(data, 4);  // D137 - CONDUCTOR: LEFT
		m_cpr_leds[38] = BIT(data, 5);  // D138 - CONDUCTOR: RIGHT 2
		m_cpr_leds[39] = BIT(data, 6);  // D139 - CONDUCTOR: RIGHT 1
		m_cpr_leds[40] = BIT(data, 7);  // D140 - TECHNI CHORD
		break;

	case 0x08:
		m_cpr_leds[49] = BIT(data, 0);  // D149 - MENU: SOUND
		m_cpr_leds[50] = BIT(data, 1);  // D150 - MENU: CONTROL
		m_cpr_leds[51] = BIT(data, 2);  // D151 - MENU: MIDI
		m_cpr_leds[52] = BIT(data, 3);  // D152 - MENU: DISK
		break;

	case 0x0a:
		m_cpr_leds[57] = BIT(data, 0);  // D157 - MEMORY A
		m_cpr_leds[58] = BIT(data, 1);  // D158 - MEMORY B
		break;

	case 0x0b:
		m_cpr_leds[61] = BIT(data, 0);  // D161 - SYNCHRO & BREAK
		m_cpr_leds[62] = BIT(data, 1);  // D162 - R1/R2 OCTAVE MINUS
		m_cpr_leds[63] = BIT(data, 2);  // D163 - R1/R2 OCTAVE PLUS
		m_cpr_leds[64] = BIT(data, 3);  // D164 - BANK VIEW
		break;

	case 0x0c:
		m_cpr_leds[65] = BIT(data, 0);  // D165 - START/STOP 1 BEAT
		m_cpr_leds[66] = BIT(data, 1);  // D166 - START/STOP 2 BEAT
		m_cpr_leds[67] = BIT(data, 2);  // D167 - START/STOP 3 BEAT
		m_cpr_leds[68] = BIT(data, 3);  // D168 - START/STOP 4 BEAT
		break;

	// Left panel LED rows
	case 0xc0:
		m_cpl_leds[1] = BIT(data, 0);  // D101 - COMPOSER: MEMORY
		m_cpl_leds[2] = BIT(data, 1);  // D102 - COMPOSER: MENU
		m_cpl_leds[3] = BIT(data, 2);  // D103 - SOUND ARRANGER: SET
		m_cpl_leds[4] = BIT(data, 3);  // D104 - SOUND ARRANGER: ON/OFF
		m_cpl_leds[5] = BIT(data, 4);  // D105 - MUSIC STYLIST
		m_cpl_leds[6] = BIT(data, 5);  // D106 - FADE IN
		m_cpl_leds[7] = BIT(data, 6);  // D107 - FADE OUT
		m_cpl_leds[8] = BIT(data, 7);  // D108 - DISPLAY HOLD
		break;

	case 0xc1:
		m_cpl_leds[9] = BIT(data, 0);   // D109 - U.S. TRAD
		m_cpl_leds[10] = BIT(data, 1);  // D110 - COUNTRY
		m_cpl_leds[11] = BIT(data, 2);  // D111 - LATIN
		m_cpl_leds[12] = BIT(data, 3);  // D112 - MARCH & WALTZ
		m_cpl_leds[13] = BIT(data, 4);  // D113 - PARTY TIME
		m_cpl_leds[14] = BIT(data, 5);  // D114 - SHOW TIME & TRAD DANCE
		m_cpl_leds[15] = BIT(data, 6);  // D115 - WORLD
		m_cpl_leds[16] = BIT(data, 7);  // D116 - CUSTOM
		break;

	case 0xc2:
		m_cpl_leds[17] = BIT(data, 0);  // D117 - STANDARD ROCK
		m_cpl_leds[18] = BIT(data, 1);  // D118 - R & ROLL & BLUES
		m_cpl_leds[19] = BIT(data, 2);  // D119 - POP & BALLAD
		m_cpl_leds[20] = BIT(data, 3);  // D120 - FUNK & FUSION
		m_cpl_leds[21] = BIT(data, 4);  // D121 - SOUL & MODERN DANCE
		m_cpl_leds[22] = BIT(data, 5);  // D122 - BIG BAND & SWING
		m_cpl_leds[23] = BIT(data, 6);  // D123 - JAZZ COMBO
		m_cpl_leds[24] = BIT(data, 7);  // D124 - MANUAL SEQUENCE PADS: MENU
		break;

	case 0xc3:
		m_cpl_leds[25] = BIT(data, 0);  // D125 - VARIATION & MSA 1
		m_cpl_leds[26] = BIT(data, 1);  // D126 - VARIATION & MSA 2
		m_cpl_leds[27] = BIT(data, 2);  // D127 - VARIATION & MSA 3
		m_cpl_leds[28] = BIT(data, 3);  // D128 - VARIATION & MSA 4
		m_cpl_leds[29] = BIT(data, 4);  // D129 - MUSIC STYLE ARRANGER
		m_cpl_leds[30] = BIT(data, 5);  // D130 - AUTO PLAY CHORD
		break;

	case 0xc4:
		m_cpl_leds[33] = BIT(data, 0);  // D133 - FILL IN 1
		m_cpl_leds[34] = BIT(data, 1);  // D134 - FILL IN 2
		m_cpl_leds[35] = BIT(data, 2);  // D135 - INTRO & ENDING 1
		m_cpl_leds[36] = BIT(data, 3);  // D136 - INTRO & ENDING 2
		m_cpl_leds[37] = BIT(data, 4);  // D137 - SPLIT POINT INDICATOR (LEFT)
		m_cpl_leds[38] = BIT(data, 5);  // D138 - SPLIT POINT INDICATOR (CENTER)
		m_cpl_leds[39] = BIT(data, 6);  // D139 - SPLIT POINT INDICATOR (RIGHT)
		m_cpl_leds[40] = BIT(data, 7);  // D140 - TEMPO/PROGRAM
		break;

	case 0xc8:
		m_cpl_leds[49] = BIT(data, 0);  // D149 - OTHER PARTS/TR
		break;
	}
}

TIMER_CALLBACK_MEMBER(kn5000_cpanel_device::timer_callback)
{
	// Timer drives the serial clock when we have data to send
	if (m_tx_clock_count > 0 || !m_tx_queue.empty())
	{
		// Toggle clock to shift out data
		m_sclk_out_cb(1);
		m_sclk_out_cb(0);
	}
}

TIMER_CALLBACK_MEMBER(kn5000_cpanel_device::idle_detect_callback)
{
	// The external serial clock (from CPU) has been idle for 250µs.
	// If we have pending response data, the CPU is not going to send
	// dummy bytes to clock it out — switch to self-clocking mode and
	// assert INTA so the CPU's firmware can enable receive mode.
	//
	// The sliding 50µs window (retriggered on every sioclk edge) ensures
	// this fires AFTER the firmware's phantom bytes complete: the phantom
	// byte edges are 4µs apart (well within 50µs), so the window slides
	// past them.  Only after the last edge does the 50µs expire.

	if (m_tx_clock_count > 0 || !m_tx_queue.empty())
	{
		// Enable TX output — response data was frozen during phantom bytes
		m_tx_output_enabled = true;

		if (m_inta_asserted)
		{
			// Multi-packet continuation: INTA is already asserted (PE.5 HIGH)
			// from the previous packet.  Do an atomic pulse (deassert then
			// reassert within this same timer callback) to re-trigger the
			// INTA interrupt.  Since the CPU doesn't execute between timer
			// callback calls, it never observes PE.5=LOW — WaitTXReady
			// stays blocked throughout the multi-packet delivery.
			LOGMASKED(LOG_SERIAL, "cpanel: re-triggering INTA for next packet (%zu bytes queued)\n",
				m_tx_queue.size());
			m_inta_cb(0);  // deassert — clears INTEAB flag, updates m_level
			m_inta_cb(1);  // reassert — sets INTEAB flag, triggers interrupt
			// m_inta_asserted stays true throughout
		}
		else
		{
			// First response packet: assert INTA for the first time
			LOGMASKED(LOG_SERIAL, "cpanel: external clock idle, asserting INTA and starting self-clock\n");
			m_inta_asserted = true;
			m_inta_cb(1);
		}

		// Reset byte counter for this INTA cycle
		m_self_clock_bytes_sent = 0;

		// Start self-clocking after a brief delay to let the CPU process
		// the INTA interrupt and enable receive mode (set IOC=1).
		// 20µs ≈ 320 CPU cycles at 16 MHz — plenty for the ISR.
		// Shorter delay means self-clocking finishes sooner, well before
		// WaitTXReady's ~375µs delay loop checks PE.5.
		m_self_clocking = true;
		m_self_clock_timer->adjust(attotime::from_usec(20), 0, attotime::from_hz(250000));
	}
}

TIMER_CALLBACK_MEMBER(kn5000_cpanel_device::self_clock_callback)
{
	// Drive one clock edge per callback (toggle), matching the CPU serial
	// timer's behavior. At 250 kHz, this gives 125 kHz SCLK = one bit
	// every 8µs, one byte every 64µs.
	int new_state = m_sioclk_state ^ 1;
	m_sclk_out_cb(new_state);
	// The edge propagates: cpanel sclk_out → CPU serial sioclk → CPU serial
	// sclk_out → cpanel sioclk. Both sides process the edge.

	// Check completion and packet-pause after RISING edges.  The preceding
	// falling edge output bit 7 and decremented tx_clock_count to 0 (and
	// incremented m_self_clock_bytes_sent).  This rising edge lets the CPU
	// sample that last bit before we stop.
	if (new_state == 1)
	{
		if (m_tx_queue.empty() && m_tx_clock_count == 0)
		{
			// All response data sent — stop self-clocking and deassert INTA.
			LOGMASKED(LOG_SERIAL, "cpanel: self-clock TX complete (%d bytes), deasserting INTA\n",
				m_self_clock_bytes_sent);
			m_self_clocking = false;
			m_self_clock_timer->reset(attotime::never);

			if (m_inta_asserted)
			{
				m_inta_asserted = false;
				m_inta_cb(0);
			}

			// Button scan timer runs periodically (set in device_reset),
			// no need to reschedule from here.
		}
		else if (m_self_clock_bytes_sent >= 2)
		{
			// Pause after 2-byte packet.  The firmware processes responses
			// in 2-byte packets; after SM_RXByteN finishes, the INTA handler
			// writes SC1CR (resetting rx_clock_count=8).  Continuous clocking
			// would corrupt the next byte mid-reception.  Real hardware
			// delivers one packet per INTA cycle.
			LOGMASKED(LOG_SERIAL, "cpanel: self-clock pausing after 2-byte packet, %zu bytes queued\n",
				m_tx_queue.size());
			m_self_clocking = false;
			m_self_clock_timer->reset(attotime::never);

			// Keep INTA asserted during the gap.  PE.5 stays HIGH, which
			// prevents the firmware's WaitTXReady from passing and starting
			// the next command while multi-packet response data is still
			// queued.  idle_detect_callback will re-trigger the interrupt
			// via an atomic pulse (deassert+reassert in same callback, so
			// the CPU never observes PE.5=LOW between packets).

			// Schedule re-trigger for next packet after 20µs.
			// On real hardware, the panel MCU responds continuously (no
			// inter-packet gap), delivering 22 bytes in ~704µs at 250kHz.
			// The firmware's CPanel_InitButtonState waits only ~1.44ms
			// (3×DELAY_6_TICKS) before calling CPanel_RX_ProcessWithFlag,
			// which processes all available data WITH flag bit 2 set.
			// A 200µs gap inflates delivery to ~3ms, causing partial
			// processing (only ~5 of 11 segments processed with the flag).
			// 20µs is enough for the CPU's INTA ISR (~10 instructions)
			// while keeping total delivery ~1.2ms (within the 1.44ms window).
			m_idle_detect_timer->adjust(attotime::from_usec(20));
		}
	}
}

TIMER_CALLBACK_MEMBER(kn5000_cpanel_device::button_scan_callback)
{
	// Proactive button change detection (periodic, 7ms / ~143 Hz).
	// On real hardware, the panel MCUs continuously scan their button
	// matrices and push change notifications via INTA to the CPU —
	// independent of any query from the CPU.  The firmware's steady-state
	// polling only queries segment 3 (E0 13 every ~42 iterations).
	//
	// Per-segment confirmation: a state change must be stable for 2
	// consecutive scans (14ms) before being reported.  This filters
	// single-scan glitches (ghost toggles) where MAME input ports
	// momentarily return non-zero values that revert on the next read.
	// On real hardware, physical button presses last 50-100ms minimum,
	// so 14ms confirmation is well within tolerance.

	if (!m_initialized)
		return;

	// Don't queue changes while actively self-clocking or while INTA is
	// asserted — the firmware's serial state machine is busy processing
	// a previous response.  Wait for the current delivery to complete.
	if (m_self_clocking || m_inta_asserted)
		return;

	// Don't queue changes while the CPU is actively transmitting (TX data
	// pending in our RX path).  Wait for the current command to complete.
	if (!m_rx_waiting_for_start)
		return;

	bool changed = false;

	// Scan right panel segments 0-10
	for (int seg = 0; seg <= 10; seg++)
	{
		if (!m_cpr_ports[seg])
			continue;
		uint8_t state = m_cpr_ports[seg]->read() & 0xff;
		if (state != m_last_button_state[seg])
		{
			// State differs from last confirmed — check if pending agrees
			if (state == m_pending_button_state[seg])
			{
				// Stable for 2 scans: confirmed change
				LOGMASKED(LOG_BUTTONS, "cpanel: confirmed right seg %d change (%02X->%02X)\n",
					seg, m_last_button_state[seg], state);
				send_button_packet(seg, false);
				changed = true;
			}
			else
			{
				// First observation — record as pending, wait for confirmation
				LOGMASKED(LOG_BUTTONS, "cpanel: pending right seg %d change (%02X->%02X)\n",
					seg, m_last_button_state[seg], state);
				m_pending_button_state[seg] = state;
			}
		}
		else
		{
			// Matches confirmed state — reset pending
			m_pending_button_state[seg] = state;
		}
	}

	// Scan left panel segments 0-10
	for (int seg = 0; seg <= 10; seg++)
	{
		if (!m_cpl_ports[seg])
			continue;
		int idx = seg + 11;
		uint8_t state = m_cpl_ports[seg]->read() & 0xff;
		if (state != m_last_button_state[idx])
		{
			if (state == m_pending_button_state[idx])
			{
				LOGMASKED(LOG_BUTTONS, "cpanel: confirmed left seg %d change (%02X->%02X)\n",
					seg, m_last_button_state[idx], state);
				send_button_packet(seg, true);
				changed = true;
			}
			else
			{
				LOGMASKED(LOG_BUTTONS, "cpanel: pending left seg %d change (%02X->%02X)\n",
					seg, m_last_button_state[idx], state);
				m_pending_button_state[idx] = state;
			}
		}
		else
		{
			m_pending_button_state[idx] = state;
		}
	}

	if (changed)
	{
		LOGMASKED(LOG_BUTTONS, "cpanel: confirmed button change, triggering INTA delivery\n");
		m_idle_detect_timer->adjust(attotime::from_usec(50));
	}
}
