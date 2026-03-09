import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher();

  static const int _iterations = 100000;
  static const int _keyLength = 32;

  PasswordHash createHash(String password) {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final derived = _pbkdf2(
      password: utf8.encode(password),
      salt: Uint8List.fromList(salt),
      iterations: _iterations,
      keyLength: _keyLength,
    );
    return PasswordHash(
      hash: base64Encode(derived),
      salt: base64Encode(salt),
      iterations: _iterations,
    );
  }

  bool verify({
    required String password,
    required String hash,
    required String salt,
  }) {
    final derived = _pbkdf2(
      password: utf8.encode(password),
      salt: Uint8List.fromList(base64Decode(salt)),
      iterations: _iterations,
      keyLength: _keyLength,
    );
    return _constantTimeEquals(base64Decode(hash), derived);
  }

  List<int> _pbkdf2({
    required List<int> password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final hmacSha256 = Hmac(sha256, password);
    final blocks = (keyLength / hmacSha256.convert(<int>[]).bytes.length)
        .ceil();
    final output = BytesBuilder();

    for (var block = 1; block <= blocks; block++) {
      final blockIndex = ByteData(4)..setUint32(0, block);
      var u = hmacSha256.convert(<int>[
        ...salt,
        ...blockIndex.buffer.asUint8List(),
      ]).bytes;
      final f = Uint8List.fromList(u);

      for (var iteration = 1; iteration < iterations; iteration++) {
        u = hmacSha256.convert(u).bytes;
        for (var i = 0; i < f.length; i++) {
          f[i] ^= u[i];
        }
      }

      output.add(f);
    }

    return output.takeBytes().sublist(0, keyLength);
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    var mismatch = 0;
    for (var index = 0; index < left.length; index++) {
      mismatch |= left[index] ^ right[index];
    }
    return mismatch == 0;
  }
}

class PasswordHash {
  const PasswordHash({
    required this.hash,
    required this.salt,
    required this.iterations,
  });

  final String hash;
  final String salt;
  final int iterations;
}
