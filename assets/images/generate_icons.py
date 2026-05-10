from PIL import Image
import os

source = r"C:\Users\FritsBoers\Documents\grakpossedartapp\gouderakpossedartapp\assets\images\logo.png"
out_dir = r"C:\Users\FritsBoers\Documents\grakpossedartapp\gouderakpossedartapp\assets\icons"
os.makedirs(out_dir, exist_ok=True)

img = Image.open(source).convert("RGBA")

# Standard web icon sizes
icons = {
    "favicon-16x16.png": 16,
    "favicon-32x32.png": 32,
    "favicon-48x48.png": 48,
    "apple-touch-icon.png": 180,       # Apple standard
    "android-chrome-192x192.png": 192,  # PWA manifest
    "android-chrome-512x512.png": 512,  # PWA manifest
    "mstile-150x150.png": 150,          # Windows tiles
    "icon-72x72.png": 72,
    "icon-96x96.png": 96,
    "icon-128x128.png": 128,
    "icon-144x144.png": 144,
    "icon-152x152.png": 152,
    "icon-384x384.png": 384,
}

for filename, size in icons.items():
    resized = img.resize((size, size), Image.LANCZOS)
    path = os.path.join(out_dir, filename)
    resized.save(path, "PNG")
    print(f"  {filename} ({size}x{size})")

# Generate favicon.ico (multi-size: 16, 32, 48)
ico_sizes = [16, 32, 48]
ico_images = [img.resize((s, s), Image.LANCZOS) for s in ico_sizes]
ico_path = os.path.join(out_dir, "favicon.ico")
ico_images[0].save(ico_path, format="ICO", sizes=[(s, s) for s in ico_sizes], append_images=ico_images[1:])
print(f"  favicon.ico (16+32+48)")

print(f"\nAll icons saved to: {out_dir}")
