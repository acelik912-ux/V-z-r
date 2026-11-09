"""Türkçe sinir ağı ses modellerinden örnek kayıt üretir ve espeak verisini kırpmayı dener."""
import glob
import os
import shutil
import subprocess
import sys

import sherpa_onnx
import numpy as np
import soundfile as sf

models_root, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
TEXT = ('Merhaba! Ben Tamirci Usta. Haydi yarışa başlayalım! '
        'Bu hece: ka. Bu hece: le. Birleştirince: kale! Aferin, çok güzel okudun!')
report = []


def make(model_dir, data_dir, name, speed):
    onnx = [f for f in glob.glob(os.path.join(model_dir, '*.onnx'))][0]
    cfg = sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(
            vits=sherpa_onnx.OfflineTtsVitsModelConfig(
                model=onnx, tokens=os.path.join(model_dir, 'tokens.txt'), data_dir=data_dir),
            num_threads=2),
        max_num_sentences=1)
    assert cfg.validate(), 'yapılandırma geçersiz'
    tts = sherpa_onnx.OfflineTts(cfg)
    wav = os.path.join(out, name + '.wav')
    print(sorted(os.listdir(model_dir)), flush=True)
    for t in ['merhaba', TEXT]:
        a2 = tts.generate(t, sid=0, speed=speed)
        print('deneme', repr(t[:20]), len(a2.samples), flush=True)
    audio = tts.generate(TEXT, sid=0, speed=speed)
    print(name, 'örnek sayısı', len(audio.samples), 'hız', audio.sample_rate, flush=True)
    if len(audio.samples) == 0:
        # Komut satırı aracıyla dene
        r = subprocess.run([sys.executable, '-c', 'pass', f'--vits-model={onnx}',
                            f'--vits-tokens={os.path.join(model_dir, "tokens.txt")}', f'--vits-data-dir={data_dir}',
                            f'--vits-length-scale={1 / speed:.3f}', f'--output-filename={wav}', TEXT],
                           capture_output=True, text=True)
        print(r.stdout[-800:], r.stderr[-1500:], flush=True)
    else:
        sf.write(wav, np.asarray(audio.samples, dtype=np.float32), samplerate=audio.sample_rate)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-b:a', '96k', wav[:-4] + '.mp3'], check=True)
    os.remove(wav)
    return os.path.getsize(onnx), tts.num_speakers


def dsize(p):
    return sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(p) for f in fs)


for d in sorted(glob.glob(os.path.join(models_root, '*'))):
    if not os.path.isdir(d):
        continue
    base = os.path.basename(d)
    if base.endswith('fp16'):
        continue
    data = os.path.join(d, 'espeak-ng-data')
    try:
        size, spk = make(d, data, base, 1.15)
        report.append(f'{base}: model {size / 1e6:.1f} MB, konuşmacı {spk}, espeak {dsize(data) / 1e6:.1f} MB')
        # espeak verisini sadece Türkçeye kırp
        small = os.path.join('/tmp', base + '-espeak')
        shutil.copytree(data, small)
        for f in glob.glob(os.path.join(small, '*_dict')):
            if not f.endswith('tr_dict'):
                os.remove(f)
        make(d, small, base + '-kirpik', 1.15)
        report.append(f'  kırpılmış espeak {dsize(small) / 1e6:.1f} MB çalıştı')
    except Exception as e:  # noqa
        report.append(f'{base}: HATA {e}')

open(os.path.join(out, 'rapor.txt'), 'w').write('\n'.join(report) + '\n')
print('\n'.join(report))
