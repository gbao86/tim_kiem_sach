import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy màu primary từ theme hiện tại của hệ thống
    final primaryColor = Theme
        .of(context)
        .primaryColor;

    return Center(
      child: CircularProgressIndicator(
        // Tự động đổi màu theo Theme
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        strokeWidth: 3,
      ),
    );
  }
}