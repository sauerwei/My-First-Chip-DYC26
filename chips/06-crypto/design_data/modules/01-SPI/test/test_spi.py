import os
from pathlib import Path
from typing import List, Tuple, Optional

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge

from cocotb_tools.runner import get_runner
import random

os.environ["COCOTB_ANSI_OUTPUT"] = "1"


def random_bits(length: int, rng: random.Random) -> List[int]:
    return [rng.randint(0, 1) for _ in range(length)]

def generate_packet(seed: Optional[int] = None) -> Tuple[List[int], List[int], List[int]]:
    rng = random.Random(seed)

    mode_num = rng.randint(0, 1)
    if mode_num == 1:
        mode = int_to_bits_msb_first(2, 2)
    else:
        mode = int_to_bits_msb_first(0, 2)      

    if mode == [0, 0]:
        value = rng.randint(0, 512)          
        ten_bits = int_to_bits_msb_first(value, 10)    
        payload = random_bits(value, rng)       

    elif mode == [1, 0]:
        ten_bits = [0] * 10                  
        payload = []                         

    else:
        ten_bits = [0] * 9+[1]
        payload = []

    return mode, ten_bits, payload

def random_binary_array(length: int) -> list[int]:
    return [random.randint(0, 1) for _ in range(length)]

def int_to_bits_msb_first(value: int, width: int) -> List[int]:
    return [(value >> (width - 1 - i)) & 1 for i in range(width)]


def bits_to_int_msb_first(bits: List[int]) -> int:
    v = 0
    for b in bits:
        v = (v << 1) | (int(b) & 1)
    return v


