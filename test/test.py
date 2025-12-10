# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


def encode_uio(addr: int, arm: bool) -> int:
    """Pack address bits [4:1] and optional arm pulse on bit 0."""
    return ((addr & 0xF) << 1) | (1 if arm else 0)


@cocotb.test()
async def test_logic_analyzer(dut):
    dut._log.info("Start logic analyzer test")

    # 50 MHz clock (20 ns period)
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())

    # Reset and defaults
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # Status should be idle after reset
    assert (int(dut.uio_out.value) >> 5) & 0b111 == 0, "Status bits should be low after reset"

    # Arm the analyzer with a one-cycle pulse on uio_in[0]
    dut.uio_in.value = encode_uio(addr=0, arm=True)
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = encode_uio(addr=0, arm=False)
    await ClockCycles(dut.clk, 2)  # allow synchronizer + capture enable pipeline

    # Stream 16 samples on ui_in while capturing is active
    sample_data = [i for i in range(16)]
    saw_capturing = False
    for value in sample_data:
        dut.ui_in.value = value
        await ClockCycles(dut.clk, 1)  # value sampled on this edge
        status = (int(dut.uio_out.value) >> 5) & 0b111
        saw_capturing |= bool(status & 0b010)
    assert saw_capturing, "Capturing flag never asserted during sample window"

    # Done should assert once capture completes
    done_seen = False
    for _ in range(6):
        status = (int(dut.uio_out.value) >> 5) & 0b111
        if status & 0b100:
            done_seen = True
            break
        await ClockCycles(dut.clk, 1)
    assert done_seen, "Done flag did not assert after capture"
    assert status == 0b100, f"Expected status done=1,capturing=0,armed=0, got {bin(status)}"

    # Read back all samples using the address bus on uio_in[4:1]
    for addr, expected in enumerate(sample_data):
        dut.uio_in.value = encode_uio(addr=addr, arm=False)
        await ClockCycles(dut.clk, 1)
        assert int(dut.uo_out.value) == expected, f"Readback mismatch at addr {addr}: got {int(dut.uo_out.value)}, expected {expected}"

    dut._log.info("Logic analyzer capture/readback OK")
