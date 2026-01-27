// license:GPL2+
// copyright-holders:Felipe Sanches
/***************************************************************************

	KN5000 control panel HLE

	Emulates the two Mitsubishi M37471M2196S MCUs on the control panel.
	Since no ROM dumps are available, this uses High Level Emulation based
	on reverse engineering of the main CPU firmware protocol.

	Protocol documentation: https://felipesanches.github.io/kn5000-docs/control-panel-protocol/

***************************************************************************/

#ifndef MAME_MATSUSHITA_KN5000_CPANEL_H
#define MAME_MATSUSHITA_KN5000_CPANEL_H

#pragma once

class kn5000_cpanel_device :
	public device_t
{
public:
	kn5000_cpanel_device(const machine_config &mconfig, const char *tag, device_t *owner, uint32_t clock = 0);

	// Serial interface from main CPU
	void rxd(int state);
	void sioclk(int state);

	// Callbacks to main CPU
	auto txd() { return m_txd_cb.bind(); }
	auto sclk_out() { return m_sclk_out_cb.bind(); }

	// Configuration
	void set_baudrate(uint16_t br);

	// Button input port setters (called from main driver)
	void set_cpl_port(int n, ioport_port *port) { m_cpl_ports[n] = port; }
	void set_cpr_port(int n, ioport_port *port) { m_cpr_ports[n] = port; }

protected:
	// device_t overrides
	virtual void device_start() override ATTR_COLD;
	virtual void device_reset() override ATTR_COLD;

	TIMER_CALLBACK_MEMBER(timer_callback);

private:
	// Serial communication
	void send_byte(uint8_t data);
	void process_received_byte(uint8_t data);
	void process_command();

	// Response generation
	void send_sync_packet();
	void send_button_packet(int segment, bool is_left_panel);
	void send_all_button_states(bool is_left_panel);

	// Read button state from input ports
	uint8_t read_button_segment(int segment, bool is_left_panel);

	// Timer
	emu_timer *m_timer;
	uint16_t m_baud_rate;

	// Serial RX state
	uint8_t m_rx_clock_count;
	uint8_t m_rx_shift_register;
	uint8_t m_rxd;
	uint8_t m_sioclk_state;

	// Serial TX state
	uint8_t m_tx_clock_count;
	uint8_t m_tx_shift_register;
	std::queue<uint8_t> m_tx_queue;

	// Command buffer (2-byte commands)
	uint8_t m_cmd_buffer[2];
	uint8_t m_cmd_index;

	// Protocol state
	bool m_initialized;
	uint8_t m_last_button_state[22];  // 11 segments * 2 panels

	// Callbacks
	devcb_write_line m_txd_cb;
	devcb_write_line m_sclk_out_cb;

	// Input port pointers (set by main driver)
	ioport_port *m_cpl_ports[11];  // Left panel segments 0-10
	ioport_port *m_cpr_ports[11];  // Right panel segments 0-10
};

DECLARE_DEVICE_TYPE(KN5000_CPANEL, kn5000_cpanel_device)

#endif // MAME_MATSUSHITA_KN5000_CPANEL_H
