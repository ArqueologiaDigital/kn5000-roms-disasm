// license:BSD-3-Clause
// copyright-holders:Olivier Galibert, Felipe Sanches
//
// HD-AE5000, Hard Disk & Audio Extension for Technics KN5000 emulation
//
// The HD-AE5000 was an extension board for the Technics KN5000 musical keyboard.
// It provided a hard-disk, additional audio outputs and a serial port to interface
// with a computer to transfer files to/from the hard-drive.
//
// Hardware:
//   - 2.5" IDE Hard Disk (1.08GB capacity)
//   - NEC uPD71055 (i8255 compatible) PPI for parallel port
//   - 512KB Static RAM (2x 256KB)
//   - 512KB ROM
//
// Memory Map (accessible from main CPU address space):
//   0x130010-0x130020: ATA/IDE registers (directly mapped)
//   0x160000-0x160007: PPI (parallel port for PC communication)
//   0x200000-0x27FFFF: Static RAM (512KB)
//   0x280000-0x2FFFFF: ROM (512KB)
//
// The firmware uses CHS (Cylinder/Head/Sector) addressing with a custom
// filesystem using FSB (File System Block), FGB (File Group Block), and
// FEB (File Entry Block) structures.
//
// ATA Register Map (verified from firmware analysis):
//   0x130010: Data Register (16-bit R/W)
//   0x130012: Error (R) / Features (W)
//   0x130014: Sector Count
//   0x130016: Sector Number / LBA Low
//   0x130018: Cylinder Low / LBA Mid
//   0x13001A: Cylinder High / LBA High
//   0x13001C: Device/Head (written as 0xA0 | head)
//   0x13001E: Status (R) / Command (W)
//   0x130020: Device Control (W)
//
// ATA Commands used by firmware:
//   0x20: Read Sectors (PIO)
//   0x30: Write Sectors (PIO)
//   0x94: Standby (spin down with timeout)
//   0xEC: Identify Device

#include "emu.h"
#include "hdae5000.h"

#include "bus/ata/hdd.h"
#include "machine/i8255.h"

#define LOG_ATA    (1U << 1)
#define LOG_PPI    (1U << 2)

#define VERBOSE (0)
#include "logmacro.h"

namespace {

class hdae5000_device : public device_t, public device_kn5000_extension_interface
{
public:
	static constexpr feature_type unemulated_features() { return feature::SOUND; }

	hdae5000_device(const machine_config &mconfig, const char *tag, device_t *owner, uint32_t clock = 0);

	virtual void program_map(address_space_installer &space) override;

protected:
	virtual void device_start() override ATTR_COLD;
	virtual void device_reset() override ATTR_COLD;
	virtual void device_add_mconfig(machine_config &config) override ATTR_COLD;

	virtual const tiny_rom_entry *device_rom_region() const override ATTR_COLD;

private:
	required_device<ide_hdd_device> m_hdd;
	required_device<i8255_device> m_ppi;
	required_memory_region m_rom;
	memory_share_creator<uint16_t> m_ram;

	void card_map(address_map &map) ATTR_COLD;

	// ATA interface - directly connected to IDE HDD
	uint16_t ata_data_r();
	void ata_data_w(uint16_t data);
	uint8_t ata_r(offs_t offset);
	void ata_w(offs_t offset, uint8_t data);
	void ata_ctrl_w(uint8_t data);

	// PPI callbacks for parallel port
	uint8_t ppi_pa_r();
	void ppi_pa_w(uint8_t data);
	uint8_t ppi_pb_r();
	void ppi_pc_w(uint8_t data);

