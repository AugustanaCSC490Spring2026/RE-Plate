import 'package:base_app/pages/signup.dart';
import 'package:base_app/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _signup(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        leadingWidth: 72,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xffF7F7F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xffECECEC),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 18,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome back!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          color: Color(0xff4CAF50),
                          fontWeight: FontWeight.w700,
                          fontSize: 34,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to continue to your account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                          color: Color(0xff8A8A8A),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
              _emailAddress(),
              const SizedBox(height: 24),
              _password(context),
              const SizedBox(height: 36),
              _signin(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username or Email',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xff8A8A8A),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
            filled: true,
            hintText: 'Enter your username or email',
            hintStyle: GoogleFonts.raleway(
              textStyle: const TextStyle(
                color: Color(0xff9A9A9A),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            fillColor: const Color(0xffF7F7F9),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xffEEEEEE),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xff4CAF50),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _password(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          obscureText: true,
          controller: _passwordController,
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          onSubmitted: (_) async {
            await AuthService().signin(
              emailOrUsername: _emailController.text,
              password: _passwordController.text,
              context: context,
            );
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xff8A8A8A),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
            filled: true,
            hintText: 'Enter your password',
            hintStyle: GoogleFonts.raleway(
              textStyle: const TextStyle(
                color: Color(0xff9A9A9A),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            fillColor: const Color(0xffF7F7F9),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xffEEEEEE),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xff4CAF50),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signin(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 13, 253, 173),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        minimumSize: const Size(double.infinity, 62),
        elevation: 0,
      ),
      onPressed: () async {
        await AuthService().signin(
          emailOrUsername: _emailController.text,
          password: _passwordController.text,
          context: context,
        );
      },
      child: Text(
        "Sign In",
        style: GoogleFonts.raleway(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _signup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28, left: 16, right: 16, top: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.raleway(),
          children: [
            const TextSpan(
              text: "New User? ",
              style: TextStyle(
                color: Color(0xff8A8A8A),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: "Create Account",
              style: const TextStyle(
                color: Color(0xff1A1D1E),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Signup(),
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