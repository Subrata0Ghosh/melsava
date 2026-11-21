import math
import struct
import wave
import subprocess
import os
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUTPUT_DIR = "playstore_assets"
VIDEO_PATH = os.path.join(OUTPUT_DIR, "melsava_promo_video.mp4")
AUDIO_PATH = os.path.join(OUTPUT_DIR, "temp_soundtrack.wav")

WIDTH = 1920
HEIGHT = 1080
FPS = 30
DURATION_SEC = 27
TOTAL_FRAMES = FPS * DURATION_SEC

# Fonts
FONT_BOLD_PATH = r"C:\Windows\Fonts\segoeuib.ttf"
FONT_REG_PATH = r"C:\Windows\Fonts\segoeui.ttf"

def get_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

# -------------------------------------------------------------
# 1. Synthesize Ambient Uplifting Soundtrack (Python Wave)
# -------------------------------------------------------------
def generate_soundtrack(filename, duration, sample_rate=44100):
    if os.path.exists(filename) and os.path.getsize(filename) > 1000000:
        print("Soundtrack already exists, using cached audio...")
        return
    print("Generating custom melodic soundtrack...")
    num_samples = int(duration * sample_rate)
    
    # Harmonic Progression: A -> F#m -> D -> E
    chords = [
        [220.0, 277.18, 329.63, 440.0, 110.0],  # A
        [185.0, 220.0, 277.18, 370.0, 92.5],   # F#m
        [146.83, 185.0, 220.0, 293.66, 73.4],  # D
        [164.81, 207.65, 246.94, 329.63, 82.4] # E
    ]
    chord_len = 3.375
    
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        chord_idx = int((t / chord_len) % len(chords))
        freqs = chords[chord_idx]
        
        vibrato = 1.0 + 0.003 * math.sin(2 * math.pi * 5.0 * t)
        val = 0.0
        
        # Chord tones
        for idx, f in enumerate(freqs):
            vol = 0.12 if idx < 3 else (0.16 if idx == 4 else 0.08)
            t_in_chord = t % chord_len
            env = min(1.0, t_in_chord * 3.0) * min(1.0, (chord_len - t_in_chord) * 3.0)
            val += vol * env * math.sin(2 * math.pi * f * vibrato * t)
            val += (vol * 0.35) * env * math.sin(2 * math.pi * (f * 2) * t)

        # Ambient bell arpeggio every 0.375s
        arp_step = int((t / 0.375) % 4)
        arp_freq = freqs[arp_step % 3] * 2.0
        t_arp = t % 0.375
        arp_env = math.exp(-t_arp * 9.0)
        val += 0.07 * arp_env * math.sin(2 * math.pi * arp_freq * t)

        # Soft heartbeat kick every 1.5s
        t_kick = t % 1.5
        if t_kick < 0.2:
            kick_freq = 120.0 * math.exp(-t_kick * 20.0)
            kick_val = math.sin(2 * math.pi * kick_freq * t_kick) * math.exp(-t_kick * 15.0)
            val += 0.22 * kick_val

        # Master fade in & fade out
        fade = min(1.0, t / 1.5) * min(1.0, (duration - t) / 2.0)
        val *= fade

        val = max(-0.95, min(0.95, val))
        sample_int = int(val * 32767.0)
        samples.append(sample_int)
        samples.append(sample_int)

    with wave.open(filename, 'w') as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        raw_data = struct.pack(f'<{len(samples)}h', *samples)
        wf.writeframes(raw_data)
    print("Soundtrack ready.")

