class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: json['expiresIn']?.toString() ?? '',
    );
  }

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}

class AuthUser {
  final String id;
  final String? email;
  final String nickname;
  final String? avatar;
  final String? role;

  const AuthUser({
    required this.id,
    required this.nickname,
    this.email,
    this.avatar,
    this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      nickname: json['nickname']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatar': avatar,
        'role': role,
      };

  String get displayName => nickname.isNotEmpty ? nickname : (email ?? '');
}

class PendingPurchaseVerify {
  final String productId;
  final String transactionId;
  final String platform;
  final String? receiptData;

  const PendingPurchaseVerify({
    required this.productId,
    required this.transactionId,
    required this.platform,
    this.receiptData,
  });

  factory PendingPurchaseVerify.fromJson(Map<String, dynamic> json) {
    return PendingPurchaseVerify(
      productId: json['productId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      platform: json['platform']?.toString() ?? 'ANDROID',
      receiptData: json['receiptData']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'transactionId': transactionId,
        'platform': platform,
        if (receiptData != null && receiptData!.isNotEmpty) 'receiptData': receiptData,
      };
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 400;

  @override
  String toString() => message;
}
