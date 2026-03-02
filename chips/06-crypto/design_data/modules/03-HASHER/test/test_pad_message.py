import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, NextTimeStep, ReadOnly
from cocotb.types import LogicArray

from cocotb_tools.runner import get_runner

import random

os.environ['COCOTB_ANSI_OUTPUT'] = '1'

class PadMessageTester:
    """Helper class for Pad Message module testing."""

    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.rst_n = dut.rst_n
        self.chunk_ready_p = dut.chunk_ready_p
        self.message = dut.message
        self.bits_read = dut.bits_read
        self.msg_lock = dut.msg_lock
        self.message_1 = dut.message_1
        self.message_2 = dut.message_2
        self.has_overflow = dut.has_overflow
        self.msg_ready_p = dut.msg_ready_p
        self.rst_p = dut.rst_p

    async def reset(self):
        """Apply reset pulse."""
        self.rst_n.value = 0
        await RisingEdge(self.clk)
        self.rst_n.value = 1
        await RisingEdge(self.clk)

    def compare_msg_1(self, expected_msg: bytearray | bytes):

        expected_msg_bits = ''.join(format(byte, '08b') for byte in expected_msg)
        expected_msg_32_bits = [expected_msg_bits[i:i+32] for i in range(0, len(expected_msg_bits), 32)][::-1]

        assert self.message_1.value == "".join(bit for bit in expected_msg_32_bits), "Expected different message 1"

    def compare_msg_2(self, expected_msg: bytearray | bytes):

        expected_msg_bits = ''.join(format(byte, '08b') for byte in expected_msg)
        expected_msg_32_bits = [expected_msg_bits[i:i+32] for i in range(0, len(expected_msg_bits), 32)][::-1]

        assert self.message_2.value == "".join(bit for bit in expected_msg_32_bits), "Expected different message 2"

@cocotb.test()
async def test_reset(dut):
    tester = PadMessageTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    message = int.from_bytes(random.randbytes(2), 'big')

    tester.message.value = message
    tester.bits_read.value = 2 * 8
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    await tester.reset()

    assert tester.msg_lock.value == 0, "expected msg_lock to be 0 on reset"
    assert tester.msg_ready_p.value == 0, 'expected msg_ready_p to be 0 on reset'
    assert tester.has_overflow.value == 0, 'expected has_overflow to be 0 on reset'
    assert tester.rst_p.value == 0, 'expected rst_p to be 0 on reset'

    dut._log.info("✓ Reset test passed")

