// license:GPL2+
// copyright-holders:Felipe Sanches
/***************************************************************************

	KN5000 control panel

***************************************************************************/

#ifndef MAME_MATSUSHITA_KN5000_CPANEL_H
#define MAME_MATSUSHITA_KN5000_CPANEL_H

#pragma once

class kn5000_cpanel_device :
	public device_t
{
public:
	kn5000_cpanel_device(const machine_config &mconfig, const char *tag, device_t *owner, uint32_t clock = 0);

	void rxd(int state);
	auto txd() { return m_txd_cb.bind(); }
	auto sclk_in() { return m_sclk_in_cb.bind(); }
	auto sclk_out() { return m_sclk_out_cb.bind(); }

	void set_baudrate(uint16_t br);
	void write(uint8_t data);
	void sioclk(int state);

protected:
	// device_t
	virtual void device_start() override ATTR_COLD;
	virtual void device_reset() override ATTR_COLD;

	TIMER_CALLBACK_MEMBER(timer_callback);

	emu_timer *m_timer;

	uint8_t m_baud_rate;

	uint8_t m_rx_clock_count;
	uint8_t m_rx_shift_register;
	uint8_t m_rx_buffer;
	uint8_t m_rxd;
	uint8_t m_rxd_prev;
	uint8_t m_sioclk_state;

	uint8_t m_tx_clock_count;
	uint8_t m_tx_shift_register;
	uint8_t m_txd;
	uint8_t m_sclk_out;

	devcb_write_line m_txd_cb;
	devcb_write_line m_sclk_in_cb;
	devcb_write_line m_sclk_out_cb;
};

DECLARE_DEVICE_TYPE(KN5000_CPANEL, kn5000_cpanel_device)

#endif // MAME_MATSUSHITA_KN5000_CPANEL_H
