import 'package:flutter/material.dart';
import 'package:bosque_app/core/routes.dart';
import 'package:bosque_app/features/news/widgets/news_item.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Sem Scaffold
      itemCount: 10,
      itemBuilder: (context, index) {
        return NewsItem(
          title: 'Notícia $index',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.newsDetail);
          },
        );
      },
    );
  }
}
