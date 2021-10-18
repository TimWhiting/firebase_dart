import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/auth/rpc/error.dart';
import 'package:firebase_dart/src/auth/rpc/identitytoolkit.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';

class BackendConnection {
  final AuthBackend backend;

  BackendConnection(this.backend);

  Future<GetAccountInfoResponse> getAccountInfo(
      IdentitytoolkitRelyingpartyGetAccountInfoRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    return GetAccountInfoResponse()
      ..kind = 'identitytoolkit#GetAccountInfoResponse'
      ..users = [user];
  }

  Future<SignupNewUserResponse> signupNewUser(
      IdentitytoolkitRelyingpartySignupNewUserRequest request) async {
    var user = await backend.createUser(
      email: request.email,
      password: request.password,
    );

    var provider = request.email == null ? 'anonymous' : 'password';

    var idToken =
        await backend.generateIdToken(uid: user.localId, providerId: provider);
    var refreshToken = await backend.generateRefreshToken(idToken);

    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return SignupNewUserResponse()
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..kind = 'identitytoolkit#SignupNewUserResponse'
      ..idToken = idToken
      ..refreshToken = refreshToken;
  }

  Future<VerifyPasswordResponse> verifyPassword(
      IdentitytoolkitRelyingpartyVerifyPasswordRequest request) async {
    var email = request.email;
    if (email == null) {
      throw ArgumentError('Invalid request: missing email');
    }
    var user = await backend.getUserByEmail(email);

    if (user.rawPassword == request.password) {
      var idToken = request.returnSecureToken == true
          ? await backend.generateIdToken(
              uid: user.localId, providerId: 'password')
          : null;
      var refreshToken =
          idToken == null ? null : await backend.generateRefreshToken(idToken);
      var tokenExpiresIn = await backend.getTokenExpiresIn();
      return VerifyPasswordResponse()
        ..kind = 'identitytoolkit#VerifyPasswordResponse'
        ..localId = user.localId
        ..idToken = idToken
        ..expiresIn = '${tokenExpiresIn.inSeconds}'
        ..refreshToken = refreshToken;
    }

    throw FirebaseAuthException.invalidPassword();
  }

  Future<CreateAuthUriResponse> createAuthUri(
      IdentitytoolkitRelyingpartyCreateAuthUriRequest request) async {
    var email = request.identifier;
    if (email == null) {
      throw ArgumentError('Invalid request: missing identifier');
    }
    var user = await backend.getUserByEmail(email);

    return CreateAuthUriResponse()
      ..kind = 'identitytoolkit#CreateAuthUriResponse'
      ..allProviders = [for (var p in user.providerUserInfo!) p.providerId!]
      ..signinMethods = [for (var p in user.providerUserInfo!) p.providerId!];
  }

  Future<VerifyCustomTokenResponse> verifyCustomToken(
      IdentitytoolkitRelyingpartyVerifyCustomTokenRequest request) async {
    var user = await _userFromIdToken(request.token!);

    var idToken = request.returnSecureToken == true
        ? await backend.generateIdToken(uid: user.localId, providerId: 'custom')
        : null;
    var refreshToken =
        idToken == null ? null : await backend.generateRefreshToken(idToken);
    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return VerifyCustomTokenResponse()
      ..idToken = idToken
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..refreshToken = refreshToken;
  }

  Future<DeleteAccountResponse> deleteAccount(
      IdentitytoolkitRelyingpartyDeleteAccountRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    await backend.deleteUser(user.localId);
    return DeleteAccountResponse()
      ..kind = 'identitytoolkit#DeleteAccountResponse';
  }

  Future<BackendUser> _userFromIdToken(String idToken) async {
    var jwt = JsonWebToken.unverified(idToken); // TODO verify
    var uid = jwt.claims['uid'] ?? jwt.claims.subject;
    if (uid == null) {
      throw ArgumentError('Invalid id token (${jwt.claims}): no subject');
    }
    var user = await backend.getUserById(uid);

    return user;
  }

