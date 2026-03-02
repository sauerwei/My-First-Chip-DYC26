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
        self.length = 0  # 64bit

    def _get_hash(self):
        return ((self.h0 << (32 * 7)) +
                (self.h1 << (32 * 6)) +
                (self.h2 << (32 * 5)) +
                (self.h3 << (32 * 4)) +
                (self.h4 << (32 * 3)) +
                (self.h5 << (32 * 2)) +
                (self.h6 << (32 * 1)) +
                (self.h7))

    def hash(self, msg: bytes) -> int:
        for i in range(0, len(msg), 64):
            end_index = i + 64 if i + 64 <= len(msg) else len(msg)
            self.hash_chunk(msg[i:end_index])
        if len(msg) % 64 == 0:
            self.hash_chunk(bytes())
        return self._get_hash()

    def hash_chunk(self, chunk: bytes) -> int:
        chunk_array: bytearray = bytearray(chunk)
        self.length += len(chunk) * 8
        self.length %= (2 ** 64)
        if len(chunk_array) != 64:
            chunk_array.append(0x80)  # 0b1000 0000
            while (len(chunk_array) + 8) % 64 != 0:
                chunk_array.append(0)
            chunk_array.extend(self.length.to_bytes(8, byteorder='big'))
            for i in range(0, len(chunk_array), 64):
                self._internal_hash_chunk(bytes(chunk_array[i * 64:(i + 1) * 64]))
        else:
            self._internal_hash_chunk(chunk)
        return self._get_hash()

    @staticmethod
    def _right_rotate(value: int, amount: int) -> int:
        return (2 ** 32 - 1) & (value >> amount | value << (32 - amount))

    def _internal_hash_chunk(self, chunk: bytes):
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
