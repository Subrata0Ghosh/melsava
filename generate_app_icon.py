import os
from PIL import Image, ImageDraw

def create_melsava_elements(size=1024):
    scale = 4
    canvas_size = size * scale

    # 1. Full Icon
    img = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 2. Foreground only (transparent background, sized for adaptive icon safe-zone ~66%)
    fg_img = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    fg_draw = ImageDraw.Draw(fg_img)

    # Colors
    bg_color = (41, 35, 50, 255)       # Deep Plum #292332
    ribbon_left = (121, 91, 145, 255)  # Mauve #795B91
    ribbon_right = (168, 132, 196, 255)# Light Mauve
    ribbon_center = (233, 161, 139, 255) # Soft Coral #E9A18B
    nexus_color = (233, 161, 139, 255) # Soft Coral
    white = (255, 255, 255, 255)

    # Rounded squircle background for full icon
    radius = int(canvas_size * 0.22)
    draw.rounded_rectangle([0, 0, canvas_size - 1, canvas_size - 1], radius=radius, fill=bg_color)
    border_color = (121, 91, 145, 60)
    draw.rounded_rectangle([scale * 8, scale * 8, canvas_size - 1 - scale * 8, canvas_size - 1 - scale * 8], radius=radius - scale * 6, outline=border_color, width=scale * 4)

    stroke_w = int(canvas_size * 0.082)

    def bezier_point(p0, p1, p2, p3, t):
        x = (1-t)**3 * p0[0] + 3*(1-t)**2 * t * p1[0] + 3*(1-t) * t**2 * p2[0] + t**3 * p3[0]
        y = (1-t)**3 * p0[1] + 3*(1-t)**2 * t * p1[1] + 3*(1-t) * t**2 * p2[1] + t**3 * p3[1]
        return (x, y)

    w = canvas_size
    h = canvas_size

    p0_l = (w * 0.24, h * 0.74)
    p1_l = (w * 0.20, h * 0.32)
    p2_l = (w * 0.38, h * 0.22)
    p3_l = (w * 0.50, h * 0.52)

    p0_r = (w * 0.76, h * 0.74)
    p1_r = (w * 0.80, h * 0.32)
    p2_r = (w * 0.62, h * 0.22)
    p3_r = (w * 0.50, h * 0.52)

    p0_c = (w * 0.50, h * 0.52)
    p1_c = (w * 0.50, h * 0.68)
    p2_c = (w * 0.50, h * 0.76)
    p3_c = (w * 0.50, h * 0.82)

    def draw_curve(d, p0, p1, p2, p3, color, width):
        steps = 200
        points = [bezier_point(p0, p1, p2, p3, i / float(steps)) for i in range(steps + 1)]
        for i in range(len(points) - 1):
            pt1 = points[i]
            pt2 = points[i+1]
            d.line([pt1, pt2], fill=color, width=width)
            d.ellipse([pt1[0] - width/2, pt1[1] - width/2, pt1[0] + width/2, pt1[1] + width/2], fill=color)
        last = points[-1]
        d.ellipse([last[0] - width/2, last[1] - width/2, last[0] + width/2, last[1] + width/2], fill=color)

    # Draw on both full icon and foreground
    for d in [draw, fg_draw]:
        draw_curve(d, p0_l, p1_l, p2_l, p3_l, ribbon_left, stroke_w)
        draw_curve(d, p0_r, p1_r, p2_r, p3_r, ribbon_right, stroke_w)
        draw_curve(d, p0_c, p1_c, p2_c, p3_c, ribbon_center, int(stroke_w * 0.9))

        node_r = stroke_w * 0.85
        d.ellipse([w * 0.50 - node_r, h * 0.52 - node_r, w * 0.50 + node_r, h * 0.52 + node_r], fill=nexus_color)

        glint_r = node_r * 0.35
        d.ellipse([w * 0.50 - glint_r, h * 0.50 - glint_r, w * 0.50 + glint_r, h * 0.50 + glint_r], fill=white)

    full_icon = img.resize((size, size), Image.Resampling.LANCZOS)
    foreground = fg_img.resize((size, size), Image.Resampling.LANCZOS)
    return full_icon, foreground

base_dir = r"c:\Users\sulat\Desktop\projects\flutter_workspace\dating_app"
res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")

full_master, fg_master = create_melsava_elements(1024)

# Android mipmap sizes
sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, s in sizes.items():
    # Full icon (legacy fallback)
    target_path = os.path.join(res_dir, folder, "ic_launcher.png")
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    full_master.resize((s, s), Image.Resampling.LANCZOS).save(target_path, "PNG")

    # Foreground for adaptive icon
    fg_path = os.path.join(res_dir, folder, "ic_launcher_foreground.png")
    fg_master.resize((s, s), Image.Resampling.LANCZOS).save(fg_path, "PNG")

# Adaptive XML for API 26+
anydpi_dir = os.path.join(res_dir, "mipmap-anydpi-v26")
os.makedirs(anydpi_dir, exist_ok=True)

xml_content = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:color="#292332"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""

with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
    f.write(xml_content)

# Values colors.xml to define #292332
values_dir = os.path.join(res_dir, "values")
colors_xml_path = os.path.join(values_dir, "colors.xml")
colors_xml = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#292332</color>
</resources>
"""
with open(colors_xml_path, "w", encoding="utf-8") as f:
    f.write(colors_xml)

print("MELSAVA adaptive icons and legacy icons generated!")