class SPITester:
    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.rst_n = dut.rst_n

        self.spi_clk = dut.spi_clk
        self.spi_in = dut.spi_in
        self.spi_out = dut.spi_out

        self.hash_ready = dut.hash_ready
        self.hash_in = dut.hash_in

        self.data_out = dut.data_out

        self.msg_lock = dut.msg_lock
        self.msg_bits = dut.msg_bits
        self.msg_set_p = dut.msg_set_p
        self.msg_up_p = dut.msg_up_p

        # inner variables for testing
        self.state = dut.state
        self.next_state = dut.next_state

        self.spi_clk_d = dut.spi_clk_d

        self.addr_bits = dut.addr_bits
        self.next_addr_bits = dut.next_addr_bits
        self.len_bits = dut.len_bits
        self.next_len_bits = dut.next_len_bits
        self.count_len_bits = dut.count_len_bits
        self.next_count_len_bits = dut.next_count_len_bits
        self.count_padding_ignore = dut.count_padding_ignore
        self.next_count_padding_ignore = dut.next_count_padding_ignore
        self.count_payload_ignore = dut.count_payload_ignore
        self.next_count_payload_ignore = dut.next_count_payload_ignore
        self.count_data_send = dut.count_data_send
        self.next_count_data_send = dut.next_count_data_send

        self.msg_cache = dut.msg_cache
        self.next_msg_cache = dut.next_msg_cache
        self.count_cached = dut.count_cached
        

    async def wait_cycles(self, num_cycles: int):
        for _ in range(num_cycles):
            await RisingEdge(self.clk)


    async def reset(self):
        self.spi_clk.value = 0

        self.rst_n.value = 0
        await RisingEdge(self.clk)
        self.rst_n.value = 1        
        await RisingEdge(self.clk)


    async def check_inner_variables_after_reset(self):
        assert self.addr_bits.value == 0
        assert self.len_bits.value == 0
        assert self.count_len_bits.value == 0
        assert self.count_padding_ignore.value == 0
        assert self.count_payload_ignore.value == 0
        assert self.count_data_send.value == 0

        assert self.next_addr_bits.value == 0
        assert self.next_len_bits.value == 0
        assert self.next_count_len_bits.value == 0
        assert self.next_count_padding_ignore.value == 0
        assert self.next_count_payload_ignore.value == 0
        assert self.next_count_data_send.value == 0

        assert self.spi_clk_d.value == 0


    async def spi_clk_turn(self):
        # set spi_clk_d = 0
        # set spi_clk_edge = 1
        self.spi_clk.value = 1
        await RisingEdge(self.clk)

        # set spi_clk_d = 1
        # set spi_clk_edge = 0
        self.spi_clk.value = 0
        await RisingEdge(self.clk)


    async def send_bit(self, bit: int):
        self.spi_in.value = bit
        await self.spi_clk_turn()

    
    async def send_bit_vector(self, bit_vector: List[int]):
        for bit in bit_vector:
            await self.send_bit(bit)

    async def send_addr(self, addr_bits=[0,0]):
        await self.send_bit_vector(addr_bits)

    async def send_len_bits(self, bits_to_read=[1,0,0,0,0,0,0,0,0,0]):
        await self.send_bit_vector(bits_to_read)

    async def send_full_header(self, addr_bits=[0,0], len_bits=[1,0,0,0,0,0,0,0,0,0]):
        await self.send_addr(addr_bits)
        await self.send_len_bits(len_bits)
        await self.send_bit_vector([0,0,0,0]) # for padding

    async def receive_bit_from_chip(self) -> int:
        self.spi_clk.value = 1
        await RisingEdge(self.clk)
        
        spi_out = self.spi_out.value

        self.spi_clk.value = 0
        await RisingEdge(self.clk)
        return spi_out

    async def receive_chip_response(self, amount_of_bits=8) -> List[int]:
        """Receive answer from chip, its always 8 bit"""
        answer = []
        for i in range(amount_of_bits):
            answer.append(await self.receive_bit_from_chip())
        
        return answer
    
    async def test_save_data_state(self):
        if self.addr_bits.value == 0: # MSG type
            assert self.data_out.value == self.msg_cache.value, f"Expected msg_cache value at data_out, got {int(self.data_out.value)} and msg_cache={int(self.msg_cache.value)}"
            assert self.msg_bits.value == self.len_bits.value, f"Expected len_bits value at msg_bits, got {int(self.msg_bits.value)} and len_bits={int(self.len_bits.value)}"


            assert self.msg_set_p.value == 1, f"Expected msg_set_p value should be one, got {int(self.msg_set_p.value)}"
            assert self.msg_up_p.value == 1, f"Expected msg_up_p value should be one, got {int(self.msg_up_p.value)}"
            
            await self.spi_clk_turn()

            assert self.data_out.value == self.msg_cache.value, f"Expected msg_cache value at data_out after clk rising edge, got {int(self.data_out.value)} and msg_cache={int(self.msg_cache.value)}"
            assert self.msg_bits.value == self.len_bits.value, f"Expected len_bits value at msg_bits after clk rising edge, got {int(self.msg_bits.value)} and len_bits={int(self.len_bits.value)}"
            assert self.msg_up_p.value == 0, f"Expected msg_up_p value should be zero, got {int(self.msg_up_p.value)}"
            assert self.msg_set_p.value == 0, f"Expected msg_set_p value should be zero, got {int(self.msg_set_p.value)}"
       

    async def send_full_msg_type(self, len_bits=int_to_bits_msb_first(512, 10), payload=int_to_bits_msb_first(1234567890, 512), msg_locked=0, rst_n=1):
        self.msg_lock.value = msg_locked
        await self.send_full_header(addr_bits=[0,0], len_bits=len_bits)

        if rst_n == -1:
            if self.rst_n.value == 0:
                assert int(self.state.value) == 0, f"Expected IDLE(0) after reset, got {int(self.state.value)}" 
                assert int(self.next_state.value) == 0, f"Expected IDLE(0) after reset, got {int(self.next_state.value)}"  
            return 

        await self.send_bit_vector(payload)
        
        response = await self.receive_chip_response()

        if not msg_locked:
            assert bits_to_int_msb_first(response) == 0xAA, f"Expected response for correct msg should be 0xAA, got {hex(bits_to_int_msb_first(response))}"
        else:
            assert bits_to_int_msb_first(response) == 0xFF, f"Expected response for error in msg should be 0xFF, got {hex(bits_to_int_msb_first(response))}"

        assert int(self.state.value) == 0, f"Expected state after correct msg should be IDLE(0), got {int(self.state.value)}"   


    async def send_full_hash_type(self, hash_is_ready=1,  rst_n=1):
        self.hash_ready.value = hash_is_ready
        await self.send_full_header([1,0])

        if rst_n == -1:
            if self.rst_n.value == 0:
                assert int(self.state.value) == 0, f"Expected IDLE(0) after reset, got {int(self.state.value)}"  
                assert int(self.next_state.value) == 0, f"Expected IDLE(0) after reset, got {int(self.next_state.value)}"
            return 

        response = await self.receive_chip_response()         

        if hash_is_ready:
            assert bits_to_int_msb_first(response) == 0xAA, f"Expected response for correct hash should be 0xAA, got {hex(bits_to_int_msb_first(response))}"
            expected_hash = 42
            self.hash_in.value = expected_hash
            response = await self.receive_chip_response(amount_of_bits=256)

            assert bits_to_int_msb_first(response) == 42, f"Expected hash should be 42, got {hex(bits_to_int_msb_first(response))}"
        else:
            assert bits_to_int_msb_first(response) == 0xFF, f"Expected response for error in hash should be 0xFF, got {hex(bits_to_int_msb_first(response))}"
        
        assert int(self.state.value) == 0, f"Expected state after correct hash should be IDLE(0), got {int(self.state.value)}"          


