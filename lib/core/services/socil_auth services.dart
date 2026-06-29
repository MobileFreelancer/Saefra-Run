import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<UserCredential?> signIn() async {
    try {
      final GoogleSignInAccount? account =
      await _googleSignIn.signIn();

      if (account == null) return null;

      final auth = await account.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      return await _auth.signInWithCredential(
        credential,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}