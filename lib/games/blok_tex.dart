import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Blokların 16x16 piksel dokuları (kodla üretilir, Minecraft tarzı).
class Tex {
  static final Map<String, ui.Image> _cache = {};
  static bool ready = false;
  static Future<void>? _loading;

  static ui.Image? get(String id, bool side) => _cache['$id${side ? 's' : 't'}'];

  static Future<void> load(List<String> ids) {
    return _loading ??= _load(ids);
  }

  /// Bütün dokular tek resimde: blok i için üst = 2i, yan = 2i+1 numaralı karo.
  static ui.Image? atlas;
  static const cols = 16;

  static ui.Rect tile(int index) => ui.Rect.fromLTWH((index % cols) * 16.0, (index ~/ cols) * 16.0, 16, 16);

  static Future<void> _load(List<String> ids) async {
    final rows = (ids.length * 2 / cols).ceil();
    final big = Uint8List(cols * 16 * rows * 16 * 4);
    for (var i = 0; i < ids.length; i++) {
      for (final side in [false, true]) {
        final px = _paint(ids[i], side);
        final c = Completer<ui.Image>();
        ui.decodeImageFromPixels(px, 16, 16, ui.PixelFormat.rgba8888, c.complete);
        _cache['${ids[i]}${side ? 's' : 't'}'] = await c.future;
        final t = i * 2 + (side ? 1 : 0);
        final ox = (t % cols) * 16, oy = (t ~/ cols) * 16;
        for (var y = 0; y < 16; y++) {
          final src = y * 16 * 4;
          final dst = ((oy + y) * cols * 16 + ox) * 4;
          big.setRange(dst, dst + 64, px, src);
        }
      }
    }
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(big, cols * 16, rows * 16, ui.PixelFormat.rgba8888, c.complete);
    atlas = await c.future;
    ready = true;
  }

