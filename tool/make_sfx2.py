"""Mini oyun ses efektleri."""
import numpy as np, scipy.io.wavfile as wf
from scipy.signal import butter, lfilter
SR = 22050
rng = np.random.default_rng(3)
def t(d): return np.arange(int(d*SR))/SR
def bp(x, lo, hi):
    b, a = butter(2, [lo/(SR/2), hi/(SR/2)], 'band'); return lfilter(b, a, x)
def save(n, x):
    x = x/np.max(np.abs(x))*0.85
    wf.write(f'assets/sfx/{n}.wav', SR, (x*32767).astype(np.int16))
# tok: tahta blok
tt = t(0.18); x = np.sin(2*np.pi*520*tt)*np.exp(-tt*40) + 0.5*np.sin(2*np.pi*1310*tt)*np.exp(-tt*70) + bp(rng.normal(0,1,len(tt)),800,3000)*np.exp(-tt*120)*0.6
save('tok', x)
# kir: taş kırılması
tt = t(0.5); x = bp(rng.normal(0,1,len(tt)),150,2500)*np.exp(-tt*9) + np.sin(2*np.pi*90*tt)*np.exp(-tt*14)
save('kir', x)
# su: su sıçraması
tt = t(0.7); x = bp(rng.normal(0,1,len(tt)),900,6000)*(np.minimum(1,tt*30))*np.exp(-tt*5)
save('su', x)
# kopuk: baloncuklar
x = np.zeros(int(0.6*SR))
for i in range(9):
    s = int(rng.uniform(0,0.45)*SR); d = t(0.08); f = rng.uniform(700,1600)
    seg = np.sin(2*np.pi*(f+f*2*d)*d)*np.exp(-d*40); x[s:s+len(seg)] += seg
save('kopuk', x)
# vinc: motor vızıltısı
tt = t(0.8); f = 110+40*tt; x = np.sign(np.sin(2*np.pi*np.cumsum(f)/SR))*0.4 + np.sin(2*np.pi*np.cumsum(f*2)/SR)
x = bp(x, 80, 1500)*np.minimum(1,tt*10)*np.minimum(1,(0.8-tt)*10)
save('vinc', x)
# uc: vuuş
tt = t(0.5); x = bp(rng.normal(0,1,len(tt)),300,2500)*np.sin(np.pi*tt/0.5)**2
save('uc', x)
# kart: kart çevirme
tt = t(0.12); x = bp(rng.normal(0,1,len(tt)),1500,7000)*np.exp(-tt*50)
save('kart', x)
print('ok')
