import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:bosque_app/core/models/arvore.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

class ExamplePopup extends StatefulWidget {
  final Marker marker;
  final List<Arvore> arvores;
  final PopupController popupController;
  final Function(BuildContext, Arvore) showDetailsBottomSheet;

  const ExamplePopup(this.marker, this.arvores, this.popupController,
      this.showDetailsBottomSheet,
      {super.key});

  @override
  State<StatefulWidget> createState() => _ExamplePopupState();
}

class _ExamplePopupState extends State<ExamplePopup> {
  final List<IconData> _icons = [
    Icons.star_border,
    Icons.star_half,
    Icons.star
  ];
  int _currentIcon = 0;

  Arvore _findArvoreById(String id) {
    return widget.arvores.firstWhere((arvore) => arvore.id.toString() == id);
  }

  @override
  Widget build(BuildContext context) {
    String arvoreId = widget.marker.key
        .toString()
        .replaceAll('[<\'', '')
        .replaceAll('\'>]', '');
    print('O id clicado foi: $arvoreId');
    Arvore arvore = _findArvoreById(arvoreId);

    return Card(
      child: InkWell(
        onTap: () => setState(() {
          _currentIcon = (_currentIcon + 1) % _icons.length;
        }),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _cardDescription(context, arvore),
          ],
        ),
      ),
    );
  }

  Widget _cardDescription(BuildContext context, Arvore arvore) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              arvore.vernacularName ?? 'Nome não consta',
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.green.shade900,
                fontSize: 18.0,
              ),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
            Text(
              arvore.calcFullName,
              style: const TextStyle(fontSize: 12.0),
            ),
            Text(
              arvore.familyName,
              style: const TextStyle(fontSize: 12.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  arvore.accession,
                  style: const TextStyle(fontSize: 12.0),
                ),
                TextButton(
                    onPressed: () {
                      //widget.popupController.hideAllPopups();
                      widget.showDetailsBottomSheet(context, arvore);
                    },
                    child: Text(
                      'DETALHES',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.blue.shade600,
                      ),
                    ))
              ],
            )
          ],
        ),
      ),
    );
  }
}
