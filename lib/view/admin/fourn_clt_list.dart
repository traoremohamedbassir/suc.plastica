import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';

class FournCltList extends StatefulWidget {
  const FournCltList({super.key});

  @override
  State<FournCltList> createState() => _FournCltListState();
}

class _FournCltListState extends State<FournCltList> {
  final CollectionReference _credit = FirebaseFirestore.instance.collection(
    "credits",
  );
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Clients'),
        backgroundColor: Color(0xFFF5F7FB),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un client par nom',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              'leste des clients',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
          SizedBox(height: 20),
          Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _creditStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Aucun crédit trouvé'),
                  );

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final nom = data['nom_clt']?.toString() ?? '';
                      final montant = (data['montant'] ?? 0).toString();
                      String dateStr = '';
                      if (data['date'] is Timestamp) {
                        final d = (data['date'] as Timestamp).toDate();
                        dateStr = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
                      } else if (data['date'] is String) {
                        dateStr = data['date'];
                      }

                      return ListTile(
                        title: Text(nom),
                        subtitle: Text('Montant: $montant FCFA\nDate: $dateStr'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Voir paiements',
                              icon: Icon(Icons.list),
                              onPressed: () => _showPayments(doc.id, nom),
                            ),
                            IconButton(
                              tooltip: 'Ajouter tranche',
                              icon: Icon(Icons.add_box),
                              onPressed: () => _addPaymentTranche(doc.id, nom),
                            ),
                            IconButton(
                              tooltip: '',
                              icon: Icon(Icons.delete,color: Colors.red,),
                              onPressed: (() async {
                                    await _credit
                                        .doc(doc.reference.id)
                                        .delete();
                                    //                               },
                                  }),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _creditStream() {
    if (_searchQuery.isEmpty) {
      return _credit.orderBy('date', descending: true).snapshots();
    }

    // prefix search on nom_clt
    final start = _searchQuery;
    final end = '$_searchQuery\uf8ff';
    return _credit
        .where('nom_clt', isGreaterThanOrEqualTo: start)
        .where('nom_clt', isLessThanOrEqualTo: end)
        .orderBy('nom_clt')
        .snapshots();
  }

  Future<void> _addPaymentTranche(String creditId, String nom) async {
    final montantController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final formKey = GlobalKey<FormState>();

    final res = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Ajouter tranche pour $nom'),
        
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Montant'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Montant requis' : null,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Date: ${selectedDate.day.toString().padLeft(2,'0')}/${selectedDate.month.toString().padLeft(2,'0')}/${selectedDate.year}')),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (d != null) setState(() => selectedDate = d);
                    },
                    child: Text('Choisir'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Annuler')),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final montant = double.tryParse(montantController.text.trim()) ?? 0;
              await _credit.doc(creditId).collection('paiements').add({
                'montant': montant,
                'date': Timestamp.fromDate(selectedDate),
              });
              Navigator.pop(context, true);
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (res == true) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tranche enregistrée')));
  }

  Future<void> _showPayments(String creditId, String nom) async {
    await showDialog(context: context, builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Paiements de $nom'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: _credit.doc(creditId).collection('paiements').orderBy('date', descending: true).snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Text('Erreur: ${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return Text('Aucune tranche');
              return ListView.separated(
                shrinkWrap: true,
                itemCount: docs.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>? ?? {};
                  final montant = (d['montant'] ?? 0).toString();
                  String dateStr = '';
                  if (d['date'] is Timestamp) {
                    final dt = (d['date'] as Timestamp).toDate();
                    dateStr = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
                  } else if (d['date'] is String) dateStr = d['date'];
                  return ListTile(
                    title: Text('Montant: $montant FCFA'),
                    subtitle: Text('Date: $dateStr'),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Fermer'))],
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}