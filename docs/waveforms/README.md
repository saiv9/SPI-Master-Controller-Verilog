The simulation script writes these files after a successful testbench run:

- `spi_master.vcd`: raw signal transitions for GTKWave
- `spi_master.png`: timing view made from the VCD
- `simulation.log`: simulator output

The last waveform is generated with `CLKS_PER_HALF=5`.
