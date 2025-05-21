import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSearch; // Thay đổi thành void Function(String)
  final String hintText; // Thêm tham số hintText

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onSearch,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (value) => onSearch(value), // Gọi onSearch với giá trị nhập
        decoration: InputDecoration(
          hintText: hintText, // Sử dụng hintText từ tham số
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => controller.clear(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }
}