import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth_bloc.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _signup() {
    context.read<AuthBloc>().add(
      SignupRequested(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        if (state is AuthSignupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFF35B8FF),
            ),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
                (route) => false,
          );
        }
      },
      builder: (context, state) {
        final bool isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF050505),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF35B8FF).withOpacity(0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF35B8FF).withOpacity(0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF35B8FF),
                        size: 52,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Sign up to plan trips with weather forecast',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 42),

                    _AuthTextField(
                      controller: nameController,
                      hintText: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                    ),

                    const SizedBox(height: 16),

                    _AuthTextField(
                      controller: emailController,
                      hintText: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    _AuthTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF35B8FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          const Color(0xFF35B8FF).withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                            : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                              (route) => false,
                        );
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: TextStyle(
                                color: Color(0xFF35B8FF),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF2E3B59),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: const Color(0xFF35B8FF),
          decoration: InputDecoration(
            filled: false,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF9CA3AF),
              size: 22,
            ),
            suffixIcon: suffixIcon,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 19,
            ),
          ),
        ),
      ),
    );
  }
}