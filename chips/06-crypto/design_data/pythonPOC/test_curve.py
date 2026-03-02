import random
import pytest

from ecpy.curves import Curve as ECPyCurve
from ecpy.curves import Point as ECPyPoint

from curve import CurveFp


def tup_from_ecpy(P: ECPyPoint) -> tuple[int, int]:
    return (int(P.x), int(P.y))


def ecpy_from_tup(cv: ECPyCurve, P: tuple[int, int]) -> ECPyPoint:
    x, y = P
    return ECPyPoint(int(x), int(y), cv)


def k_times_G(cv: ECPyCurve, k: int) -> ECPyPoint:
    return cv.mul_point(cv.generator, k)


@pytest.fixture(scope="session")
def ecpy_curve():
    return ECPyCurve.get_curve("secp256k1")


@pytest.fixture(scope="session")
def curve(ecpy_curve):
    return CurveFp()


@pytest.fixture(scope="session")
def G(ecpy_curve):
    return tup_from_ecpy(ecpy_curve.generator)


@pytest.fixture(scope="session")
def n(ecpy_curve):
    return int(ecpy_curve.order)


@pytest.fixture(scope="session")
def rng():
    r = random.Random(1337)
    return r


@pytest.fixture
def some_scalars(n):
    return [
        1,
        2,
        3,
        5,
        7,
        11,
        42,
        1337,
        n - 1,
        n - 2,  # letzten beiden zahlen
    ]


@pytest.fixture
def random_scalar_pairs(rng, n):
    pairs = []
    while len(pairs) < 10:
        k1 = rng.randrange(1, n)
        k2 = rng.randrange(1, n)
        if (k1 + k2) % n != 0:
            pairs.append((k1, k2))
    return pairs


def test_curve_params_match_ecpy(curve, ecpy_curve):
    assert curve.p == int(ecpy_curve.field)
    assert curve.a == int(ecpy_curve.a) % curve.p
    assert curve.b == int(ecpy_curve.b) % curve.p


def test_generator_is_on_curve(curve, G):
    assert curve.is_on_curve(G)


@pytest.mark.parametrize(
    "x,y",
    [
        (0, 0),
        (1, 1),
        (2, 3),
        (12345, 67890),
    ],
)
def test_is_on_curve_rejects_most_random_points(curve, x, y):
    assert curve.is_on_curve((x % curve.p, y % curve.p)) is False


@pytest.mark.parametrize("x", [1, 2, 3, 5, 7, 11, 42, -5, -1, 1234567890])
def test_inv_mod_binary_matches_pow(curve, x):
    p = curve.p
    inv = curve.inv_mod_binary(x, p)
    assert inv == pow(x, p - 2, p)
    assert (x * inv) % p == 1


def test_inv_mod_binary_zero_raises(curve):
    with pytest.raises(ZeroDivisionError):
        p = curve.p
        curve.inv_mod_binary(0, p)


def test_negation_identity(curve):
    assert curve.neg(None) is None


def test_negation_matches_ecpy(curve, ecpy_curve, G):
    P_ec = ecpy_from_tup(ecpy_curve, G)
    neg_ec = -P_ec

    neg_py = curve.neg(G)
    assert neg_py == tup_from_ecpy(neg_ec)
    assert curve.is_on_curve(neg_py)


def test_add_identity_left_right(curve, G):
    assert curve.add(None, G) == G
    assert curve.add(G, None) == G


def test_add_inverse_is_infinity(curve, G):
    negG = curve.neg(G)
    assert curve.add(G, negG) is None
    assert curve.add(negG, G) is None


@pytest.mark.parametrize("k", [1, 2, 3, 5, 7, 11, 42, -5, -1, 1234567890])
def test_add_doubling_matches_ecpy(curve, ecpy_curve, G, k):
    P_ec = k_times_G(ecpy_curve, k)
    R_ec = P_ec + P_ec

    P_py = tup_from_ecpy(P_ec)
    R_py = curve.add(P_py, P_py)

    assert R_py == tup_from_ecpy(R_ec)
    assert curve.is_on_curve(R_py)


def test_add_random_pairs_matches_ecpy(curve, ecpy_curve, random_scalar_pairs):
    # Das ist bereits ein Pedersen Commitment
    for k1, k2 in random_scalar_pairs:
        P_ec = k_times_G(ecpy_curve, k1)
        Q_ec = k_times_G(ecpy_curve, k2)

        R_ec = P_ec + Q_ec

        P_py = tup_from_ecpy(P_ec)
        Q_py = tup_from_ecpy(Q_ec)
        R_py = curve.add(P_py, Q_py)

        assert R_py == tup_from_ecpy(R_ec)
        assert curve.is_on_curve(R_py)


def test_mul_zero_returns_infinity(curve, G):
    assert curve.mul(0, G) is None


def test_mul_negative_scalar(curve, ecpy_curve, G):
    k = 12345
    P_ec = k_times_G(ecpy_curve, -k)

    R_py = curve.mul(-k, G)
    assert R_py == tup_from_ecpy(P_ec)
    assert curve.is_on_curve(R_py)


@pytest.mark.parametrize("k", [1, 2, 3, 5, 7, 11, 42, -5, -1, 1234567890])
def test_mul_matches_ecpy_on_generator(curve, ecpy_curve, G, k):
    R_ec = k_times_G(ecpy_curve, k)
    R_py = curve.mul(k, G)
    assert R_py == tup_from_ecpy(R_ec)
    assert curve.is_on_curve(R_py)


def test_mul_matches_ecpy_on_random_point(curve, ecpy_curve, n, rng):
    a = rng.randrange(1, n)
    k = rng.randrange(1, n)

    P_ec = k_times_G(ecpy_curve, a)
    R_ec = k * P_ec

    P_py = tup_from_ecpy(P_ec)
    R_py = curve.mul(k, P_py)

    assert R_py == tup_from_ecpy(R_ec)
    assert curve.is_on_curve(R_py)


def test_group_law_associativity_small_sample(curve, G):
    a, b, c = 3, 5, 7
    A = curve.mul(a, G)
    B = curve.mul(b, G)
    C = curve.mul(c, G)

    left = curve.add(curve.add(A, B), C)
    right = curve.add(A, curve.add(B, C))

    assert left == right
    assert curve.is_on_curve(left)
