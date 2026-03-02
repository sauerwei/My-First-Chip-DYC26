import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, NextTimeStep, ReadOnly
from cocotb.types import LogicArray

from cocotb_tools.runner import get_runner

import random

os.environ['COCOTB_ANSI_OUTPUT'] = '1'

class RegTester:
    """Helper class for Reg module testing."""

    def __init__(self, dut):
        self.dut = dut
        self.data_in = dut.data_in
        self.bits_in = dut.bits_in
        self.set_p = dut.set_p
        self.data_out = dut.data_out
        self.bits_out = dut.bits_out

@cocotb.test()
async def test_set_msg(dut):
    tester = RegTester(dut)
    # Start clock
    clock = Clock(dut.set_p, 10, unit="us")
    cocotb.start_soon(clock.start())
    await RisingEdge(tester.set_p)

    message = int.from_bytes(random.randbytes(512 // 8), 'big')

    tester.data_in.value = message
    tester.bits_in.value = 512
    await RisingEdge(tester.set_p)
    await RisingEdge(tester.set_p)
    assert tester.data_out.value == message, "message saved not the same"
    assert tester.bits_out.value == 512, "bits out not the same"

    dut._log.info("✓ Single message test passed")

@cocotb.test()
async def test_set_small_msg(dut):
    tester = RegTester(dut)
    # Start clock
    clock = Clock(dut.set_p, 10, unit="us")
    cocotb.start_soon(clock.start())
    await RisingEdge(tester.set_p)

    message = int.from_bytes(random.randbytes(256 // 8), 'big')

    tester.data_in.value = message
    tester.bits_in.value = 256
    await RisingEdge(tester.set_p)
    await RisingEdge(tester.set_p)
    assert tester.data_out.value == message, "message saved not the same"
    assert tester.bits_out.value == 256, "bits out not the same"

    dut._log.info("✓ Single Small message test passed")

@cocotb.test()
async def test_set_msg_twice(dut):
    tester = RegTester(dut)
    # Start clock
    clock = Clock(dut.set_p, 10, unit="us")
    cocotb.start_soon(clock.start())
    await RisingEdge(tester.set_p)

    message = int.from_bytes(random.randbytes(512 // 8), 'big')

    tester.data_in.value = message
    tester.bits_in.value = 512
    await RisingEdge(tester.set_p)
    await RisingEdge(tester.set_p)
    assert tester.data_out.value == message, "message saved not the same"
    assert tester.bits_out.value == 512, "bits out not the same"

    message_new = int.from_bytes(random.randbytes(256 // 8), 'big')

    tester.data_in.value = message_new
    tester.bits_in.value = 256
    assert tester.data_out.value == message, "message should not have changed yet"
    assert tester.bits_out.value == 512, "bits out should not have changed yet"
    await RisingEdge(tester.set_p)
    await RisingEdge(tester.set_p)
    assert tester.data_out.value == message_new, "message saved not the same"
    assert tester.bits_out.value == 256, "bits out not the same"

    dut._log.info("✓ Double message test passed")

def test_reg_runner():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    sources = [proj_path / "src" / "reg_msg.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="reg_msg",
        always=True,
        waves=True,
        timescale=("1ns", "1ps"),
    )

    runner.test(hdl_toplevel="reg_msg", test_module="test_reg_msg", waves=True)

if __name__ == "__main__":
    test_reg_runner()
