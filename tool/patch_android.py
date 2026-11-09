"""flutter create sonrası Android ayarlarını düzenler: uygulama adı, dikey ekran, TTS izni."""
import pathlib
import re

manifest = pathlib.Path('android/app/src/main/AndroidManifest.xml')
s = manifest.read_text(encoding='utf-8')

s = re.sub(r'android:label="[^"]*"', 'android:label="Vızır"', s, count=1)

if 'screenOrientation' not in s:
    s = s.replace('<activity', '<activity\n            android:screenOrientation="portrait"', 1)

tts = ('<intent>\n            <action android:name="android.intent.action.TTS_SERVICE" />\n'
       '        </intent>')
if 'TTS_SERVICE' not in s:
    if '<queries>' in s:
        s = s.replace('<queries>', '<queries>\n        ' + tts, 1)
    else:
        s = s.replace('</manifest>', '    <queries>\n        ' + tts + '\n    </queries>\n</manifest>', 1)

manifest.write_text(s, encoding='utf-8')
print(s)

# ---- Sabit imza: her sürüm aynı anahtarla imzalansın (güncellemeler üst üste kurulabilsin) ----
kts = pathlib.Path('android/app/build.gradle.kts')
groovy = pathlib.Path('android/app/build.gradle')
if kts.exists():
    g = kts.read_text(encoding='utf-8')
    block = '''
    signingConfigs {
        create("vizir") {
            storeFile = file("../../tool/debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    buildTypes {'''
    if 'create("vizir")' not in g:
        g = g.replace('\n    buildTypes {', block, 1)
        g = g.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("vizir")')
    kts.write_text(g, encoding='utf-8')
    print(g)
elif groovy.exists():
    g = groovy.read_text(encoding='utf-8')
    block = '''
    signingConfigs {
        vizir {
            storeFile file("../../tool/debug.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
    }

    buildTypes {'''
    if 'vizir {' not in g:
        g = g.replace('\n    buildTypes {', block, 1)
        g = g.replace('signingConfig = signingConfigs.debug', 'signingConfig = signingConfigs.vizir')
        g = g.replace('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.vizir')
    groovy.write_text(g, encoding='utf-8')
    print(g)

# ---- Uygulama simgesi ve açılış ekranı ----
import shutil
src = pathlib.Path('tool/android_res')
dst = pathlib.Path('android/app/src/main/res')
if src.exists():
    for f in src.rglob('*'):
        if f.is_file():
            t = dst / f.relative_to(src)
            t.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(f, t)
    m = manifest.read_text(encoding='utf-8')
    if 'android:roundIcon' not in m:
        m = m.replace('android:icon="@mipmap/ic_launcher"', 'android:icon="@mipmap/ic_launcher"\n        android:roundIcon="@mipmap/ic_launcher_round"', 1)
    manifest.write_text(m, encoding='utf-8')
    print('simgeler kopyalandı')
