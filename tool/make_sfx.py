"""Vızır ses efektlerini sentezler (assets/sfx/*.wav). Telif içermez, tamamen üretilmiştir.

Çalıştırma: python3 tool/make_sfx.py
"""
import pathlib
import wave

import numpy as np
from scipy.signal import butter, lfilter

SR = 22050
OUT = pathlib.Path(__file__).resolve().parent.parent / 'assets' / 'sfx'
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(7)


def t_(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, a=0.005, r=0.05, shape=1.0):
    e = np.ones(n)
    na, nr = int(SR * a), int(SR * r)
    if na:
        e[:na] = np.linspace(0, 1, na)
    if nr:
        e[-nr:] *= np.linspace(1, 0, nr) ** shape
    return e


def decay(n, k):
    return np.exp(-np.arange(n) / SR * k)


def lp(x, fc, order=2):
    b, a = butter(order, fc / (SR / 2), 'low')
    return lfilter(b, a, x)


def hp(x, fc, order=2):
    b, a = butter(order, fc / (SR / 2), 'high')
    return lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR / 2), hi / (SR / 2)], 'band')
    return lfilter(b, a, x)


def tone(freq, dur, kind='sine', harm=8):
    t = t_(dur)
    if kind == 'sine':
        return np.sin(2 * np.pi * freq * t)
    if kind == 'square':
        return sum(np.sin(2 * np.pi * freq * k * t) / k for k in range(1, harm * 2, 2))
    if kind == 'saw':
        return sum(np.sin(2 * np.pi * freq * k * t) / k for k in range(1, harm + 1))
    if kind == 'tri':
        return sum(((-1) ** i) * np.sin(2 * np.pi * freq * (2 * i + 1) * t) / (2 * i + 1) ** 2 for i in range(harm))
    raise ValueError(kind)


def bell(freq, dur, k=6):
    t = t_(dur)
    x = np.sin(2 * np.pi * freq * t) + 0.4 * np.sin(2 * np.pi * freq * 2.76 * t) * decay(len(t), k * 2) \
        + 0.2 * np.sin(2 * np.pi * freq * 5.4 * t) * decay(len(t), k * 3)
    return x * decay(len(t), k)


def seq(parts, gap=0.0):
    out = []
    for p in parts:
        out.append(p)
        if gap:
            out.append(np.zeros(int(SR * gap)))
    return np.concatenate(out)


def mix(*xs):
    n = max(len(x) for x in xs)
    out = np.zeros(n)
    for x in xs:
        out[:len(x)] += x
    return out


def save(name, x, peak=0.85, fade=True):
    x = np.asarray(x, dtype=float)
    if fade:
        x = x * env(len(x), 0.004, 0.01)
    m = np.max(np.abs(x)) or 1
    x = x / m * peak
    data = (x * 32767).astype('<i2').tobytes()
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)
    print(name, f'{len(x) / SR:.2f}s')


# ---- Motor (kusursuz döngü: 1 sn, tam sayı periyot) ----
def engine_loop():
    t = t_(1.0)
    f0 = 46.0
    x = sum(np.sin(2 * np.pi * f0 * k * t + k * 0.7) / (k ** 0.9) for k in range(1, 14))
    puls = 0.75 + 0.25 * np.sin(2 * np.pi * 23 * t)
    rumble = lp(rng.standard_normal(len(t)), 300) * 0.25
    y = lp(x * puls + rumble, 900)
    # döngü sınırını yumuşat
    n = int(SR * 0.02)
    y[:n] = y[:n] * np.linspace(0, 1, n) + y[-n:] * np.linspace(1, 0, n)
    return y[: len(t) - n]


save('engine', engine_loop(), peak=0.7, fade=False)


def rev():
    dur = 1.6
    t = t_(dur)
    f = np.interp(t, [0, 0.15, 0.7, 1.0, 1.6], [45, 50, 150, 120, 60])
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = sum(np.sin(k * ph) / k ** 0.8 for k in range(1, 12))
    x = x * (0.8 + 0.2 * np.sin(ph / 2))
    x = lp(x + lp(rng.standard_normal(len(t)), 400) * 0.2, 1400)
    return x * env(len(t), 0.05, 0.4)


save('rev', rev())

