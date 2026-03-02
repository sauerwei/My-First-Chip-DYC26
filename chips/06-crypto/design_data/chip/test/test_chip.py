import os
import random
from pathlib import Path

import random
import hashlib
from typing import List

from ecpy.ecdsa import ECDSA as ECPyecdsa, ECPrivateKey, decode_sig
from ecpy.curves import Curve as ECPyCurve


import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner

os.environ["COCOTB_ANSI_OUTPUT"] = "1"


def int_to_bits_msb_first(value: int, width: int) -> List[int]:
    return [(value >> (width - 1 - i)) & 1 for i in range(width)]


def bits_to_int_msb_first(bits: List[int]) -> int:
    v = 0
    for b in bits:
        v = (v << 1) | (int(b) & 1)
    return v

def prepare_payload(value: int, width: int) -> List[int]:
    byte_array = bytearray()
    byte_array.extend(value.to_bytes(width//8))

    byte_array = byte_array[::-1]
    converted_value = int.from_bytes(byte_array)

    return int_to_bits_msb_first(converted_value, width)


class ChipTester:

    def __init__(self, dut):
        self.clk = dut.clk
        self.rst_n = dut.rst_n
        self.spi_in = dut.spi_in
        self.spi_out = dut.spi_out
        self.spi_clk = dut.spi_clk
        self.dut = dut

        self.count_last_msg_sent_clk_count = 0
        self.clk_count = 0


    async def clk_turn(self):
        await RisingEdge(self.clk)
        self.clk_count += 1

    async def clk_turns(self, num_cycles: int):
        for _ in range(num_cycles):
            await self.clk_turn()

    async def spi_clk_turn(self):
        self.spi_clk.value = 1
        await self.clk_turn()

        self.spi_clk.value = 0
        await self.clk_turn()

    async def set_calc_pulse(self):
        self.calc_p.value = 1
        await self.clk_turn()
        self.calc_p.value = 0
        await self.clk_turn()

    async def _send_bit(self, bit: int):
        self.spi_in.value = bit
        await self.spi_clk_turn()
        self.spi_in.value = 0


    async def _receive_bit_from_chip(self) -> int:
        self.spi_clk.value = 1
        await RisingEdge(self.clk)
        
        response = self.spi_out.value

        self.spi_clk.value = 0
        await RisingEdge(self.clk)
        return response

    async def _receive_chip_response(self, amount_of_bits=8) -> List[int]:
        """Receive answer from chip, its always 8 bit"""
        response = []
        for i in range(amount_of_bits):
            response.append(await self._receive_bit_from_chip())
        
        return response

    async def _send_bit_vector(self, bit_vector: List[int]):
        for bit in bit_vector:
            await self._send_bit(bit)

    async def send_message(self, addr_bits: List[int], len_bits: List[int], payload: List[int]) -> int:
        start_count = self.clk_count
        type_of_message = "HASH" if addr_bits[0] == 1 else "MSG"


        msg = addr_bits + len_bits + [0] * 4 + payload
        await self._send_bit_vector(msg)
           
        if addr_bits[0] == 0 and addr_bits[1] ==0:
            self.count_last_msg_sent_clk_count = self.clk_count
        
        diff_start_end = self.clk_count - start_count
        response = bits_to_int_msb_first(await self._receive_chip_response())

        self.log_send_message_info(diff_start_end=diff_start_end, payload_length=len(payload), type_of_message=type_of_message, response=response)
        
        return response
    
    def log_send_message_info(self, diff_start_end, payload_length, type_of_message, response):
        if type_of_message == "MSG":
            was_locked_or_not_ready = "LOCKED"
        else:
             was_locked_or_not_ready = "NOT READY"

        error_message = f"{type_of_message} was {was_locked_or_not_ready}, got error response {hex(response)}" if response == 0xFF else ""
        self.dut._log.info(f"Start sending Message ({type_of_message}-type)")
        self.dut._log.info(f"\tType:\t {type_of_message}-Message")
        self.dut._log.info(f"\tMessage size: {payload_length//8} bytes")
        self.dut._log.info("\t---- wait until the message has been sent ----")
        self.dut._log.info(f"\tMessage was sent in {diff_start_end} clk cycles")
        if error_message != "":
            self.dut._log.info(f"\tMessage response \033[38;2;255;165;0mERROR\033[0m, because {error_message}")
        else:
            self.dut._log.info(f"\tMessage response \033[32mOK\033[0m, {hex(response)}")
    
    async def receive_hash(self) -> int:
        sig_is_ready = False
        while sig_is_ready == False:
            response = await self.send_message([1,0], [0]*10, [])
            sig_is_ready = response == 0xAA
        
        self.dut._log.info(f"Hashing of single msg block was done in {self.clk_count-self.count_last_msg_sent_clk_count} clk cycles")
        return await self._receive_chip_response(256)
    
    async def reset(self):
        self.rst_n.value = 0
        self.spi_clk.value = 0
        await self.clk_turn()
        self.rst_n.value = 1
        await self.clk_turn()


@cocotb.test(skip=False)
async def test_hasher_chip_with_empty_msg(dut):
    tester, clock = await init_testcase(dut)
    tester.spi_clk.value = 0

    dut._log.info("\n\nStart test_hasher_chip_with_empty_msg")

    await tester.clk_turns(5)

    response = await tester.send_message([0,0], int_to_bits_msb_first(0, 10), [])

    assert response == 0xAA
    
    msg_hash = hashlib.sha256().digest()

    hash_response = bits_to_int_msb_first(await tester.receive_hash())

    assert msg_hash == hash_response.to_bytes(256//8)


@cocotb.test(skip=False)
async def test_hasher_chip_small_msg(dut):
    tester, clock = await init_testcase(dut)
    tester.spi_clk.value = 0

    dut._log.info("\n\nStart test_hasher_chip_small_msg")

    await tester.clk_turns(5)

    payload = 0xAABBCCEEFF

    response = await tester.send_message([0,0], int_to_bits_msb_first(8*5, 10), prepare_payload(payload, 8*5))

    assert response == 0xAA
    
    msg_hash = hashlib.sha256(payload.to_bytes(5)).digest()

    hash_response = bits_to_int_msb_first(await tester.receive_hash())

    assert msg_hash == hash_response.to_bytes(256//8)


@cocotb.test(skip=False)
async def test_hasher_chip_msg(dut):
    tester, clock = await init_testcase(dut)
    tester.spi_clk.value = 0

    dut._log.info("\n\nStart test_hasher_chip_msg")

    await tester.clk_turns(5)

    payload = 0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F
    
    response = await tester.send_message([0,0], int_to_bits_msb_first(512, 10), prepare_payload(payload, 512))

    assert response == 0xAA
    
    response = 0xFF
    while response == 0xFF:
        response = await tester.send_message([0,0], int_to_bits_msb_first(0, 10), [])
    
    assert response == 0xAA
    
    msg_hash = hashlib.sha256(payload.to_bytes(512//8)).digest()

    hash_response = bits_to_int_msb_first(await tester.receive_hash())

    assert msg_hash == hash_response.to_bytes(256//8)


@cocotb.test(skip=False)
async def test_hasher_chip_small_but_not_small_msg(dut):
    tester, clock = await init_testcase(dut)
    tester.spi_clk.value = 0

    dut._log.info("\n\nStart test_hasher_chip_small_but_not_small_msg")

    await tester.clk_turns(5)

    payload = 0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C
    response = await tester.send_message([0,0], int_to_bits_msb_first(512-24, 10), prepare_payload(payload, 512-24))
    
    assert response == 0xAA

    msg_hash = hashlib.sha256(payload.to_bytes((512-24)//8)).digest()

    hash_response = bits_to_int_msb_first(await tester.receive_hash())

    assert msg_hash == hash_response.to_bytes(256//8)



@cocotb.test(skip=False)
async def test_hasher_chip_multi_msg(dut):
    tester, clock = await init_testcase(dut)
    tester.spi_clk.value = 0

    dut._log.info("\n\nStart test_hasher_chip_multi_msg")

    await tester.clk_turns(5)

    payload = 0x000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F
    sha256_instance = hashlib.sha256(payload.to_bytes(512//8))
    
    response = await tester.send_message([0,0], int_to_bits_msb_first(512, 10), prepare_payload(payload, 512))

    assert response == 0xAA

    payload = 0x3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A292827262524232221201F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100
    sha256_instance.update(payload.to_bytes(512//8))

    msg_hash = sha256_instance.digest()

    response = 0xFF
    while response == 0xFF:
        response = await tester.send_message([0,0], int_to_bits_msb_first(512, 10), prepare_payload(payload, 512))

    assert response == 0xAA

    response = 0xFF
    while response == 0xFF:
        response = await tester.send_message([0,0], int_to_bits_msb_first(0, 10), [])

    assert response == 0xAA
    

    hash_response = bits_to_int_msb_first(await tester.receive_hash())

    assert msg_hash == hash_response.to_bytes(256//8)


async def init_testcase(dut) -> tuple[ChipTester, Clock]:
    tester = ChipTester(dut)

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    await tester.reset()

    return tester, clock

def test_chip_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent.parent

    # Update these filenames to match your actual source layout
    sources = [
        proj_path / "modules" / "01-SPI" / "src" / "spi.sv",
        proj_path / "modules" / "02-REG-MSG" / "src" / "reg_msg.sv",
        proj_path / "modules" / "03-HASHER" / "src" / "multiplexer.sv",
        proj_path / "modules" / "03-HASHER" / "src" / "pad_message.sv",
        proj_path / "modules" / "03-HASHER" / "src" / "sha256.sv",
        proj_path / "modules" / "03-HASHER" / "src" / "hasher.sv",
        proj_path / "chip" / "src" / "chip.sv",
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="chip",
        always=True,
        waves=True,
        timescale=("1ns", "1ps"),
    )
    runner.test(
        hdl_toplevel="chip",
        test_module="test_chip",
        waves=True,
    )


if __name__ == "__main__":
    test_chip_runner()
