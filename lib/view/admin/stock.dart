import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:plastica_suc/view/constants/drawer.dart';
import 'package:printing/printing.dart';

class Stock extends StatefulWidget {
  const Stock({super.key});

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final CollectionReference _stocks = FirebaseFirestore.instance.collection(
    "stocks",
  );
  final CollectionReference _recettes = FirebaseFirestore.instance.collection(
    "recettes",
  );

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }
//  CA
  double _calculateChiffreAffaires(QuerySnapshot recettesSnapshot) {
    var total = 0.0;
    for (final document in recettesSnapshot.docs) {
      final data = document.data() as Map<String, dynamic>? ?? {};
      final products = data['produits'];
      if (products is! List) continue;

      for (final product in products) {
        if (product is! Map) continue;
        total +=
            _toDouble(product['quantite']) * _toDouble(product['prix_unitaire']);
      }
    }
    return total;
  }
// rechercher
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

   // mise a jour

  Future<void> _updateStockProduct(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nomController = TextEditingController(
      text: data['nom_produit']?.toString() ?? '',
    );
    final achatController = TextEditingController(
      text: data['prix_achat']?.toString() ?? '',
    );
    final venteController = TextEditingController(
      text: data['prix_vente']?.toString() ?? '',
    );
    final qteController = TextEditingController(
      text: data['quantite']?.toString() ?? '',
    );
    final frsController = TextEditingController(
      text: data['fournisseur']?.toString() ?? '',
    );

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Modifier le produit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomController, decoration: const InputDecoration(labelText: 'Nom du produit')),
              const SizedBox(height: 8),
              TextField(controller: achatController, decoration: const InputDecoration(labelText: 'Prix d\'achat')),
              const SizedBox(height: 8),
              TextField(controller: venteController, decoration: const InputDecoration(labelText: 'Prix de vente')),
              const SizedBox(height: 8),
              TextField(controller: qteController, decoration: const InputDecoration(labelText: 'Quantité')),
              const SizedBox(height: 8),
              TextField(controller: frsController, decoration: const InputDecoration(labelText: 'Fournisseur')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'nom_produit': nomController.text.trim(),
                'prix_achat': achatController.text.trim(),
                'prix_vente': venteController.text.trim(),
                'quantite': qteController.text.trim(),
                'fournisseur': frsController.text.trim(),
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    nomController.dispose();
    achatController.dispose();
    venteController.dispose();
    qteController.dispose();
    frsController.dispose();

    if (updated == null) return;
    await _stocks.doc(doc.id).update(updated);
  }
  // print

  Future<void> _printStockList() async {
    final snapshot = await _stocks.get();
    final query = _searchQuery.trim().toLowerCase();
    final products = snapshot.docs.where((doc) {
      if (query.isEmpty) return true;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final name = data['nom_produit']?.toString().toLowerCase() ?? '';
      final fournisseur = data['fournisseur']?.toString().toLowerCase() ?? '';
      return name.contains(query) || fournisseur.contains(query);
    }).map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return [
        data['nom_produit']?.toString() ?? '',
        data['fournisseur']?.toString() ?? '',
        data['quantite']?.toString() ?? '',
        data['prix_achat']?.toString() ?? '',
        data['prix_vente']?.toString() ?? '',
      ];
    }).toList();

    if (products.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun produit dans le stock.')),
      );
      return;
    }

    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Liste du stock',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Produit', 'Fournisseur', 'Qté', 'Prix achat', 'Prix vente'],
              data: products,
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Stock'),
          backgroundColor: Color(0xFFF5F7FB),
          actions: [
             Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                     showDialog(context: context, builder: (context) => Ajout());
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        drawer: Drawers(),
        // floatingActionButton: FloatingActionButton(
        //   backgroundColor: Colors.black,
        //   onPressed: () {
        //     showDialog(context: context, builder: (context) => Ajout());
        //   },
        //   child: Icon(Icons.add, color: Colors.white),
        // ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _stocks.snapshots(),
                  builder: (context, stockSnapshot) {
                    if (!stockSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator.adaptive());
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: _recettes.snapshots(),
                      builder: (context, recetteSnapshot) {
                        final stockDocs = stockSnapshot.data!.docs;
                        final totalQuantity = stockDocs.fold<double>(
                          0,
                          (sum, document) =>
                              sum + _toDouble(document['quantite']),
                        );
                        final purchaseValue = stockDocs.fold<double>(
                          0,
                          (sum, document) =>
                              sum + _toDouble(document['prix_achat']),
                        );
                        final revenue = recetteSnapshot.hasData
                            ? _calculateChiffreAffaires(recetteSnapshot.data!)
                            : 0;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Produits',
                                    value: stockDocs.length.toString(),
                                    icon: Icons.inventory_2_outlined,
                                    color: const Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: StatCard(
                                    title: 'Qté totale',
                                    value: totalQuantity.toStringAsFixed(0),
                                    icon: Icons.widgets_outlined,
                                    color: const Color(0xFF0EA5E9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Valeur d\'achat',
                                    value: '${purchaseValue.toStringAsFixed(0)} FCFA',
                                    icon: Icons.shopping_bag_outlined,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                               
                              ],
                              
                            ),
                            const SizedBox(width: 16),
                            Row(children: [
                               
                                Expanded(
                                  child: StatCard(
                                    title: 'Chiffre d\'affaire',
                                    value: '${revenue.toStringAsFixed(0)} FCFA',
                                    icon: Icons.trending_up_rounded,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                            ],)
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Liste des produits',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // rechercher
                Row(
                  // recherche et imprimer
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value.trim().toLowerCase());
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit ou fournisseur',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Effacer la recherche',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Imprimer la liste du stock',
                      onPressed: _printStockList,
                      icon: const Icon(Icons.print),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Column(
                  children: [
                    SizedBox(
                      height: 290,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _stocks.snapshots(),
                        builder: ((context, snapshot) {
                          if (snapshot.hasData) {
                            final products = snapshot.data!.docs.where((doc) {
                              final data =
                                  doc.data() as Map<String, dynamic>? ?? {};
                              final name =
                                  data['nom_produit']?.toString().toLowerCase() ??
                                  '';
                              final fournisseur =
                                  data['fournisseur']?.toString().toLowerCase() ??
                                  '';
                              return name.contains(_searchQuery) ||
                                  fournisseur.contains(_searchQuery);
                            }).toList();

                            return ListView(
                              children: products.map((doc) {
                                final data = doc.data() as Map<String, dynamic>? ?? {};
                                final qty = _toDouble(data['quantite']);
                                final isZero = qty == 0;
                                return Slidable(
                                  startActionPane: ActionPane(
                                    motion: StretchMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) => _updateStockProduct(doc),
                                        backgroundColor: Colors.green,
                                        icon: Icons.edit,
                                      ),
                                      SlidableAction(
                                        onPressed: ((context) async {
                                          await _stocks
                                              .doc(doc.reference.id)
                                              .delete();
                                          //                               },
                                        }),
                                        backgroundColor: Colors.red,
                                        icon: Icons.delete,
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    elevation: 20,
                                    color: isZero ? Colors.red.withOpacity(0.08) : null,
                                    child: ListTile(
                                      title: Text(
                                        data['nom_produit']?.toString() ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isZero ? Colors.red : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        data['quantite']?.toString() ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isZero ? Colors.red : null,
                                        ),
                                      ),
                                      trailing: Text(
                                        data['prix_vente']?.toString() ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isZero ? Colors.red : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator.adaptive(),
                            );
                          } else {
                            return Center(child: Text('pas de donnees'));
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ////////////////////////////////////////////////////////////////////
// textformulaire pour ajouter
class Ajout extends StatefulWidget {
  const Ajout({super.key});

  @override
  State<Ajout> createState() => _AjoutState();
}

class _AjoutState extends State<Ajout> {
  final TextEditingController _nomController = TextEditingController();

  final TextEditingController _achatContoller = TextEditingController();

  final TextEditingController _venteController = TextEditingController();

  final TextEditingController _frsController = TextEditingController();

  final TextEditingController _qteController = TextEditingController();
final _formKey = GlobalKey<FormState>();
  final CollectionReference _stocks = FirebaseFirestore.instance.collection(
    "stocks",
  );
 

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      // title: Text('Ajouter un article'),
      
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // IconButton(
            //   onPressed: () {
            //     // Navigator.pop(context)
            //   },
            //   icon: Icon(Icons.barcode_reader),
            // ),
            SizedBox(height: 10),
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                hintText: 'Nom du produit',
                fillColor: Colors.white,
                filled: true,
                // prefixIcon: Icon(Icons.lock),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Le nom est requis';
                    return null;
                  },
            ),
        
            SizedBox(height: 6),
            TextFormField(
              controller: _achatContoller,
              decoration: InputDecoration(
                hintText: "Prix d'achat",
                fillColor: Colors.white,
                filled: true,
                // prefixIcon: Icon(Icons.lock),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le prix est requis';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Entrez un montant valide';
                  return null;
                },
            ),
        
            SizedBox(height: 6),
            TextFormField(
              controller: _venteController,
              decoration: InputDecoration(
                hintText: 'Prix de vente',
                fillColor: Colors.white,
                filled: true,
                // prefixIcon: Icon(Icons.lock),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Le prix est requis';
                  final vente = double.tryParse(value.replaceAll(',', '.'));
                  if (vente == null) return 'Entrez un montant valide';
                  final achat = double.tryParse(_achatContoller.text.replaceAll(',', '.')) ?? 0;
                  if (vente < achat) return 'Prix de vente inférieur au prix d\'achat';
                  return null;
                },
            ),
        
            SizedBox(height: 6),
            TextFormField(
              controller: _qteController,
              decoration: InputDecoration(
                hintText: 'Quantite  (unite)',
                fillColor: Colors.white,
                filled: true,
                // prefixIcon: Icon(Icons.lock),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'La quantite est requis';
                    return null;
                  },
            ),
        
            SizedBox(height: 6),
            TextFormField(
              controller: _frsController,
              decoration: InputDecoration(
                hintText: 'Fournisseur',
                fillColor: Colors.white,
                filled: true,
                // prefixIcon: Icon(Icons.lock),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Le fournisseur est requis';
                    return null;
                  },
            ),
        
            SizedBox(height: 6),
            // textforme(hinttext: 'Code bare / QR code'),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final prixA = double.tryParse(_achatContoller.text.replaceAll(',', '.')) ?? 0.0;
                final prixV = double.tryParse(_venteController.text.replaceAll(',', '.')) ?? 0.0;
                final quant = double.tryParse(_qteController.text.replaceAll(',', '.')) ?? 0.0;
                await _stocks.add({
                  'fournisseur': _frsController.text.trim(),
                  'quantite': quant,
                  'nom_produit': _nomController.text.trim(),
                  'prix_achat': prixA,
                  'prix_vente': prixV,
                  // 'created_at': FieldValue.serverTimestamp(),
                });
               
                setState(() {
                  Navigator.pop(context);
                _achatContoller.clear();
                _frsController.clear();
                _nomController.clear();
                _venteController.clear();
                _qteController.clear();
                });
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      ],
    );
  }
}
// ////////////////////////////////////////////////
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
