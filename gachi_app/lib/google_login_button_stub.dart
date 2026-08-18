import 'package:flutter/material.dart';

Widget buildGoogleLoginButton({required VoidCallback onPressed}) =>
    OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff14161B),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xffD9DEE8)),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Text(
        'G',
        style: TextStyle(
          color: Color(0xff4285F4),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      label: const Text('Google로 계속하기'),
    );