@cocotb.test(skip=False)
async def test_reset(dut):
    tester = SPITester(dut)

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.wait_cycles(1)

    await tester.reset()

    assert tester.state.value == 0, f"Expected IDLE(0) after reset, got {int(tester.state.value)}"

    await tester.check_inner_variables_after_reset()

    dut._log.info("✓ Reset test passed")


@cocotb.test(skip=False)
async def test_idle(dut):
    tester, clock = await init_testcase(dut)

    assert int(tester.state.value) == 0, f"Expected IDLE(0) after starting state maschine, got {int(tester.state.value)}"

    await tester.wait_cycles(1)

    await tester.check_inner_variables_after_reset()

    await tester.send_bit(1)

    assert int(tester.state.value) == 1, f"Expected ADDR_READ(1) after starting state maschine, got {int(tester.state.value)}"

    dut._log.info("✓ Idle test passed")



@cocotb.test(skip=False)
async def test_addr_read(dut):
    tester, clock = await init_testcase(dut)

    await tester.send_bit(1)

    assert int(tester.state.value) == 1, f"Expected ADDR_READ(1) because of one spi_clk cycle, got {int(tester.state.value)}"
    
    await tester.send_bit(0)

    assert int(tester.state.value) == 2, f"Expected LEN_READ(2) because address was read, got {int(tester.state.value)}"

    assert tester.addr_bits.value.to_unsigned() == 2, f"Expected addr_bits equal 2 because address was SIG_MSG 0b10, got {int(tester.addr_bits.value.to_unsigned())}"

    dut._log.info("✓ Addr_read test passed")


@cocotb.test(skip=False)
async def test_len_read_msg_hash(dut):
    tester, clock = await init_testcase(dut)

    # send addr_bits
    await tester.send_addr()

    assert int(tester.state.value) == 2, f"Expected LEN_READ(2) because address was read, got {int(tester.state.value)}"

    # send 9 of 10 bits
    await tester.send_bit_vector([1,0,0,0,0,0,0,0,0])

    assert int(tester.state.value) == 2, f"Expected LEN_READ(2) because only 9 of 10 bits was read, got {int(tester.state.value)}"

    await tester.send_bit(0)

    assert int(tester.state.value) == 3, f"Expected PAD_IGNORE(3) because full length was read, got {int(tester.state.value)}"

    assert tester.len_bits.value.to_unsigned() == 512, f"Expected 512 length in len_bits, got {tester.len_bits.value.to_unsigned()}"

    dut._log.info("✓ Len_read for msg and hash msgs test passed")


@cocotb.test(skip=False)
async def test_pad_ignore(dut):
    tester, clock = await init_testcase(dut)

    # send addr and len bits
    await tester.send_addr()
    await tester.send_len_bits()

    assert int(tester.state.value) == 3, f"Expected PAD_IGNORE(3) because full length was read, got {int(tester.state.value)}"

    # send random 3 of 4 bits because its padding
    await tester.send_bit_vector([1,0,1])

    assert int(tester.state.value) == 3, f"Expected PAD_IGNORE(3) because 3 of 4 padding bits was read, got {int(tester.state.value)}"

    await tester.send_bit(0)

    assert int(tester.state.value) == 4, f"Expected LOCK_CHECK(4) because padding was ignored, got {int(tester.state.value)}"

    dut._log.info("✓ pad_ignore test passed")


@cocotb.test(skip=False)
async def test_lock_check_msg_lock(dut):
    tester, clock = await init_testcase(dut)
    
    tester.msg_lock.value = 1
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0]) # set MSG type

    assert int(tester.state.value) == 4, f"Expected LOCK_CHECK(4) because full header was read, got {int(tester.state.value)}"

    # The decision was already made in the CLK cycle whether the payload is cached or an error is sent because msg_lock == 1
    assert int(tester.next_state.value) == 11, f"Expected IGNORE_PAYLOAD(11) because msg was locked, got {int(tester.next_state.value)}"
    dut._log.info("✓ lock_check msg_lock test passed")

    
