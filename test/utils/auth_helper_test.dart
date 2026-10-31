import 'package:disclosure_app_fl/utils/auth_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// テスト用の GoogleSignInPlatform モック実装
class FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  AuthenticationResults? lightweightResult;
  bool throwOnLightweight = false;

  AuthenticationResults? authenticateResult;
  bool throwOnAuthenticate = false;

  InitParameters? lastInitParameters;

  @override
  Future<void> init(InitParameters params) async {
    lastInitParameters = params;
  }

  @override
  Future<AuthenticationResults?> attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) async {
    if (throwOnLightweight) {
      throw Exception('Network error during lightweight auth');
    }
    return lightweightResult;
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    if (throwOnAuthenticate) {
      throw Exception('User cancelled sign in');
    }
    if (authenticateResult != null) {
      return authenticateResult!;
    }
    throw StateError('authenticateResult is not set');
  }

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async =>
      null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async =>
      null;

  @override
  Future<void> clearAuthorizationToken(
    ClearAuthorizationTokenParams params,
  ) async {}

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGoogleSignInPlatform fakePlatform;

  const testUser = GoogleSignInUserData(
    email: 'test@example.com',
    id: 'user_123',
    displayName: 'Test User',
  );

  const testTokens = AuthenticationTokenData(
    idToken: 'sample_id_token_xyz',
  );

  const testAuthResults = AuthenticationResults(
    user: testUser,
    authenticationTokens: testTokens,
  );

  setUp(() async {
    fakePlatform = FakeGoogleSignInPlatform();
    GoogleSignInPlatform.instance = fakePlatform;
    await GoogleSignIn.instance.initialize();
  });

  group('AuthHelper static methods', () {
    test('createGoogleCredential generates GoogleAuthCredential with idToken',
        () {
      final credential =
          AuthHelper.createGoogleCredential(idToken: 'test_token');
      expect(credential, isA<OAuthCredential>());
      expect(credential.signInMethod, equals('google.com'));
    });

    test('hasGoogleProvider correctly identifies google.com presence', () {
      expect(
        AuthHelper.hasGoogleProvider(['google.com', 'password']),
        isTrue,
      );
      expect(
        AuthHelper.hasGoogleProvider(['password']),
        isFalse,
      );
      expect(
        AuthHelper.hasGoogleProvider([]),
        isFalse,
      );
    });
  });

  group('AuthHelper.initializeAuth', () {
    test(
        'calls onSignInWithCredential with correct idToken when lightweight auth succeeds',
        () async {
      fakePlatform.lightweightResult = testAuthResults;

      AuthCredential? capturedCredential;
      bool anonymousCalled = false;

      final helper = AuthHelper();
      await helper.initializeAuth(
        onSignInWithCredential: (cred) async {
          capturedCredential = cred;
        },
        onSignInAnonymously: () async {
          anonymousCalled = true;
        },
      );

      expect(anonymousCalled, isFalse);
      expect(capturedCredential, isNotNull);
      expect(capturedCredential?.signInMethod, equals('google.com'));
    });

    test(
        'calls onSignInAnonymously when lightweight auth returns null (not signed in)',
        () async {
      fakePlatform.lightweightResult = null;

      AuthCredential? capturedCredential;
      bool anonymousCalled = false;

      final helper = AuthHelper();
      await helper.initializeAuth(
        onSignInWithCredential: (cred) async {
          capturedCredential = cred;
        },
        onSignInAnonymously: () async {
          anonymousCalled = true;
        },
      );

      expect(anonymousCalled, isTrue);
      expect(capturedCredential, isNull);
    });

    test(
        'catches error and falls back to onSignInAnonymously when lightweight auth throws',
        () async {
      fakePlatform.throwOnLightweight = true;

      AuthCredential? capturedCredential;
      bool anonymousCalled = false;

      final helper = AuthHelper();
      await helper.initializeAuth(
        onSignInWithCredential: (cred) async {
          capturedCredential = cred;
        },
        onSignInAnonymously: () async {
          anonymousCalled = true;
        },
      );

      expect(anonymousCalled, isTrue);
      expect(capturedCredential, isNull);
    });
  });

  group('AuthHelper.handleGoogleSignIn', () {
    test(
        'signs in with credential when provider list contains google.com (existing account)',
        () async {
      fakePlatform.authenticateResult = testAuthResults;

      String? fetchedEmail;
      AuthCredential? signInCred;
      AuthCredential? linkCred;
      bool reloaded = false;

      final helper = AuthHelper();
      final result = await helper.handleGoogleSignIn(
        onFetchSignInMethods: (email) async {
          fetchedEmail = email;
          return ['google.com'];
        },
        onSignInWithCredential: (cred) async {
          signInCred = cred;
          return null;
        },
        onLinkWithCredential: (cred) async {
          linkCred = cred;
          return null;
        },
        onReloadUser: (user) async {
          reloaded = true;
        },
      );

      expect(fetchedEmail, equals('test@example.com'));
      expect(signInCred, isNotNull);
      expect(linkCred, isNull);
      expect(reloaded, isFalse); // null user returned in test callback
      expect(result, isNull);
    });

    test(
        'links with credential when provider list does not contain google.com (new link)',
        () async {
      fakePlatform.authenticateResult = testAuthResults;

      String? fetchedEmail;
      AuthCredential? signInCred;
      AuthCredential? linkCred;

      final helper = AuthHelper();
      await helper.handleGoogleSignIn(
        onFetchSignInMethods: (email) async {
          fetchedEmail = email;
          return ['password'];
        },
        onSignInWithCredential: (cred) async {
          signInCred = cred;
          return null;
        },
        onLinkWithCredential: (cred) async {
          linkCred = cred;
          return null;
        },
      );

      expect(fetchedEmail, equals('test@example.com'));
      expect(signInCred, isNull);
      expect(linkCred, isNotNull);
    });

    test('returns null and does not throw when authenticate fails/cancels',
        () async {
      fakePlatform.throwOnAuthenticate = true;

      bool signInCalled = false;
      bool linkCalled = false;

      final helper = AuthHelper();
      final result = await helper.handleGoogleSignIn(
        onSignInWithCredential: (cred) async {
          signInCalled = true;
          return null;
        },
        onLinkWithCredential: (cred) async {
          linkCalled = true;
          return null;
        },
      );

      expect(result, isNull);
      expect(signInCalled, isFalse);
      expect(linkCalled, isFalse);
    });
  });
}
