# SPI Master Controller

A small SPI Mode 0 master written in Verilog. I kept the first version to one 8-bit transfer so the serial timing and shift-register operation are straightforward to follow.

The controller sends the most significant bit first. It samples MISO on rising SCLK edges and updates MOSI on falling edges. The clock divider is set with `CLKS_PER_HALF`.

## What is included

- SPI Mode 0, 8-bit, MSB-first transfers
- Full-duplex transmit and receive
- Active-low chip select
- `busy` status and a one-clock `done` pulse
- Testbench with a simple behavioral slave
- Icarus Verilog script for simulation and waveform capture

## Run the simulation

Install Icarus Verilog and Python with Matplotlib, then run:

```bash
./scripts/run_sim.sh
```

The design currently supports one byte per start pulse. SPI Modes 1 to 3, multiple chip selects, and variable word lengths are outside the scope of this version.

Sai Teja