@cocotb.test(skip=False)
async def test_lock_check_msg_lock_is_not_set(dut):
    tester, clock = await init_testcase(dut)
    
    tester.msg_lock.value = 0
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0]) # set MSG type

    assert int(tester.state.value) == 4, f"Expected LOCK_CHECK(4) because full header was read, got {int(tester.state.value)}"

    # The decision was already made in the CLK cycle whether the payload is cached or an error is sent because msg_lock == 1
    assert int(tester.next_state.value) == 8, f"Expected CACHE_PAYLOAD(8) because msg is not locked, got {int(tester.next_state.value)}"
    dut._log.info("✓ lock_check msg not locked test passed")


@cocotb.test(skip=False)
async def test_lock_check_hash_is_not_ready(dut):
    tester, clock = await init_testcase(dut)
    
    tester.hash_ready.value = 0
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[1,0]) # set hash type

    assert int(tester.state.value) == 4, f"Expected LOCK_CHECK(4) because full header was read, got {int(tester.state.value)}"

    # The decision was already made in the CLK cycle whether the hash ok will be sent or an error will be sent. So we need to check next_state
    assert int(tester.next_state.value) == 5, f"Expected SEND_ERR(5) because hash was not ready, got {int(tester.next_state.value)}"
    dut._log.info("✓ lock_check hash is not ready test passed")

    
@cocotb.test(skip=False)
async def test_lock_check_hash_is_ready(dut):
    tester, clock = await init_testcase(dut)

    tester.hash_ready.value = 1
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[1,0]) # set hash type

    assert int(tester.state.value) == 4, f"Expected LOCK_CHECK(4) because full header was read, got {int(tester.state.value)}"

    # The decision was already made in the CLK cycle whether the hash ok will be sent or an error will be sent. So we need to check next_state
    assert int(tester.next_state.value) == 6, f"Expected SEND_HASH_OK(6) because hash is ready, got {int(tester.next_state.value)}"
    dut._log.info("✓ lock_check hash is ready test passed")


@cocotb.test(skip=False)
async def test_msg_payload_ignore_because_msg_is_locked(dut):
    tester, clock = await init_testcase(dut)
        
    tester.msg_lock.value = 1
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0], len_bits=[0,0,0,0,0,0,1,0,0,0]) # set MSG type and len to 8

    assert tester.len_bits.value.to_unsigned() == 8
    # now we should ignore exacly 8 bits before we go to the error state
    # the next state should be IGNORE_PAYLOAD
    assert int(tester.next_state.value) == 11, f"Expected IGNORE_PAYLOAD(11) because msg was locked, got {int(tester.next_state.value)}"

    # now we sent 7 bits we should still be in IGNORE_PAYLOAD
    await tester.send_bit_vector([0,0,0,0,0,0,0])
    assert int(tester.next_state.value) == 11, f"Expected IGNORE_PAYLOAD(11) because we only sent 7 of 8 bits, got {int(tester.next_state.value)}"

    await tester.send_bit(0)
    assert int(tester.state.value) == 5, f"Expected SEND_ERR(5) because all payload was ignored, got {int(tester.state.value)}"
    dut._log.info("✓ msg payload ignore test passed")
    

@cocotb.test(skip=False)
async def test_receive_error_from_msg_lock(dut):
    tester, clock = await init_testcase(dut)

    # lock msg
    tester.msg_lock.value = 1
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0], len_bits=[0,0,0,0,0,0,0,0,0,1])

    await tester.send_bit(0) # send bit because len_bits is 1

    assert int(tester.next_state.value) == 5, f"Expected SEND_ERR(5) because msg was locked, got {int(tester.next_state.value)}"

    chip_response = await tester.receive_chip_response()

    assert bits_to_int_msb_first(chip_response) == 0xFF

    assert int(tester.state.value) == 0, f"Expected IDLE(0) because error msg was sent, got {int(tester.state.value)}"
    
    dut._log.info("✓ error from msg lock test passed")


@cocotb.test(skip=False)
async def test_receive_error_from_msg_lock_with_empty_payload(dut):
    tester, clock = await init_testcase(dut)

    # lock msg
    tester.msg_lock.value = 1
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0], len_bits=[0,0,0,0,0,0,0,0,0,0])

    assert int(tester.next_state.value) == 5, f"Expected SEND_ERR(5) because msg was locked, got {int(tester.next_state.value)}"

    chip_response = await tester.receive_chip_response()

    assert bits_to_int_msb_first(chip_response) == 0xFF

    assert int(tester.state.value) == 0, f"Expected IDLE(0) because error msg was sent, got {int(tester.state.value)}"
    
    dut._log.info("✓ error from msg lock test passed")


