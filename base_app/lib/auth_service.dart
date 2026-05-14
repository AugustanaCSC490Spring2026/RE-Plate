import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// credits to @MahdiNazmi for source code

class AuthService {
  void showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  Future<void> signup({
    required String username,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final userUsername = username.trim().toLowerCase();
      final userEmail = email.trim();

      // Checks if username already exists
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: userUsername)
          .limit(1)
          .get();

      // if the username is already taken
      if (existingUser.docs.isNotEmpty) {
        showErrorMessage('That username is already taken.');
        return;
      }

      // creates an account with email and password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: userEmail, password: password);

      // added this line to display username in sidebar
      await userCredential.user!.updateDisplayName(userUsername);

      // saves the user's uid
      String uid = userCredential.user!.uid;

      // saves the user's username into the account
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': userUsername,
        'email': userEmail,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      //await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      } else {
        message = 'Signup failed. Please try again.';
      }
      showErrorMessage(message);
    } catch (e) {
      showErrorMessage('Something went wrong. Please try again.');
    }
  }

  Future<void> signIn({
    required String emailOrUsername,
    required String password,
    required BuildContext context,
  }) async {
    try {
      String loginCredential = emailOrUsername.trim();

      // If input doesn't contain '@', it treated as a username
      if (!loginCredential.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: loginCredential.toLowerCase())
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          showErrorMessage('No user found with that username.');

          return;
        }

        // get the email linked to that username
        loginCredential = query.docs.first.data()['email'] as String;
      }
      // account sign in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginCredential,
        password: password,
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user.';
      } else {
        message = 'Sign in failed. Please try again.';
      }
      showErrorMessage(message);
    } catch (e) {
      showErrorMessage('Something went wrong. Please try again.');
    }
  }

  Future<void> signout({required BuildContext context}) async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => Login()),
    );
  }
}
