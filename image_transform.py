from PIL import Image, ImageChops

def trim(im):
    bg = Image.new(im.mode, im.size, "white")
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)

def crop_image(input_img, start_x, start_y, width, height):
    """Pass input name image, output name image, x coordinate to start croping, y coordinate to start croping, width to crop, height to crop """
    box = (start_x, start_y, start_x + width, start_y + height)
    return input_img.crop(box)
    

IMAGE = 'destiny.jpg'
IMAGE = '4_xbox-360_tomb-raider.jpg'
IMAGE = 'mario.jpg'
IMAGE = '0_3ds_super-mario-3d-land.jpg'
IMAGE = '4_3ds_super-paper-mario-strikers.jpg'
INAME = IMAGE.split('.')[0]
IEXT = IMAGE.split('.')[1]

## load image
im = Image.open(IMAGE)

## size, what i whant
width_size=392
height_size=220
ratio = float(height_size)/float(width_size)

## white border delete
width, height = im.size
im = trim(im)
im.save(INAME+'_noborder.'+IEXT)

### box cut
width, height = im.size
diff_width=int(width*.08)
cut_width=width-diff_width
cut_height=int(ratio*cut_width)
diff_height=height-cut_height

im = crop_image(im, diff_width/2, diff_height/2, cut_width, cut_height)
im.save(INAME+'_Cropped.'+IEXT)

## resize
width, height = im.size
if width > width_size or height > height_size:
	im = im.resize((width_size, height_size), Image.ANTIALIAS)
	im.save(INAME+'_resize.'+IEXT)
print "done"
