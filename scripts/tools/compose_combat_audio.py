"""Original one-shot combat Foley synthesized without external samples."""
from pathlib import Path
import math,random,wave,struct
root=Path(__file__).resolve().parents[2]/'assets/audio/combat'
root.mkdir(parents=True,exist_ok=True)
rng=random.Random(737)
sr=44100
for name,duration in [('swing',.14),('heavy',.23),('hit',.17),('guard',.22),('parry',.58),('dash',.20),('recall',.48),('crash',.32)]:
 data=[];low=0;previous=0
 for i in range(int(sr*duration)):
  t=i/sr;p=t/duration;n=rng.uniform(-1,1);low=low*.88+n*.12;high=n-previous;previous=n
  if name=='swing': v=high*.22*math.sin(math.pi*p)**1.4+math.sin(2*math.pi*(500*t-700*t*t))*.07*math.sin(math.pi*p)
  elif name=='heavy': v=(low*.65+math.sin(2*math.pi*(145*t-160*t*t))*.24)*math.sin(math.pi*p)*math.exp(-p)
  elif name=='hit': v=(n*.28+math.sin(2*math.pi*92*t)*.4)*math.exp(-t*40)*(1-math.exp(-t*1600))
  elif name=='guard': v=(math.sin(2*math.pi*630*t)+.5*math.sin(2*math.pi*1710*t)+n*.5)*.24*math.exp(-t*33)
  elif name=='parry': v=(math.sin(2*math.pi*1357*t)+.55*math.sin(2*math.pi*2810*t)+.3*math.sin(2*math.pi*4230*t))*.21*math.exp(-t*11)*(1-math.exp(-t*3000))
  elif name=='dash': v=high*.16*math.sin(math.pi*p)**1.3
  elif name=='recall': v=(math.sin(2*math.pi*(260*t+1100*t*t))*.17+high*.10)*math.sin(math.pi*p)
  else: v=(low*.95+n*.12+math.sin(2*math.pi*62*t)*.23)*math.exp(-t*16)
  data.append(max(-32767,min(32767,int(v*26000))))
 with wave.open(str(root/f'{name}.wav'),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(sr);f.writeframes(struct.pack('<%dh'%len(data),*data))
 print(name,len(data)/sr)