  Future<GetOobConfirmationCodeResponse> getOobConfirmationCode(
      Relyingparty request) async {
    var idToken = request.idToken;
    var email = request.email;
    var user = idToken != null
        ? await _userFromIdToken(idToken)
        : email != null
            ? await backend.getUserByEmail(email)
            : throw ArgumentError('Invalid request: missing idToken or email');
    return GetOobConfirmationCodeResponse()
      ..kind = 'identitytoolkit#GetOobConfirmationCodeResponse'
      ..email = user.email;
  }

  Future<ResetPasswordResponse> resetPassword(
      IdentitytoolkitRelyingpartyResetPasswordRequest request) async {
    try {
      var jwt = JsonWebToken.unverified(request.oobCode!);
      var user = await backend.getUserById(jwt.claims['sub']);
      await backend.updateUser(user..rawPassword = request.newPassword);
      return ResetPasswordResponse()
        ..kind = 'identitytoolkit#ResetPasswordResponse'
        ..requestType = jwt.claims['operation']
        ..email = user.email;
    } on ArgumentError {
      throw FirebaseAuthException.invalidOobCode();
    }
  }

  Future<SetAccountInfoResponse> setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest request) async {
    BackendUser user;
    try {
      user = await _userFromIdToken(request.idToken ?? request.oobCode!);
    } on ArgumentError {
      if (request.oobCode != null) {
        throw FirebaseAuthException.invalidOobCode();
      }
      rethrow;
    }
    if (request.deleteProvider != null) {
      user.providerUserInfo!.removeWhere(
          (element) => request.deleteProvider!.contains(element.providerId));
      if (request.deleteProvider!.contains('phone')) {
        user.phoneNumber = null;
      }
    }
    if (request.displayName != null) {
      user.displayName = request.displayName;
    }
    if (request.photoUrl != null) {
      user.photoUrl = request.photoUrl;
    }
    if (request.deleteAttribute != null) {
      for (var a in request.deleteAttribute!) {
        switch (a) {
          case 'displayName':
            user.displayName = null;
            break;
          case 'photoUrl':
            user.photoUrl = null;
            break;
        }
      }
    }
    if (request.email != null) {
      user.email = request.email;
      user.emailVerified = false;
    }

    await backend.updateUser(user);

    return SetAccountInfoResponse()
      ..kind = 'identitytoolkit#SetAccountInfoResponse'
      ..displayName = user.displayName
      ..photoUrl = user.photoUrl
      ..email = user.email
      ..idToken = request.returnSecureToken == true
          ? await backend.generateIdToken(
              uid: user.localId, providerId: 'password')
          : null
      ..providerUserInfo = [
        for (var u in user.providerUserInfo!)
          SetAccountInfoResponseProviderUserInfo()
            ..providerId = u.providerId
            ..photoUrl = u.photoUrl
            ..displayName = u.displayName
      ];
  }

  Future<IdentitytoolkitRelyingpartySendVerificationCodeResponse>
      sendVerificationCode(
          IdentitytoolkitRelyingpartySendVerificationCodeRequest
              request) async {
    var phoneNumber = request.phoneNumber;
    if (phoneNumber == null) {
      throw ArgumentError('Invalid request: missing phoneNumber');
    }
    var token = await backend.sendVerificationCode(phoneNumber);
    return IdentitytoolkitRelyingpartySendVerificationCodeResponse()
      ..sessionInfo = token;
  }

  Future<IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse>
      verifyPhoneNumber(
          IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest request) async {
    var sessionInfo = request.sessionInfo;
    if (sessionInfo == null) {
      throw ArgumentError('Invalid request: missing sessionInfo');
    }
    var code = request.code;
    if (code == null) {
      throw ArgumentError('Invalid request: missing code');
    }
    var user = await backend.verifyPhoneNumber(sessionInfo, code);

    var idToken = await backend.generateIdToken(
        uid: user.localId, providerId: 'password');
    var refreshToken = await backend.generateRefreshToken(idToken);
    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse()
      ..localId = user.localId
      ..idToken = idToken
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..refreshToken = refreshToken;
  }

  Future<VerifyAssertionResponse> verifyAssertion(
      IdentitytoolkitRelyingpartyVerifyAssertionRequest request) async {
    var args = Uri.parse('?${request.postBody}').queryParameters;
    try {
      var user =
          await backend.verifyAssertion(args['providerId']!, args['id_token']!);
      var idToken = await backend.generateIdToken(
          uid: user.localId, providerId: 'password');
      var refreshToken = await backend.generateRefreshToken(idToken);
      var tokenExpiresIn = await backend.getTokenExpiresIn();
      return VerifyAssertionResponse()
        ..localId = user.localId
        ..idToken = idToken
        ..expiresIn = '${tokenExpiresIn.inSeconds}'
        ..refreshToken = refreshToken;
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthException.needConfirmation().code) {
        return VerifyAssertionResponse()..needConfirmation = true;
      }
      rethrow;
    }
  }

  Future<EmailLinkSigninResponse> emailLinkSignin(
      IdentitytoolkitRelyingpartyEmailLinkSigninRequest request) async {
    var email = request.email;
    if (email == null) {
      throw ArgumentError('Invalid request: missing email');
    }

    var jwt = JsonWebToken.unverified(request.oobCode!);
    var user = await backend.getUserById(jwt.claims['sub']);

    var idToken = request.returnSecureToken == true
        ? await backend.generateIdToken(
            uid: user.localId, providerId: 'password')
        : null;
    var refreshToken =
        idToken == null ? null : await backend.generateRefreshToken(idToken);
    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return EmailLinkSigninResponse()
      ..kind = 'identitytoolkit#EmailLinkSigninResponse'
      ..localId = user.localId
      ..idToken = idToken
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..refreshToken = refreshToken;
  }

  Future<dynamic> _handle(String method, dynamic body) async {
    switch (method) {
      case 'signupNewUser':
        var request =
            IdentitytoolkitRelyingpartySignupNewUserRequest.fromJson(body);
        return signupNewUser(request);
      case 'getAccountInfo':
        var request =
            IdentitytoolkitRelyingpartyGetAccountInfoRequest.fromJson(body);
        return getAccountInfo(request);
      case 'verifyPassword':
        var request =
            IdentitytoolkitRelyingpartyVerifyPasswordRequest.fromJson(body);
        return verifyPassword(request);
      case 'createAuthUri':
        var request =
            IdentitytoolkitRelyingpartyCreateAuthUriRequest.fromJson(body);
        return createAuthUri(request);
      case 'verifyCustomToken':
        var request =
            IdentitytoolkitRelyingpartyVerifyCustomTokenRequest.fromJson(body);
        return verifyCustomToken(request);
      case 'deleteAccount':
        var request =
            IdentitytoolkitRelyingpartyDeleteAccountRequest.fromJson(body);
        return deleteAccount(request);
      case 'getOobConfirmationCode':
        var request = Relyingparty.fromJson(body);
        return getOobConfirmationCode(request);
      case 'resetPassword':
        var request =
            IdentitytoolkitRelyingpartyResetPasswordRequest.fromJson(body);
        return resetPassword(request);
      case 'setAccountInfo':
        var request =
            IdentitytoolkitRelyingpartySetAccountInfoRequest.fromJson(body);
        return setAccountInfo(request);
      case 'sendVerificationCode':
        var request =
            IdentitytoolkitRelyingpartySendVerificationCodeRequest.fromJson(
                body);
        return sendVerificationCode(request);
      case 'verifyPhoneNumber':
        var request =
            IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest.fromJson(body);
        return verifyPhoneNumber(request);
      case 'verifyAssertion':
        var request =
            IdentitytoolkitRelyingpartyVerifyAssertionRequest.fromJson(body);
        return verifyAssertion(request);
      case 'emailLinkSignin':
        var request =
            IdentitytoolkitRelyingpartyEmailLinkSigninRequest.fromJson(body);
        return emailLinkSignin(request);
      default:
        throw UnsupportedError('Unsupported method $method');
    }
  }

  Future<http.Response> handleRequest(http.Request request) async {
    var method = request.url.pathSegments.last;

    var body = json.decode(request.body);

    try {
      return http.Response(json.encode(await _handle(method, body)), 200,
          headers: {'content-type': 'application/json'});
    } on FirebaseAuthException catch (e) {
      return http.Response(json.encode(errorToServerResponse(e)), 400,
          headers: {'content-type': 'application/json'});
    }
  }
}

