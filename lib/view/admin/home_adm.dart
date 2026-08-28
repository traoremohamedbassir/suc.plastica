import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plastica_suc/connection/login.dart';
import 'package:plastica_suc/controller/auth.dart';
import 'package:plastica_suc/view/admin/caisse.dart';
import 'package:plastica_suc/view/admin/rapport.dart';
import 'package:plastica_suc/view/admin/recette.dart';
import 'package:plastica_suc/view/admin/stock.dart';
import 'package:plastica_suc/view/constants/drawer.dart';

AuthService _authService = AuthService();
class HomeAdm extends StatefulWidget {
  const HomeAdm({super.key});

  @override
  State<HomeAdm> createState() => _HomeAdmState();
}

class _HomeAdmState extends State<HomeAdm> {
  String _userName = '';
  final CollectionReference _stocks = FirebaseFirestore.instance.collection(
    'stocks',
  );
  final CollectionReference _recettes = FirebaseFirestore.instance.collection(
    'recettes',
  );

  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Stock',
      'image': 'lib/assets/stock/stock1.PNG',
      'route': const Stock(),
    },
    {
      'title': 'Recette',
      'image': 'lib/assets/recette/recette.PNG',
      'route': const Recette(),
    },
    {
      'title': 'Caisse',
      'image': 'lib/assets/caisse/caisse.PNG',
      'route': const Caisse(),
    },
    {
      'title': 'Rapport',
      'image': 'lib/assets/rapport/rapport1.PNG',
      'route': const Rapport(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
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

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    final stockSnapshot = await _stocks.get();
    final recetteSnapshot = await _recettes.get();

    int totalProduits = stockSnapshot.docs.length;
    int totalQuantiteStock = 0;
    double valeurStock = 0;

    for (final doc in stockSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final quantite = _toDouble(data['quantite']);
      final prixVente = _toDouble(data['prix_vente']);
      totalQuantiteStock += quantite.round();
      valeurStock += quantite * prixVente;
    }

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    final last7Days = <String, double>{};

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      last7Days[DateFormat('yyyy-MM-dd').format(date)] = 0;
    }

    double recetteDuJour = 0;

    for (final doc in recetteSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final montant = _toDouble(data['montant']);
      final dateText = data['date']?.toString() ?? '';
      final parsedDate = _parseDate(dateText);

      if (parsedDate != null) {
        final key = DateFormat('yyyy-MM-dd').format(parsedDate);
        if (last7Days.containsKey(key)) {
          last7Days[key] = (last7Days[key] ?? 0) + montant;
        }
      }

      if (_isSameDay(parsedDate, now)) {
        recetteDuJour += montant;
      }
    }

    final chartValues = <double>[];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      chartValues.add(last7Days[key] ?? 0);
    }

    return {
      'recetteDuJour': recetteDuJour,
      'totalProduits': totalProduits,
      'totalQuantiteStock': totalQuantiteStock,
      'valeurStock': valeurStock,
      'chartValues': chartValues,
    };
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;

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

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} M FCFA';
    }
    return '${value.toStringAsFixed(0)} FCFA';
  }

  String _formatNumber(int value) {
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          
          title: Text(
            ' $_userName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevation: 2,
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: (){
                 _authService.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Login()),
                    );
              },
            ),
          ],
        ),
        drawer: const Drawers(),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _loadDashboardStats(),
          builder: (context, snapshot) {
            final stats =
                snapshot.data ??
                {
                  'recetteDuJour': 0.0,
                  'totalProduits': 0,
                  'totalQuantiteStock': 0,
                  'valeurStock': 0.0,
                  'chartValues': [0, 0, 0, 0, 0, 0, 0],
                };

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Produits',
                        value: _formatNumber(stats['totalProduits'] as int),
                        icon: Icons.widgets_outlined,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Stock total',
                        value: _formatNumber(
                          stats['totalQuantiteStock'] as int,
                        ),
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Recette du jour',
                        value: _formatCurrency(
                          stats['recetteDuJour'] as double,
                        ),
                        icon: Icons.monetization_on_outlined,
                        color: const Color(0xFF10B981),
                      ),
                    ),

                    // Expanded(
                    //   child: _StatCard(
                    //     title: 'Valeur stock',
                    //     value: _formatCurrency(stats['valeurStock'] as double),
                    //     icon: Icons.account_balance_wallet_outlined,
                    //     color: const Color(0xFFF59E0B),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Performance',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '7 derniers jours',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 170,
                        child: CustomPaint(
                          painter: _PerformanceChartPainter(
                            (stats['chartValues'] as List<dynamic>)
                                .map((e) => (e as num).toDouble())
                                .toList(),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          _LegendDot(color: Color(0xFF2563EB)),
                          SizedBox(width: 8),
                          Text(
                            'Recettes',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 18),
                          _LegendDot(color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text(
                            'Stock',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Gestion rapide',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return _BuildMenuCard(
                      title: item['title'],
                      image: item['image'],
                      route: item['route'],
                      index: index,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _PerformanceChartPainter extends CustomPainter {
  final List<double> values;

  const _PerformanceChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    final axisPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    final bluePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final greenPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final safeValues = values.isEmpty
        ? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        : values;
    final maxValue = safeValues.reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue > 0 ? maxValue : 1.0;

    final gridCount = 4;
    for (int i = 0; i <= gridCount; i++) {
      final y = (size.height / gridCount) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      bgPaint,
    );

    final bluePoints = <Offset>[];
    final greenPoints = <Offset>[];

    for (int i = 0; i < safeValues.length; i++) {
      final x = size.width * (i / (safeValues.length - 1));
      final y =
          size.height - ((safeValues[i] / chartMax) * (size.height - 18)) - 8;
      bluePoints.add(Offset(x, y));
      greenPoints.add(Offset(x, size.height - (0.2 + (i / 10)) * 20));
    }

    final bluePath = Path()..moveTo(bluePoints.first.dx, bluePoints.first.dy);
    for (int i = 1; i < bluePoints.length; i++) {
      bluePath.lineTo(bluePoints[i].dx, bluePoints[i].dy);
    }
    canvas.drawPath(bluePath, bluePaint);

    final greenPath = Path()..moveTo(0, size.height - 20);
    greenPath.lineTo(size.width, size.height - 20);
    canvas.drawPath(greenPath, greenPaint);

    for (final point in bluePoints) {
      canvas.drawCircle(point, 4, Paint()..color = const Color(0xFF2563EB));
    }
  }

  @override
  bool shouldRepaint(covariant _PerformanceChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

class _BuildMenuCard extends StatelessWidget {
  final String title;
  final String image;
  final Widget route;
  final int index;

  const _BuildMenuCard({
    required this.title,
    required this.image,
    required this.route,
    required this.index,
  });

  BorderRadius _getRadius() {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(20));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(20));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(20));
      case 3:
        return const BorderRadius.only(bottomRight: Radius.circular(20));
      default:
        return BorderRadius.circular(20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => route));
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 244, 243, 243),
          borderRadius: _getRadius(),
          boxShadow: [
            BoxShadow(
              color: Colors.black87.withOpacity(0.15),
              offset: const Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: _getRadius(),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
