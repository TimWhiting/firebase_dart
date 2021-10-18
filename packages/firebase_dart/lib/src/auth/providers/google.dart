import '../auth_provider.dart';
import 'oauth.dart';

/// This class should be used to either create a new Google credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// GoogleAuthProvider googleProvider = GoogleAuthProvider();
/// googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
/// googleProvider.setCustomParameters({
///   'login_hint': 'user@example.com'
/// });
///
/// FirebaseAuth.instance.signInWithPopup(googleProvider)
///   .then(...);
/// ```
///
/// If authenticating with Google via a 3rd party, use the returned `accessToken`
/// to sign-in or link the user with the created credential, for example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// GoogleAuthCredential googleAuthCredential = GoogleAuthProvider.credential(accessToken: accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(googleAuthCredential)
///   .then(...);
/// ```
class GoogleAuthProvider extends OAuthProvider {
  /// Creates a new instance.
  GoogleAuthProvider() : super(PROVIDER_ID);

  /// This corresponds to the sign-in method identifier.
  static String get GOOGLE_SIGN_IN_METHOD => PROVIDER_ID;

  static const String PROVIDER_ID = 'google.com';

  /// Create a new [GoogleAuthCredential] from a provided [accessToken].
  static OAuthCredential credential({String? idToken, String? accessToken}) {
    assert(accessToken != null || idToken != null,
        'At least one of ID token and access token is required');
    return GoogleAuthCredential._(
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}

/// An [AuthCredential] for authenticating via google.com
class GoogleAuthCredential extends OAuthCredential {
  GoogleAuthCredential._(
      {required String? idToken, required String? accessToken})
      : super(
            providerId: GoogleAuthProvider.PROVIDER_ID,
            signInMethod: GoogleAuthProvider.GOOGLE_SIGN_IN_METHOD,
            accessToken: accessToken,
            idToken: idToken);
}