abstract class AuthBackend {
  Future<BackendUser> getUserById(String uid);

  Future<BackendUser> getUserByEmail(String email);

  Future<BackendUser> getUserByPhoneNumber(String phoneNumber);

  Future<BackendUser> getUserByProvider(String providerId, String rawId);

  Future<BackendUser> createUser(
      {required String? email, required String? password});

  Future<BackendUser> updateUser(BackendUser user);

  Future<void> deleteUser(String uid);

  Future<String> generateIdToken(
      {required String uid, required String providerId});

  Future<String> generateRefreshToken(String idToken);

  Future<String> verifyRefreshToken(String token);

  Future<String> sendVerificationCode(String phoneNumber);

  Future<BackendUser> verifyPhoneNumber(String sessionInfo, String code);

  Future<BackendUser> verifyAssertion(String providerId, String idToken);

  Future<BackendUser> storeUser(BackendUser user);

  Future<String?> receiveSmsCode(String phoneNumber);

  Future<void> setTokenGenerationSettings(
      {Duration? tokenExpiresIn, JsonWebKey? tokenSigningKey});

  Future<JsonWebKey> getTokenSigningKey();

  Future<Duration> getTokenExpiresIn();

  Future<String?> createActionCode(String operation, String email);
}

abstract class BaseBackend extends AuthBackend {
  final String projectId;

