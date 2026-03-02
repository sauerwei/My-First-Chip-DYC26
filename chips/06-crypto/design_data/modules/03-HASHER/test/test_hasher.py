import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, NextTimeStep, ReadOnly
from cocotb.types import LogicArray

from cocotb_tools.runner import get_runner

import random

os.environ['COCOTB_ANSI_OUTPUT'] = '1'

class SHA256:
    # all 32 bit unsigned ints

    def __init__(self) -> None:
        self.reset()

    def reset(self) -> None:
        self.h0 = 0x6a09e667
        self.h1 = 0xbb67ae85
        self.h2 = 0x3c6ef372
        self.h3 = 0xa54ff53a
        self.h4 = 0x510e527f
        self.h5 = 0x9b05688c
        self.h6 = 0x1f83d9ab
        self.h7 = 0x5be0cd19
        self.k = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
        ]
        print()
        self.length = 0  # 64bit

    def h(self) -> list[int]:
        return [self.h0, self.h1, self.h2, self.h3, self.h4, self.h5, self.h6, self.h7]

    def get_hash(self):
        return ((self.h0 << (32 * 7)) +
                (self.h1 << (32 * 6)) +
                (self.h2 << (32 * 5)) +
                (self.h3 << (32 * 4)) +
                (self.h4 << (32 * 3)) +
                (self.h5 << (32 * 2)) +
                (self.h6 << (32 * 1)) +
                (self.h7))

    @staticmethod
    def _right_rotate(value: int, amount: int) -> int:
        return (2 ** 32 - 1) & (value >> amount | value << (32 - amount))

    def hash_chunk(self, chunk: bytes):
        w = [0] * 64
        for i in range(16):
            w[i] = int.from_bytes(chunk[i * 4:(i + 1) * 4], byteorder='big')
        for i in range(16, 64):
            s0 = (self._right_rotate(w[i - 15], 7) ^
                  self._right_rotate(w[i - 15], 18) ^
                  (w[i - 15] >> 3))
            s1 = (self._right_rotate(w[i - 2], 17) ^
                  self._right_rotate(w[i - 2], 19) ^
                  (w[i - 2] >> 10))
            w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % (2 ** 32)

        a = self.h0
        b = self.h1
        c = self.h2
        d = self.h3
        e = self.h4
        f = self.h5
        g = self.h6
        h = self.h7

        for i in range(0, 64):
            S1 = (self._right_rotate(e, 6) ^
                  self._right_rotate(e, 11) ^
                  self._right_rotate(e, 25))
            ch = (e & f) ^ ((~e) & g)
            temp1 = (h + S1 + ch + self.k[i] + w[i]) % (2 ** 32)
            S0 = (self._right_rotate(a, 2) ^
                  self._right_rotate(a, 13) ^
                  self._right_rotate(a, 22))
            maj = (a & b) ^ (a & c) ^ (b & c)
            temp2 = (S0 + maj) % (2 ** 32)

            h = g
            g = f
            f = e
            e = (d + temp1) % (2 ** 32)
            d = c
            c = b
            b = a
            a = (temp1 + temp2) % (2 ** 32)
            pass

        self.h0 = (self.h0 + a) % (2 ** 32)
        self.h1 = (self.h1 + b) % (2 ** 32)
        self.h2 = (self.h2 + c) % (2 ** 32)
        self.h3 = (self.h3 + d) % (2 ** 32)
        self.h4 = (self.h4 + e) % (2 ** 32)
        self.h5 = (self.h5 + f) % (2 ** 32)
        self.h6 = (self.h6 + g) % (2 ** 32)
        self.h7 = (self.h7 + h) % (2 ** 32)


class HasherTester:
    """Helper class for Hasher module testing."""

    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.rst_n = dut.rst_n
        self.message = dut.message
        self.bits_read = dut.bits_read
        self.chunk_ready_p = dut.chunk_ready_p
        self.msg_lock = dut.msg_lock
        self.hash_ready = dut.hash_ready
        self.hash = dut.hash

    async def reset(self):
        """Apply reset pulse."""
        self.rst_n.value = 0
        await RisingEdge(self.clk)
        self.rst_n.value = 1
        await RisingEdge(self.clk)

    async def wait_lock(self):
        """Wait for specified number of clock cycles."""
        while self.msg_lock.value == 1:
            await RisingEdge(self.clk)

    async def wait_chunk_done(self):
        """Wait for specified number of clock cycles."""
        while self.msg_lock.value == 1:
            await RisingEdge(self.clk)

@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_empty_msg(dut):
    tester = HasherTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()
    sha256 = SHA256()

    tester.message.value = 0
    tester.bits_read.value = 0
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    await tester.wait_lock()
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset"

    expected_padding = bytearray()
    expected_padding.append(0x80)
    while (len(expected_padding) + 8) % 64 != 0:
        expected_padding.append(0)
    expected_padding.extend((0).to_bytes(8, byteorder='big'))
    sha256.hash_chunk(expected_padding)

    assert int(str(tester.hash.value), base=2) == sha256.get_hash(), "hash of empty message not as expected"

    dut._log.info("✓ Hash empty message test passed")

