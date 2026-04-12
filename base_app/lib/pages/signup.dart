import 'package:base_app/pages/login.dart';
import 'package:base_app/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// credits to @MahdiNazmi for source code
// github link:

class Signup extends StatelessWidget {
  Signup({super.key});
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _signin(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Register Account',
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _username(),
              const SizedBox(height: 20),
              _emailAddress(),
              const SizedBox(height: 20),
              _password(context),
              const SizedBox(height: 50),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _username() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            filled: true,
            hintText: 'Enter your username',
            hintStyle: const TextStyle(
              color: Color(0xff6A6A6A),
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            fillColor: const Color(0xffF7F7F9),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        )
      ],
    );
  }

  Widget _emailAddress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            filled: true,
            hintText: 'test@email.com',
            hintStyle: const TextStyle(
              color: Color(0xff6A6A6A),
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            fillColor: const Color(0xffF7F7F9),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        )
      ],
    );
  }
Widget _password(BuildContext context) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Password',
        style: GoogleFonts.raleway(
          textStyle: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.normal,
            fontSize: 16
          )
        ),
      ),
      const SizedBox(height: 16,),
      TextField(
        obscureText: true,
        controller: _passwordController,
        onSubmitted: (_) async {       
          await AuthService().signin(
            emailOrUsername: _emailController.text,
            password: _passwordController.text,
            context: context,
          );
        },
        decoration: InputDecoration(
          filled: true,
          hintText: 'Enter a secure password',
          hintStyle: const TextStyle(
            color: Color(0xff6A6A6A),
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          fillColor: const Color(0xffF7F7F9),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14)
          )
        ),
      )
    ],
  );
}
  Widget _signup(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 13, 253, 153),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size(double.infinity, 60),
        elevation: 0,
      ),
      onPressed: () async {
        await AuthService().signup(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          context: context,
        );
      },
      child: const Text("Sign Up"),
    );
  }

  Widget _signin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: "Already Have Account? ",
              style: TextStyle(
                color: Color(0xff6A6A6A),
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: "Log In",
              style: const TextStyle(
                color: Color(0xff1A1D1E),
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Login(),
                    ),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}