from PIL import Image, ImageDraw
import numpy as np

# Load the image
img = Image.open(r"C:\Users\FritsBoers\Documents\grakpossedartapp\gouderakpossedartapp\assets\images\logo.jpg")
img = img.convert("RGBA")
width, height = img.size
pixels = np.array(img)

# Step 1: Flood-fill from corners to find all connected white/near-white pixels
# This removes the white corners AND the thin white border fringe
white_threshold = 230  # pixels with R,G,B all above this are considered "white"

visited = np.zeros((height, width), dtype=bool)
to_make_transparent = np.zeros((height, width), dtype=bool)

# BFS flood fill from corner seed points
from collections import deque

def flood_fill_white(start_points):
    queue = deque(start_points)
    for (sy, sx) in start_points:
        if 0 <= sy < height and 0 <= sx < width:
            visited[sy, sx] = True
    
    while queue:
        y, x = queue.popleft()
        r, g, b = pixels[y, x, 0], pixels[y, x, 1], pixels[y, x, 2]
        if r >= white_threshold and g >= white_threshold and b >= white_threshold:
            to_make_transparent[y, x] = True
            for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
                ny, nx = y + dy, x + dx
                if 0 <= ny < height and 0 <= nx < width and not visited[ny, nx]:
                    visited[ny, nx] = True
                    queue.append((ny, nx))

# Seed from all edges (multiple points along each edge to catch all connected white)
seeds = []
for x in range(width):
    seeds.append((0, x))
    seeds.append((height - 1, x))
for y in range(height):
    seeds.append((y, 0))
    seeds.append((y, width - 1))

flood_fill_white(seeds)

# Apply transparency to all flood-filled white pixels
pixels[to_make_transparent, 3] = 0

# Also soften the edge: make semi-white pixels near transparent areas semi-transparent
# This handles anti-aliased fringe
from scipy.ndimage import binary_dilation
edge_zone = binary_dilation(to_make_transparent, iterations=2) & ~to_make_transparent
semi_white = 200
for y, x in zip(*np.where(edge_zone)):
    r, g, b = pixels[y, x, 0], pixels[y, x, 1], pixels[y, x, 2]
    if r >= semi_white and g >= semi_white and b >= semi_white:
        # Scale alpha based on how white the pixel is (whiter = more transparent)
        whiteness = min(r, g, b)
        alpha = int(255 * (1 - (whiteness - semi_white) / (255 - semi_white)))
        pixels[y, x, 3] = alpha

result = Image.fromarray(pixels)

# Save as PNG (supports transparency)
output_path = r"C:\Users\FritsBoers\Documents\grakpossedartapp\gouderakpossedartapp\assets\images\logo.png"
result.save(output_path, "PNG")
print(f"Saved transparent logo to: {output_path}")
print(f"Size: {width}x{height}")
