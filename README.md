# TinyTapeout Logic Analyzer (WIP)

Minimal 16-sample logic analyzer for TinyTapeout. Captures `ui_in[7:0]` on every clock after an arm pulse and exposes samples for random-access readback.

## Interface
- Arm: pulse `uio_in[0]` high.
- Capture: samples `ui_in` for 16 clocks once armed.
- Read: set address on `uio_in[4:1]`, sample value appears on `uo_out[7:0]`.
- Status on `uio_out[7:5]`: `done`, `capturing`, `armed` (driven high), other uio bits stay inputs.

## Status
- Work in progress: doc + tests to follow.
- See `src/project.v` for implementation; `docs/info.md` will be updated once behavior is validated.
