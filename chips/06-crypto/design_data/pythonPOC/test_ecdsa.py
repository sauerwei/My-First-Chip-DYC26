import random
import hashlib
import ecpy
import pytest

from ecpy.ecdsa import ECDSA as ECPyecdsa, ECPrivateKey, decode_sig, encode_sig
from ecpy.curves import Curve as ECPyCurve
from ecdsa import Ecdsa

num_test = 1000

ecdsa = Ecdsa()


def test_ecdsa():
    for i in range(0, num_test):
        msg = str(random.randint(1, 2**512))

        privkey = random.randint(1, 2**256)
        pubkey = ecdsa.ec_curve.mul(privkey, ecdsa.generator)

        sig = ecdsa.sign(msg, privkey)
        assert ecdsa.verify(msg, sig, pubkey)


def test_ecdsa_ecpy_same_sig():
    for i in range(0, num_test):
        msg = str(random.randint(1, 2**512))
        msg_hash = hashlib.sha256(msg.encode()).digest()

        privkey = random.randint(1, 2**256)
        k = random.randint(1, 2**256)
        pubkey = ecdsa.ec_curve.mul(privkey, ecdsa.generator)
        ecpy_privkey = ECPrivateKey(privkey, ECPyCurve.get_curve("secp256k1"))

        sig = ecdsa.sign(msg, privkey, k)
        sig_ecpy = ECPyecdsa().sign_k(msg_hash, ecpy_privkey, k)
        dec_sig = decode_sig(sig_ecpy)

        assert sig == dec_sig
        assert ecdsa.verify(msg, dec_sig, pubkey)
        assert ECPyecdsa().verify(
            msg_hash, encode_sig(sig[0], sig[1]), ecpy_privkey.get_public_key()
        )


def test_ecdsa_againt_ecpy_with_k1():
    msg = str(random.randint(1, 2**512))
    msg_hash = hashlib.sha256(msg.encode()).digest()

    privkey = random.randint(1, 2**256)
    k = 1
    pubkey = ecdsa.ec_curve.mul(privkey, ecdsa.generator)
    ecpy_privkey = ECPrivateKey(privkey, ECPyCurve.get_curve("secp256k1"))
    sig = ecdsa.sign(msg, privkey, k)
    sig_ecpy = ECPyecdsa().sign_k(msg_hash, ecpy_privkey, k)
    dec_sig = decode_sig(sig_ecpy)
    assert sig == dec_sig
    assert ecdsa.verify(msg, dec_sig, pubkey)
    assert ECPyecdsa().verify(
        msg_hash, encode_sig(sig[0], sig[1]), ecpy_privkey.get_public_key()
    )
