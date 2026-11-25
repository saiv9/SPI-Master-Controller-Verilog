# Verification plan

The testbench uses a small behavioral slave so transmit and receive can be checked in the same frame.

| Check | What is checked |
| --- | --- |
| Four data patterns | TX and RX bytes match the values sent by the testbench |
| Eight sample edges | The master samples one bit for each clock pulse |
| Bus idle after frame | SCLK returns low, chip select deasserts, and busy clears |
| Divider values 1, 2, 5 | The testbench is run with three half-period settings |

Run `./scripts/run_sim.sh`. A passing run prints one PASS line for each frame and a final summary for each divider.

This testbench does not replace testing on an FPGA or with a physical SPI peripheral.