@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_small_msg(dut):
    tester = HasherTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()
    sha256 = SHA256()

    message_bytes = 0x01234567abcdef.to_bytes(7)
    message_bits = "1" * (512 - 7*8) + ''.join([format(byte, '08b') for byte in message_bytes][::-1])
    message_32_bits = [message_bits[i:i+32] for i in range(0, len(message_bits), 32)]

    tester.message.value = "".join(bit for bit in message_32_bits)
    tester.bits_read.value = 7 * 8
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    await tester.wait_lock()
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset"

    expected_padding = bytearray()
    expected_padding.extend(message_bytes)
    expected_padding.append(0x80)
    while (len(expected_padding) + 8) % 64 != 0:
        expected_padding.append(0)
    expected_padding.extend((7*8).to_bytes(8, byteorder='big'))
    sha256.hash_chunk(expected_padding)

    assert int(str(tester.hash.value), base=2) == sha256.get_hash(), "hash of small message not as expected"

    dut._log.info("✓ Hash small message test passed")

@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_big_msg(dut):
    tester = HasherTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()
    sha256 = SHA256()

    message_bytes = random.randbytes(60)
    message_bits = "0" * (512 - 60*8) + ''.join([format(byte, '08b') for byte in message_bytes][::-1])
    message_32_bits = [message_bits[i:i+32] for i in range(0, len(message_bits), 32)]

    tester.message.value = "".join(bit for bit in message_32_bits)
    tester.bits_read.value = 60 * 8
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    await tester.wait_lock()
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset"

    expected_padding = bytearray()
    expected_padding.extend(message_bytes)
    expected_padding.append(0x80)
    while (len(expected_padding) + 8) % 64 != 0:
        expected_padding.append(0)
    expected_padding.extend((60*8).to_bytes(8, byteorder='big'))
    expected_msg_1 = bytes(expected_padding[:512//8])
    expected_msg_2 = bytes(expected_padding[512//8:])
    sha256.hash_chunk(expected_msg_1)
    sha256.hash_chunk(expected_msg_2)

    assert int(str(tester.hash.value), base=2) == sha256.get_hash(), "hash of big message not as expected"

    dut._log.info("✓ Padding on big message test passed")


@cocotb.test(timeout_time=10, timeout_unit="ms")
async def test_multi_msg(dut):
    tester = HasherTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()
    sha256 = SHA256()

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
    await tester.wait_lock()
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset"
    sha256.hash_chunk(message_bytes)

    assert int(str(tester.hash.value), base=2) == sha256.get_hash(), "hash of first message not as expected"

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
    await tester.wait_lock()
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset"
    sha256.hash_chunk(message_bytes)

    assert int(str(tester.hash.value), base=2) == sha256.get_hash(), "hash of second message not as expected"

    tester.message.value = 0
    tester.bits_read.value = 0
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 1, "msg_lock needs to be set"
    await tester.wait_lock()
    await RisingEdge(tester.clk)
    assert tester.msg_lock.value == 0, "msg_lock needs to be reset"

    expected_padding = bytearray()
    expected_padding.append(0x80)
    while (len(expected_padding) + 8) % 64 != 0:
        expected_padding.append(0)
    expected_padding.extend((512 * 2).to_bytes(8, byteorder='big'))
    sha256.hash_chunk(expected_padding)

    assert int(str(tester.hash.value), base=2) == sha256.get_hash(), "hash of multiple chunk of message not as expected"

    dut._log.info("✓ Padding on multiple chunk message test passed")

@cocotb.test()
async def test_reset(dut):
    tester = HasherTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await tester.reset()

    assert tester.msg_lock.value == 0, "expected msg_lock to be 0 on reset"
    assert tester.hash_ready.value == 0, 'expected msg_ready_p to be 0 on reset'

    dut._log.info("✓ Reset test passed")

@cocotb.test()
async def test_reset_2(dut):
    tester = HasherTester(dut)
    # Start clock
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    message = int.from_bytes(random.randbytes(2), 'big')

    tester.message.value = message
    tester.bits_read.value = 2 * 8
    tester.chunk_ready_p.value = 1
    await RisingEdge(tester.clk)
    tester.chunk_ready_p.value = 0
    await RisingEdge(tester.clk)
    await tester.reset()

    assert tester.msg_lock.value == 0, "expected msg_lock to be 0 on reset"
    assert tester.hash_ready.value == 0, 'expected msg_ready_p to be 0 on reset'

    dut._log.info("✓ Reset test passed")

def test_hasher_runner():
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    sources = [
        proj_path / "src" / "hasher.sv",
        proj_path / "src" / "pad_message.sv",
        proj_path / "src" / "multiplexer.sv",
        proj_path / "src" / "sha256.sv",
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="hasher",
        always=True,
        waves=True,
        timescale=("1ns", "1ps"),
    )

    runner.test(hdl_toplevel="hasher", test_module="test_hasher", waves=True)

if __name__ == "__main__":
    test_hasher_runner()
