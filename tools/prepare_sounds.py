"""Freesound.org ki CC0 (public domain) recordings download kar ke game ke sounds banata hai.

Zaroorat: sox (ogg support ke saath)
Chalao:   python3 tools/prepare_sounds.py [cache_dir]
Output:   assets/sounds/*.ogg  +  assets/sounds/CREDITS.md
"""
import array
import os
import subprocess
import sys
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "assets", "sounds")
CACHE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "sound_cache")
RATE = 44100

# id: (preview url, title, author) — sab CC0, freesound.org/s/<id>/ pe verify kiye gaye
SOURCES = {
    683958: ("683/683958_6217756", "Footsteps on dry leaves", "eqavox"),
    179339: ("179/179339_544580", "Crunchy Footsteps On Leaves", "lolamadeus"),
    422972: ("422/422972_6366356", "SFXJumpLiftOffGround", "WakuWakuWakuWaku"),
    172960: ("172/172960_71257", "Jump Landing", "qubodup"),
    390769: ("390/390769_7350412", "FX_022_breath_landing", "d00121058"),
    504626: ("504/504626_4437257", "BODY FALL - V HVY - DIRT", "leonelmail"),
    872378: ("872/872378_19181807", "Bone Crack", "cb9382"),
    399538: ("399/399538_4519159", "Windchime soft", "Vendarro"),
    867567: ("867/867567_15636277", "Glass Wind Chimes Jangling in a Soft Breeze", "bassimat"),
    617747: ("617/617747_2282212", "Forest Birds Wind Dark Haunted Outdoor Eerie Atmo", "szegvari"),
    861757: ("861/861757_15636277", "Wind - Low Frequency, Warm and Strong", "bassimat"),
    536843: ("536/536843_2061858", "rain in the forest atmo field recording", "Garuda1982"),
    840628: ("840/840628_16682330", "Closeup Thunder Strike 01", "loganzsound"),
    151447: ("151/151447_2147090", "Long Rumbling Thunder", "billgrip"),
}


def src(sid):
    path = os.path.join(CACHE, f"{sid}.ogg")
    if not os.path.exists(path):
        url = f"https://cdn.freesound.org/previews/{SOURCES[sid][0]}-hq.ogg"
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with open(path, "wb") as f:
            f.write(urllib.request.urlopen(req, timeout=60).read())
    return path


def sox(*args):
    subprocess.run(["sox", *map(str, args)], check=True)


def oneshot(name, sid, start, length, fade_out, extra=()):
    """Recording ka chhota hissa: mono, saaf, halka fade, normalize"""
    sox(src(sid), "-c", 1, "-r", RATE, os.path.join(OUT, name + ".ogg"),
        "trim", start, length, "highpass", 50, *extra,
        "fade", "t", 0.005, length, fade_out, "norm", -1)


def layered(name, parts, length, fade_out):
    """Kai recordings ko mila kar ek sound — parts: [(sid, start, delay, volume)]"""
    tmp = []
    for i, (sid, start, delay, vol) in enumerate(parts):
        t = os.path.join(CACHE, f"_{name}_{i}.wav")
        sox(src(sid), "-c", 1, "-r", RATE, t, "trim", start, length, "pad", delay, "vol", vol)
        tmp.append(t)
    sox("-m", *tmp, os.path.join(OUT, name + ".ogg"),
        "trim", 0, length, "highpass", 40, "fade", "t", 0.005, length, fade_out, "norm", -1)


def loop(name, sid, start, length, xfade=3.0, extra=()):
    """Seamless loop: aakhri hissa shuru wale pe crossfade, taake loop ka jor sunai na de"""
    t = os.path.join(CACHE, f"_{name}.raw")
    sox(src(sid), "-c", 1, "-r", RATE, "-t", "raw", "-e", "signed", "-b", 16, t,
        "trim", start, length + xfade, "highpass", 30, *extra, "norm", -3)
    a = array.array("h")
    with open(t, "rb") as f:
        a.frombytes(f.read())
    n, x = int(length * RATE), int(xfade * RATE)
    out = a[:n]
    for i in range(x):
        k = i / x
        out[i] = int(a[n + i] * (1 - k) + a[i] * k)
    with open(t, "wb") as f:
        out.tofile(f)
    sox("-t", "raw", "-e", "signed", "-b", 16, "-c", 1, "-r", RATE, t,
        "-C", 3, os.path.join(OUT, name + ".ogg"))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(CACHE, exist_ok=True)

    # Sukhay patton pe qadam — 6 alag qadam, taake har dafa thora alag sunai de
    steps = [(683958, 0.24), (683958, 1.05), (683958, 1.78), (683958, 6.79),
             (179339, 0.37), (179339, 2.04)]
    for i, (sid, t) in enumerate(steps, 1):
        oneshot(f"step{i}", sid, t, 0.3, 0.12)

    oneshot("jump", 422972, 0, 0.5, 0.2)
    layered("land", [(172960, 0, 0, 1.0), (390769, 0, 0.02, 0.5)], 0.5, 0.2)
    layered("death", [(872378, 0, 0, 1.0), (504626, 0, 0.05, 0.9)], 1.6, 0.6)
    oneshot("checkpoint", 399538, 0.5, 4.0, 2.5)
    oneshot("win", 867567, 4.0, 8.0, 3.5)
    oneshot("thunder", 840628, 0, 12.0, 5.0)
    oneshot("thunder_far", 151447, 2.0, 16.0, 6.0, extra=("lowpass", 900))

    # Lagataar chalne wali awaazen (loops) — volume game hawa/baarish ke hisaab se badalta hai
    loop("forest", 617747, 30, 36)
    loop("wind", 861757, 6, 36)
    loop("rain", 536843, 8, 36)

    with open(os.path.join(OUT, "CREDITS.md"), "w") as f:
        f.write("# Sound credits\n\nSab recordings [Freesound.org](https://freesound.org) se, "
                "license **CC0 1.0 (public domain)**. Credit dena zaroori nahi, phir bhi shukriya:\n\n")
        for sid, (_, title, author) in SOURCES.items():
            f.write(f"- [{title}](https://freesound.org/s/{sid}/) — {author}\n")
    print("✓ sounds ready:", sorted(os.listdir(OUT)))
