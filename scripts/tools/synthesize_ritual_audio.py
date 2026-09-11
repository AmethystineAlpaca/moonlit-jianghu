"""Original short stingers. Deliberately no continuous soundtrack."""
import math
import random
import struct
import wave
from pathlib import Path

DEST = Path(__file__).resolve().parents[2] / 'assets/audio/combat'
RATE = 24000

def save(name, seconds, notes, strike=0.0):
    rng = random.Random(1407)
    samples = []
    previous = 0.0
    for i in range(int(RATE * seconds)):
        t = i / RATE
        value = 0.0
        for start, freq, amp, decay in notes:
            u = t - start
            if u < 0:
                continue
            env = (1-math.exp(-u*150)) * math.exp(-u*decay)
            value += amp*env*(math.sin(math.tau*freq*u)+0.28*math.sin(math.tau*freq*2.003*u)+0.12*math.sin(math.tau*freq*3.97*u))
        previous = previous * 0.88 + rng.uniform(-1,1)*0.12
        value += previous*strike*math.exp(-t*8)
        value *= min(1,(seconds-t)*12)
        samples.append(value)
    peak = max(abs(v) for v in samples) or 1
    data = b''.join(struct.pack('<h',round(v/peak*21000)) for v in samples)
    with wave.open(str(DEST / f'{name}.wav'), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(RATE); out.writeframes(data)

if __name__ == '__main__':
    DEST.mkdir(parents=True, exist_ok=True)
    save('ui',0.12,[(0,880,0.12,38)])
    save('ready',1.45,[(0,587.33,0.25,4),(.10,880,0.23,4),(.2,1174.66,0.18,3)])
    save('seal',2.1,[(0,220,.30,2.4),(.03,440,.14,2),(.22,587.33,.18,2.2),(.48,880,.12,2.1)],.15)
    save('surge',1.45,[(0,110,.25,5),(.2,146.83,.35,4),(.22,587.33,.22,3),(.24,880,.13,4)],1.4)
    save('boss',2.0,[(0,73.416,.4,2),(.16,110,.22,2.5),(.4,146.83,.15,3)],.45)
    save('victory',3.4,[(0,293.66,.26,2),(.28,440,.23,2),(.57,587.33,.22,1.8),(.85,880,.16,1.7),(1.1,1174.66,.1,1.8)])
    print('Wrote six original ritual/UI stingers.')
