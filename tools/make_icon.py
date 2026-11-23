# tools/make_icon.py
# ساخت آیکن ESMAIRO: مربع گرادیان بنفش-صورتی با حرف E (دندانه‌ی شانه + تیغه‌ی قیچی)
# استفاده:
#   python make_icon.py android <مسیر res اندروید>
#   python make_icon.py windows <مسیر app_icon.ico>
#   python make_icon.py png <مسیر خروجی png>

import os
import sys

from PIL import Image, ImageChops, ImageDraw

S = 1024
VIOLET = (124, 58, 237)
PINK = (236, 72, 153)
WHITE = (255, 255, 255, 255)


def render():
    # گرادیان قطری
    v = Image.linear_gradient("L").resize((S, S))
    h = v.transpose(Image.Transpose.ROTATE_90)
    mask = ImageChops.add(v, h, scale=2)
    bg = Image.composite(
        Image.new("RGB", (S, S), PINK),
        Image.new("RGB", (S, S), VIOLET),
        mask,
    ).convert("RGBA")

    # حرف E
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(fg)

    def rr(l, t, r, b, rad):
        d.rounded_rectangle([l * S, t * S, r * S, b * S], radius=rad * S, fill=WHITE)

    rr(0.26, 0.24, 0.36, 0.76, 0.05)   # ستون E
    rr(0.34, 0.24, 0.70, 0.33, 0.045)  # دندانه‌ی بالا
    rr(0.34, 0.67, 0.70, 0.76, 0.045)  # دندانه‌ی پایین
    d.polygon(                          # تیغه‌ی قیچی (میله‌ی وسط)
        [(0.34 * S, 0.455 * S), (0.78 * S, 0.50 * S), (0.34 * S, 0.545 * S)],
        fill=WHITE,
    )

    img = Image.alpha_composite(bg, fg)

    # گوشه‌های گرد
    corner = Image.new("L", (S, S), 0)
    ImageDraw.Draw(corner).rounded_rectangle(
        [0, 0, S - 1, S - 1], radius=int(0.22 * S), fill=255
    )
    img.putalpha(corner)
    return img


def main():
    if len(sys.argv) < 3:
        print("usage: make_icon.py <android|windows|png> <output>")
        sys.exit(1)

    mode, out = sys.argv[1], sys.argv[2]
    img = render()

    if mode == "android":
        sizes = [
            ("mipmap-mdpi", 48),
            ("mipmap-hdpi", 72),
            ("mipmap-xhdpi", 96),
            ("mipmap-xxhdpi", 144),
            ("mipmap-xxxhdpi", 192),
        ]
        for folder, px in sizes:
            d = os.path.join(out, folder)
            os.makedirs(d, exist_ok=True)
            small = img.resize((px, px), Image.Resampling.LANCZOS)
            small.save(os.path.join(out, folder, "ic_launcher.png"))
        print("android icons written to", out)
    elif mode == "windows":
        os.makedirs(os.path.dirname(out), exist_ok=True)
        img.save(
            out,
            format="ICO",
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
        )
        print("windows icon written to", out)
    else:
        img.save(out)
        print("png written to", out)


if __name__ == "__main__":
    main()
