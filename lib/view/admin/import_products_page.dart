// import 'package:flutter/material.dart';
// import 'package:csv/csv.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'dart:async' show Future;
// class Impot extends StatefulWidget {
//   const Impot({super.key});

//   @override
//   State<Impot> createState() => _ImpotState();
// }

// class _ImpotState extends State<Impot> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       drawer: Drawer(),
//       appbar: AppBar(
//         title: Text('Importer des produits'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: importCSV,
//           child: Text('Importer CSV'),
//         ),
//       ),
//     );
//   }
//   void importCSV() async {
//     final CollectionReference stocks = FirebaseFirestore
//     .instance.collection("stocks");
//     final myData = await rootBundle
//     .loadString('lib/assets/doc/Produits.csv');
//     List<List<dynamic>> csvTable = CsvToListConverter()
//     .convert(myData);
//     List<List<dynamic>> data= [];
//     data=csvTable;
//     for(var i=0; i<data.length; i++){
//       var record = {
//         "nom_produit": data[i][1],
//         "quantite": data[i][2],
//         "prix_achat": data[i][3],
//         "prix_vente": data[i][4],
//       };
//       stocks.add(record);
//     }
//   }
// }