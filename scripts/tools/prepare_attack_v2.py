"""Align generated unarmed strike poses; preserve originals and store side poses facing left."""
from pathlib import Path
from PIL import Image, ImageOps
root = Path(__file__).resolve().parents[2] / 'assets/art_v2'
im = Image.open(root / 'player_attack_keyed.png').convert('RGBA')
frames=[]
for row in range(3):
    for col in range(6):
        frame=im.crop((col*256,row*341,(col+1)*256,(row+1)*341))
        alpha=frame.getchannel('A').point(lambda x: 255 if x>90 else 0)
        bbox=alpha.getbbox()
        frame=frame.crop(bbox)
        if row==1: frame=ImageOps.mirror(frame)
        frames.append(frame)
scale=min(152/max(f.width for f in frames),216/max(f.height for f in frames))
out=Image.new('RGBA',(960,672))
for i,f in enumerate(frames):
    f=f.resize((round(f.width*scale),round(f.height*scale)),Image.Resampling.LANCZOS)
    out.paste(f,((i%6)*160+(160-f.width)//2,(i//6)*224+220-f.height))
out.save(root/'player_attack_aligned.png')
print('Aligned', out.size, 'scale',scale)
