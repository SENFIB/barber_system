# tools/make_icon.py
# آیکن برنامه را از لوگوی خودت (barber_app/assets/logo.png) می‌سازد.
# استفاده:
#   python make_icon.py android <مسیر res اندروید>
#   python make_icon.py windows <مسیر app_icon.ico>
#   python make_icon.py png <مسیر خروجی png>
import os
import sys
from PIL import Image

S = 1024
HERE = os.path.dirname(os.path.abspath(__file__))
LOGO = os.path.join(HERE, "..", "barber_app", "assets", "logo.png")


def render():
    if not os.path.isfile(LOGO):
        print("فایل لوگو پیدا نشد:", os.path.normpath(LOGO))
        print("لوگو باید با اسم دقیق logo.png داخل barber_app/assets باشد.")
        sys.exit(1)
    img = Image.open(LOGO).convert("RGBA")
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    img = img.crop((left, top, left + side, top + side))
    return img.resize((S, S), Image.Resampling.LANCZOS)


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
            small.save(os.path.join(d, "ic_launcher.png"))
        print("android icons written to", out)
    elif mode == "windows":
        folder = os.path.dirname(out)
        if folder:
            os.makedirs(folder, exist_ok=True)
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
