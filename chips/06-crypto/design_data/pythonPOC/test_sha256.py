import random
import pytest

from sha256 import SHA256

from hashlib import sha256 as libsha256

num_test = 1000


def test_sha256():
    sha256 = SHA256()
    for _ in range(0, num_test):
        sha256.reset()
        msg = random.randbytes(2000)  # not a multiple of 512 on purpose

        hash = sha256.hash(msg)
        lib_hash = int.from_bytes(libsha256(msg).digest(), byteorder='big')
        assert hash == lib_hash

    msg = random.randbytes(1024)  # a multiple of 512 on purpose
    sha256.reset()
    hash = sha256.hash(msg)
    lib_hash = int.from_bytes(libsha256(msg).digest(), byteorder='big')
    assert hash == lib_hash


def test_sha256_against_known_hash():
    msg = bytes()
    hash = SHA256().hash(msg)
    assert hash == 0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
