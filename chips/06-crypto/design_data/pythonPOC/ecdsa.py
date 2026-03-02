from random import randint
import hashlib
from curve import CurveFp


class Ecdsa:
    def __init__(self) -> None:

        self.generator = (
            0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,
            0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8,
        )

        self.order = 115792089237316195423570985008687907852837564279074904382605163141518161494337

        self.ec_curve = CurveFp()

    def sign(self, msg, privkey, k=None):
        if not k:
            k = randint(1, 2**256)
        msg_hash = int(hashlib.sha256(msg.encode()).hexdigest(), 16)

        point = self.ec_curve.mul(k, self.generator)
        if point is None:  # Punkt ist Point at Infinity
            raise ValueError("Random Number K is not suited for signing")

        n = self.order
        r = point[0] % n
        if r == 0:
            raise ValueError("Random Number K is not suited for signing")
        s = (
            self.ec_curve.inv_mod_binary(k, n) * (msg_hash + r * privkey)
        ) % n  # s = k^{-1}(H(m) + r * privkey) mod n

        if s == 0:
            raise ValueError("Random Number K is not suited for signing")

        return r, s

    def verify(self, msg, sig, pubkey):
        msg_hash = int(hashlib.sha256(msg.encode()).hexdigest(), 16)
        pub_point = pubkey
        n = self.order
        r, s = sig
        if not (
            1 <= r <= n - 1 or 1 <= s <= n - 1
        ):  # r and s has to be in intervall [1, n-1]
            raise ValueError("Signature is not Element of [1; n-1]")

        # ECDSA-Verify
        u1 = (
            msg_hash * self.ec_curve.inv_mod_binary(s, n)
        ) % n  # u1 = H(m) * s^{-1} mod n
        u2 = (r * self.ec_curve.inv_mod_binary(s, n)) % n  # u2 = r * s^{-1} mod n

        # Calculate P; Signature is invalid if P zero
        P = self.ec_curve.add(
            self.ec_curve.mul(u1, self.generator), self.ec_curve.mul(u2, pub_point)
        )  # P = u1*G + u2*Q
        if P is None:
            return False

        return (
            r == P[0] % n
        )  # Signature is valid if x coordinate is congruent to r mod n
