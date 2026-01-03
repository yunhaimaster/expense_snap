#!/usr/bin/env python3
"""
生成 App Icon 同 Splash Logo
設計：簡約風格 - 收據 + 相機快門圈
"""

from PIL import Image, ImageDraw
import os

# 顏色定義
PRIMARY_BLUE = (33, 150, 243)  # #2196F3
WHITE = (255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

def draw_receipt(draw, x, y, width, height, color, torn_edge=True):
    """畫一張收據"""
    # 主體矩形
    draw.rectangle([x, y + 20, x + width, y + height], fill=color)

    # 撕邊效果（鋸齒狀頂部）
    if torn_edge:
        tooth_width = width // 8
        for i in range(8):
            tx = x + i * tooth_width
            points = [
                (tx, y + 20),
                (tx + tooth_width // 2, y),
                (tx + tooth_width, y + 20)
            ]
            draw.polygon(points, fill=color)

    # 收據上嘅橫線（代表文字）
    line_y = y + 60
    line_spacing = 35
    for i in range(4):
        line_width = width * (0.8 if i < 3 else 0.5)
        line_x = x + (width - line_width) // 2
        draw.rectangle(
            [line_x, line_y + i * line_spacing,
             line_x + line_width, line_y + i * line_spacing + 12],
            fill=PRIMARY_BLUE if color == WHITE else WHITE
        )

def draw_camera_shutter(draw, cx, cy, radius, color):
    """畫相機快門圈"""
    # 外圈
    draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        outline=color, width=max(6, radius // 8)
    )
    # 內圈
    inner_r = radius * 0.6
    draw.ellipse(
        [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
        outline=color, width=max(4, radius // 12)
    )
    # 中心點
    center_r = radius * 0.2
    draw.ellipse(
        [cx - center_r, cy - center_r, cx + center_r, cy + center_r],
        fill=color
    )

def generate_main_icon(size=1024):
    """生成主 App Icon (1024x1024)"""
    img = Image.new('RGBA', (size, size), PRIMARY_BLUE + (255,))
    draw = ImageDraw.Draw(img)

    # 圓角背景（通過 mask 實現）
    # Flutter launcher icons 會自動處理圓角

    # 收據位置同大小
    receipt_width = int(size * 0.5)
    receipt_height = int(size * 0.6)
    receipt_x = int((size - receipt_width) // 2 - size * 0.05)
    receipt_y = int((size - receipt_height) // 2 - size * 0.05)

    draw_receipt(draw, receipt_x, receipt_y, receipt_width, receipt_height, WHITE)

    # 相機快門圈 - 右下角
    shutter_radius = int(size * 0.12)
    shutter_x = receipt_x + receipt_width - shutter_radius // 2
    shutter_y = receipt_y + receipt_height - shutter_radius // 2
    draw_camera_shutter(draw, shutter_x, shutter_y, shutter_radius, WHITE)

    return img

def generate_adaptive_foreground(size=1024):
    """生成 Adaptive Icon 前景（透明背景，白色圖案）"""
    img = Image.new('RGBA', (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    # Adaptive icon 需要留邊（安全區域約 66%）
    safe_size = int(size * 0.66)
    offset = (size - safe_size) // 2

    # 收據
    receipt_width = int(safe_size * 0.55)
    receipt_height = int(safe_size * 0.65)
    receipt_x = offset + int((safe_size - receipt_width) // 2 - safe_size * 0.08)
    receipt_y = offset + int((safe_size - receipt_height) // 2 - safe_size * 0.05)

    draw_receipt(draw, receipt_x, receipt_y, receipt_width, receipt_height, WHITE)

    # 相機快門圈
    shutter_radius = int(safe_size * 0.13)
    shutter_x = receipt_x + receipt_width - shutter_radius // 3
    shutter_y = receipt_y + receipt_height - shutter_radius // 3
    draw_camera_shutter(draw, shutter_x, shutter_y, shutter_radius, WHITE)

    return img

def generate_adaptive_background(size=1024):
    """生成 Adaptive Icon 背景（純藍色）"""
    return Image.new('RGBA', (size, size), PRIMARY_BLUE + (255,))

def generate_splash_logo(size=512):
    """生成 Splash Screen Logo（白色，透明背景）"""
    img = Image.new('RGBA', (size, size), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    # 收據
    receipt_width = int(size * 0.55)
    receipt_height = int(size * 0.65)
    receipt_x = int((size - receipt_width) // 2 - size * 0.08)
    receipt_y = int((size - receipt_height) // 2 - size * 0.08)

    draw_receipt(draw, receipt_x, receipt_y, receipt_width, receipt_height, WHITE)

    # 相機快門圈
    shutter_radius = int(size * 0.13)
    shutter_x = receipt_x + receipt_width - shutter_radius // 3
    shutter_y = receipt_y + receipt_height - shutter_radius // 3
    draw_camera_shutter(draw, shutter_x, shutter_y, shutter_radius, WHITE)

    return img

def generate_feature_graphic(width=1024, height=500):
    """生成 Play Store Feature Graphic (1024x500)"""
    # 漸變背景
    img = Image.new('RGBA', (width, height), PRIMARY_BLUE + (255,))
    draw = ImageDraw.Draw(img)

    # 簡單漸變效果
    for y in range(height):
        alpha = int(255 - (y / height) * 50)
        color = (33, 150, 243, alpha)
        draw.line([(0, y), (width, y)], fill=color[:3])

    # 左邊：大 icon
    icon_size = int(height * 0.6)
    icon = generate_splash_logo(icon_size)
    icon_x = int(width * 0.1)
    icon_y = (height - icon_size) // 2
    img.paste(icon, (icon_x, icon_y), icon)

    # 右邊：手機框架 placeholder（簡化版）
    phone_width = int(width * 0.25)
    phone_height = int(height * 0.8)
    phone_x = int(width * 0.65)
    phone_y = (height - phone_height) // 2

    # 手機外框
    draw.rounded_rectangle(
        [phone_x, phone_y, phone_x + phone_width, phone_y + phone_height],
        radius=20, outline=WHITE, width=4
    )
    # 手機螢幕
    screen_margin = 8
    draw.rounded_rectangle(
        [phone_x + screen_margin, phone_y + screen_margin + 20,
         phone_x + phone_width - screen_margin, phone_y + phone_height - screen_margin - 20],
        radius=10, fill=(245, 245, 245)
    )

    return img

def main():
    # 確保輸出目錄存在
    output_dir = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon')
    os.makedirs(output_dir, exist_ok=True)

    print("生成 App Icon...")

    # 1. 主 icon (1024x1024)
    icon = generate_main_icon(1024)
    icon.save(os.path.join(output_dir, 'icon.png'))
    print("  ✓ icon.png (1024x1024)")

    # 2. Adaptive foreground
    foreground = generate_adaptive_foreground(1024)
    foreground.save(os.path.join(output_dir, 'icon_foreground.png'))
    print("  ✓ icon_foreground.png")

    # 3. Adaptive background
    background = generate_adaptive_background(1024)
    background.save(os.path.join(output_dir, 'icon_background.png'))
    print("  ✓ icon_background.png")

    # 4. Splash logo
    splash = generate_splash_logo(512)
    splash.save(os.path.join(output_dir, 'splash_logo.png'))
    print("  ✓ splash_logo.png (512x512)")

    # 5. Feature graphic for Play Store
    feature = generate_feature_graphic(1024, 500)
    feature.save(os.path.join(output_dir, 'feature_graphic.png'))
    print("  ✓ feature_graphic.png (1024x500)")

    print("\n全部圖檔生成完成！")

if __name__ == '__main__':
    main()
