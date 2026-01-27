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
	    Type 0,1: Button state (bit 6 selects panel: 0=right, 1=left)
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

#define VERBOSE (LOG_COMMANDS)
#include "logmacro.h"

DEFINE_DEVICE_TYPE(KN5000_CPANEL, kn5000_cpanel_device, "kn5000_cpanel", "KN5000 Control Panel HLE")

kn5000_cpanel_device::kn5000_cpanel_device(const machine_config &mconfig, const char *tag, device_t *owner, uint32_t clock) :
	device_t(mconfig, KN5000_CPANEL, tag, owner, clock),
	m_timer(nullptr),
	m_baud_rate(0),
	m_rx_clock_count(8),
	m_rx_shift_register(0),
	m_rxd(1),
	m_sioclk_state(0),
	m_tx_clock_count(0),
	m_tx_shift_register(0xff),
	m_cmd_index(0),
	m_initialized(false),
	m_txd_cb(*this),
	m_sclk_out_cb(*this)
{
	std::fill(std::begin(m_cmd_buffer), std::end(m_cmd_buffer), 0);
	std::fill(std::begin(m_last_button_state), std::end(m_last_button_state), 0);
	std::fill(std::begin(m_cpl_ports), std::end(m_cpl_ports), nullptr);
	std::fill(std::begin(m_cpr_ports), std::end(m_cpr_ports), nullptr);
}

void kn5000_cpanel_device::device_start()
{
	m_timer = timer_alloc(FUNC(kn5000_cpanel_device::timer_callback), this);

	// Save state
	save_item(NAME(m_baud_rate));
	save_item(NAME(m_rx_clock_count));
	save_item(NAME(m_rx_shift_register));
	save_item(NAME(m_rxd));
	save_item(NAME(m_sioclk_state));
	save_item(NAME(m_tx_clock_count));
	save_item(NAME(m_tx_shift_register));
	save_item(NAME(m_cmd_buffer));
	save_item(NAME(m_cmd_index));
	save_item(NAME(m_initialized));
	save_item(NAME(m_last_button_state));

	// Initial state - line idle high
	m_txd_cb(1);
}

void kn5000_cpanel_device::device_reset()
{
	m_baud_rate = 0;
	m_rx_clock_count = 8;
	m_tx_clock_count = 0;
	m_cmd_index = 0;
	m_initialized = false;

	// Clear TX queue
	while (!m_tx_queue.empty())
		m_tx_queue.pop();

	std::fill(std::begin(m_last_button_state), std::end(m_last_button_state), 0);
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

void kn5000_cpanel_device::sioclk(int state)
{
	if (m_sioclk_state == state)
		return;

	m_sioclk_state = state;

	if (state)
	{
		// Rising edge: Sample RXD (receive bit from CPU)
		if (m_rx_clock_count > 0)
		{
			m_rx_shift_register >>= 1;
			m_rx_shift_register |= (m_rxd << 7);
			m_rx_clock_count--;

			if (m_rx_clock_count == 0)
			{
				// Full byte received
				m_rx_clock_count = 8;
				process_received_byte(m_rx_shift_register);
			}
		}
	}
	else
	{
		// Falling edge: Output TXD (transmit bit to CPU)
		// This prepares the bit for the CPU to sample on the next rising edge
		if (m_tx_clock_count > 0)
		{
			m_txd_cb(m_tx_shift_register & 1);
			m_tx_shift_register >>= 1;
			m_tx_clock_count--;

			if (m_tx_clock_count == 0)
			{
				// Byte sent, check for more
				if (!m_tx_queue.empty())
				{
					m_tx_shift_register = m_tx_queue.front();
					m_tx_queue.pop();
					m_tx_clock_count = 8;
				}
				else
				{
					// Return to idle
					m_txd_cb(1);
				}
			}
		}
	}
}

void kn5000_cpanel_device::send_byte(uint8_t data)
{
	if (m_tx_clock_count == 0)
	{
		// Start sending immediately
		m_tx_shift_register = data;
		m_tx_clock_count = 8;
	}
	else
	{
		// Queue for later
		m_tx_queue.push(data);
	}
}

void kn5000_cpanel_device::process_received_byte(uint8_t data)
{
	LOGMASKED(LOG_SERIAL, "RX byte: %02X (cmd_index=%d)\n", data, m_cmd_index);

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
	// Initialization commands
	case 0x1f:  // Init sequence (left)
	case 0x1d:
	case 0x1e:
	case 0xdd:  // Setup mode
		LOGMASKED(LOG_COMMANDS, "Init command\n");
		send_sync_packet();
		m_initialized = true;
		break;

	// Query commands
	case 0x20:  // Query left panel
	case 0xe0:  // Query right panel
		if (param == 0x00)
		{
			// Ping - respond with sync
			send_sync_packet();
		}
		else if (param <= 0x0a)
		{
			// Button segment query
			send_button_packet(param, !is_right_panel);
		}
		else if (param == 0x0b || param == 0x10)
		{
			// Status query
			send_sync_packet();
		}
		break;

	case 0x25:  // Left panel data command
	case 0xe2:  // Right panel query
	case 0xe3:  // Right panel extended query
		send_sync_packet();
		break;

	case 0x2b:  // Init button state array (left)
		send_all_button_states(true);
		break;

	case 0xeb:  // Init button state array (right)
		send_all_button_states(false);
		break;

	default:
		// Unknown command - send sync as acknowledgment
		LOGMASKED(LOG_COMMANDS, "Unknown command %02X %02X\n", cmd, param);
		send_sync_packet();
		break;
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
	// Button packet format:
	// Byte 0: [ Panel | Type | Segment ]
	//   - Bit 6: Panel select (0=right, 1=left)
	//   - Bits 5-3: Type 0 or 1 (button packet)
	//   - Bits 3-0 + bit 6: Segment index
	// Byte 1: Button state bitmap

	uint8_t state = read_button_segment(segment, is_left_panel);

	// For button packets, bit 6 indicates left panel
	uint8_t header = (segment & 0x0f);
	if (is_left_panel)
		header |= 0x40;  // Set bit 6 for left panel

	// Type 0 for buttons (bits 5-3 = 000)
	send_byte(header);
	send_byte(state);

	LOGMASKED(LOG_BUTTONS, "Button packet: seg=%d left=%d state=%02X\n",
		segment, is_left_panel, state);

	// Track state for change detection
	int state_idx = is_left_panel ? (segment + 11) : segment;
	m_last_button_state[state_idx] = state;
}

void kn5000_cpanel_device::send_all_button_states(bool is_left_panel)
{
	// Send all 11 segments for the requested panel
	for (int seg = 0; seg <= 10; seg++)
	{
		send_button_packet(seg, is_left_panel);
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
