"""Original procedural pentatonic underscore; no samples or external recordings."""
import math, random, wave, array
from pathlib import Path
RATE=22050
LENGTH=24
notes=[74,69,66,64,62,66,69,71,69,66,64,62]
rng=random.Random(17)
result=array.array('h')
for i in range(RATE*LENGTH):
    t=i/RATE
    sample=0.0
    # Sparse bell-like plucks with a quiet reflection.
    for index,note in enumerate(notes):
        start=index*2.0
        f=440*2**((note-69)/12)
        for delay,gain in [(0,1.0),(.19,.20),(.43,.09)]:
            age=t-start-delay
            if 0<=age<3.5:
                env=(1-math.exp(-age*70))*math.exp(-age*1.7)
                sample+=gain*env*(math.sin(2*math.pi*f*age)+.24*math.sin(2*math.pi*f*2.003*age)+.08*math.sin(2*math.pi*f*3*age))*.20
    pad=(math.sin(2*math.pi*146.8324*t)+.3*math.sin(2*math.pi*220*t))*.028
    fade=min(1,t/1.4,(LENGTH-t)/1.4)
    sample=(sample+pad)*max(0,fade)
    result.append(int(max(-1,min(1,sample))*27000))
path=Path(__file__).resolve().parents[2]/'assets/audio/qinglan_night.wav'
with wave.open(str(path),'wb') as output:
    output.setnchannels(1);output.setsampwidth(2);output.setframerate(RATE);output.writeframes(result.tobytes())
print(path)