# -------------------------------------------------------------
# 2. Helper: Build Rounded Phone Frame with Realistic Shadow
# -------------------------------------------------------------
def create_phone_mockup(screen_path, target_h=860):
    screen = Image.open(screen_path).convert("RGBA")
    aspect = screen.width / screen.height
    target_w = int(target_h * aspect)
    screen = screen.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    bezel_pad = 12
    outer_w = target_w + bezel_pad * 2
    outer_h = target_h + bezel_pad * 2
    
    phone = Image.new("RGBA", (outer_w, outer_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(phone)
    
    radius = 34
    draw.rounded_rectangle([0, 0, outer_w - 1, outer_h - 1], radius=radius, fill=(28, 24, 38, 255), outline=(100, 85, 125, 220), width=2)
    
    screen_mask = Image.new("L", (target_w, target_h), 0)
    mask_draw = ImageDraw.Draw(screen_mask)
    mask_draw.rounded_rectangle([0, 0, target_w - 1, target_h - 1], radius=radius - 6, fill=255)
    
    phone.paste(screen, (bezel_pad, bezel_pad), screen_mask)
    
    # Camera pill
    pill_w, pill_h = 66, 16
    pill_x = (outer_w - pill_w) // 2
    pill_y = bezel_pad + 8
    draw.rounded_rectangle([pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=8, fill=(10, 8, 14, 255))
    
    # Drop shadow
    shadow_pad = 28
    shadow_img = Image.new("RGBA", (outer_w + shadow_pad * 2, outer_h + shadow_pad * 2), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_img)
    s_draw.rounded_rectangle([shadow_pad, shadow_pad, shadow_pad + outer_w, shadow_pad + outer_h], radius=radius, fill=(0, 0, 0, 140))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(16))
    
    final_mockup = Image.new("RGBA", shadow_img.size, (0, 0, 0, 0))
    final_mockup.alpha_composite(shadow_img)
    final_mockup.alpha_composite(phone, (shadow_pad, shadow_pad))
    return final_mockup

# -------------------------------------------------------------
# 3. Pre-render Background & Phone Mockups
# -------------------------------------------------------------
print("Preparing graphics and pre-rendering backgrounds...")
app_icon = Image.open(os.path.join(OUTPUT_DIR, "app_icon_512.png")).convert("RGBA")

icon_size = 220
app_icon_resized = app_icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
icon_mask = Image.new("L", (icon_size, icon_size), 0)
ImageDraw.Draw(icon_mask).rounded_rectangle([0, 0, icon_size-1, icon_size-1], radius=44, fill=255)
rounded_icon = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 0))
rounded_icon.paste(app_icon_resized, (0, 0), icon_mask)

mockup_1 = create_phone_mockup(os.path.join(OUTPUT_DIR, "screenshot_1_discover.png"))
mockup_2 = create_phone_mockup(os.path.join(OUTPUT_DIR, "screenshot_2_experience_detail.png"))
mockup_3 = create_phone_mockup(os.path.join(OUTPUT_DIR, "screenshot_3_connections.png"))
mockup_4 = create_phone_mockup(os.path.join(OUTPUT_DIR, "screenshot_4_chat.png"))
mockup_5 = create_phone_mockup(os.path.join(OUTPUT_DIR, "screenshot_5_profile_trust.png"))

# Pre-render static base background with rich bokeh/glows once!
def create_master_bg():
    bg = Image.new("RGBA", (WIDTH, HEIGHT), (18, 14, 28, 255))
    
    # Ambient glows
    glow1 = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    g1_draw = ImageDraw.Draw(glow1)
    g1_draw.ellipse([WIDTH * 0.20 - 380, HEIGHT * 0.45 - 380, WIDTH * 0.20 + 380, HEIGHT * 0.45 + 380], fill=(124, 58, 237, 50))
    glow1 = glow1.filter(ImageFilter.GaussianBlur(110))
    
    glow2 = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    g2_draw = ImageDraw.Draw(glow2)
    g2_draw.ellipse([WIDTH * 0.80 - 400, HEIGHT * 0.65 - 400, WIDTH * 0.80 + 400, HEIGHT * 0.65 + 400], fill=(236, 72, 153, 35))
    glow2 = glow2.filter(ImageFilter.GaussianBlur(120))
    
    bg.alpha_composite(glow1)
    bg.alpha_composite(glow2)
    return bg

MASTER_BG = create_master_bg()

# Fonts
font_title = get_font(FONT_BOLD_PATH, 56)
font_subtitle = get_font(FONT_BOLD_PATH, 32)
font_body = get_font(FONT_REG_PATH, 24)
font_pill = get_font(FONT_BOLD_PATH, 19)
font_brand = get_font(FONT_BOLD_PATH, 76)
font_brand_tag = get_font(FONT_REG_PATH, 30)

def draw_pill(draw, x, y, text, bg_color=(124, 58, 237, 220), text_color=(255, 255, 255, 255)):
    bbox = font_pill.getbbox(text)
    w = bbox[2] - bbox[0] + 32
    h = bbox[3] - bbox[1] + 18
    draw.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=bg_color)
    draw.text((x + 16, y + 8), text, font=font_pill, fill=text_color)
    return h

