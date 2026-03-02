import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, NextTimeStep, ReadOnly
from cocotb.types import LogicArray

from cocotb_tools.runner import get_runner

import random

os.environ['COCOTB_ANSI_OUTPUT'] = '1'

class MultiplexerTester:
    """Helper class for Multiplexer module testing."""

    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.rst_n = dut.rst_n
        self.message_1 = dut.message_1
        self.message_2 = dut.message_2
        self.has_message_2 = dut.has_message_2
        self.msg_lock = dut.msg_lock
        self.msg_ready_p = dut.msg_ready_p
        self.next_p = dut.next_p
        self.msg_ready_out_p = dut.msg_ready_out_p
        self.message = dut.message
        self.done = dut.done
        self.last_msg = dut.last_msg

    async def reset(self):
        """Apply reset pulse."""
        self.rst_n.value = 0
        await RisingEdge(self.clk)
        self.rst_n.value = 1
        await RisingEdge(self.clk)

    async def wait_cycles(self, num_cycles: int):
        """Wait for specified number of clock cycles."""
        for _ in range(num_cycles):
            await RisingEdge(self.clk)

@cocotb.test()
async def test_single_msg(dut):
    tester = MultiplexerTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    message = int.from_bytes(random.randbytes(512 // 8), 'big')

    tester.message_1.value = message
    tester.has_message_2.value = 0
    tester.msg_ready_p.value = 1
    tester.last_msg.value = 0
    await RisingEdge(tester.clk)
    tester.msg_ready_p.value = 0
    assert tester.msg_ready_out_p.value == 1, "should set out msg ready flag"
    await RisingEdge(tester.clk)
    assert tester.message.value == message, "message not the same"
    assert tester.done.value == 0, "done flag shouldn't be set"
    assert tester.msg_lock.value == 1, "msg_lock should be set"
    await RisingEdge(tester.clk)
    assert tester.msg_ready_out_p.value == 0, "msg ready flag should pulse"
    assert tester.message.value == message, "message should stay"
    tester.next_p.value = 1
    await RisingEdge(tester.clk)
    tester.next_p.value = 0
    assert tester.done.value == 0, "done flag shouldn't be set"
    assert tester.msg_ready_out_p.value == 0, "set msg_ready_out pulse"
    tester.last_msg.value = 1
    await RisingEdge(tester.clk)
    assert tester.done.value == 1, "done flag should be set"
    assert tester.msg_lock.value == 0, "msg_lock shouldn't be set"

    dut._log.info("✓ Single message test passed")

@cocotb.test()
async def test_double_msg(dut):
    tester = MultiplexerTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    message1 = int.from_bytes(random.randbytes(512 // 8), 'big')
    message2 = int.from_bytes(random.randbytes(512 // 8), 'big')

    tester.message_1.value = message1
    tester.message_2.value = message2
    tester.has_message_2.value = 1
    tester.msg_ready_p.value = 1
    tester.last_msg.value = 1
    await RisingEdge(tester.clk)
    tester.msg_ready_p.value = 0
    assert tester.msg_ready_out_p.value == 1, "should set out msg ready flag"
    await RisingEdge(tester.clk)
    assert tester.message.value == message1, "message not the same"
    assert tester.done.value == 0, "done flag shouldn't be set"
    assert tester.msg_lock.value == 1, "msg_lock should be set"
    await RisingEdge(tester.clk)
    assert tester.msg_ready_out_p.value == 0, "msg ready flag should pulse"
    assert tester.message.value == message1, "message should stay"
    tester.next_p.value = 1
    await RisingEdge(tester.clk)
    tester.next_p.value = 0
    assert tester.message.value == message2, "message not the same"
    assert tester.done.value == 0, "done flag shouldn't be set"
    assert tester.msg_ready_out_p.value == 1, "should set out msg ready flag"
    assert tester.msg_lock.value == 1, "msg_lock should be set"
    await RisingEdge(tester.clk)
    assert tester.msg_ready_out_p.value == 0, "msg ready flag should pulse"
    assert tester.message.value == message2, "message should stay"
    tester.next_p.value = 1
    await RisingEdge(tester.clk)
    tester.next_p.value = 0
    assert tester.done.value == 1, "done flag should be set"
    assert tester.msg_ready_out_p.value == 0, "set msg_ready_out pulse"
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock shouldn't be set"

    dut._log.info("✓ Double message test passed")

@cocotb.test()
async def test_reset(dut):
    tester = MultiplexerTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    tester.rst_n.value = 0
    await RisingEdge(tester.clk)
    tester.rst_n.value = 1

    assert tester.done.value == 0, "done flag shouldn't be set"
    assert tester.msg_ready_out_p.value == 0, "should set out msg ready flag"
    assert tester.msg_lock.value == 0, "msg_lock should be set"

    dut._log.info("✓ Reset test passed")

def test_multiplexer_runner():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    sources = [proj_path / "src" / "multiplexer.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="multiplexer",
        always=True,
        waves=True,
        timescale=("1ns", "1ps"),
    )

    runner.test(hdl_toplevel="multiplexer", test_module="test_multiplexer", waves=True)

if __name__ == "__main__":
    test_multiplexer_runner()
