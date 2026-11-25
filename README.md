# SPI Master Controller

A small SPI Mode 0 master written in Verilog. I kept the first version to one 8-bit transfer so the serial timing and shift-register operation are straightforward to follow.

The controller sends the most significant bit first. It samples MISO on rising SCLK edges and updates MOSI on falling edges. The clock divider is set with `CLKS_PER_HALF`.

![SPI master block diagram](docs/architecture.svg)

## Interface

| Signal | Direction | Meaning |
| --- | --- | --- |
| `clk`, `rst_n` | Input | System clock and active-low reset |
| `start` | Input | One-clock transfer request while idle |
| `tx_data[7:0]` | Input | Byte to transmit, most significant bit first |
| `miso` | Input | Serial data from the peripheral |
| `rx_data[7:0]` | Output | Received byte, updated when the frame ends |
| `busy`, `done` | Output | Transfer status and one-clock completion pulse |
| `sclk`, `mosi`, `cs_n` | Output | SPI Mode 0 signals |

## Run the simulation

Install Icarus Verilog and Python with Matplotlib, then run:

```bash
./scripts/run_sim.sh
```

The testbench exchanges four byte patterns with a simple behavioral slave. The script runs divider values 1, 2, and 5. It saves the VCD, simulation log, and a PNG timing view in `docs/waveforms/`.

## Scope

This version handles one byte per start pulse. SPI Modes 1 to 3, multiple chip selects, variable word lengths, and a streaming interface are not included.

Sai Teja
