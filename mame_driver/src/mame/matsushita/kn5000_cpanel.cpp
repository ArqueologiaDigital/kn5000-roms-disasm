// license:GPL2+
// copyright-holders:Felipe Sanches
/***************************************************************************

	KN5000 control panel

***************************************************************************/

#include "emu.h"
#include "kn5000_cpanel.h"

#include "logmacro.h"

DEFINE_DEVICE_TYPE(KN5000_CPANEL, kn5000_cpanel_device, "kn5000_cpanel", "KN5000 Control Panel")

kn5000_cpanel_device::kn5000_cpanel_device(const machine_config &mconfig, const char *tag, device_t *owner, uint32_t clock) :
	device_t(mconfig, KN5000_CPANEL, tag, owner, clock),
	m_baud_rate(0),
	m_rx_clock_count(8),
	m_rx_shift_register(0),
	m_rx_buffer(0),
	m_rxd(0),
	m_rxd_prev(0),
	m_sioclk_state(0),
	m_tx_clock_count(0),
	m_tx_shift_register(0),
	m_txd(0),
	m_sclk_out(0),
	m_txd_cb(*this),
	m_sclk_in_cb(*this),
	m_sclk_out_cb(*this)
{
}

void kn5000_cpanel_device::device_start()
{
	m_timer = timer_alloc(FUNC(kn5000_cpanel_device::timer_callback), this);

	save_item(NAME(m_baud_rate));
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

	m_sclk_out_cb(m_sclk_out);
	m_txd_cb(m_txd);
	
	set_baudrate(31250);
	write(0xe2);
}

void kn5000_cpanel_device::device_reset()
{
	m_baud_rate = 0;
}

void kn5000_cpanel_device::sioclk(int state)
{
	if (m_sioclk_state == state)
		return;

	m_sioclk_state = state;
	// logerror("sioclk state=%d rxd=%d m_rx_clock_count=%d txd=%d m_tx_clock_count=%d\n", m_sioclk_state, m_rxd, m_rx_clock_count, m_txd, m_tx_clock_count);

	if (m_rx_clock_count){
		m_rx_clock_count--;

		m_rx_shift_register >>= 1;
		m_rx_shift_register |= (m_rxd << 7);

		if (m_rx_clock_count == 0)
		{
			m_rx_clock_count = 8;
			m_rx_buffer = m_rx_shift_register;
		}
	}

	if (m_tx_clock_count){
		logerror("send bit #%d: %d\n", 8-m_tx_clock_count, m_tx_shift_register & 1);

		m_txd_cb(m_tx_shift_register & 1);
		m_sclk_out_cb(1);
		m_sclk_out_cb(0);
		m_tx_shift_register >>= 1;
		if (--m_tx_clock_count == 0) {
			logerror("Finished sending byte.\n");
		}
	}
}

void kn5000_cpanel_device::rxd(int state)
{
	if (m_rxd != state)
	{
		m_rxd = state;
	}
}


void kn5000_cpanel_device::write(uint8_t data)
{
	logerror("write: %02X\n", data);
	m_tx_shift_register = data;
	m_tx_clock_count = 8;
}

void kn5000_cpanel_device::set_baudrate(uint16_t br)
{
	m_baud_rate = br;
	logerror("baud rate: %d\n", br);
	if (br)
	{
		m_timer->adjust(attotime::from_hz(m_baud_rate), 0, attotime::from_hz(m_baud_rate));
		logerror("timer set to %d Hz.\n", m_baud_rate);
	} else {
		m_timer->reset(attotime::never);
		logerror("timer disabled.\n");
	}
}

TIMER_CALLBACK_MEMBER(kn5000_cpanel_device::timer_callback)
{

	if (m_baud_rate && m_tx_clock_count)
	{
		sioclk(m_sioclk_state ^ 1);
	}
}
