import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


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

                            return ListView(
                              children: products.map((doc) {
                                final data = doc.data() as Map<String, dynamic>? ?? {};
                                final qty = _toDouble(data['quantite']);
                                final isZero = qty == 0;
                                return Slidable(
                                  startActionPane: ActionPane(
                                    motion: StretchMotion(),
                                    children: [
                                     
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