@cocotb.test(skip=False)
async def test_receive_error_from_sig_is_not_ready(dut):
    tester, clock = await init_testcase(dut)

    # set hash is not ready
    tester.hash_ready.value = 0
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[1,0], len_bits=[0,1,0,0,0,0,1,0,0,1])

    assert int(tester.next_state.value) == 5, f"Expected SEND_ERR(5) because hash is not ready, got {int(tester.next_state.value)}"

    chip_response = await tester.receive_chip_response()

    assert bits_to_int_msb_first(chip_response) == 0xFF

    assert int(tester.state.value) == 0, f"Expected IDLE(0) because error msg was sent, got {int(tester.state.value)}"

    dut._log.info("✓ error from hash is not ready test passed")


@cocotb.test(skip=False)
async def test_receive_hash_ok(dut):
    tester, clock = await init_testcase(dut)

    # set hash is ready
    tester.hash_ready.value = 1
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[1,0], len_bits=[0,1,0,0,0,0,1,0,0,1])

    assert int(tester.next_state.value) == 6, f"Expected SEND_HASH_OK(6) because hash is ready, got {int(tester.next_state.value)}"

    chip_response = await tester.receive_chip_response()

    assert bits_to_int_msb_first(chip_response) == 0xAA

    assert int(tester.state.value) == 7, f"Expected SEND_HASH(7) because sig_ok was sent, got {int(tester.state.value)}"

    dut._log.info("✓ received hash ok test passed")


@cocotb.test(skip=False)
async def test_receive_hash(dut):
    tester, clock = await init_testcase(dut)

    # set hash is ready
    tester.hash_ready.value = 1
    # set sig
    expected_hash_val = 0xDEADBEEFCAFEBABE12345678
    tester.hash_in.value = expected_hash_val
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[1,0], len_bits=[0,1,0,0,0,0,1,0,0,1])

    assert int(tester.next_state.value) == 6, f"Expected SEND_HASH_OK(6) because hash is ready, got {int(tester.next_state.value)}"

    await tester.receive_chip_response()

    assert int(tester.state.value) == 7, f"Expected SEND_HASH(7) because sig_ok was sent, got {int(tester.state.value)}"

    chip_response = await tester.receive_chip_response(amount_of_bits=256)

    assert bits_to_int_msb_first(chip_response) == expected_hash_val

    assert int(tester.state.value) == 0, f"Expected IDLE(0) because hash was sent, got {int(tester.state.value)}"

    dut._log.info("✓ received hash test passed")


@cocotb.test(skip=False)
async def test_cache_payload_for_msg(dut):
    tester, clock = await init_testcase(dut)

    tester.msg_lock.value = 0
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0], len_bits=int_to_bits_msb_first(value=256, width=10))

    assert int(tester.next_state.value) == 8, f"Expected CACHE_PAYLOAD(8) because msg was not locked, got {int(tester.next_state.value)}"

    expected_payload = int_to_bits_msb_first(0xABFCAFE971215, 256)

    await tester.send_bit_vector(expected_payload)

    assert tester.msg_cache.value == bits_to_int_msb_first(expected_payload)

    assert int(tester.state.value) == 9, f"Expected SAVE_DATA(9) because payload was cached, got {int(tester.state.value)}"

    dut._log.info("✓ cache payload for msg test passed")


@cocotb.test(skip=False)
async def test_cache_payload_for_msg_with_empty_payload(dut):
    tester, clock = await init_testcase(dut)

    tester.msg_lock.value = 0
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0], len_bits=int_to_bits_msb_first(value=0, width=10))

    assert int(tester.next_state.value) == 10, f"Expected SEND_OK(10) because msg was not locked but payload was empty so we need one step in CACHE_PAYLOAD to set up pulses, got {int(tester.next_state.value)}"

    chip_response = await tester.receive_chip_response()

    assert bits_to_int_msb_first(chip_response) == 0xAA

    dut._log.info("✓ cache payload for msg with empty payload test passed")


