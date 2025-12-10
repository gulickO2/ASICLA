## How it works
- `tt_um_asicla` is a 16-sample logic analyzer. A pulse on `uio_in[0]` arms it, then it captures `ui_in[7:0]` on the next 16 clock edges.
- Samples are stored in on-chip RAM. Set an address on `uio_in[4:1]` to select one entry; the byte appears on `uo_out[7:0]` combinationally.
- Status is exposed on `uio_out[7:5]` (driven, with `uio_oe` high): `done`, `capturing`, `armed`. Other `uio` bits remain inputs.
- `clk` is the sampling clock; reset is active-low on `rst_n`; `ena` can be ignored (always high in production).

## How to test
- Simulation (recommended): from `test/`, run `make test` (cocotb). The test arms the analyzer, streams 16 known samples, waits for `done`, then reads back every entry via the address bus and checks status bits.
- Manual bench use: hold `rst_n` low to reset, then high. Pulse `uio_in[0]` high once to arm. On each of the next 16 clocks the current `ui_in` byte is captured. After capture, set `uio_in[4:1]` to an address (0–15) and read the byte on `uo_out[7:0]`. Watch `uio_out[7:5]` for `{done, capturing, armed}`.

## External hardware
None; uses only the TinyTapeout pins.
