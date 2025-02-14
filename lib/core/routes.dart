import 'package:flutter/material.dart';
import 'package:bosque_app/features/map/map_page.dart';
import 'package:bosque_app/features/list/list_page.dart';
import 'package:bosque_app/features/news/news_page.dart';
import 'package:bosque_app/features/news/news_detail_page.dart';

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