	// Parallel port state
	uint8_t m_pport_data;
	uint8_t m_pport_status;
	uint8_t m_pport_control;
};

hdae5000_device::hdae5000_device(const machine_config &mconfig, const char *tag, device_t *owner, uint32_t clock) :
	device_t(mconfig, HDAE5000, tag, owner, clock),
	device_kn5000_extension_interface(mconfig, *this),
	m_hdd(*this, "hdd"),
	m_ppi(*this, "ppi"),
	m_rom(*this, "rom"),
	m_ram(*this, "ram", 0x80000, ENDIANNESS_LITTLE),
	m_pport_data(0),
	m_pport_status(0),
	m_pport_control(0)
{
}

void hdae5000_device::program_map(address_space_installer &space)
{
	space.install_device(0x000000, 0x2fffff, *this, &hdae5000_device::card_map);
}

void hdae5000_device::card_map(address_map &map)
{
	// ATA/IDE interface - directly mapped registers (verified from firmware analysis)
	// Registers at 0x130010-0x130020, 16-bit bus with registers at even addresses
	map(0x130010, 0x130011).rw(FUNC(hdae5000_device::ata_data_r), FUNC(hdae5000_device::ata_data_w));
	map(0x130012, 0x13001f).rw(FUNC(hdae5000_device::ata_r), FUNC(hdae5000_device::ata_w)).umask16(0x00ff);
	map(0x130020, 0x130021).w(FUNC(hdae5000_device::ata_ctrl_w)).umask16(0x00ff);

	// Parallel port interface (NEC uPD71055, i8255 compatible) for PC communication
	map(0x160000, 0x160007).umask16(0x00ff).rw(m_ppi, FUNC(i8255_device::read), FUNC(i8255_device::write));

	// Static RAM - 512KB (2x 256KB chips)
	map(0x200000, 0x27ffff).ram().share("ram");

	// ROM - 512KB
	map(0x280000, 0x2fffff).rom().region(m_rom, 0);
}

//
// ATA/IDE Interface (verified from firmware analysis)
//
// The HD-AE5000 connects directly to an IDE hard disk.
// ATA commands observed in firmware:
//   0x20: Read Sectors (PIO) - at 0x29781D
//   0x30: Write Sectors (PIO) - at 0x29772B
//   0x94: Standby (spin down with timeout) - at 0x297501
//   0xEC: Identify Device - at 0x2978C3
//
// Register access pattern (from firmware at 0x2976AB-0x297883):
//   1. Wait for Status (0x13001E) bit 6 set, bit 7 clear (BSY=0, DRDY=1)
//   2. Write Sector Count to 0x130014
//   3. Write Device/Head (0xA0 | head) to 0x13001C
//   4. Write CHS parameters to 0x130016/18/1A
//   5. Write Command to 0x13001E
//   6. Wait for DRQ (Status bit 3) or error
//   7. Transfer data via Data Register (0x130010)
//

uint16_t hdae5000_device::ata_data_r()
{
	uint16_t data = m_hdd->read_dma();
	LOGMASKED(LOG_ATA, "ATA data read @0x130010: %04x\n", data);
	return data;
}

void hdae5000_device::ata_data_w(uint16_t data)
{
	LOGMASKED(LOG_ATA, "ATA data write @0x130010: %04x\n", data);
	m_hdd->write_dma(data);
}

uint8_t hdae5000_device::ata_r(offs_t offset)
{
	// Offset is in bytes from 0x130012
	// Register index = (offset / 2) + 1
	// So offset 0 (0x130012) = reg 1 (Features/Error)
	//    offset 2 (0x130014) = reg 2 (Sector Count)
	//    offset 4 (0x130016) = reg 3 (Sector Number)
	//    offset 6 (0x130018) = reg 4 (Cylinder Low)
	//    offset 8 (0x13001A) = reg 5 (Cylinder High)
	//    offset 10 (0x13001C) = reg 6 (Device/Head)
	//    offset 12 (0x13001E) = reg 7 (Status/Command)
	int reg = (offset >> 1) + 1;
	uint8_t data = m_hdd->read_cs0(reg);
	LOGMASKED(LOG_ATA, "ATA reg %d read @0x%06x: %02x\n", reg, 0x130012 + offset, data);
	return data;
}

void hdae5000_device::ata_w(offs_t offset, uint8_t data)
{
	int reg = (offset >> 1) + 1;
	LOGMASKED(LOG_ATA, "ATA reg %d write @0x%06x: %02x\n", reg, 0x130012 + offset, data);
	m_hdd->write_cs0(reg, data);
}

void hdae5000_device::ata_ctrl_w(uint8_t data)
{
	// Device Control register at 0x130020
	// Firmware writes 0x0E (SRST + nIEN) and 0x0A (nIEN) during init
	LOGMASKED(LOG_ATA, "ATA device control write @0x130020: %02x\n", data);
	m_hdd->write_cs1(6, data);
}

//
// Parallel Port (PPORT) Interface
//
// The PPI provides a parallel port interface for communication with
// HD-TechManager5000 Windows software via the PC's parallel port.
//
// Port A: Data output to PC
// Port B: Status input from PC
// Port C: Control signals
//

uint8_t hdae5000_device::ppi_pa_r()
{
	LOGMASKED(LOG_PPI, "PPI Port A read: %02x\n", m_pport_data);
	return m_pport_data;
}

void hdae5000_device::ppi_pa_w(uint8_t data)
{
	LOGMASKED(LOG_PPI, "PPI Port A write: %02x\n", data);
	m_pport_data = data;
}

uint8_t hdae5000_device::ppi_pb_r()
{
	// Status from PC - directly return stored status
	LOGMASKED(LOG_PPI, "PPI Port B read: %02x\n", m_pport_status);
	return m_pport_status;
}

void hdae5000_device::ppi_pc_w(uint8_t data)
{
	LOGMASKED(LOG_PPI, "PPI Port C write: %02x\n", data);
	m_pport_control = data;
}

void hdae5000_device::device_add_mconfig(machine_config &config)
{
	IDE_HARDDISK(config, m_hdd, 0);

	// Parallel Port PPI (NEC uPD71055, i8255 compatible)
	I8255(config, m_ppi);
	m_ppi->in_pa_callback().set(FUNC(hdae5000_device::ppi_pa_r));
	m_ppi->out_pa_callback().set(FUNC(hdae5000_device::ppi_pa_w));
	m_ppi->in_pb_callback().set(FUNC(hdae5000_device::ppi_pb_r));
	m_ppi->out_pc_callback().set(FUNC(hdae5000_device::ppi_pc_w));
}

void hdae5000_device::device_start()
{
	save_item(NAME(m_pport_data));
	save_item(NAME(m_pport_status));
	save_item(NAME(m_pport_control));
}

void hdae5000_device::device_reset()
{
	m_pport_data = 0;
	m_pport_status = 0;
	m_pport_control = 0;
}

ROM_START(hdae5000)
	ROM_REGION16_LE(0x80000, "rom" , 0)
	ROM_DEFAULT_BIOS("v2.06i")

