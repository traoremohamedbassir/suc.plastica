import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plastica_suc/view/admin/recette_calcul.dart';


class RecetteEmp extends StatefulWidget {
  const RecetteEmp({super.key});

  @override
  State<RecetteEmp> createState() => _RecetteEmpState();
}

class _RecetteEmpState extends State<RecetteEmp> {
  final CollectionReference _recette = FirebaseFirestore.instance.collection(
    "recettes",
  );
  final CollectionReference _depenses = FirebaseFirestore.instance.collection(
    "depenses",
  );

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;

    final cleaned = value.trim();
    final patterns = ['dd/MM/yyyy', 'dd/MM/yy', 'yyyy-MM-dd', 'yyyy/MM/dd'];

    for (final pattern in patterns) {
      try {
        return DateFormat(pattern).parseStrict(cleaned);
      } catch (_) {}
    }

    try {
      return DateTime.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime? value, DateTime now) {
    if (value == null) return false;
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  String _safeStringValue(Map<String, dynamic>? data, String key) {
    if (data == null || !data.containsKey(key)) return '';
    return data[key]?.toString() ?? '';
  }
// benefice 
  // double _recipeProfit(Map<String, dynamic> data) {
  //   final products = (data['produits'] as List<dynamic>?) ?? const [];
  //   return products.fold<double>(0, (sum, product) {
  //     final item = Map<String, dynamic>.from(product as Map);
  //     final quantity = _toDouble(item['quantite']);
  //     final salePrice = _toDouble(item['prix_unitaire']);
  //     final purchasePrice = _toDouble(item['prix_achat']);
  //     return sum + (salePrice - purchasePrice) * quantity;
  //   });
  // }
//  mise a jours
  Future<void> _updateRecette(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final dateController = TextEditingController(text: _safeStringValue(data, 'date'));
    final clientController = TextEditingController(text: _safeStringValue(data, 'nom_clt'));
    final montantController = TextEditingController(text: _toDouble(data['montant']).toStringAsFixed(0));
    var paiement = _safeStringValue(data, 'paiement');

    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Mettre à jour la recette'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date')),
                TextField(controller: clientController, decoration: const InputDecoration(labelText: 'Nom du client')),
                TextField(
                  controller: montantController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Montant'),
                ),
                DropdownButtonFormField<String>(
                  value: paiement.isEmpty ? null : paiement,
                  decoration: const InputDecoration(labelText: 'Paiement'),
                  items: const [
                    DropdownMenuItem(value: 'espece', child: Text('espece')),
                    DropdownMenuItem(value: 'mobile', child: Text('mobile money')),
                    DropdownMenuItem(value: 'credit', child: Text('credit')),
                    DropdownMenuItem(value: 'virement', child: Text('virement')),
                    DropdownMenuItem(value: 'en attente', child: Text('en attente')),
                  ],
                  onChanged: (value) => setDialogState(() => paiement = value ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'date': dateController.text.trim(),
                'nom_clt': clientController.text.trim(),
                'montant': _toDouble(montantController.text.replaceAll(',', '.')),
                'paiement': paiement,
              }),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
    dateController.dispose();
    clientController.dispose();
    montantController.dispose();
    if (values == null) return;

    final stockSnapshot = await FirebaseFirestore.instance.collection('stocks').get();
    final purchasePrices = <String, double>{};
    for (final stock in stockSnapshot.docs) {
      final stockData = stock.data();
      final name = stockData['nom_produit']?.toString();
      if (name != null) purchasePrices[name] = _toDouble(stockData['prix_achat']);
    }

    final products = ((data['produits'] as List<dynamic>?) ?? const []).map((product) {
      final item = Map<String, dynamic>.from(product as Map);
      final name = item['nom_produit']?.toString() ?? '';
      item['prix_achat'] = _toDouble(item['prix_achat'] ?? purchasePrices[name]);
      return item;
    }).toList();
    final updatedData = {...values, 'produits': products};
    // updatedData['benefice'] = _recipeProfit(updatedData);
    await _recette.doc(doc.id).update(updatedData);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Recette',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: const Center(child: Text('Utilisateur non connecté.')),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Recette',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecetteCalcul(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
       
        body: SingleChildScrollView(
          child: StreamBuilder<QuerySnapshot>(
            // user_id filter
            stream: _recette.where('user_id', isEqualTo: user.uid).snapshots(),
            builder: (context, recetteSnapshot) {
              if (recetteSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }
          
              final todayRecettes = (recetteSnapshot.data?.docs ?? []).where((
                doc,
              ) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final dateText = _safeStringValue(data, 'date');
                return _isSameDay(_parseDate(dateText), today);
              }).toList();
          
              final totalRecette = todayRecettes.fold<double>(
                0,
                (sum, doc) => sum + _toDouble(doc['montant']),
              );
          
              return StreamBuilder<QuerySnapshot>(
                stream: _depenses.snapshots(),
                builder: (context, depenseSnapshot) {
                  // final todayDepenses = (depenseSnapshot.data?.docs ?? []).where((
                  //   doc,
                  // ) {
                  //   final data = doc.data() as Map<String, dynamic>? ?? {};
                  //   final dateText = _safeStringValue(data, 'date');
                  //   return _isSameDay(_parseDate(dateText), today);
                  // }).toList();
          
                  // final totalDepense = todayDepenses.fold<double>(
                  //   0,
                  //   (sum, doc) => sum + _toDouble(doc['montant']),
                  // );
          
                  // final benefice = todayRecettes.fold<double>(
                  //   0,
                  //   (sum, doc) => sum + _recipeProfit(doc.data() as Map<String, dynamic>),
                  // );
          
                  final rows = todayRecettes.map((doc) {
                    return DataRow(
                      color: WidgetStateProperty.all(Colors.white),
                      cells: [
                        DataCell(
                          Text(
                            _safeStringValue(
                              doc.data() as Map<String, dynamic>? ?? {},
                              'date',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(
                            doc['montant']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(
                            doc['paiement']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  await _recette.doc(doc.reference.id).delete();
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                              IconButton(
                                onPressed: () => _updateRecette(doc),
                                icon: const Icon(
                                  Icons.update,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList();
          
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Header(
                          tite: 'Totale',
                          valeur: totalRecette.toStringAsFixed(0),
                          devise: 'FCFA',
                        ),
                        const SizedBox(height: 12),
                        // Header(
                        //   tite: 'Bénéfice',
                        //   valeur: benefice.toStringAsFixed(0),
                        //   devise: 'FCFA',
                        // ),
                        const SizedBox(height: 24),
                        const Text(
                          'Historique des paiements',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 28,
                                headingRowColor: WidgetStateProperty.all(
                                  const Color(0xFFF8FAFC),
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Total payé',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Paiement',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'actions',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                ],
                                rows: rows,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class Header extends StatelessWidget {
  final String tite, valeur, devise;
  const Header({
    super.key,
    required this.tite,
    required this.valeur,
    required this.devise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tite,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valeur,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                devise,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
