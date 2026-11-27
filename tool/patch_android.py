"""flutter create sonrası Android ayarlarını düzenler: uygulama adı, dikey ekran, TTS izni."""
import os
import pathlib
import re

# Google Play derlemesi mi? (gizli yükleme anahtarıyla imzalanır, 32 bit cihazlar da desteklenir)
PLAY = bool(os.environ.get("PLAY_KEYSTORE"))

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

# ---- Sadece arm64 yerel kütüphaneleri (APK boyutu) ----
if kts.exists():
    g = kts.read_text(encoding='utf-8')
    if 'abiFilters' not in g:
        abis = '"arm64-v8a", "armeabi-v7a"' if PLAY else '"arm64-v8a"'
        g = g.replace('    defaultConfig {', '    defaultConfig {\n        ndk { abiFilters += listOf(' + abis + ') }', 1)
        kts.write_text(g, encoding='utf-8')
elif groovy.exists():
    g = groovy.read_text(encoding='utf-8')
    if 'abiFilters' not in g:
        g = g.replace('    defaultConfig {', "    defaultConfig {\n        ndk { abiFilters 'arm64-v8a' }", 1)
        groovy.write_text(g, encoding='utf-8')

# Diğer mimarilerin yerel kütüphanelerini paketten çıkar
if kts.exists():
    g = kts.read_text(encoding='utf-8')
    if 'lib/x86_64/**' not in g:
        ex = '"lib/x86_64/**", "lib/x86/**"' if PLAY else '"lib/armeabi-v7a/**", "lib/x86_64/**", "lib/x86/**"'
        g = g.replace('android {', 'android {\n    packaging {\n        jniLibs {\n            excludes += listOf(' + ex + ')\n        }\n    }\n', 1)
        kts.write_text(g, encoding='utf-8')
elif groovy.exists():
    g = groovy.read_text(encoding='utf-8')
    if 'lib/x86_64/**' not in g:
        g = g.replace('android {', "android {\n    packagingOptions {\n        jniLibs {\n            excludes += ['lib/armeabi-v7a/**', 'lib/x86_64/**', 'lib/x86/**']\n        }\n    }\n", 1)
        groovy.write_text(g, encoding='utf-8')
print(kts.read_text(encoding='utf-8')[:600] if kts.exists() else '')

# ---- Google Play: yükleme anahtarıyla imzala (şifreler ortam değişkeninden, dosyaya yazılmaz) ----
if PLAY and kts.exists():
    g = kts.read_text(encoding='utf-8')
    if 'create("play")' not in g:
        g = g.replace('        create("vizir") {', """        create("play") {
            storeFile = file(System.getenv("PLAY_KEYSTORE"))
            storePassword = System.getenv("PLAY_PASSWORD")
            keyAlias = "vizir"
            keyPassword = System.getenv("PLAY_PASSWORD")
        }
        create("vizir") {""", 1)
        g = g.replace('signingConfig = signingConfigs.getByName("vizir")', 'signingConfig = signingConfigs.getByName("play")')
        kts.write_text(g, encoding='utf-8')
    print('Play imzası ayarlandı')
