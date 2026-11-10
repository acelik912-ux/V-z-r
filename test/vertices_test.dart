import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('vertices doku denemesi', (tester) async {
    await tester.runAsync(() async {
      final px = Uint8List(32 * 32 * 4);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final i = (y * 32 + x) * 4;
          final c = ((x ~/ 4) + (y ~/ 4)).isEven;
          px[i] = c ? 255 : 0;
          px[i + 1] = c ? 0 : 200;
          px[i + 2] = 0;
          px[i + 3] = 255;
        }
      }
      final comp = Completer<ui.Image>();
      ui.decodeImageFromPixels(px, 32, 32, ui.PixelFormat.rgba8888, comp.complete);
      final im = await comp.future;
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 100), Paint()..color = Colors.white);
      final modes = <(bool, BlendMode)>[(false, BlendMode.modulate), (true, BlendMode.modulate), (true, BlendMode.multiply), (true, BlendMode.dstIn)];
      for (var k = 0; k < modes.length; k++) {
        final o = k * 100.0;
        final pos = Float32List.fromList([o + 10, 10, o + 90, 10, o + 90, 90, o + 10, 90]);
        final uv = Float32List.fromList([0, 0, 32, 0, 32, 32, 0, 32]);
        final cols = Int32List.fromList([0xFFAAAAAA, 0xFFAAAAAA, 0xFFAAAAAA, 0xFFAAAAAA]);
        final v = ui.Vertices.raw(ui.VertexMode.triangles, pos,
            textureCoordinates: uv, colors: modes[k].$1 ? cols : null, indices: Uint16List.fromList([0, 1, 2, 0, 2, 3]));
        final paint = Paint()..shader = ui.ImageShader(im, TileMode.clamp, TileMode.clamp, Matrix4.identity().storage, filterQuality: FilterQuality.none);
        canvas.drawVertices(v, modes[k].$2, paint);
      }
      final out = await rec.endRecording().toImage(400, 100);
      final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
      Directory('previews').createSync(recursive: true);
      File('previews/vertices.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
