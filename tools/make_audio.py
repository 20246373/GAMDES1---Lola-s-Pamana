"""Generates the placeholder sound effects and radio music in res://audio/.

Every sound is synthesized from sine waves and filtered noise, so the files are
original work owned by the team. Replace them with recorded or CC0 audio later
and list the new sources in Table 23.

Run from the repository root:  python3 tools/make_audio.py
Needs numpy and scipy.
"""
import os
import wave

import numpy as np
from scipy import signal

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(sec * RATE)) / RATE


def env(n, attack=0.005, release=0.2, sec=None):
    e = np.ones(n)
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    e[:a] = np.linspace(0, 1, a)
    if r < n:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def noise(sec):
    return rng.uniform(-1, 1, int(sec * RATE))


def band(x, lo, hi, order=3):
    b, a = signal.butter(order, [lo / (RATE / 2), hi / (RATE / 2)], btype="band")
    return signal.lfilter(b, a, x)


def lowpass(x, hi, order=3):
    b, a = signal.butter(order, hi / (RATE / 2), btype="low")
    return signal.lfilter(b, a, x)


def save(name, x, gain=0.8):
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * gain
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())


def place(total, parts):
    out = np.zeros(int(total * RATE))
    for start, clip in parts:
        i = int(start * RATE)
        j = min(len(out), i + len(clip))
        out[i:j] += clip[: j - i]
    return out


def tone(freq, sec, kind="sine"):
    tt = t(sec)
    if kind == "sine":
        return np.sin(2 * np.pi * freq * tt)
    if kind == "tri":
        return signal.sawtooth(2 * np.pi * freq * tt, 0.5)
    return signal.square(2 * np.pi * freq * tt) * 0.5