  static Uint8List _paint(String id, bool side) {
    final g = _G(Random(id.hashCode * 7 + (side ? 1 : 0)));
    switch (id) {
      case 'cim':
        if (side) {
          g.noise(0xFF8B5A2B, 14);
          for (var x = 0; x < 16; x++) {
            final d = 3 + g.r.nextInt(3);
            for (var y = 0; y < d; y++) {
              g.set(x, y, g.vary(0xFF6DBE45, 16));
            }
          }
        } else {
          g.noise(0xFF6DBE45, 18);
          g.specks(0xFF4E9A2E, 18);
        }
      case 'toprak':
        g.noise(0xFF8B5A2B, 16);
        g.specks(0xFF6B4220, 14);
      case 'tas':
        g.noise(0xFF8E8E8E, 12);
        g.specks(0xFF6E6E6E, 16);
        g.specks(0xFFA8A8A8, 10);
      case 'parke':
        g.fill(0xFF505050);
        for (var row = 0; row < 4; row++) {
          final off = row.isEven ? 0 : 2;
          for (var col = -1; col < 4; col++) {
            final x0 = col * 4 + off + 1, y0 = row * 4 + 1;
            final c = g.vary(0xFF9A9A9A, 18);
            for (var y = y0; y < y0 + 3; y++) {
              for (var x = x0; x < x0 + 3; x++) {
                if (x >= 0 && x < 16) g.set(x, y, g.vary(c, 6));
              }
            }
          }
        }
      case 'tahta':
      case 'koyu':
        g.planks(id == 'tahta' ? 0xFFB8834A : 0xFF6B4423);
      case 'kutuk':
        if (side) {
          for (var x = 0; x < 16; x++) {
            final c = x % 4 == 0 ? 0xFF4A3220 : 0xFF6B4A2B;
            for (var y = 0; y < 16; y++) {
              g.set(x, y, g.vary(c, 10));
            }
          }
        } else {
          for (var y = 0; y < 16; y++) {
            for (var x = 0; x < 16; x++) {
              final d = sqrt(pow(x - 7.5, 2) + pow(y - 7.5, 2));
              final c = d > 7 ? 0xFF6B4A2B : ((d ~/ 2).isEven ? 0xFFC49A5E : 0xFFA9804A);
              g.set(x, y, g.vary(c, 6));
            }
          }
        }
      case 'yaprak':
        g.noise(0xFF2E7D32, 28);
        g.specks(0xFF1B5E20, 30);
        g.specks(0xFF66BB6A, 14);
      case 'kiremit':
        for (var y = 0; y < 16; y++) {
          for (var x = 0; x < 16; x++) {
            final yy = y % 4;
            final shift = (y ~/ 4).isEven ? 0 : 2;
            final edge = yy == 3 || ((x + shift) % 4 == 0 && yy > 0);
            g.set(x, y, g.vary(edge ? 0xFF8E2F1C : (yy == 0 ? 0xFFE0603F : 0xFFC0442A), 8));
          }
        }
      case 'tugla':
        g.fill(0xFFD8CFC4);
        for (var row = 0; row < 4; row++) {
          final off = row.isEven ? 0 : 4;
          for (var col = -1; col < 2; col++) {
            final c = g.vary(0xFFB04A2F, 16);
            for (var y = row * 4; y < row * 4 + 3; y++) {
              for (var x = col * 8 + off; x < col * 8 + off + 7; x++) {
                if (x >= 0 && x < 16) g.set(x, y, g.vary(c, 6));
              }
            }
          }
        }
      case 'cam':
        g.fill(0x669EE6FF);
        g.border(0xFFE0F7FA);
        for (var i = 0; i < 5; i++) {
          g.set(3 + i, 9 - i, 0xCCFFFFFF);
          g.set(6 + i, 12 - i, 0x99FFFFFF);
        }
      case 'beyaz':
        g.noise(0xFFF2F0EA, 5);
        for (var i = 0; i < 12; i++) {
          g.set(i + 2, (i * 0.6 + 3).toInt(), 0xFFD6D2C8);
        }
      case 'altin':
        g.noise(0xFFFFC928, 10);
        g.border(0xFFD99A00);
        g.set(3, 3, 0xFFFFF59D);
        g.set(4, 3, 0xFFFFF59D);
        g.set(3, 4, 0xFFFFF59D);
        g.set(11, 10, 0xFFFFF59D);
      case 'su':
        g.noise(0xCC2E9AE6, 10);
        for (var x = 0; x < 16; x++) {
          g.set(x, 4 + (sin(x / 2.5) * 1.5).round(), 0xDD7CCBFF);
          g.set(x, 11 + (sin(x / 2.5 + 2) * 1.5).round(), 0xDD7CCBFF);
        }
      case 'kum':
        g.noise(0xFFE8D29A, 10);
        g.specks(0xFFCDB273, 14);
      case 'kumtasi':
        if (side) {
          for (var y = 0; y < 16; y++) {
            final c = y < 4 ? 0xFFE8D29A : (y % 5 == 0 ? 0xFFC9AE6E : 0xFFDCC384);
            for (var x = 0; x < 16; x++) {
              g.set(x, y, g.vary(c, 5));
            }
          }
        } else {
          g.noise(0xFFE8D29A, 6);
        }
      case 'kar':
        g.noise(0xFFF8FBFF, 5);
        g.specks(0xFFDDEBFA, 18);
      case 'buz':
        g.noise(0xD9A8DDF5, 8);
        for (var i = 0; i < 6; i++) {
          g.set(2 + i, 12 - i, 0xEEFFFFFF);
          g.set(9 + i, 7 - i, 0xEEFFFFFF);
        }
      case 'saman':
        if (side) {
          for (var x = 0; x < 16; x++) {
            for (var y = 0; y < 16; y++) {
              final band = y == 5 || y == 10;
              g.set(x, y, g.vary(band ? 0xFF9C7A2A : (x.isEven ? 0xFFE3C14B : 0xFFD4AE3A), 8));
            }
          }
        } else {
          g.noise(0xFFE3C14B, 14);
          g.specks(0xFFC49A2A, 20);
        }
      case 'kitaplik':
        if (side) {
          g.planks(0xFFB8834A);
          const books = [0xFFC62828, 0xFF1565C0, 0xFF2E7D32, 0xFFF9A825, 0xFF6A1B9A, 0xFFEF6C00];
          for (final y0 in [1, 9]) {
            for (var x = 1; x < 15; x++) {
              final c = books[(x + y0) % books.length];
              final h = 5 + (x % 3 == 0 ? 0 : 1);
              for (var y = y0 + 6 - h; y < y0 + 6; y++) {
                g.set(x, y, g.vary(c, 10));
              }
            }
          }
        } else {
          g.planks(0xFFB8834A);
        }
      case 'kapi':
        if (side) {
          g.fill(0xFF7A4E2A);
          g.border(0xFF4E2F17);
          for (var y = 2; y < 7; y++) {
            for (var x = 3; x < 13; x++) {
              g.set(x, y, g.vary(0xFF9B6A3E, 6));
            }
          }
          for (var y = 9; y < 14; y++) {
            for (var x = 3; x < 13; x++) {
              g.set(x, y, g.vary(0xFF9B6A3E, 6));
            }
          }
          g.set(12, 8, 0xFFFFD54F);
          g.set(12, 9, 0xFFFFD54F);
        } else {
          g.planks(0xFF7A4E2A);
        }
      case 'fener':
        g.fill(0xFF4E342E);
        for (var y = 2; y < 14; y++) {
          for (var x = 2; x < 14; x++) {
            final d = sqrt(pow(x - 7.5, 2) + pow(y - 7.5, 2));
            g.set(x, y, d < 3 ? 0xFFFFFDE7 : (d < 5 ? 0xFFFFE082 : 0xFFFFC107));
          }
        }
        for (var i = 2; i < 14; i++) {
          g.set(i, 8, 0xFF4E342E);
          g.set(8, i, 0xFF4E342E);
        }
      case 'elmas':
        g.noise(0xFF8E8E8E, 12);
        for (final p in const [(3, 3), (10, 5), (5, 11), (12, 12)]) {
          g.set(p.$1, p.$2, 0xFF4DD0E1);
          g.set(p.$1 + 1, p.$2, 0xFFB2EBF2);
          g.set(p.$1, p.$2 + 1, 0xFF00ACC1);
          g.set(p.$1 + 1, p.$2 + 1, 0xFF4DD0E1);
        }
      case 'demir':
        g.noise(0xFFD6D6D6, 5);
        for (var i = 0; i < 16; i++) {
          g.set(i, 7, 0xFFB0B0B0);
          g.set(7, i, 0xFFB0B0B0);
        }
        for (final p in const [(2, 2), (13, 2), (2, 13), (13, 13)]) {
          g.set(p.$1, p.$2, 0xFF8A8A8A);
        }
      case 'asfalt':
        g.noise(0xFF4A4A50, 8);
        g.specks(0xFF5E5E66, 20);
      case 'yol':
        g.noise(0xFF4A4A50, 8);
        if (!side) {
          for (var y = 2; y < 14; y++) {
            g.set(7, y, 0xFFF5F5F5);
            g.set(8, y, 0xFFF5F5F5);
          }
        }
      case 'cicek':
        if (side) {
          g.noise(0xFF8B5A2B, 14);
          for (var x = 0; x < 16; x++) {
            for (var y = 0; y < 3 + g.r.nextInt(2); y++) {
              g.set(x, y, g.vary(0xFF6DBE45, 16));
            }
          }
        } else {
          g.noise(0xFF6DBE45, 18);
          const fl = [0xFFE53935, 0xFFFFEB3B, 0xFFF48FB1, 0xFFFFFFFF, 0xFFAB47BC];
          for (var i = 0; i < 9; i++) {
            final x = 1 + g.r.nextInt(14), y = 1 + g.r.nextInt(14);
            final c = fl[i % fl.length];
            g.set(x, y, c);
            g.set(x + 1, y, c);
            g.set(x, y + 1, c);
            g.set(x + 1, y + 1, 0xFFFFC107);
          }
        }
      case 'cit':
        g.fill(0x00000000);
        for (var y = 0; y < 16; y++) {
          for (final x in [1, 2, 13, 14]) {
            g.set(x, y, g.vary(0xFFB8834A, 8));
          }
        }
        for (var x = 0; x < 16; x++) {
          for (final y in [3, 4, 10, 11]) {
            g.set(x, y, g.vary(0xFF9C6B3A, 8));
          }
        }
      case 'cali':
        g.noise(0xFF558B2F, 26);
        g.specks(0xFF7CB342, 30);
        g.specks(0xFF33691E, 20);
      case 'kabak':
        if (side) {
          for (var x = 0; x < 16; x++) {
            for (var y = 0; y < 16; y++) {
              g.set(x, y, g.vary(x % 4 == 0 ? 0xFFD35400 : 0xFFF07F1A, 8));
            }
          }
        } else {
          g.noise(0xFFF07F1A, 8);
          for (var y = 6; y < 10; y++) {
            for (var x = 6; x < 10; x++) {
              g.set(x, y, 0xFF5D7A2B);
            }
          }
        }
      case 'karpuz':
        if (side) {
          for (var x = 0; x < 16; x++) {
            for (var y = 0; y < 16; y++) {
              g.set(x, y, g.vary((x ~/ 2).isEven ? 0xFF2E7D32 : 0xFF66BB6A, 8));
            }
          }
        } else {
          g.noise(0xFF388E3C, 10);
        }
      case 'mantar':
        g.noise(0xFFD32F2F, 10);
        for (final p in const [(3, 3), (10, 2), (7, 8), (2, 11), (12, 11)]) {
          for (var dy = 0; dy < 2; dy++) {
            for (var dx = 0; dx < 2; dx++) {
              g.set(p.$1 + dx, p.$2 + dy, 0xFFFFFFFF);
            }
          }
        }
      case 'bal':
        g.noise(0xFFFFB300, 10);
        g.border(0xFFE08E00);
        for (var i = 3; i < 13; i += 4) {
          for (var x = 1; x < 15; x++) {
            g.set(x, i, 0xFFFFCA28);
          }
        }
      case 'toprakyol':
        g.noise(0xFFC9A26B, 10);
        g.specks(0xFFA88552, 24);
      case 'pencere':
        g.fill(0x889EE6FF);
        g.border(0xFF8D5524);
        for (var i = 1; i < 15; i++) {
          g.set(i, 7, 0xFF8D5524);
          g.set(7, i, 0xFF8D5524);
        }
        g.set(3, 4, 0xCCFFFFFF);
        g.set(4, 3, 0xCCFFFFFF);
      case 'tasduvar':
        g.fill(0xFF5A5A5A);
        for (var row = 0; row < 2; row++) {
          final off = row.isEven ? 0 : 4;
          for (var col = -1; col < 2; col++) {
            final c = g.vary(0xFF9A9A9A, 10);
            for (var y = row * 8 + 1; y < row * 8 + 7; y++) {
              for (var x = col * 8 + off + 1; x < col * 8 + off + 8; x++) {
                if (x >= 0 && x < 16) g.set(x, y, g.vary(c, 7));
              }
            }
          }
        }
      case 'mavicati':
        for (var y = 0; y < 16; y++) {
          for (var x = 0; x < 16; x++) {
            final yy = y % 4;
            final shift = (y ~/ 4).isEven ? 0 : 2;
            final edge = yy == 3 || ((x + shift) % 4 == 0 && yy > 0);
            g.set(x, y, g.vary(edge ? 0xFF0D3C7A : (yy == 0 ? 0xFF4F8FE0 : 0xFF1E5FB5), 8));
          }
        }
      case 'tarla':
        if (side) {
          g.noise(0xFF8B5A2B, 14);
          g.specks(0xFF6B4220, 14);
        } else {
          for (var y = 0; y < 16; y++) {
            for (var x = 0; x < 16; x++) {
              g.set(x, y, g.vary(y % 4 < 2 ? 0xFF5D3A1A : 0xFF7A4B24, 8));
            }
          }
        }
      case '_beyaz':
        g.fill(0xFFFFFFFF);
      case '_yuz':
        g.fill(0xFFFFFFFF);
        for (final ex in const [4, 10]) {
          for (var y = 6; y < 9; y++) {
            for (var x = ex; x < ex + 2; x++) {
              g.set(x, y, 0xFF263238);
            }
          }
          g.set(ex, 6, 0xFFFFFFFF);
        }
        for (var x = 5; x < 11; x++) {
          g.set(x, 12, 0xFF8E2A2A);
        }
        g.set(4, 11, 0xFF8E2A2A);
        g.set(11, 11, 0xFF8E2A2A);
        for (final cx in const [2, 13]) {
          g.set(cx, 10, 0xFFFFB4B4);
        }
      case 'hazine':
        g.planks(0xFF8D5524);
        for (var i = 0; i < 16; i++) {
          g.set(i, side ? 5 : 0, 0xFF5D4037);
          g.set(i, side ? 6 : 15, 0xFF5D4037);
          g.set(0, i, 0xFFFFC107);
          g.set(15, i, 0xFFFFC107);
        }
        if (side) {
          for (var y = 5; y < 10; y++) {
            for (var x = 6; x < 10; x++) {
              g.set(x, y, 0xFFFFC107);
            }
          }
          g.set(7, 7, 0xFF3E2723);
          g.set(8, 7, 0xFF3E2723);
          g.set(7, 8, 0xFF3E2723);
        }
      default:
        // yün / renkli bloklar
        g.wool(_woolColors[id] ?? 0xFFFF00FF);
    }
    return g.px;
  }