@cocotb.test(skip=False)
async def test_save_data_msg_and_reset(dut):
    tester, clock = await init_testcase(dut)
 
    tester.msg_lock.value = 0
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0], len_bits=int_to_bits_msb_first(value=16, width=10))  

    await tester.send_bit_vector([0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1])

    assert int(tester.state.value) == 9, f"Expected SAVE_DATA(9) because payload was cached, got {int(tester.state.value)}"
    assert int(tester.next_state.value) == 10, f"Expected SEND_OK(10) because save data will be executed in next clk cycle, got {int(tester.next_state.value)}"

    await tester.test_save_data_state()
    assert int(tester.state.value) == 10, f"Expected SEND_OK(10), got {int(tester.state.value)}"

    await tester.reset()

    assert tester.data_out.value == 0, f"Expected data_out is zero, got {int(tester.data_out.value)}"
    assert tester.msg_bits.value == 0, f"Expected msg_bits is zero, got {int(tester.msg_bits.value)}"

    assert tester.msg_set_p.value == 1, f"Expected msg_set_p is one, got {int(tester.msg_set_p.value)}"
    assert tester.msg_up_p.value == 0, f"Expected msg_up_p is zero, got {int(tester.msg_up_p.value)}"

    await tester.wait_cycles(1)
    assert tester.msg_set_p.value == 0, f"Expected msg_set_p is zero, got {int(tester.msg_set_p.value)}"

    dut._log.info("✓ save data and reset data for msg test passed")


@cocotb.test(skip=False)
async def test_send_ok_msg(dut):
    tester, clock = await init_testcase(dut)
 
    tester.msg_lock.value = 0
    await tester.wait_cycles(1)

    await tester.send_full_header(addr_bits=[0,0], len_bits=int_to_bits_msb_first(value=16, width=10))  

    await tester.send_bit_vector([0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1])

    assert int(tester.state.value) == 9, f"Expected SAVE_DATA(9) because payload was cached, got {int(tester.state.value)}"
    assert int(tester.next_state.value) == 10, f"Expected SEND_OK(10) because save data will be executed in next clk cycle, got {int(tester.next_state.value)}"

    chip_response = await tester.receive_chip_response()

    assert bits_to_int_msb_first(chip_response) == 0xAA

    assert int(tester.state.value) == 0, f"Expected IDLE(0) because ok was sent, got {int(tester.state.value)}"
    dut._log.info("✓ send ok for msg test passed")


@cocotb.test(skip=False)
async def test_complete_fsm(dut):
    tester, clock = await init_testcase(dut)

    await tester.send_full_msg_type()
    await tester.send_full_hash_type()


@cocotb.test(skip=False)
async def test_random_messages(dut):
    tester, clock = await init_testcase(dut)

    seed = 42

    for i in range(1000):
        type, len_bits, payload = generate_packet(seed+i)
        type_value = bits_to_int_msb_first(type)
        locked_or_ready = i % 2

        rst_n_inactive = random.Random(seed+i).randint(0,1)

        assert bits_to_int_msb_first(len_bits) == len(payload), f"len_bits not equal to payload from random generator"

        if type_value==0:
            await tester.send_full_msg_type(len_bits=len_bits, payload=payload, msg_locked=locked_or_ready, rst_n=rst_n_inactive)
        elif type_value==2:
            await tester.send_full_hash_type(hash_is_ready=locked_or_ready)

    dut._log.info("✓ send random messages test passed")

    
@cocotb.test(skip=False)
async def test_random_messages_with_resets(dut):
    tester, clock = await init_testcase(dut)
    tester.rst_n.value = 0

    seed = 42

    for i in range(100):
        type, len_bits, payload = generate_packet(seed+i)
        type_value = bits_to_int_msb_first(type)
        locked_or_ready = i % 2

        assert bits_to_int_msb_first(len_bits) == len(payload), f"len_bits not equal to payload from random generator"

        if type_value==0:
            await tester.send_full_msg_type(len_bits=len_bits, payload=payload, msg_locked=locked_or_ready, rst_n=-1)
        elif type_value==2:
            await tester.send_full_hash_type(hash_is_ready=locked_or_ready, rst_n=-1)       

    dut._log.info("✓ send random messages with resets test passed")


async def init_testcase(dut) -> tuple[SPITester, Clock]:
    tester = SPITester(dut)

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())
    await tester.reset()

    return tester, clock


def test_spi_runner():
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sources = [proj_path / "src" / "spi.sv"]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="spi",
        always=True,
        waves=True,
        timescale=("1ns", "1ps"),
    )
    runner.test(hdl_toplevel="spi", test_module="test_spi", waves=True)


if __name__ == "__main__":
    test_spi_runner()