	ROM_SYSTEM_BIOS(0, "v1.10i", "Version 1.10i - July 6th, 1998")
	ROMX_LOAD("hd-ae5000_v1_10i.ic4", 0x000000, 0x80000, CRC(7461374b) SHA1(6019f3c28b6277730418974dde4dc6893fced00e), ROM_BIOS(0))

	ROM_SYSTEM_BIOS(1, "v1.15i", "Version 1.15i - October 13th, 1998")
	ROMX_LOAD("hd-ae5000_v1_15i.ic4", 0x000000, 0x80000, CRC(e76d4b9f) SHA1(581fa58e2cd6fe381cfc312c73771d25ff2e662c), ROM_BIOS(1))

	// Version 2.01i is described as having "additions like lyrics display etc."
	ROM_SYSTEM_BIOS(2, "v2.01i", "Version 2.01i - January 15th, 1999") // installation file indicated "v2.0i" but signature inside the ROM is "v2.01i"
	ROMX_LOAD("hd-ae5000_v2_01i.ic4", 0x000000, 0x80000, CRC(961e6dcd) SHA1(0160c17baa7b026771872126d8146038a19ef53b), ROM_BIOS(2))

	ROM_SYSTEM_BIOS(3, "v2.06i", "Version 2.06i") // unknown release date
	ROMX_LOAD("hd-ae5000_v2_06i.ic4", 0x000000, 0x80000, CRC(836be80a) SHA1(c4da28f0ad16b1288774af761b3729142e8050b3), ROM_BIOS(3))
ROM_END

const tiny_rom_entry *hdae5000_device::device_rom_region() const
{
	return ROM_NAME(hdae5000);
}

} // anonymous namespace

DEFINE_DEVICE_TYPE_PRIVATE(HDAE5000, device_kn5000_extension_interface, hdae5000_device, "hdae5000", "HD-AE5000, Hard Disk & Audio Extension")
