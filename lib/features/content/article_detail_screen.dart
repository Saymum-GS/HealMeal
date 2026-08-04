import 'package:flutter/material.dart';
import '../../core/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, this.slug});

  final String? slug;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HealMealAppBar(title: 'ArticleDetail', showBack: true),
      body: Center(
        child: Text(
          'ArticleDetailScreen is under construction.',
          style: TextStyle(fontSize: 18.sp, color: Colors.grey),
        ),
      ),
    );
  }
}
