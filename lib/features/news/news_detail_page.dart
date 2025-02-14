import 'package:flutter/material.dart';

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key});

  // Exemplo de como receber um argumento (se necessário):
  // final int newsId;
  // const NewsDetailPage({Key? key, required this.newsId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Com Scaffold!
      appBar: AppBar(title: Text('Detalhes da Notícia')),
      body: Center(
        child: Text('Conteúdo da notícia...'),
      ),
    );
  }
}
