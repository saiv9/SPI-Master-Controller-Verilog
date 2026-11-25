#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
WAVE_DIR="$ROOT_DIR/docs/waveforms"
mkdir -p "$BUILD_DIR" "$WAVE_DIR"
command -v iverilog >/dev/null 2>&1 || { echo "Install Icarus Verilog first." >&2; exit 127; }
command -v vvp >/dev/null 2>&1 || { echo "Icarus Verilog runtime (vvp) is missing." >&2; exit 127; }
cd "$ROOT_DIR"
: > "$BUILD_DIR/simulation.log"
for divider in 1 2 5; do
    echo "SPI simulation with CLKS_PER_HALF=$divider"
    iverilog -g2012 -Wall -s tb_spi_master -Ptb_spi_master.CLKS_PER_HALF="$divider" \
        -o "$BUILD_DIR/spi_$divider.vvp" rtl/spi_master.v tb/tb_spi_master.v
    vvp "$BUILD_DIR/spi_$divider.vvp" | tee -a "$BUILD_DIR/simulation.log"
done
python3 scripts/render_waveform.py "$BUILD_DIR/spi_master.vcd" "$WAVE_DIR/spi_master.png" \
    "SPI Master Controller, Mode 0 timing" \
    "tb_spi_master.clk,tb_spi_master.rst_n,tb_spi_master.cs_n,tb_spi_master.sclk,tb_spi_master.mosi,tb_spi_master.miso,tb_spi_master.busy,tb_spi_master.done,tb_spi_master.tx_data,tb_spi_master.rx_data"
cp "$BUILD_DIR/spi_master.vcd" "$WAVE_DIR/spi_master.vcd"
cp "$BUILD_DIR/simulation.log" "$WAVE_DIR/simulation.log"
echo "Waveform, VCD and log saved in docs/waveforms/."
