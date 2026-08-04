import os
from PIL import Image

def compress_images(folder_path, max_dimension=800, quality=80):
    for filename in os.listdir(folder_path):
        if filename.endswith(".png"):
            filepath = os.path.join(folder_path, filename)
            try:
                with Image.open(filepath) as img:
                    # Convert to RGB if necessary (WebP supports RGBA, so we can keep transparency)
                    # WebP format is supported by Pillow out of the box
                    width, height = img.size
                    
                    if width > max_dimension or height > max_dimension:
                        # Calculate new dimensions preserving aspect ratio
                        if width > height:
                            new_width = max_dimension
                            new_height = int(max_dimension * height / width)
                        else:
                            new_height = max_dimension
                            new_width = int(max_dimension * width / height)
                        
                        img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                        print(f"Resized {filename} to {new_width}x{new_height}")

                    new_filename = filename.rsplit('.', 1)[0] + '.webp'
                    new_filepath = os.path.join(folder_path, new_filename)
                    
                    # Save as WebP
                    img.save(new_filepath, 'webp', quality=quality)
                    print(f"Saved {new_filename}")
                    
                # Remove original PNG
                os.remove(filepath)
                print(f"Deleted original {filename}")
            except Exception as e:
                print(f"Error processing {filename}: {e}")

if __name__ == "__main__":
    assets_dir = os.path.join(os.path.dirname(__file__), "assets", "images")
    compress_images(assets_dir)
