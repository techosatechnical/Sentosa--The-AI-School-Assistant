import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Pure-Dart ISO/IEC 18004 QR Code Widget for the NIRA Kiosk.
/// Works 100% offline with zero external dependencies and renders crisp vector modules.
class KioskQrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;
  final int quietZoneModules;

  const KioskQrCodeWidget({
    super.key,
    required this.data,
    this.size = 176,
    this.foregroundColor = const Color(0xFF0F2942),
    this.backgroundColor = Colors.white,
    this.quietZoneModules = 3,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = _IsoQrEncoder.encode(data);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _QrMatrixPainter(
          matrix: matrix,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          quietZone: quietZoneModules,
        ),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final List<List<bool>> matrix;
  final Color foregroundColor;
  final Color backgroundColor;
  final int quietZone;

  _QrMatrixPainter({
    required this.matrix,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.quietZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = matrix.length;
    if (n == 0) return;

    final totalModules = n + quietZone * 2;
    final moduleSize = size.width / totalModules;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(14),
      ),
      bgPaint,
    );

    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        if (matrix[r][c]) {
          final left = (c + quietZone) * moduleSize;
          final top = (r + quietZone) * moduleSize;
          canvas.drawRect(
            Rect.fromLTWH(left, top, moduleSize + 0.35, moduleSize + 0.35),
            fgPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _QrVersionSpec {
  final int version;
  final int ecCodewordsPerBlock;
  final int group1Blocks;
  final int group1DataCodewords;
  final int group2Blocks;
  final int group2DataCodewords;
  final List<int> alignmentCenters;

  const _QrVersionSpec({
    required this.version,
    required this.ecCodewordsPerBlock,
    required this.group1Blocks,
    required this.group1DataCodewords,
    this.group2Blocks = 0,
    this.group2DataCodewords = 0,
    required this.alignmentCenters,
  });

  int get totalDataCodewords =>
      group1Blocks * group1DataCodewords + group2Blocks * group2DataCodewords;

  int get dimension => 17 + version * 4;
}

/// ISO/IEC 18004 QR Code Generator (Byte Mode, Error Correction Level L, Versions 1..12).
class _IsoQrEncoder {
  static const List<_QrVersionSpec> _specsL = [
    _QrVersionSpec(
      version: 1,
      ecCodewordsPerBlock: 7,
      group1Blocks: 1,
      group1DataCodewords: 19,
      alignmentCenters: [],
    ),
    _QrVersionSpec(
      version: 2,
      ecCodewordsPerBlock: 10,
      group1Blocks: 1,
      group1DataCodewords: 34,
      alignmentCenters: [6, 18],
    ),
    _QrVersionSpec(
      version: 3,
      ecCodewordsPerBlock: 15,
      group1Blocks: 1,
      group1DataCodewords: 55,
      alignmentCenters: [6, 22],
    ),
    _QrVersionSpec(
      version: 4,
      ecCodewordsPerBlock: 20,
      group1Blocks: 1,
      group1DataCodewords: 80,
      alignmentCenters: [6, 26],
    ),
    _QrVersionSpec(
      version: 5,
      ecCodewordsPerBlock: 26,
      group1Blocks: 1,
      group1DataCodewords: 108,
      alignmentCenters: [6, 30],
    ),
    _QrVersionSpec(
      version: 6,
      ecCodewordsPerBlock: 18,
      group1Blocks: 2,
      group1DataCodewords: 68,
      alignmentCenters: [6, 34],
    ),
    _QrVersionSpec(
      version: 7,
      ecCodewordsPerBlock: 20,
      group1Blocks: 2,
      group1DataCodewords: 78,
      alignmentCenters: [6, 22, 38],
    ),
    _QrVersionSpec(
      version: 8,
      ecCodewordsPerBlock: 24,
      group1Blocks: 2,
      group1DataCodewords: 97,
      alignmentCenters: [6, 24, 42],
    ),
    _QrVersionSpec(
      version: 9,
      ecCodewordsPerBlock: 30,
      group1Blocks: 2,
      group1DataCodewords: 116,
      alignmentCenters: [6, 26, 46],
    ),
    _QrVersionSpec(
      version: 10,
      ecCodewordsPerBlock: 18,
      group1Blocks: 2,
      group1DataCodewords: 68,
      group2Blocks: 2,
      group2DataCodewords: 69,
      alignmentCenters: [6, 28, 50],
    ),
    _QrVersionSpec(
      version: 11,
      ecCodewordsPerBlock: 20,
      group1Blocks: 4,
      group1DataCodewords: 81,
      alignmentCenters: [6, 30, 54],
    ),
    _QrVersionSpec(
      version: 12,
      ecCodewordsPerBlock: 24,
      group1Blocks: 2,
      group1DataCodewords: 92,
      group2Blocks: 2,
      group2DataCodewords: 93,
      alignmentCenters: [6, 32, 58],
    ),
  ];

  static List<List<bool>> encode(String text) {
    Uint8List utf8Bytes = Uint8List.fromList(utf8.encode(text));
    if (utf8Bytes.length > 360) {
      utf8Bytes = utf8Bytes.sublist(0, 360);
    }

    _QrVersionSpec spec = _specsL.last;
    for (final candidate in _specsL) {
      final countBits = candidate.version <= 9 ? 8 : 16;
      final availableDataBits = candidate.totalDataCodewords * 8;
      final neededBits = 4 + countBits + utf8Bytes.length * 8;
      if (neededBits <= availableDataBits) {
        spec = candidate;
        break;
      }
    }

    final dataCodewords = _buildDataCodewords(utf8Bytes, spec);
    final finalCodewords = _interleaveWithEcc(dataCodewords, spec);
    return _buildBestMatrix(finalCodewords, spec);
  }

  static Uint8List _buildDataCodewords(Uint8List payload, _QrVersionSpec spec) {
    final totalBitsCapacity = spec.totalDataCodewords * 8;
    final bits = <int>[];

    void appendBits(int value, int length) {
      for (int i = length - 1; i >= 0; i--) {
        bits.add((value >> i) & 1);
      }
    }

    // Byte mode indicator (0100)
    appendBits(0x4, 4);
    // Character count indicator (8 bits for V1-9, 16 bits for V10+)
    appendBits(payload.length, spec.version <= 9 ? 8 : 16);
    // Payload bytes
    for (final b in payload) {
      appendBits(b, 8);
    }

    // Terminator (up to 4 zero bits)
    final terminatorLen = (totalBitsCapacity - bits.length).clamp(0, 4);
    appendBits(0, terminatorLen);

    // Pad to byte boundary
    while (bits.length % 8 != 0) {
      bits.add(0);
    }

    final codewords = Uint8List(spec.totalDataCodewords);
    int byteIdx = 0;
    for (int i = 0; i < bits.length; i += 8) {
      int val = 0;
      for (int b = 0; b < 8; b++) {
        val = (val << 1) | bits[i + b];
      }
      codewords[byteIdx++] = val;
    }

    // Pad alternating 0xEC and 0x11
    bool padToggle = true;
    while (byteIdx < spec.totalDataCodewords) {
      codewords[byteIdx++] = padToggle ? 0xEC : 0x11;
      padToggle = !padToggle;
    }

    return codewords;
  }

  static Uint8List _interleaveWithEcc(
    Uint8List dataCodewords,
    _QrVersionSpec spec,
  ) {
    final dataBlocks = <Uint8List>[];
    final eccBlocks = <Uint8List>[];
    final rsDivisor = _rsGeneratorPoly(spec.ecCodewordsPerBlock);

    int offset = 0;
    for (int i = 0; i < spec.group1Blocks; i++) {
      final block = dataCodewords.sublist(
        offset,
        offset + spec.group1DataCodewords,
      );
      offset += spec.group1DataCodewords;
      dataBlocks.add(block);
      eccBlocks.add(_rsComputeRemainder(block, rsDivisor));
    }
    for (int i = 0; i < spec.group2Blocks; i++) {
      final block = dataCodewords.sublist(
        offset,
        offset + spec.group2DataCodewords,
      );
      offset += spec.group2DataCodewords;
      dataBlocks.add(block);
      eccBlocks.add(_rsComputeRemainder(block, rsDivisor));
    }

    final out = <int>[];
    final maxDataLen = spec.group2DataCodewords > spec.group1DataCodewords
        ? spec.group2DataCodewords
        : spec.group1DataCodewords;

    for (int col = 0; col < maxDataLen; col++) {
      for (final block in dataBlocks) {
        if (col < block.length) {
          out.add(block[col]);
        }
      }
    }
    for (int col = 0; col < spec.ecCodewordsPerBlock; col++) {
      for (final block in eccBlocks) {
        out.add(block[col]);
      }
    }

    return Uint8List.fromList(out);
  }

  static List<List<bool>> _buildBestMatrix(
    Uint8List codewords,
    _QrVersionSpec spec,
  ) {
    final dim = spec.dimension;
    final modules = List.generate(dim, (_) => List<bool>.filled(dim, false));
    final isFunction = List.generate(dim, (_) => List<bool>.filled(dim, false));

    _drawFunctionPatterns(modules, isFunction, spec);
    _drawCodewords(modules, isFunction, codewords);

    int bestMask = 0;
    int lowestPenalty = 0x7FFFFFFF;
    List<List<bool>>? bestMatrix;

    for (int mask = 0; mask < 8; mask++) {
      final trial = List.generate(
        dim,
        (r) => List<bool>.from(modules[r]),
      );
      _applyMask(trial, isFunction, mask);
      _drawFormatBits(trial, mask);
      final penalty = _computePenalty(trial);
      if (penalty < lowestPenalty) {
        lowestPenalty = penalty;
        bestMask = mask;
        bestMatrix = trial;
      }
    }

    if (bestMatrix != null) return bestMatrix;
    _applyMask(modules, isFunction, bestMask);
    _drawFormatBits(modules, bestMask);
    return modules;
  }

  static void _drawFunctionPatterns(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    _QrVersionSpec spec,
  ) {
    final dim = spec.dimension;

    void setFuncModule(int r, int c, bool dark) {
      if (r < 0 || r >= dim || c < 0 || c >= dim) return;
      modules[r][c] = dark;
      isFunction[r][c] = true;
    }

    // Timing patterns
    for (int i = 0; i < dim; i++) {
      setFuncModule(6, i, i % 2 == 0);
      setFuncModule(i, 6, i % 2 == 0);
    }

    // Finder patterns (3 corners) + separators
    void drawFinder(int topR, int leftC) {
      for (int dr = -1; dr <= 7; dr++) {
        for (int dc = -1; dc <= 7; dc++) {
          final r = topR + dr;
          final c = leftC + dc;
          if (r < 0 || r >= dim || c < 0 || c >= dim) continue;
          final inOuter =
              dr >= 0 && dr <= 6 && dc >= 0 && dc <= 6 &&
              (dr == 0 || dr == 6 || dc == 0 || dc == 6);
          final inInner = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;
          setFuncModule(r, c, inOuter || inInner);
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(0, dim - 7);
    drawFinder(dim - 7, 0);

    // Alignment patterns
    final centers = spec.alignmentCenters;
    for (int i = 0; i < centers.length; i++) {
      for (int j = 0; j < centers.length; j++) {
        // Skip the 3 finder corners
        if ((i == 0 && j == 0) ||
            (i == 0 && j == centers.length - 1) ||
            (i == centers.length - 1 && j == 0)) {
          continue;
        }
        final cr = centers[i];
        final cc = centers[j];
        for (int dr = -2; dr <= 2; dr++) {
          for (int dc = -2; dc <= 2; dc++) {
            final dark = dr.abs() == 2 || dc.abs() == 2 || (dr == 0 && dc == 0);
            setFuncModule(cr + dr, cc + dc, dark);
          }
        }
      }
    }

    // Reserve format info areas
    for (int i = 0; i <= 8; i++) {
      if (i != 6) {
        isFunction[8][i] = true;
        isFunction[i][8] = true;
      }
    }
    for (int i = 0; i < 8; i++) {
      isFunction[8][dim - 1 - i] = true;
      isFunction[dim - 1 - i][8] = true;
    }
    // Always-dark module
    setFuncModule(dim - 8, 8, true);

    // Version info for Version >= 7
    if (spec.version >= 7) {
      int rem = spec.version;
      for (int i = 0; i < 12; i++) {
        rem = (rem << 1) ^ ((rem >> 11) * 0x1F25);
      }
      final bits = (spec.version << 12) | rem;
      for (int i = 0; i < 18; i++) {
        final bit = ((bits >> i) & 1) != 0;
        final a = dim - 11 + (i % 3);
        final b = i ~/ 3;
        setFuncModule(a, b, bit);
        setFuncModule(b, a, bit);
      }
    }
  }

  static void _drawCodewords(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    Uint8List codewords,
  ) {
    final dim = modules.length;
    int bitIdx = 0;
    final totalBits = codewords.length * 8;

    // Zigzag upward/downward in 2-column pairs from right to left
    for (int right = dim - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5; // Skip vertical timing column
      for (int vert = 0; vert < dim; vert++) {
        for (int j = 0; j < 2; j++) {
          final c = right - j;
          final upward = ((right + 1) & 2) == 0;
          final r = upward ? (dim - 1 - vert) : vert;
          if (!isFunction[r][c] && bitIdx < totalBits) {
            final byteVal = codewords[bitIdx >> 3];
            final bitVal = ((byteVal >> (7 - (bitIdx & 7))) & 1) != 0;
            modules[r][c] = bitVal;
            bitIdx++;
          }
        }
      }
    }
  }

  static void _applyMask(
    List<List<bool>> modules,
    List<List<bool>> isFunction,
    int mask,
  ) {
    final dim = modules.length;
    for (int r = 0; r < dim; r++) {
      for (int c = 0; c < dim; c++) {
        if (isFunction[r][c]) continue;
        bool invert;
        switch (mask) {
          case 0:
            invert = (r + c) % 2 == 0;
            break;
          case 1:
            invert = r % 2 == 0;
            break;
          case 2:
            invert = c % 3 == 0;
            break;
          case 3:
            invert = (r + c) % 3 == 0;
            break;
          case 4:
            invert = ((r ~/ 2) + (c ~/ 3)) % 2 == 0;
            break;
          case 5:
            invert = (r * c) % 2 + (r * c) % 3 == 0;
            break;
          case 6:
            invert = ((r * c) % 2 + (r * c) % 3) % 2 == 0;
            break;
          default:
            invert = ((r + c) % 2 + (r * c) % 3) % 2 == 0;
            break;
        }
        if (invert) {
          modules[r][c] = !modules[r][c];
        }
      }
    }
  }

  static void _drawFormatBits(List<List<bool>> modules, int mask) {
    final dim = modules.length;
    // ECC Level L format indicator is 01 (1)
    final data = (1 << 3) | mask;
    int rem = data;
    for (int i = 0; i < 10; i++) {
      rem = (rem << 1) ^ ((rem >> 9) * 0x537);
    }
    final bits = ((data << 10) | rem) ^ 0x5412;

    bool getBit(int index) => ((bits >> index) & 1) != 0;

    // First copy around top-left finder
    for (int i = 0; i <= 5; i++) {
      modules[8][i] = getBit(i);
    }
    modules[8][7] = getBit(6);
    modules[8][8] = getBit(7);
    modules[7][8] = getBit(8);
    for (int i = 9; i < 15; i++) {
      modules[14 - i][8] = getBit(i);
    }

    // Second copy along bottom-left & top-right
    for (int i = 0; i < 8; i++) {
      modules[8][dim - 1 - i] = getBit(i);
    }
    for (int i = 8; i < 15; i++) {
      modules[dim - 15 + i][8] = getBit(i);
    }
    modules[dim - 8][8] = true;
  }

  static int _computePenalty(List<List<bool>> modules) {
    final dim = modules.length;
    int penalty = 0;

    // Rule 1: 5+ consecutive same-colored modules in row/col
    for (int r = 0; r < dim; r++) {
      int runLen = 1;
      for (int c = 1; c < dim; c++) {
        if (modules[r][c] == modules[r][c - 1]) {
          runLen++;
          if (runLen == 5) {
            penalty += 3;
          } else if (runLen > 5) {
            penalty += 1;
          }
        } else {
          runLen = 1;
        }
      }
    }
    for (int c = 0; c < dim; c++) {
      int runLen = 1;
      for (int r = 1; r < dim; r++) {
        if (modules[r][c] == modules[r - 1][c]) {
          runLen++;
          if (runLen == 5) {
            penalty += 3;
          } else if (runLen > 5) {
            penalty += 1;
          }
        } else {
          runLen = 1;
        }
      }
    }

    // Rule 2: 2x2 blocks of same color
    for (int r = 0; r < dim - 1; r++) {
      for (int c = 0; c < dim - 1; c++) {
        final color = modules[r][c];
        if (color == modules[r][c + 1] &&
            color == modules[r + 1][c] &&
            color == modules[r + 1][c + 1]) {
          penalty += 3;
        }
      }
    }
    return penalty;
  }

  // --- Reed-Solomon GF(256) Arithmetic (Primitive Polynomial 0x11D) ---
  static int _gfMultiply(int x, int y) {
    int z = 0;
    for (int i = 7; i >= 0; i--) {
      z = (z << 1) ^ ((z >> 7) * 0x11D);
      z ^= ((y >> i) & 1) * x;
    }
    return z;
  }

  static Uint8List _rsGeneratorPoly(int degree) {
    final result = Uint8List(degree);
    result[degree - 1] = 1;
    int root = 1;
    for (int i = 0; i < degree; i++) {
      for (int j = 0; j < degree; j++) {
        result[j] = _gfMultiply(result[j], root);
        if (j + 1 < degree) {
          result[j] ^= result[j + 1];
        }
      }
      root = _gfMultiply(root, 0x02);
    }
    return result;
  }

  static Uint8List _rsComputeRemainder(Uint8List data, Uint8List divisor) {
    final result = Uint8List(divisor.length);
    for (final b in data) {
      final factor = b ^ result[0];
      for (int i = 0; i < result.length - 1; i++) {
        result[i] = result[i + 1] ^ _gfMultiply(divisor[i], factor);
      }
      result[result.length - 1] = _gfMultiply(divisor.last, factor);
    }
    return result;
  }
}

