import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Center PODE ser necessário aqui, dependendo do conteúdo
      child: Text(
        'Conteúdo da Lista',
        style: TextStyle(color: Colors.red, backgroundColor: Colors.yellow),
      ), //Adicionei um estilo para verificar
    );
  }
}
