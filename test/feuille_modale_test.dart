import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yay360_mobile/widgets/common.dart';

void main() {
  testWidgets('FeuilleModale affiche son contenu dans une zone défilante', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FeuilleModale(children: [Text('Titre du formulaire'), Text('Champ')]),
      ),
    ));

    expect(find.text('Titre du formulaire'), findsOneWidget);
    expect(find.text('Champ'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
