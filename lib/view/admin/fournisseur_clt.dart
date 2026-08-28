import 'package:flutter/material.dart';
import 'package:plastica_suc/view/admin/fourn_clt_list.dart';
import 'package:plastica_suc/view/admin/fourn_frs_list.dart';
import 'package:plastica_suc/view/constants/drawer.dart';

class FournisseurClt extends StatefulWidget {
  const FournisseurClt({super.key});

  @override
  State<FournisseurClt> createState() => _FournisseurCltState();
}

class _FournisseurCltState extends State<FournisseurClt> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Fournisseur & client'),
          backgroundColor: Color(0xFFF5F7FB),
        ),
        drawer: Drawers(),

        body: Stack(
          children: [
            Center(
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black87.withOpacity(0.20),
                      offset: const Offset(5, 5),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                    BoxShadow(
                      color: Colors.black87.withOpacity(0.20),
                      offset: const Offset(-5, -5),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 80),

                      StatCard(
                        title: 'Liste des clients',
                        press: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) {
                                return FournCltList();
                              },
                            ),
                          );
                        },
                        icon: Icons.group,
                        color: const Color(0xFF4F46E5),
                      ),

                      const SizedBox(height: 26),
                      StatCard(
                        title: 'Liste des fournisseurs',
                        press: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) {
                                return FournFrsList();
                              },
                            ),
                          );
                        },
                        icon: Icons.business,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ],
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

class StatCard extends StatelessWidget {
  final String title;
  final Function() press;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.press,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(left: 10, right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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

          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
          ),
          // const SizedBox(width: 19),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 202, 201, 201),
              shape: BoxShape.circle,
            ),
            child: InkWell(onTap: press, child: Icon(Icons.arrow_forward)),
          ),
        ],
      ),
    );
  }
}