# ---- Kornalar ----
save('horn0', seq([mix(tone(420, 0.24, 'square', 6), tone(525, 0.24, 'square', 6)) * env(int(SR * 0.24), 0.01, 0.04)] * 2, 0.08))
save('horn1', seq([mix(tone(880, 0.1, 'square', 4), tone(1100, 0.1, 'square', 4)) * env(int(SR * 0.1), 0.005, 0.02)] * 3, 0.06))
save('horn2', lp(mix(tone(155, 1.0, 'saw', 14), tone(196, 1.0, 'saw', 14)), 1800) * env(int(SR * 1.0), 0.04, 0.15))
save('horn3', seq([tone(f, 0.16, 'square', 5) * env(int(SR * 0.16), 0.005, 0.04) for f in (523, 659, 784, 1047)], 0.03))

# ---- Oyun sesleri ----
save('coin', seq([tone(988, 0.07, 'square', 3) * 0.6, tone(1319, 0.32, 'square', 3) * decay(int(SR * 0.32), 9)]), peak=0.6)
save('correct', mix(bell(1047, 0.7), np.pad(bell(1319, 0.6), (int(SR * 0.08), 0)), np.pad(bell(1568, 0.6), (int(SR * 0.16), 0))))
save('wrong', seq([tone(330, 0.16, 'tri') * env(int(SR * 0.16), 0.01, 0.05), tone(262, 0.28, 'tri') * env(int(SR * 0.28), 0.01, 0.15)]), peak=0.5)
save('beep', tone(660, 0.16, 'square', 3) * env(int(SR * 0.16), 0.005, 0.05), peak=0.55)
save('go', tone(1320, 0.4, 'square', 3) * env(int(SR * 0.4), 0.005, 0.2), peak=0.6)
save('click', hp(rng.standard_normal(int(SR * 0.025)), 2000) * decay(int(SR * 0.025), 200), peak=0.5)


def turbo():
    dur = 0.9
    n = int(SR * dur)
    noise = rng.standard_normal(n)
    out = np.zeros(n)
    seg = 512
    for i in range(0, n, seg):
        fc = 300 + 3500 * (i / n)
        out[i:i + seg] = bp(noise[max(0, i - 2048):i + seg], fc * 0.6, fc * 1.4)[-len(out[i:i + seg]):]
    t = t_(dur)
    whine = np.sin(2 * np.pi * np.cumsum(np.interp(t, [0, dur], [400, 1600])) / SR) * 0.25
    return (out + whine) * env(n, 0.05, 0.35)


save('turbo', turbo(), peak=0.6)


def fanfare():
    notes = [(392, 0.16), (523, 0.16), (659, 0.16), (784, 0.5)]
    parts = []
    for f, d in notes:
        x = lp(tone(f, d, 'saw', 10), 2500) * env(int(SR * d), 0.02, 0.06)
        parts.append(x)
    head = seq(parts, 0.02)
    chord = sum(lp(tone(f, 1.0, 'saw', 10), 2200) for f in (523, 659, 784, 1047)) * env(int(SR * 1.0), 0.03, 0.6)
    return np.concatenate([head, chord])


save('finish', fanfare(), peak=0.7)
save('spray', bp(rng.standard_normal(int(SR * 0.6)), 2500, 8000) * env(int(SR * 0.6), 0.03, 0.25), peak=0.45)


def ratchet():
    parts = []
    for i in range(6):
        c = bp(rng.standard_normal(int(SR * 0.02)), 1500, 6000) * decay(int(SR * 0.02), 250)
        parts.append(c)
        parts.append(np.zeros(int(SR * 0.06)))
    return np.concatenate(parts)


save('wrench', ratchet(), peak=0.6)
save('unlock', mix(*[np.pad(bell(f, 0.5, 8) * 0.6, (int(SR * 0.06 * i), 0)) for i, f in enumerate((784, 988, 1175, 1568, 1976))]), peak=0.6)
save('heart', mix(bell(784, 0.8, 4), np.pad(bell(1175, 0.8, 4), (int(SR * 0.12), 0))), peak=0.6)
save('pop', tone(600, 0.08, 'sine') * np.linspace(1, 0, int(SR * 0.08)) ** 2, peak=0.5)
