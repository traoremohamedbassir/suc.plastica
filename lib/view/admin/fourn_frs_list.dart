import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';

class FournFrsList extends StatefulWidget {
  const FournFrsList({super.key});

  @override
  State<FournFrsList> createState() => _FournFrsListState();
}

class _FournFrsListState extends State<FournFrsList> {
  final CollectionReference _fournisseur = FirebaseFirestore.instance
      .collection("fournisseurs");
  // final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Fournisseurs'),
        backgroundColor: Color(0xFFF5F7FB),
      ),
      body: ListView(
        children: [
          Ajoutfour(),
          SizedBox(height: 10),
          Center(
            child: Text(
              'liste des fournisseurs',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                fontStyle: FontStyle.normal,
              ),
            ),
          ),
          SizedBox(height: 20),
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
          Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _fournisseurStream(),
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
                      final nom = data['nom']?.toString() ?? '';
                      final montant = (data['reste'] ?? 0).toString();
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
                                    await _fournisseur
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

  Stream<QuerySnapshot> _fournisseurStream() {
    if (_searchQuery.isEmpty) {
      return _fournisseur.orderBy('date', descending: true).snapshots();
    }

    // prefix search on nom_clt
    final start = _searchQuery;
    final end = '$_searchQuery\uf8ff';
    return _fournisseur
        .where('nom', isGreaterThanOrEqualTo: start)
        .where('nom', isLessThanOrEqualTo: end)
        .orderBy('nom')
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
              await _fournisseur.doc(creditId).collection('paiements').add({
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
            stream: _fournisseur.doc(creditId).collection('paiements').orderBy('date', descending: true).snapshots(),
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

class Ajoutfour extends StatefulWidget {
  const Ajoutfour({super.key});

  @override
  State<Ajoutfour> createState() => _AjoutfourState();
}

class _AjoutfourState extends State<Ajoutfour> {
  final TextEditingController _nomContoller = TextEditingController();
    final TextEditingController _resteContoller = TextEditingController();
    final TextEditingController _dateController = TextEditingController();
final _formKey = GlobalKey<FormState>();
  final CollectionReference _fournisseur = FirebaseFirestore.instance
      .collection("fournisseurs");

@override
  void initState() {
    super.initState();
    _dateController.text = _todayDate();
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      // 
      child: Form(
        key: _formKey,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
Expanded(
                child: TextFormField(
                  controller: _nomContoller,
                  decoration: InputDecoration(
                    hintText: 'nom',
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
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              
              Expanded(
                child: TextFormField(
                  controller: _resteContoller,
                  decoration: InputDecoration(
                    hintText: 'reste',
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
                    if (value == null || value.trim().isEmpty) return 'Le reste est requis';
                    if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Entrez un montant valide';
                    return null;
                  },
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    hintText: 'date',
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
                  
                ),
              ),
              SizedBox(width: 6),
            ],
          ),

          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  style: ButtonStyle(),
                  onPressed: () async {
                    // 
                    if (!_formKey.currentState!.validate()) return;
                    await _fournisseur.add({
                      'nom': _nomContoller.text.trim(),
                      'reste': _resteContoller.text.trim(),
                      'date': _dateController.text,
                    });

                    _nomContoller.clear();
                    _resteContoller.clear();
                    _dateController.text = _todayDate();
                    // Navigator.pop(context);
                  },
                  child: Text(
                    'Ajouter',
                    style: TextStyle(
                      color: Colors.white,

                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      )
    );
  }
}








  