def draw_bullet(draw, x, y, headline, description, alpha=255):
    badge_r = 14
    draw.ellipse([x, y + 4, x + badge_r*2, y + 4 + badge_r*2], fill=(124, 58, 237, int(alpha * 0.85)))
    draw.line([x + 8, y + 17, x + 13, y + 22], fill=(255, 255, 255, alpha), width=3)
    draw.line([x + 13, y + 22, x + 20, y + 12], fill=(255, 255, 255, alpha), width=3)
    
    draw.text((x + 42, y), headline, font=font_subtitle, fill=(255, 255, 255, alpha))
    draw.text((x + 42, y + 44), description, font=font_body, fill=(195, 185, 215, alpha))

# -------------------------------------------------------------
# 4. Render Video Pipeline
# -------------------------------------------------------------
def render_frame(frame_idx):
    bg = MASTER_BG.copy()
    draw = ImageDraw.Draw(bg)
    
    # SCENE 1: Brand Intro (0 to 4.5s, frames 0 to 135)
    if frame_idx < 135:
        progress = min(1.0, frame_idx / 80.0)
        ease = 1.0 - math.pow(1.0 - progress, 3)
        fade_out = 1.0 if frame_idx < 115 else max(0.0, (135 - frame_idx) / 20.0)
        alpha = int(255 * fade_out)
        
        pulse = 1.0 + 0.03 * math.sin(frame_idx * 0.08)
        cur_icon_size = int(icon_size * pulse * min(1.0, 0.6 + 0.4 * ease))
        icon_frame = rounded_icon.resize((cur_icon_size, cur_icon_size), Image.Resampling.LANCZOS)
        
        ix = (WIDTH - cur_icon_size) // 2
        iy = int(HEIGHT * 0.28 - 20 * ease)
        bg.paste(icon_frame, (ix, iy), icon_frame)
        
        ring_r = cur_icon_size // 2 + 18
        draw.ellipse([WIDTH//2 - ring_r, iy + cur_icon_size//2 - ring_r, WIDTH//2 + ring_r, iy + cur_icon_size//2 + ring_r], outline=(167, 139, 250, int(alpha * 0.6)), width=3)
        
        brand_text = "MELSAVA"
        bbox = font_brand.getbbox(brand_text)
        bw = bbox[2] - bbox[0]
        draw.text(((WIDTH - bw) // 2, iy + cur_icon_size + 36), brand_text, font=font_brand, fill=(255, 255, 255, alpha))
        
        pill_text = "18+ ACTIVITY-FIRST SOCIAL DISCOVERY"
        p_bbox = font_pill.getbbox(pill_text)
        pw = p_bbox[2] - p_bbox[0] + 36
        px = (WIDTH - pw) // 2
        py = iy + cur_icon_size + 140
        draw.rounded_rectangle([px, py, px + pw, py + 38], radius=19, fill=(124, 58, 237, int(alpha * 0.9)))
        draw.text((px + 18, py + 8), pill_text, font=font_pill, fill=(255, 255, 255, alpha))
        
        tag_text = "Meet people through experiences, not endless swiping."
        t_bbox = font_brand_tag.getbbox(tag_text)
        tw = t_bbox[2] - t_bbox[0]
        draw.text(((WIDTH - tw) // 2, py + 64), tag_text, font=font_brand_tag, fill=(210, 200, 230, int(alpha * 0.85)))

    # SCENE 2: Discover Experiences (4.5 to 9.5s, frames 135 to 285)
    elif frame_idx < 285:
        local_idx = frame_idx - 135
        progress = min(1.0, local_idx / 25.0)
        ease = 1.0 - math.pow(1.0 - progress, 3)
        fade_out = 1.0 if frame_idx < 265 else max(0.0, (285 - frame_idx) / 20.0)
        alpha = int(255 * fade_out)
        
        px = int(140 + 30 * ease)
        py = int(140 - 40 * ease + 6 * math.sin(local_idx * 0.05))
        bg.paste(mockup_1, (px, py), mockup_1)
        
        tx = 740
        draw_pill(draw, tx, 170, "CURATED ACTIVITIES", (124, 58, 237, alpha), (255, 255, 255, alpha))
        draw.text((tx, 230), "Real-World Social Circles", font=font_title, fill=(255, 255, 255, alpha))
        
        draw_bullet(draw, tx, 330, "3–5 Member Micro-Groups", "Intimate, welcoming meetups that feel natural and relaxed.", alpha)
        draw_bullet(draw, tx, 460, "Vetted Public Venues", "Artisan cafes, scenic trails, bookshops, and cultural spaces.", alpha)
        draw_bullet(draw, tx, 590, "Local Radar & Map Discovery", "Find verified experiences happening right around you.", alpha)

    # SCENE 3: Event Detail & Icebreakers (9.5 to 14.5s, frames 285 to 435)
    elif frame_idx < 435:
        local_idx = frame_idx - 285
        progress = min(1.0, local_idx / 25.0)
        ease = 1.0 - math.pow(1.0 - progress, 3)
        fade_out = 1.0 if frame_idx < 415 else max(0.0, (435 - frame_idx) / 20.0)
        alpha = int(255 * fade_out)
        
        px = int(140 + 30 * ease)
        py = int(140 - 40 * ease + 6 * math.sin(local_idx * 0.05))
        bg.paste(mockup_2, (px, py), mockup_2)
        
        tx = 740
        draw_pill(draw, tx, 170, "NO AWKWARD MOMENTS", (236, 72, 153, alpha), (255, 255, 255, alpha))
        draw.text((tx, 230), "Effortless Connections", font=font_title, fill=(255, 255, 255, alpha))
        
        draw_bullet(draw, tx, 330, "Guided Icebreakers", "Thoughtful conversation prompts built into every meetup.", alpha)
        draw_bullet(draw, tx, 460, "Transparent Itinerary", "Clear event schedules, group expectations, and venue details.", alpha)
        draw_bullet(draw, tx, 590, "Shared Passion Filters", "Coffee lovers, weekend hikers, book clubbers & creative souls.", alpha)

    # SCENE 4: Mutual Reconnect & Messaging (14.5 to 19.5s, frames 435 to 585)
    elif frame_idx < 585:
        local_idx = frame_idx - 435
        progress = min(1.0, local_idx / 25.0)
        ease = 1.0 - math.pow(1.0 - progress, 3)
        fade_out = 1.0 if frame_idx < 565 else max(0.0, (585 - frame_idx) / 20.0)
        alpha = int(255 * fade_out)
        
        p1_x = int(80 + 30 * ease)
        p1_y = int(120 + 6 * math.sin(local_idx * 0.05))
        bg.paste(mockup_3, (p1_x, p1_y), mockup_3)
        
        p2_x = p1_x + 280
        p2_y = p1_y + 50
        bg.paste(mockup_4, (p2_x, p2_y), mockup_4)
        
        tx = 980
        draw_pill(draw, tx, 170, "ZERO-PRESSURE RECONNECT", (16, 185, 129, alpha), (255, 255, 255, alpha))
        draw.text((tx, 230), "Private Mutual Reconnect", font=font_title, fill=(255, 255, 255, alpha))
        
        draw_bullet(draw, tx, 330, "100% Confidential Choices", "Privately select who you liked. No one knows unless mutual.", alpha)
        draw_bullet(draw, tx, 460, "Instant 1-on-1 Chat", "Unlock direct messaging with your mutual connection.", alpha)
        draw_bullet(draw, tx, 590, "Private & Secure", "Encrypted transit, strict privacy, and zero unwanted DMs.", alpha)

    # SCENE 5: Community Trust & Safety (19.5 to 23.5s, frames 585 to 705)
    elif frame_idx < 705:
        local_idx = frame_idx - 585
        progress = min(1.0, local_idx / 25.0)
        ease = 1.0 - math.pow(1.0 - progress, 3)
        fade_out = 1.0 if frame_idx < 685 else max(0.0, (705 - frame_idx) / 20.0)
        alpha = int(255 * fade_out)
        
        px = int(140 + 30 * ease)
        py = int(140 - 40 * ease + 6 * math.sin(local_idx * 0.05))
        bg.paste(mockup_5, (px, py), mockup_5)
        
        tx = 740
        draw_pill(draw, tx, 170, "VERIFIED COMMUNITY", (245, 158, 11, alpha), (255, 255, 255, alpha))
        draw.text((tx, 230), "Built on Genuine Trust", font=font_title, fill=(255, 255, 255, alpha))
        
        draw_bullet(draw, tx, 330, "Community Trust Score", "Accountability system rewarding respectful behavior and punctuality.", alpha)
        draw_bullet(draw, tx, 460, "Anti-Ghosting Protection", "Attendance verification protects your time and plans.", alpha)
        draw_bullet(draw, tx, 590, "Instant Block & Report", "Robust safety moderation keeping our circle secure and kind.", alpha)

    # SCENE 6: Grand Finale / Outro (23.5 to 27.0s, frames 705 to 810)
    else:
        local_idx = frame_idx - 705
        progress = min(1.0, local_idx / 25.0)
        ease = 1.0 - math.pow(1.0 - progress, 3)
        fade_out = 1.0 if frame_idx < 780 else max(0.0, (810 - frame_idx) / 30.0)
        alpha = int(255 * fade_out)
        
        center_x = WIDTH // 2
        center_y = int(HEIGHT * 0.35)
        
        pulse = 1.0 + 0.04 * math.sin(local_idx * 0.1)
        cur_size = int(240 * pulse)
        icon_frame = rounded_icon.resize((cur_size, cur_size), Image.Resampling.LANCZOS)
        
        ix = center_x - cur_size // 2
        iy = center_y - cur_size // 2
        bg.paste(icon_frame, (ix, iy), icon_frame)
        
        draw.ellipse([center_x - 150, center_y - 150, center_x + 150, center_y + 150], outline=(167, 139, 250, int(alpha * 0.7)), width=3)
        draw.ellipse([center_x - 170, center_y - 170, center_x + 170, center_y + 170], outline=(124, 58, 237, int(alpha * 0.4)), width=2)
        
        brand_text = "MELSAVA"
        bbox = font_brand.getbbox(brand_text)
        bw = bbox[2] - bbox[0]
        draw.text(((WIDTH - bw) // 2, center_y + 150), brand_text, font=font_brand, fill=(255, 255, 255, alpha))
        
        cta_text = "Available Now on Google Play"
        c_bbox = font_subtitle.getbbox(cta_text)
        cw = c_bbox[2] - c_bbox[0] + 56
        ch = c_bbox[3] - c_bbox[1] + 28
        cx = (WIDTH - cw) // 2
        cy = center_y + 260
        draw.rounded_rectangle([cx, cy, cx + cw, cy + ch], radius=ch // 2, fill=(124, 58, 237, alpha))
        draw.text((cx + 28, cy + 12), cta_text, font=font_subtitle, fill=(255, 255, 255, alpha))
        
        dev_text = "Developed with ❤️ by TechnOrchid"
        d_bbox = font_body.getbbox(dev_text)
        dw = d_bbox[2] - d_bbox[0]
        draw.text(((WIDTH - dw) // 2, cy + 90), dev_text, font=font_body, fill=(180, 170, 205, int(alpha * 0.8)))

    return bg.convert("RGB")

# -------------------------------------------------------------
# 5. Main Execution: Pipe Frames Directly to FFmpeg
# -------------------------------------------------------------
def main():
    generate_soundtrack(AUDIO_PATH, DURATION_SEC)
    
    ffmpeg_cmd = [
        "ffmpeg",
        "-y",
        "-loglevel", "error",
        "-nostats",
        "-f", "rawvideo",
        "-vcodec", "rawvideo",
        "-s", f"{WIDTH}x{HEIGHT}",
        "-pix_fmt", "rgb24",
        "-r", str(FPS),
        "-i", "-",  # Pipe input
        "-i", AUDIO_PATH,
        "-c:v", "libx264",
        "-preset", "veryfast",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-movflags", "+faststart",
        VIDEO_PATH
    ]
    
    print(f"Starting optimized video encoding pipeline ({TOTAL_FRAMES} frames @ 30fps)...", flush=True)
    process = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE, stderr=subprocess.DEVNULL)
    
    for i in range(TOTAL_FRAMES):
        if i % 150 == 0:
            print(f"Rendering frame {i}/{TOTAL_FRAMES} ({(i/TOTAL_FRAMES)*100:.1f}%)...", flush=True)
        frame_img = render_frame(i)
        process.stdin.write(frame_img.tobytes())
        
    process.stdin.close()
    process.wait()
    
    if os.path.exists(AUDIO_PATH):
        try:
            os.remove(AUDIO_PATH)
        except:
            pass
            
    if process.returncode == 0:
        file_size = os.path.getsize(VIDEO_PATH) / (1024 * 1024)
        print(f"SUCCESS: Video exported to {VIDEO_PATH} ({file_size:.2f} MB)", flush=True)
    else:
        print(f"FFmpeg exited with code {process.returncode}", flush=True)

if __name__ == "__main__":
    main()
