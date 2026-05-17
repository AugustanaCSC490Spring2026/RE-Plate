import 'package:base_app/pages/signup.dart';
import 'package:base_app/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatelessWidget {
  Login({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color background = Color.fromARGB(255, 222, 209, 182);
  static const Color maroon = Color(0xFF670E10);
  static const Color softMaroon = Color.fromARGB(255, 117, 52, 61);
  static const Color sage = Color.fromARGB(255, 126, 153, 120);
  static const Color inputFill = Color.fromARGB(255, 247, 245, 241);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/images/replateLogo1.png',
                    height: 250,
                  ),

                  const SizedBox(height: 0),

                  Text(
                    'Welcome to RE-Plate!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                      color: maroon,
                      fontWeight: FontWeight.w800,
                      fontSize: 44,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to Start Cooking',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.raleway(
                      color: softMaroon,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 48),

                  _emailAddress(),

                  const SizedBox(height: 22),

                  _password(context),

                  const SizedBox(height: 32),

                  _signin(context),

                  const SizedBox(height: 28),

                  _signup(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Username or Email'),
        const SizedBox(height: 10),
        _inputField(
          controller: _emailController,
          hintText: 'Enter your username or email',
          icon: Icons.person_outline_rounded,
        ),
      ],
    );
  }

  Widget _password(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Password'),
        const SizedBox(height: 10),
        _inputField(
          controller: _passwordController,
          hintText: 'Enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
          onSubmitted: (_) async {
            await AuthService().signIn(
              emailOrUsername: _emailController.text,
              password: _passwordController.text,
              context: context,
            );
          },
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.raleway(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      style: GoogleFonts.raleway(
        color: Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: softMaroon),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
        filled: true,
        fillColor: inputFill,
        hintText: hintText,
        hintStyle: GoogleFonts.raleway(
          color: const Color(0xff9A9A9A),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffEFE7DD), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: sage, width: 1.6),
        ),
      ),
    );
  }

  Widget _signin(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: sage,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size(double.infinity, 60),
        elevation: 0,
      ),
      onPressed: () async {
        await AuthService().signIn(
          emailOrUsername: _emailController.text,
          password: _passwordController.text,
          context: context,
        );
      },
      child: Text(
        "Sign In",
        style: GoogleFonts.raleway(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _signup(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.raleway(),
        children: [
          const TextSpan(
            text: "New User? ",
            style: TextStyle(
              color: softMaroon,
              fontWeight: FontWeight.w500,
              fontSize: 17,
            ),
          ),
          TextSpan(
            text: "Create Account",
            style: const TextStyle(
              color: sage,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Signup()),
                );
              },
          ),
        ],
      ),
    );
  }
}