  BaseBackend({required this.projectId});

  @override
  Future<BackendUser> createUser(
      {required String? email, required String? password}) async {
    var uid = _generateRandomString(24);
    var now = (clock.now().millisecondsSinceEpoch ~/ 1000).toString();
    return storeUser(BackendUser(uid)
      ..createdAt = now
      ..lastLoginAt = now
      ..email = email
      ..rawPassword = password
      ..providerUserInfo = [
        if (password != null)
          UserInfoProviderUserInfo()
            ..providerId = 'password'
            ..email = email
      ]);
  }

  @override
  Future<BackendUser> updateUser(BackendUser user) {
    return storeUser(user);
  }

  @override
  Future<String> generateIdToken(
      {required String uid, required String providerId}) async {
    var tokenSigningKey = await getTokenSigningKey();
    var user = await getUserById(uid);
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = await _jwtPayloadFor(user, providerId)
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<String> generateRefreshToken(String idToken) async {
    var tokenSigningKey = await getTokenSigningKey();
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = idToken
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<String> verifyRefreshToken(String token) async {
    var tokenSigningKey = await getTokenSigningKey();
    var store = JsonWebKeyStore()..addKey(tokenSigningKey);
    var jws = JsonWebSignature.fromCompactSerialization(token);
    var payload = await jws.getPayload(store);
    return payload.jsonContent!;
  }

  @override
  Future<String?> createActionCode(String operation, String email) async {
    var user = await getUserByEmail(email);

    var tokenSigningKey = await getTokenSigningKey();
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = {'sub': user.localId, 'operation': operation}
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  static final _random = Random(DateTime.now().millisecondsSinceEpoch);

  static String _generateRandomString(int length) {
    var chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    return Iterable.generate(
        length, (i) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<Map<String, dynamic>> _jwtPayloadFor(
      BackendUser user, String providerId) async {
    var now = clock.now().millisecondsSinceEpoch ~/ 1000;
    var tokenExpiration = await getTokenExpiresIn();
    return {
      'iss': 'https://securetoken.google.com/$projectId',
      'provider_id': providerId,
      'aud': '$projectId',
      'auth_time': now,
      'sub': user.localId,
      'iat': now,
      'exp': now + tokenExpiration.inSeconds,
      'random': Random().nextDouble(),
      'email': user.email,
      if (providerId == 'anonymous')
        'firebase': {'identities': {}, 'sign_in_provider': 'anonymous'},
      if (providerId == 'password')
        'firebase': {
          'identities': {
            'email': [user.email]
          },
          'sign_in_provider': 'password'
        }
    };
  }
}

class BackendUser extends UserInfo {
  BackendUser(String localId) {
    this.localId = localId;
  }

  @override
  String get localId => super.localId!;
}
