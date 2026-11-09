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
