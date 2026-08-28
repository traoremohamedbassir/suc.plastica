import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RapportResultats extends StatelessWidget {
  const RapportResultats({
    super.key,
    required this.title,
    required this.filterDate,
    required this.description,
  });

  final String title;
  final String description;
  final bool Function(DateTime?) filterDate;

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;

    final parts = text.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(text);
  }

  List<Map<String, dynamic>> _rowsFromDocument(
    QueryDocumentSnapshot document,
  ) {
    final data = document.data() as Map<String, dynamic>? ?? {};
    final products = data['produits'];
    if (products is! List) return [];

    return products.whereType<Map>().map((product) {
      return {
        'date': data['date']?.toString() ?? '',
        'facture': data['num_facture']?.toString() ?? '',
        'produit': product['nom_produit']?.toString() ?? '',
        'fournisseur': product['fournisseur']?.toString() ?? '',
        'quantite': product['quantite']?.toString() ?? '0',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text(title)),
       backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Rapports'),
          backgroundColor: const Color(0xFFF5F7FB),
        ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('recettes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement des recettes.'));
          }

          final rows = <Map<String, dynamic>>[];
          for (final document in snapshot.data?.docs ?? []) {
            final data = document.data() as Map<String, dynamic>? ?? {};
            if (filterDate(_parseDate(data['date']))) {
              rows.addAll(_rowsFromDocument(document));
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(description, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucune recette pour cette période.')),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      // DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Facture')),
                      DataColumn(label: Text('Produit')),
                      DataColumn(label: Text('Fournisseur')),
                      DataColumn(label: Text('Quantité')),
                    ],
                    rows: rows.map((row) {
                      return DataRow(cells: [
                        // DataCell(Text(row['date'])),
                        DataCell(Text(row['facture'])),
                        DataCell(Text(row['produit'])),
                        DataCell(Text(row['fournisseur'])),
                        DataCell(Text(row['quantite'])),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}