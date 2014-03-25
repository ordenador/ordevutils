from PIL import Image, ImageChops

def trim(im):
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)

IMAGE = 'mario.jpg'
# IMAGE = '4_xbox-360_tomb-raider.jpg'
# IMAGE = '0_3ds_super-mario-3d-land.jpg'
# IMAGE = '4_3ds_super-paper-mario-strikers.jpg'
INAME = IMAGE.split('.')[0]
IEXT = IMAGE.split('.')[1]

im = Image.open(IMAGE)
im = trim(im)

im.save(INAME+'_noborder.'+IEXT)
width, height = im.size
ratio_im = float(height)/float(width)

ratio_rectangle = float(720)/float(512)
ratio_square = 1

## ratio cover ratio_rectangle
if ratio_im*0.9 < ratio_rectangle < ratio_im*1.1:
	if width > 512:
		im = im.resize((512, 720), Image.ANTIALIAS)
		im.save(INAME+'_resize.'+IEXT)

## ratio cover ratio_square
if ratio_im*0.9 < ratio_square < ratio_im*1.1:
	if width > 512:
		im = im.resize((512, 512), Image.ANTIALIAS)
		im.save(INAME+'_resize.'+IEXT)
