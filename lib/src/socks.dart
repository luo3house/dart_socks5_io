// ignore_for_file: unnecessary_brace_in_string_interps

// The code here mostly referenced golang package: golang.org/x/net

import 'dart:convert';
import 'dart:io';

const version5 = 0x05;

enum Command {
  connect(0x01),
  bind(0x02),
  udpAssociate(0x03);

  final int value;
  const Command(this.value);
}

enum AuthMethod {
  notRequired(0x01),
  usernamePassword(0x02),
  noAcceptableMethods(0xff);

  final int value;
  const AuthMethod(this.value);
}

enum AddrType {
  ipv4(0x01),
  domain(0x03),
  ipv6(0x04);

  final int value;
  const AddrType(this.value);
}

enum CmdResult {
  statusSuccess(0x00),
  generalFailure(0x01),
  notAllowedByRuleSet(0x02),
  networkUnreachable(0x03),
  hostUnreachable(0x04),
  connectionRefused(0x05),
  ttlExpired(0x06),
  commandNotSupported(0x07),
  addressTypeNotSupported(0x08);

  final int value;
  const CmdResult(this.value);
  static String toCodeString(code) {
    switch (code) {
      case CmdResult.statusSuccess:
        return "succeeded";
      case CmdResult.generalFailure:
        return "general SOCKS server failure";
      case CmdResult.notAllowedByRuleSet:
        return "connection not allowed by ruleset";
      case CmdResult.networkUnreachable:
        return "network unreachable";
      case CmdResult.hostUnreachable:
        return "host unreachable";
      case CmdResult.connectionRefused:
        return "connection refused";
      case CmdResult.ttlExpired:
        return "TTL expired";
      case CmdResult.commandNotSupported:
        return "command not supported";
      case CmdResult.addressTypeNotSupported:
        return "address type not supported";
      default:
        return "unknown code: ${code}";
    }
  }
}

class Protocol {
  static encodeAuthRequest(List<AuthMethod> authMethods) {
    final buffer = <int>[];
    buffer.add(version5);
    if (authMethods.isEmpty) {
      buffer.addAll([1, AuthMethod.notRequired.value]);
    } else {
      if (authMethods.length > 255) {
        throw 'too many auth methods';
      }
      buffer.add(authMethods.length);
      for (final method in authMethods) {
        buffer.add(method.value);
      }
    }
    return buffer;
  }

  static decodeAuthResponse(List<int> buffer) {
    // length 2
    final version = buffer[0];
    final authMethod = buffer[1];
    if (version != version5) {
      throw 'auth failed: unexpected protocol version ${version}';
    } else if (authMethod == AuthMethod.noAcceptableMethods.value) {
      throw 'auth failed: no acceptable auth method';
    }
  }

  static encodeCommandRequest(String targetHost, int targetPort, Command cmd) {
    final buffer = <int>[];
    buffer.addAll([version5, cmd.value, 0]);
    final addr = InternetAddress.tryParse(targetHost);
    if (addr == null) {
      final domain = targetHost;
      if (domain.length > 255) {
        throw 'command failed: domain too long';
      }
      buffer.addAll([
        AddrType.domain.value,
        domain.length,
        ...ascii.encode(domain),
      ]);
    } else if (addr.type == InternetAddressType.IPv4) {
      buffer.add(AddrType.ipv4.value);
      buffer.addAll(addr.rawAddress);
    } else if (addr.type == InternetAddressType.IPv6) {
      buffer.add(AddrType.ipv6.value);
      buffer.addAll(addr.rawAddress);
    }
    buffer.addAll([
      (targetPort >> 8) & 0xff,
      targetPort & 0xff,
    ]);
    return buffer;
  }

  static decodeCommandResponse(List<int> buffer) {
    // length 4 + ip bytes
    final version = buffer[0];
    final cmdResult = buffer[1];
    final reserved = buffer[2];
    final addrType = buffer[3];
    if (version != version5) {
      throw 'command failed: unexpected protocol version ${version}';
    } else if (cmdResult != CmdResult.statusSuccess.value) {
      throw 'command failed: unknown error ${CmdResult.toCodeString(cmdResult)}';
    } else if (reserved != 0) {
      throw 'command failed: non-zero reserved field: ${reserved}';
    }
  }
}