  static const _woolColors = {
    'kirmizi': 0xFFE53935,
    'mavi': 0xFF1E88E5,
    'sari': 0xFFFDD835,
    'yesil': 0xFF43A047,
    'turuncu': 0xFFFB8C00,
    'mor': 0xFF8E24AA,
    'pembe': 0xFFF48FB1,
    'siyah': 0xFF37373F,
    'acikmavi': 0xFF81D4FA,
  };
}

class _G {
  final Random r;
  final Uint8List px = Uint8List(16 * 16 * 4);
  _G(this.r);

  void set(int x, int y, int c) {
    if (x < 0 || y < 0 || x > 15 || y > 15) return;
    final i = (y * 16 + x) * 4;
    px[i] = (c >> 16) & 0xFF;
    px[i + 1] = (c >> 8) & 0xFF;
    px[i + 2] = c & 0xFF;
    px[i + 3] = (c >> 24) & 0xFF;
  }

  int vary(int c, int v) {
    final d = r.nextInt(v * 2 + 1) - v;
    int ch(int s) => (((c >> s) & 0xFF) + d).clamp(0, 255).toInt();
    return (c & 0xFF000000) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }

  void fill(int c) {
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        set(x, y, c);
      }
    }
  }

  void noise(int c, int v) {
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        set(x, y, vary(c, v));
      }
    }
  }

  void specks(int c, int n) {
    for (var i = 0; i < n; i++) {
      set(r.nextInt(16), r.nextInt(16), vary(c, 6));
    }
  }

  void border(int c) {
    for (var i = 0; i < 16; i++) {
      set(i, 0, c);
      set(i, 15, c);
      set(0, i, c);
      set(15, i, c);
    }
  }

  void planks(int c) {
    for (var y = 0; y < 16; y++) {
      final row = y ~/ 4;
      for (var x = 0; x < 16; x++) {
        final seam = (x == (row.isEven ? 5 : 11));
        final dark = y % 4 == 3 || seam;
        g(x, y, dark ? _darken(c, 0.72) : vary(c, 9));
      }
    }
  }

  void g(int x, int y, int c) => set(x, y, c);

  void wool(int c) {
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        final k = ((x + y) % 4 == 0) ? _darken(c, 0.9) : c;
        set(x, y, vary(k, 7));
      }
    }
  }

  static int _darken(int c, double f) {
    int ch(int s) => (((c >> s) & 0xFF) * f).round().clamp(0, 255).toInt();
    return (c & 0xFF000000) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }
}
