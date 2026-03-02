class CurveFp:
    def __init__(self):
        self.p = 115792089237316195423570985008687907853269984665640564039457584007908834671663
        self.a = 0
        self.b = 7

    def is_on_curve(self, P) -> bool:
        if P is None:  # point at infinity
            return True
        x, y = P
        p = self.p
        return (y * y - (x * x * x + self.a * x + self.b)) % p == 0

    def inv_mod_binary(self, a, p) -> int:
        a %= p
        if a == 0:
            raise ZeroDivisionError
        u, v = a, p
        x1, x2 = 1, 0
        while u != 1 and v != 1:
            while (u & 1) == 0:
                u >>= 1
                if (x1 & 1) == 0:
                    x1 >>= 1
                else:
                    x1 = (x1 + p) >> 1
            while (v & 1) == 0:
                v >>= 1
                if (x2 & 1) == 0:
                    x2 >>= 1
                else:
                    x2 = (x2 + p) >> 1
            if u >= v:
                u -= v
                x1 = (x1 - x2) % p
            else:
                v -= u
                x2 = (x2 - x1) % p
        return x1 % p if u == 1 else x2 % p

    def neg(self, P) -> tuple[int, int] | None:
        if P is None:
            return None
        x, y = P
        return (x, (self.p - y) % self.p)

    def add(self, P, Q) -> tuple[int, int] | None:
        """Group law on the elliptic curve in affine coordinates."""
        p = self.p

        # Identity cases
        if P is None:
            return Q
        if Q is None:
            return P

        x1, y1 = P
        x2, y2 = Q

        # If x1 == x2 and y1 == -y2, result is point at infinity
        if x1 == x2 and (y1 + y2) % p == 0:
            return None

        # Point doubling
        if P == Q:
            # slope lambda = (3*x1^2 + a) / (2*y1)
            num = (3 * x1 * x1 + self.a) % p
            den = (2 * y1) % p
        else:
            # slope lambda = (y2 - y1) / (x2 - x1)
            num = (y2 - y1) % p
            den = (x2 - x1) % p

        lam = (num * self.inv_mod_binary(den, p)) % p

        x3 = (lam * lam - x1 - x2) % p
        y3 = (lam * (x1 - x3) - y1) % p
        return (x3, y3)

    def mul(self, k: int, P) -> tuple[int, int] | None:
        """Scalar multiplication k*P using double-and-add (left-to-right)."""
        if k < 0:
            return self.mul(-k, self.neg(P))
        result = None
        addend = P

        while k > 0:
            if k & 1:
                result = self.add(result, addend)
            addend = self.add(addend, addend)
            k >>= 1

        return result
