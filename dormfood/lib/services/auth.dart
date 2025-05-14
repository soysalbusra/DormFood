import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

User? get currentUser => _firebaseAuth.currentUser;

Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

//register
  Future<void> createUser({
    required String email,
    required String password
  })
  async{
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email, 
      password: password,
    );
  }

  //login
  Future<void> signIn({
    required String email,
    required String password
  })
  async{
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email, 
      password: password
      );
  }

  //sing out
  Future<void> signOut() async{
    await _firebaseAuth.signOut();
  }
}