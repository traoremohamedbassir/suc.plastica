import 'package:flutter/material.dart';
import 'package:plastica_suc/connection/login.dart';
import 'package:plastica_suc/controller/auth.dart';
import 'package:plastica_suc/view/admin/caisse.dart';
import 'package:plastica_suc/view/admin/fournisseur_clt.dart';
import 'package:plastica_suc/view/admin/home_adm.dart';
import 'package:plastica_suc/view/admin/menbre.dart';
import 'package:plastica_suc/view/admin/perte.dart';
import 'package:plastica_suc/view/admin/rapport.dart';
import 'package:plastica_suc/view/admin/recette.dart';
import 'package:plastica_suc/view/admin/stock.dart';

AuthService _authService = AuthService();

class Drawers extends StatelessWidget {
  const Drawers({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header del Drawer
          DrawerHeader(
            decoration: BoxDecoration(
              
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 130,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade900, width: 1),
                    shape: BoxShape.rectangle,
                    image: DecorationImage(
                      image: AssetImage('lib/assets/log/logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                 
                ),
                const Text(
                  'Plastica gestion',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   'usuario@plastica.com',
                //   style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                // ),
              ],
            ),
          ),

          // Menú Principal
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerMenuItem(
                  icon: Icons.home_outlined,
                  title: 'Accueille',
                  onTap: () {},
                  submenu: [
                    _SubMenuItem(
                      icon: Icons.home,
                      title: 'accueille',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return HomeAdm();
                          },
                        ),
                      ),
                    ),
                    _SubMenuItem(
                      icon: Icons.receipt_long,
                      title: 'Recette',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Recette();
                          },
                        ),
                      ),
                    ),
                    _SubMenuItem(
                      icon: Icons.storage,
                      title: 'Stock',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Stock();
                          },
                        ),
                      ),
                    ),
                    _SubMenuItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Caisse',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Caisse();
                          },
                        ),
                      ),
                    ),
                    _SubMenuItem(
                      icon: Icons.assessment,
                      title: 'Rapports',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Rapport();
                          },
                        ),
                      ),
                    ),
                    _SubMenuItem(
                      icon: Icons.remove_circle_outline,
                      title: 'pertes',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return Perte();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                _DrawerMenuItem(
                  icon: Icons.person_outline,
                  title: 'Client & Fournisseur',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return FournisseurClt();
                      },
                    ),
                  ),
                ),
                 _DrawerMenuItem(
                  icon: Icons.group,
                  title: 'Employers',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Menbre();
                      },
                    ),
                  ),
                ),
               
              ],
            ),
          ),

          // Footer
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                _DrawerMenuItem(
                  icon: Icons.logout_outlined,
                  title: 'Se Deconnecter',
                  onTap: () {
                    _authService.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Login()),
                    );
                  },
                  isLogout: true,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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

class _DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;
  final List<_SubMenuItem>? submenu;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
    this.submenu,
  });

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSubmenu() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSubmenu = widget.submenu != null && widget.submenu!.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasSubmenu ? _toggleSubmenu : widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.isLogout ? Colors.red : Colors.black,
                        size: 34,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 20,
                            color: widget.isLogout
                                ? Colors.red
                                : Colors.grey.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasSubmenu)
                        RotationTransition(
                          turns: Tween(
                            begin: 0.0,
                            end: 0.5,
                          ).animate(_animationController),
                          child: Icon(
                            Icons.expand_more,
                            color: Colors.blue.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasSubmenu && _isExpanded)
          Column(
            children: widget.submenu!
                .map((submenu) => _SubMenuItemWidget(submenu: submenu))
                .toList(),
          ),
      ],
    );
  }
}

class _SubMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _SubMenuItem({required this.icon, required this.title, required this.onTap});
}

class _SubMenuItemWidget extends StatelessWidget {
  final _SubMenuItem submenu;

  const _SubMenuItemWidget({required this.submenu});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 8, bottom: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: submenu.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(submenu.icon, color: Colors.blue.shade400, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      submenu.title,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
