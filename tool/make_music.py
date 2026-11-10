"""Vızır fon müziği: neşeli, yumuşak marimba döngüsü (assets/sfx/muzik.mp3)."""
import numpy as np, subprocess, scipy.io.wavfile as wf
SR = 32000
BPM = 104
beat = 60 / BPM
bars = 8
L = int(SR * beat * 4 * bars)
out = np.zeros(L + SR)

def note(f, t, d, amp, kind='mar'):
    n = int(d * SR); tt = np.arange(n) / SR
    if kind == 'mar':
        w = np.sin(2*np.pi*f*tt) + 0.35*np.sin(2*np.pi*f*4*tt)*np.exp(-tt*30) + 0.12*np.sin(2*np.pi*f*10*tt)*np.exp(-tt*60)
        env = np.exp(-tt * 5.5) * np.minimum(1, tt*400)
    elif kind == 'bass':
        w = np.sin(2*np.pi*f*tt) + 0.2*np.sin(2*np.pi*f*2*tt)
        env = np.exp(-tt*3) * np.minimum(1, tt*200)
    elif kind == 'pad':
        w = sum(np.sin(2*np.pi*f*k*tt*(1+0.002*k))/k for k in (1, 2, 3))
        env = np.minimum(1, tt*3) * np.minimum(1, (d-tt)*3)
    i = int(t * SR); out[i:i+n] += w * env * amp

def hz(m): return 440 * 2 ** ((m - 69) / 12)
chords = [[60, 64, 67], [55, 59, 62], [57, 60, 64], [53, 57, 60]] * 2
mel = [
  76, None, 79, 76, 74, None, 72, 74,  74, None, 76, 74, 72, None, 67, None,
  69, 72, 76, None, 74, 72, 69, None,  72, None, 69, 67, 69, None, None, None,
  76, None, 79, 81, 79, None, 76, 74,  74, 76, 79, None, 76, None, 74, None,
  72, None, 74, 76, 74, 72, 69, None,  72, None, None, None, 72, None, None, None,
]
step = beat / 2
for b in range(bars):
    t0 = b * beat * 4
    ch = chords[b]
    for k in ch: note(hz(k), t0, beat*4, 0.05, 'pad')
    note(hz(ch[0] - 24), t0, beat*1.8, 0.35, 'bass')
    note(hz(ch[0] - 17), t0 + beat*2, beat*1.8, 0.28, 'bass')
    for s in range(8):
        if s % 2 == 1: note(hz(ch[s % 3] + 12), t0 + s*step, step*1.5, 0.08, 'mar')
for i, m in enumerate(mel):
    if m: note(hz(m), i*step, step*2.5, 0.28, 'mar')
# yumuşak çalkalama
rng = np.random.default_rng(1)
for i in range(bars*8):
    n = int(0.05*SR); env = np.exp(-np.arange(n)/SR*80)
    s = int(i*step*SR); out[s:s+n] += rng.normal(0, 1, n)*env*(0.025 if i % 2 else 0.012)
# döngü: kuyruğu başa ekle
tail = out[L:]; out = out[:L]; out[:len(tail)] += tail
# basit yankı
d = int(0.23*SR); out[d:] += 0.22*out[:-d]
out = out / np.max(np.abs(out)) * 0.8
wf.write('/tmp/muzik.wav', SR, (out*32767).astype(np.int16))
subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', '/tmp/muzik.wav', '-ac', '1', '-b:a', '64k', 'assets/sfx/muzik.mp3'], check=True)
print('ok', L/SR, 's')
