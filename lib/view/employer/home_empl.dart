import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:plastica_suc/connection/login.dart';
import 'package:plastica_suc/controller/auth.dart';
import 'package:plastica_suc/view/employer/recette_emp.dart';
import 'package:plastica_suc/view/employer/stock_empl.dart';

class HomeEmpl extends StatefulWidget {
  const HomeEmpl({super.key});

  @override
  State<HomeEmpl> createState() => _HomeEmplState();
}

class _HomeEmplState extends State<HomeEmpl> {
  final AuthService _authService = AuthService();
  String _userName = '';
  late Future<Map<String, dynamic>> _statsFuture;
  

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final stocks = FirebaseFirestore.instance.collection('stocks');
    final recettes = FirebaseFirestore.instance.collection('recettes');

    final stockSnapshot = await stocks.get();
    final user = FirebaseAuth.instance.currentUser;
    QuerySnapshot recetteSnapshot;
    if (user != null) {
      recetteSnapshot = await recettes.where('user_id', isEqualTo: user.uid).get();
    } else {
      recetteSnapshot = await recettes.get();
    }

    int totalQuantiteStock = 0;
    for (final doc in stockSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final q = _toDouble(data['quantite']);
      totalQuantiteStock += q.round();
    }

    final now = DateTime.now();
    double recetteDuJour = 0;
    for (final doc in recetteSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final montant = _toDouble(data['montant']);
      final dateText = data['date']?.toString() ?? '';
      final parsed = _parseDate(dateText);
      if (_isSameDay(parsed, now)) {
        recetteDuJour += montant;
      }
    }

    return {
      'recetteDuJour': recetteDuJour,
      'totalQuantiteStock': totalQuantiteStock,
    };
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0;
    return 0;
  }
// rec
  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    final v = value.trim();
    final patterns = ['dd/MM/yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd', 'yyyy/MM/dd', 'dd/MM/yy'];
    for (final p in patterns) {
      try {
        return DateFormat(p).parseStrict(v);
      } catch (_) {}
    }
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime? value, DateTime now) {
    if (value == null) return false;
    return value.year == now.year && value.month == now.month && value.day == now.day;
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)} M FCFA';
    return '${value.toStringAsFixed(0)} FCFA';
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!mounted) return;

    setState(() {
      _userName = userSnapshot.data()?['name']?.toString().trim() ?? '';
      if (_userName.isEmpty) _userName = user.email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Plactica'),
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 237, 139, 35),
        actions: [
          IconButton(
            onPressed: () {
              _authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => Login()),
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de bienvenue
              Row(
                children: [
                Expanded(
                  child: HeaderEmpl(
                    name: 'Bienvenue',
                    valeur: _userName,
                  ),
                ),
                ],
              ),
              const SizedBox(height: 30),
              // Titre des sections
              const Text(
                'Sections principales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),

              // Cards des sections
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSectionCard(
                    context,
                    image: 'lib/assets/recette/recette.PNG',
                    title: 'Recettes',
                    subtitle: 'Gérer les recettes',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      // Navigation vers recette_empl
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return RecetteEmp();
                          },
                        ),
                      );
                    },
                  ),
                  _buildSectionCard(
                    context,
                    image: 'lib/assets/stock/stock.PNG',
                    title: 'Stock',
                    subtitle: 'Gérer le stock',
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      // Navigation vers stock_empl
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return StockEmpl();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Section stats rapides
              const Text(
                'Résumé rapide',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snap) {
                  final data = snap.data ?? {'recetteDuJour': 0.0, 'totalQuantiteStock': 0};
                  final recette = data['recetteDuJour'] as double;
                  final stockCount = data['totalQuantiteStock'] as int;
                  return Column(
                    children: [
                      _buildStatCard('Total Recettes', _formatCurrency(recette), const Color(0xFF4CAF50)),
                      const SizedBox(height: 12),
                      _buildStatCard('Articles en Stock', stockCount.toString(), const Color(0xFFFF9800)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {

    required String title,
    image,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Image.asset(image, width: 68),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderEmpl extends StatelessWidget {
  final String name, valeur;
  const HeaderEmpl({super.key, required this.name, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 189, 213, 177),
            Color.fromARGB(255, 199, 158, 97),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(
              fontSize: 19,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