def main():
    os.makedirs(OUT, exist_ok=True)

    # Radio music: a slow, soft loop of four chords with a gentle melody.
    bpm_beat = 0.75
    chords = [[220.0, 261.6, 329.6], [196.0, 246.9, 293.7], [174.6, 220.0, 261.6], [196.0, 246.9, 329.6]]
    melody = [659.3, 587.3, 523.3, 493.9, 523.3, 587.3, 523.3, 440.0,
              587.3, 523.3, 493.9, 440.0, 493.9, 523.3, 587.3, 659.3]
    total = len(chords) * 4 * bpm_beat
    parts = []
    for ci, ch in enumerate(chords):
        dur = 4 * bpm_beat
        pad = sum(tone(f, dur, "tri") * 0.25 for f in ch) * env(int(dur * RATE), 0.3, 0.6)
        parts.append((ci * dur, pad))
    for mi, f in enumerate(melody):
        d = bpm_beat
        note = tone(f, d) * np.exp(-t(d) * 3.5) * 0.5
        parts.append((mi * d, note))
    music = place(total, parts)
    music = lowpass(music, 2600)
    crackle = (rng.random(len(music)) > 0.9993) * rng.uniform(-0.4, 0.4, len(music))
    music = music + lowpass(noise(total) * 0.015, 3000) + crackle
    save("radio_music", music, 0.6)

    # Radio static.
    st = band(noise(2.0), 400, 6000) * (0.7 + 0.3 * np.sin(2 * np.pi * 3 * t(2.0)))
    save("static", st, 0.5)

    # Tik-tik bird: sharp chirps that fade, as if far up the street.
    chirp = lambda f: band(noise(0.04), f - 400, f + 400) * env(int(0.04 * RATE), 0.001, 0.03)
    parts = []
    for k, s in enumerate([0.0, 0.18, 0.9, 1.08, 1.9, 2.05]):
        parts.append((s, chirp(3200 if k % 2 == 0 else 2900) * (1.0 - k * 0.12)))
    save("tiktik", place(2.6, parts), 0.7)

    # Whispers: breathy filtered noise with a syllable rhythm.
    w = band(noise(2.6), 1500, 5000)
    syl = np.clip(np.sin(2 * np.pi * 2.3 * t(2.6)) + 0.2 * np.sin(2 * np.pi * 7 * t(2.6)), 0, 1) ** 2
    save("whispers", w * syl * env(len(w), 0.3, 0.6), 0.5)

    # Heartbeat thump for Sanity loss.
    thump = lambda: lowpass(tone(55, 0.18) * np.exp(-t(0.18) * 22), 300)
    save("heartbeat", place(0.6, [(0.0, thump()), (0.22, thump() * 0.7)]), 0.9)

    # 6 AM bell.
    bt = t(3.5)
    bell = sum(a * np.sin(2 * np.pi * f * bt) * np.exp(-bt * d)
               for f, a, d in [(392, 1.0, 1.2), (784, 0.5, 1.8), (1176, 0.3, 2.5), (523, 0.25, 1.5), (987, 0.2, 3.0)])
    save("bell", bell, 0.7)

    # Shriek at a banish: a falling harsh tone over noise.
    sh_t = t(1.0)
    freq = np.linspace(1800, 500, len(sh_t))
    shriek = signal.sawtooth(2 * np.pi * np.cumsum(freq) / RATE) * 0.6 + band(noise(1.0), 800, 4000) * 0.4
    save("shriek", shriek * env(len(sh_t), 0.01, 0.5), 0.8)

    # Jump scare sting: a loud dissonant burst.
    sc_t = t(1.2)
    scare = sum(np.sin(2 * np.pi * f * sc_t) for f in [311, 330, 466, 622, 659]) * 0.3
    scare += band(noise(1.2), 200, 6000) * 0.8
    save("scare", scare * env(len(sc_t), 0.002, 0.9), 0.95)

    # Shutter slam: metallic rattle bursts.
    parts = []
    for k in range(9):
        clip = band(noise(0.06), 1500, 7000) * env(int(0.06 * RATE), 0.001, 0.05)
        parts.append((k * 0.04, clip * (1.0 - k * 0.06)))
    parts.append((0.38, lowpass(noise(0.2), 250) * np.exp(-t(0.2) * 12) * 2))
    save("shutter", place(0.7, parts), 0.8)

    # Coins in the cash drawer.
    clink = lambda f: sum(np.sin(2 * np.pi * f * m * t(0.25)) / m for m in [1, 2.7, 5.1]) * np.exp(-t(0.25) * 18)
    save("coin", place(0.45, [(0.0, clink(2400)), (0.09, clink(2900)), (0.17, clink(2600))]), 0.6)

    # Register ching for a day purchase.
    save("buy", place(0.5, [(0.0, clink(1800)), (0.05, clink(3600))]), 0.6)

    # Salt sprinkle and spark.
    grains = place(0.6, [(rng.uniform(0, 0.5), band(noise(0.01), 3000, 9000)) for _ in range(40)])
    save("salt", grains, 0.5)
    spark = place(0.5, [(rng.uniform(0, 0.4), band(noise(0.008), 2000, 9000) * 1.5) for _ in range(25)])
    spark += tone(120, 0.5) * np.exp(-t(0.5) * 6) * 0.3
    save("spark", spark, 0.7)

    # Pen scratch on paper.
    pen = band(noise(0.7), 2500, 7000) * np.abs(np.sin(2 * np.pi * 6 * t(0.7)))
    save("pen", pen * env(len(pen), 0.02, 0.1), 0.45)

    # Page turn.
    pg = band(noise(0.35), 600, 4000) * np.sin(np.pi * np.linspace(0, 1, int(0.35 * RATE)))
    save("page", pg, 0.45)

    # UI click.
    save("click", tone(1400, 0.04) * np.exp(-t(0.04) * 90), 0.4)

    # UV scan finished: a soft chime.
    save("scan_done", (tone(1046, 0.4) + 0.5 * tone(1568, 0.4)) * np.exp(-t(0.4) * 9), 0.35)

    # A tell is revealed: a low swell.
    rv_t = t(1.0)
    reveal = (np.sin(2 * np.pi * 110 * rv_t) + 0.6 * np.sin(2 * np.pi * 116.5 * rv_t)) * np.sin(np.pi * rv_t / 1.0)
    save("reveal", reveal, 0.6)

    # Voice babble for a talking customer.
    sy = []
    for k in range(5):
        f = rng.uniform(170, 260)
        d = rng.uniform(0.07, 0.12)
        sy.append((k * 0.13, tone(f, d, "tri") * env(int(d * RATE), 0.01, 0.05) * 0.6))
    save("voice", lowpass(place(0.75, sy), 1800), 0.4)

    # Street sounds for quiet gaps. Never the tik-tik bird or whispers.
    bark = lambda: band(noise(0.15), 300, 1500) * env(int(0.15 * RATE), 0.005, 0.1) + tone(350, 0.15) * np.exp(-t(0.15) * 15)
    save("dog", place(1.2, [(0.0, bark()), (0.35, bark() * 0.8)]), 0.35)
    save("footsteps", place(2.0, [(k * 0.45, lowpass(noise(0.07), 600) * env(int(0.07 * RATE), 0.002, 0.05)) for k in range(4)]), 0.4)
    wind = lowpass(noise(6.0), 500) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.17 * t(6.0)))
    save("wind", wind * env(len(wind), 0.8, 0.8), 0.35)

    # Desk lamp flicker buzz.
    bz = signal.square(2 * np.pi * 120 * t(0.5)) * band(noise(0.5), 80, 2000) * 0.5
    save("buzz", bz * env(len(bz), 0.01, 0.1), 0.35)

    # Leaves rustle when an entity collapses.
    rs = band(noise(1.2), 1500, 8000) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 4 * t(1.2))))
    save("leaves", rs * env(len(rs), 0.05, 0.6), 0.5)

    # Empty jar rattle or a refused click.
    save("error", place(0.3, [(0.0, tone(180, 0.08, "sq")), (0.12, tone(150, 0.1, "sq"))]) * 0.6, 0.4)

    # Low battery beep.
    save("low_battery", place(0.4, [(0.0, tone(880, 0.08)), (0.16, tone(660, 0.1))]), 0.35)

    # Gain chime for Sanity or a correct call.
    save("gain", (tone(784, 0.3) + tone(1175, 0.3) * 0.5) * np.exp(-t(0.3) * 8), 0.35)


if __name__ == "__main__":
    main()