@cocotb.test()
async def test_no_padding_needed(dut):
    tester = PadMessageTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    message_bytes = random.randbytes(512 // 8)
    message_bits = ''.join([format(byte, '08b') for byte in message_bytes][::-1])
    message_32_bits = [message_bits[i:i+32] for i in range(0, len(message_bits), 32)]

    tester.message.value = "".join(bit for bit in message_32_bits)
    tester.bits_read.value = 512
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    assert tester.msg_ready_p.value == 1, "msg_ready_p needs to be set after padding is calculated"
    assert tester.has_overflow.value == 0, "Expected no overflow on 512 bit big message"
    tester.compare_msg_1(message_bytes)
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset after padding is calculated"
    assert tester.msg_ready_p.value == 0, "msg_ready_p needs to be sa pulse"
    assert tester.rst_p.value == 0, "rst_p can't be on"

    dut._log.info("✓ No Padding needed test passed")

@cocotb.test()
async def test_no_padding_needed_twice(dut):
    tester = PadMessageTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    message_bytes = random.randbytes(512 // 8)
    message_bits = ''.join([format(byte, '08b') for byte in message_bytes][::-1])
    message_32_bits = [message_bits[i:i+32] for i in range(0, len(message_bits), 32)]

    tester.message.value = "".join(bit for bit in message_32_bits)
    tester.bits_read.value = 512
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    assert tester.msg_ready_p.value == 1, "msg_ready_p needs to be set after padding is calculated"
    assert tester.has_overflow.value == 0, "Expected no overflow on 512 bit big message"
    tester.compare_msg_1(message_bytes)
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset after padding is calculated"
    assert tester.msg_ready_p.value == 0, "msg_ready_p needs to be sa pulse"
    assert tester.rst_p.value == 0, "rst_p can't be on"

    message_bytes = random.randbytes(512 // 8)
    message_bits = ''.join([format(byte, '08b') for byte in message_bytes][::-1])
    message_32_bits = [message_bits[i:i+32] for i in range(0, len(message_bits), 32)]

    tester.message.value = "".join(bit for bit in message_32_bits)
    tester.bits_read.value = 512
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    assert tester.msg_ready_p.value == 1, "msg_ready_p needs to be set after padding is calculated"
    assert tester.has_overflow.value == 0, "Expected no overflow on 512 bit big message"
    tester.compare_msg_1(message_bytes)
    assert tester.rst_p.value == 0, "rst_p can't be on"
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset after padding is calculated"
    assert tester.msg_ready_p.value == 0, "msg_ready_p needs to be sa pulse"
    assert tester.rst_p.value == 0, "rst_p can't be on"

    dut._log.info("✓ No Padding needed test passed")

@cocotb.test()
async def test_empty_msg(dut):
    tester = PadMessageTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    tester.message.value = int.from_bytes(random.randbytes(512 // 8), 'big')
    tester.bits_read.value = 512
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)

    tester.message.value = 0
    tester.bits_read.value = 0
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    assert tester.rst_p.value == 0, "rst_p can't be on"

    expected_padding = bytearray()
    expected_padding.append(0x80)
    while (len(expected_padding) + 8) % 64 != 0:
        expected_padding.append(0)
    expected_padding.extend((512).to_bytes(8, byteorder='big'))

    assert tester.msg_ready_p.value == 1, "msg_ready_p needs to be set after padding is calculated"
    assert tester.has_overflow.value == 0, "Expected no overflow on empty message"
    tester.compare_msg_1(expected_padding)
    assert tester.rst_p.value == 0, "rst_p can't be on"
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset after padding is calculated"
    assert tester.msg_ready_p.value == 0, "msg_ready_p needs to be a pulse"
    assert tester.rst_p.value == 0, "rst_p can't be on"

    dut._log.info("✓ Padding on empty message test passed")

@cocotb.test()
async def test_small_msg(dut):
    tester = PadMessageTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    message_bytes = random.randbytes(2)
    message_bits = "1" * (512 - 2*8) + ''.join([format(byte, '08b') for byte in message_bytes][::-1])
    message_32_bits = [message_bits[i:i+32] for i in range(0, len(message_bits), 32)]

    tester.message.value = "".join(bit for bit in message_32_bits)
    tester.bits_read.value = 2 * 8
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"

    expected_padding = bytearray()
    expected_padding.extend(message_bytes)
    expected_padding.append(0x80)
    while (len(expected_padding) + 8) % 64 != 0:
        expected_padding.append(0)
    expected_padding.extend((2*8).to_bytes(8, byteorder='big'))

    assert tester.msg_ready_p.value == 1, "msg_ready_p needs to be set after padding is calculated"
    assert tester.has_overflow.value == 0, "Expected no overflow on small message"
    tester.compare_msg_1(expected_padding)
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset after padding is calculated"
    assert tester.msg_ready_p.value == 0, "msg_ready_p needs to be a pulse"
    assert tester.rst_p.value == 0, "rst_p can't be on"

    dut._log.info("✓ Padding on small message test passed")

@cocotb.test()
async def test_big_msg(dut):
    tester = PadMessageTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    message_bytes = random.randbytes(60)
    message_bits = "1" * (512 - 60*8) + ''.join([format(byte, '08b') for byte in message_bytes][::-1])
    message_32_bits = [message_bits[i:i+32] for i in range(0, len(message_bits), 32)]

    tester.message.value = "".join(bit for bit in message_32_bits)
    tester.bits_read.value = 60 * 8
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"

    expected_padding = bytearray()
    expected_padding.extend(message_bytes)
    expected_padding.append(0x80)
    while (len(expected_padding) + 8) % 64 != 0:
        expected_padding.append(0)
    expected_padding.extend((60*8).to_bytes(8, byteorder='big'))
    expected_msg_1 = bytes(expected_padding[:512//8])
    expected_msg_2 = bytes(expected_padding[512//8:])

    assert tester.msg_ready_p.value == 1, "msg_ready_p needs to be set after padding is calculated"
    assert tester.has_overflow.value == 1, "Expected overflow on big message"
    tester.compare_msg_1(expected_msg_1)
    tester.compare_msg_2(expected_msg_2)
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset after padding is calculated"
    assert tester.msg_ready_p.value == 0, "msg_ready_p needs to be a pulse"
    assert tester.rst_p.value == 0, "rst_p can't be on"

    dut._log.info("✓ Padding on big message test passed")

@cocotb.test()
async def test_reset_on_new_msg(dut):
    tester = PadMessageTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    tester.message.value = int.from_bytes(random.randbytes(10), 'big')
    tester.bits_read.value = 10 * 8
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    await RisingEdge(tester.clk)
    assert tester.rst_p.value == 0, "rst_p can't be on"

    tester.message.value = int.from_bytes(random.randbytes(512 // 8), 'big')
    tester.bits_read.value = 512
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.rst_p.value == 1, "rst_p needs to be set on a new message"
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    assert tester.msg_ready_p.value == 1, "msg_ready_p needs to be set after padding is calculated"
    await RisingEdge(tester.clk)
    assert tester.rst_p.value == 0, "rst_p needs to be reset after a clk cycle"
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset after padding is calculated"
    assert tester.msg_ready_p.value == 0, "msg_ready_p needs to be a pulse"

    dut._log.info("✓ Padding on new msg test passed")

def test_pad_message_runner():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    sources = [proj_path / "src" / "pad_message.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="pad_message",
        always=True,
        waves=True,
        timescale=("1ns", "1ps"),
    )

    runner.test(hdl_toplevel="pad_message", test_module="test_pad_message", waves=True)

if __name__ == "__main__":
    test_pad_message_runner()
