from PIL import Image
import numpy as np

def read_image_pixels(file_path):
    with open(file_path, 'r') as file:
        return [int(line.strip()) for line in file]

def create_images(pixels, width, height, num_images):
    for i in range(num_images):
        
        start_index = i * width * height
        end_index = (i + 1) * width * height
        image_pixels = pixels[start_index:end_index]

       
        image = Image.new('L', (width, height))  
        image.putdata(image_pixels)
        image.save(f'image_{i}.png')

pixels = read_image_pixels('result_images.dat')
create_images(pixels, 256, 256, 4)
