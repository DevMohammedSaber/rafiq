import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

import '../cubit/auth_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Branding
                  Icon(
                    Icons.mosque,
                    size: 100,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "auth.login_title".tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Google Sign In
                  _SocialButton(
                    text: "auth.continue_google".tr(),
                    icon: FontAwesomeIcons.google,
                    color: Colors.red,
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<AuthCubit>().signInWithGoogle();
                          },
                  ),
                  const SizedBox(height: 16),

                  // Apple Sign In (iOS only)
                  if (Platform.isIOS) ...[
                    _SocialButton(
                      text: "auth.continue_apple".tr(),
                      icon: FontAwesomeIcons.apple,
                      color: Colors.black,
                      isLoading: isLoading,
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().signInWithApple();
                            },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Guest Mode
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.read<AuthCubit>().continueAsGuest();
                          },
                    child: Text(
                      "auth.continue_guest".tr(),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SocialButton({
    required this.text,
    required this.icon,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isLoading ? color.withValues(alpha: 0.7) : color,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
