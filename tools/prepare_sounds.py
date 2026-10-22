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
    # Peechha
    575447: ("575/575447_2282212", "Tribal Jungle Drum beat", "szegvari"),
    # Shikaariyon ki awaazen (Apocalypto jaisi): jhund ki "hi-yi-yi", hook, yip, munh pe haath ki "wa-wa-wa"
    479551: ("479/479551_2524442", "R15-69-Native Americans and Horses", "craigsmith"),
    401693: ("401/401693_5437016", "Guys Howling Fun", "valdrag"),
    190548: ("190/190548_3512972", "Central American Indian Salute", "danielsilveira321"),
    219860: ("219/219860_4071086", "crazy indian scream", "polmdx"),
    # Kai log daurte hue (qadmon ka loop)
    480677: ("480/480677_2524442", "R27-46-Many Run By on Dirty Floor", "craigsmith"),
    635052: ("635/635052_5756735", "Panicked Running Footsteps on Grass", "sillygrizzlies"),
    716949: ("716/716949_8698658", "Running on dry leaves", "AudioPapkin"),
    850166: ("850/850166_3552348", "swoosh_bamboo_03", "Evan_McLoud"),
    850164: ("850/850164_3552348", "swoosh_bamboo_01", "Evan_McLoud"),
    205938: ("205/205938_3842302", "Arrow Impact", "Twisted_Euphoria"),
    456037: ("456/456037_6253486", "heavy breathing while running", "florianreichelt"),
    # Maut ki awaazen (har maut ki apni)
    547521: ("547/547521_11785387", "Splash", "colorsCrimsonTears"),
    529383: ("529/529383_5072671", "Bubbles In Water", "calebrankin"),
    813306: ("813/813306_71257", "Wilhelm Scream Alternative 4", "qubodup"),
    610998: ("610/610998_1038806", "Medium Male Pain Grunts", "unfa"),
    244926: ("244/244926_3983630", "fire-whoosh", "hnhnh"),
    583595: ("583/583595_4679127", "Male Screams", "Jerome_Walter_Bigoli_Bang"),
    278203: ("278/278203_1499685", "Bear Trap", "ThePriest909"),
    164472: ("164/164472_2104797", "Crack of branch 3", "deleted_user_2104797"),
    276600: ("276/276600_464940", "body_hit", "insanity54"),
    264062: ("264/264062_2971294", "Melee Weapon hit with male moan & body fall", "Paul368"),
    399617: ("399/399617_7386498", "Knife/sword stab #2", "SoundsForHim"),
    # Panah: patton mein se gaddhay mein girna
    560261: ("560/560261_12560866", "Bush Rustle", "RoyalRose"),
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


def loop(name, sid, start, length, xfade=3.0, extra=(), source=None):
    """Seamless loop: aakhri hissa shuru wale pe crossfade, taake loop ka jor sunai na de"""
    t = os.path.join(CACHE, f"_{name}.raw")
    sox(source or src(sid), "-c", 1, "-r", RATE, "-t", "raw", "-e", "signed", "-b", 16, t,
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

    # Peechha: jang ki cheekh, beech beech ki cheekhein, neze, dhol, aur hero ki tez saans
    # Jang ki cheekh: jhund ki "hi-yi-yi" (neeche ki ghoron ki dhamak highpass se hata di)
    oneshot("warcry", 479551, 1.0, 5.0, 1.2, extra=("highpass", 230))
    # Beech beech ki awaazen: hook, yip, munh pe haath ki "wa-wa-wa", kaanpti cheekh
    shouts = [(401693, 0.25, 1.4), (401693, 2.55, 0.65), (190548, 0.28, 1.4),
              (401693, 10.05, 0.8), (219860, 0.45, 1.9), (401693, 11.5, 1.2)]
    for i, (sid, t, length) in enumerate(shouts, 1):
        oneshot(f"shout{i}", sid, t, length, 0.25)
    # Daurte shikaari: kai logon ke qadmon ki chaadar + oopar patton pe do alag daurte qadam
    run = os.path.join(CACHE, "_hunters_run_mix.wav")
    parts = []
    for i, (sid, start, delay, vol, hp) in enumerate([(480677, 4.0, 0, 1.0, 60),
                                                      (635052, 2.5, 0.13, 0.55, 90),
                                                      (716949, 0.5, 0.31, 0.45, 90)]):
        t = os.path.join(CACHE, f"_hunters_run_{i}.wav")
        sox(src(sid), "-c", 1, "-r", RATE, t, "trim", start, 26, "highpass", hp, "norm", -3,
            "vol", vol, "pad", delay)
        parts.append(t)
    sox("-m", *parts, run, "trim", 0, 25.5)
    loop("hunters_run", None, 0, 22, source=run)
    oneshot("spear_throw1", 850166, 0, 0.41, 0.15)
    oneshot("spear_throw2", 850164, 0, 0.6, 0.2)
    oneshot("spear_stick", 205938, 0, 0.6, 0.25)
    loop("drums", 575447, 6, 36)
    loop("breath", 456037, 2, 36)

    # Maut: har qism ki apni awaaz
    oneshot("splash", 547521, 0, 2.8, 1.2)
    oneshot("bubbles", 529383, 2.4, 1.3, 0.5)
    oneshot("scream_fall", 813306, 0, 1.5, 0.6)
    for i, t in enumerate([12.7, 16.1, 19.1, 21.7], 1):
        oneshot(f"grunt{i}", 610998, t, 0.6, 0.2)
    oneshot("fire_whoosh", 244926, 0, 2.5, 1.0)
    oneshot("scream_burn", 583595, 19.4, 1.1, 0.4)
    oneshot("trap_snap", 278203, 0, 0.5, 0.15)
    oneshot("branch_crack", 164472, 0, 0.63, 0.2)
    oneshot("body_hit", 276600, 0, 0.84, 0.25)
    oneshot("hit_moan", 264062, 0, 1.6, 0.5)
    for i, t in enumerate([0.4, 5.5, 13.7], 1):
        oneshot(f"stab{i}", 399617, t, 0.5, 0.15)

    # Panah
    oneshot("rustle", 560261, 0.6, 1.1, 0.4)

    with open(os.path.join(OUT, "CREDITS.md"), "w") as f:
        f.write("# Sound credits\n\nSab recordings [Freesound.org](https://freesound.org) se, "
                "license **CC0 1.0 (public domain)**. Credit dena zaroori nahi, phir bhi shukriya:\n\n")
        for sid, (_, title, author) in SOURCES.items():
            f.write(f"- [{title}](https://freesound.org/s/{sid}/) — {author}\n")
    print("✓ sounds ready:", sorted(os.listdir(OUT)))
