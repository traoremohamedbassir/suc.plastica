import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:plastica_suc/view/shared/display_fields.dart';

class StockEmpl extends StatefulWidget {
  const StockEmpl({super.key});

  @override
  State<StockEmpl> createState() => _StockEmplState();
}

class _StockEmplState extends State<StockEmpl> {
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

// rechercher
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Stock'),
          backgroundColor: Color(0xFFF5F7FB),
        ),
        
        
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
                    
                  ],
                ),
                SizedBox(height: 12),
                Column(
                  children: [
                    SizedBox(
                      height: 600,
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

                            return ListView.separated(
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final doc = products[index];
                                final data = doc.data() as Map<String, dynamic>? ?? {};
                                final values = stockDisplayValues(data);
                                final productName = values['nom_produit'] ?? '';
                                final qtyText = values['quantite'] ?? '';
                                final qty = _toDouble(data['quantite']);
                                final isZero = qty == 0;

                                return Slidable(
                                  startActionPane: ActionPane(
                                    motion: StretchMotion(),
                                    children: const [],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isZero ? Colors.red.withOpacity(0.06) : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isZero ? Colors.red.shade200 : Colors.grey.shade200,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                productName.isEmpty ? 'Produit' : productName,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: isZero ? Colors.red.shade700 : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isZero ? Colors.red.shade100 : Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Qté $qtyText',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: isZero ? Colors.red.shade700 : Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            _DetailChip(label: 'Prix achat', value: values['prix_achat'] ?? ''),
                                            _DetailChip(label: 'Fournisseur', value: values['fournisseur'] ?? ''),
                                            _DetailChip(label: 'Prix vente', value: values['prix_vente'] ?? ''),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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

// ////////////////////////////////////////////////
class _DetailChip extends StatelessWidget {
  final String label;
  final String value;

  const _DetailChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

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
