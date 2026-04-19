import 'dart:convert';
import 'dart:math';
import '../models/ssh_key.dart';

class SSHKeyGenerator {
  static SSHKey generateKeySync(SSHKeyType keyType, String name) {
    String publicKey;
    String privateKey;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random(timestamp);

    switch (keyType) {
      case SSHKeyType.rsa2048:
      case SSHKeyType.rsa4096:
        privateKey = _generateRSAKey(keyType, random);
        publicKey =
            'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ${_generateRandomBase64(random, 200)}';
        break;
      case SSHKeyType.ed25519:
        privateKey = _generateEd25519Key(random);
        publicKey =
            'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI${_generateRandomBase64(random, 40)}';
        break;
      case SSHKeyType.ecdsa256:
      case SSHKeyType.ecdsa384:
      case SSHKeyType.ecdsa521:
        privateKey = _generateECKey(keyType, random);
        publicKey =
            'ecdsa-sha2-nistp${keyType.bitSize} AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTY=${_generateRandomBase64(random, 40)}';
        break;
    }

    return SSHKey(
      name: name,
      keyType: keyType,
      publicKey: publicKey,
      privateKey: privateKey,
    );
  }

  static String _generateRSAKey(SSHKeyType type, Random random) {
    final bitSize = type == SSHKeyType.rsa2048 ? 2048 : 4096;
    final keyBytes =
        List<int>.generate(bitSize ~/ 8, (_) => random.nextInt(256));
    final encoded = base64Encode(keyBytes);
    return '-----BEGIN RSA PRIVATE KEY-----\n${_wrapBase64(encoded)}\n-----END RSA PRIVATE KEY-----';
  }

  static String _generateEd25519Key(Random random) {
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final encoded = base64Encode(keyBytes);
    return '-----BEGIN OPENSSH PRIVATE KEY-----\n${_wrapBase64(encoded)}\n-----END OPENSSH PRIVATE KEY-----';
  }

  static String _generateECKey(SSHKeyType type, Random random) {
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final encoded = base64Encode(keyBytes);
    return '-----BEGIN EC PRIVATE KEY-----\n${_wrapBase64(encoded)}\n-----END EC PRIVATE KEY-----';
  }

  static String _generateRandomBase64(Random random, int length) {
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Encode(bytes).substring(0, length);
  }

  static String _wrapBase64(String encoded) {
    final buffer = StringBuffer();
    for (var i = 0; i < encoded.length; i += 64) {
      final end = (i + 64 < encoded.length) ? i + 64 : encoded.length;
      buffer.writeln(encoded.substring(i, end));
    }
    return buffer.toString().trimRight();
  }
}
