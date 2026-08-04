import 'package:flutter/material.dart';
import '../../core/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArticleListScreen extends StatelessWidget {
  const ArticleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'ArticleList', showBack: true),
      body: Center(
        child: Text(
          'ArticleListScreen is under construction.',
          style: TextStyle(fontSize: 18.sp, color: Colors.grey),
        ),
      ),
    );
  }
}
