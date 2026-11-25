"""Golden model: writes random INT8 matrix pairs and their INT32 products."""
import os, random

N, CASES = 4, 300
random.seed(2027)
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build")
os.makedirs(out, exist_ok=True)

def case(n):
    if n == 0: return [[-128] * N for _ in range(N)], [[-128] * N for _ in range(N)]
    if n == 1: return [[127] * N for _ in range(N)], [[-128] * N for _ in range(N)]
    if n == 2: return [[int(i == j) for j in range(N)] for i in range(N)], [[i * N + j - 8 for j in range(N)] for i in range(N)]
    return tuple([[random.randint(-128, 127) for _ in range(N)] for _ in range(N)] for _ in range(2))

with open(f"{out}/a.hex", "w") as fa, open(f"{out}/b.hex", "w") as fb, open(f"{out}/c.hex", "w") as fc:
    for n in range(CASES):
        a, b = case(n)
        for i in range(N):
            for j in range(N):
                fa.write(f"{a[i][j] & 0xff:02x}\n")
                fb.write(f"{b[i][j] & 0xff:02x}\n")
                fc.write(f"{sum(a[i][k] * b[k][j] for k in range(N)) & 0xffffffff:08x}\n")
