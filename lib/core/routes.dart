import 'package:flutter/material.dart';

// Classes Placeholder temporárias (serão substituídas)
class MapPage extends StatelessWidget {
  const MapPage({super.key});
  @override
  Widget build(BuildContext context) => Container(color: Colors.red);
}

class ListPage extends StatelessWidget {
  const ListPage({super.key});
  @override
  Widget build(BuildContext context) => Container(color: Colors.green);
}

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});
  @override
  Widget build(BuildContext context) => Container(color: Colors.blue);
}

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(color: Colors.purple),
    );
  }
}

class AppRoutes {
  static const String map = '/map';
  static const String list = '/list';
  static const String news = '/news';
  static const String newsDetail = '/newsDetail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case map:
        return MaterialPageRoute(builder: (_) => MapPage());
      case list:
        return MaterialPageRoute(builder: (_) => ListPage());
      case news:
        return MaterialPageRoute(builder: (_) => NewsPage());
      case newsDetail:
        return MaterialPageRoute(builder: (_) => NewsDetailPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
