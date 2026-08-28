import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plastica_suc/view/admin/caisse_depense.dart';
import 'package:plastica_suc/view/constants/drawer.dart';

class Caisse extends StatefulWidget {
  const Caisse({super.key});

  @override
  State<Caisse> createState() => _CaisseState();
}

class _CaisseState extends State<Caisse> {
  final CollectionReference _caisse = FirebaseFirestore.instance.collection(
    "caisses",
  );
  // 
  Future<void> _updateCaisse(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final designationController = TextEditingController(
      text: data['designation']?.toString() ?? '',
    );
    final montantController = TextEditingController(
      text: data['montant']?.toString() ?? '',
    );

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Modifier la caisse'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: designationController, decoration: const InputDecoration(labelText: 'Désignation')),
            const SizedBox(height: 8),
            TextField(controller: montantController, decoration: const InputDecoration(labelText: 'Montant')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'designation': designationController.text.trim(),
                'montant': montantController.text.trim(),
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    designationController.dispose();
    montantController.dispose();

    if (updated == null) return;
    await _caisse.doc(doc.id).update(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color(0xFFF5F7FB),
          title: Text('Caisse'),
          actions: [
            Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return CaisseDepense();
                      },
                    ),
                  );
                },
                child: Text(
                  'Depense',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        drawer: Drawers(),
        body: ListView(
          children: [
            Totalecaisse(),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: InkWell(
                onTap: () {
                  Ajoutfond();
                },
                child: Container(
                  width: 100,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Ajoutfond(),
                      );
                    },
                    child: Text(
                      'Ajouer des fonds dans la caisse',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _caisse.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('pas de donnees'));
                }

                final rows = snapshot.data!.docs.map((doc) {
                  return DataRow(
                    selected: true,
                    cells: [
                      DataCell(Text(doc['designation']?.toString() ?? '')),
                      DataCell(Text(doc['montant']?.toString() ?? '')),
                      DataCell(Text(doc['date']?.toString() ?? '')),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await _caisse.doc(doc.reference.id).delete();
                              },
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                            IconButton(
                              onPressed: () => _updateCaisse(doc),
                              icon: Icon(Icons.edit, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(
                          label: Text(
                            'designation',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'montant',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'date',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'actions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      rows: rows,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Totalecaisse extends StatelessWidget {
  const Totalecaisse({super.key});

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final caisseRef = FirebaseFirestore.instance.collection('caisses');
    final depenseRef = FirebaseFirestore.instance.collection('depenses');

    return StreamBuilder<QuerySnapshot>(
      stream: caisseRef.snapshots(),
      builder: (context, caisseSnapshot) {
        final totalEntree = (caisseSnapshot.data?.docs ?? []).fold<double>(
          0,
          (sum, doc) => sum + _toDouble(doc['montant']),
        );

        return StreamBuilder<QuerySnapshot>(
          stream: depenseRef.snapshots(),
          builder: (context, depenseSnapshot) {
            final totalDepense = (depenseSnapshot.data?.docs ?? [])
                .fold<double>(0, (sum, doc) => sum + _toDouble(doc['montant']));

            final totalFinal = totalEntree - totalDepense;

            return Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Montant',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Text(
                      '${totalFinal.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class Ajoutfond extends StatefulWidget {
  const Ajoutfond({super.key});

  @override
  State<Ajoutfond> createState() => _AjoutfondState();
}

class _AjoutfondState extends State<Ajoutfond> {
  final TextEditingController _desigController = TextEditingController();
  final TextEditingController _montContoller = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final CollectionReference _caisse = FirebaseFirestore.instance.collection(
    "caisses",
  );
  final _formKey = GlobalKey<FormState>();

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
    return AlertDialog(
      backgroundColor: Colors.white,
      // title: Text('Ajouter un article'),
      content: Form(
        key: _formKey,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10),

          TextFormField(
            controller: _desigController,
            decoration: InputDecoration(
              hintText: "designation",
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
            if (value == null || value.trim().isEmpty) return 'La désignation est requise';
            return null;
          },
          ),
          

          SizedBox(height: 6),
          TextFormField(
            controller: _montContoller,
            decoration: InputDecoration(
              hintText: 'montant',
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
            if (value == null || value.trim().isEmpty) return 'Le montant est requis';
            if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Entrez un montant valide';
            return null;
          },
          ),
          

          SizedBox(height: 6),
          TextFormField(
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
             validator: (value) {
            if (value == null || value.trim().isEmpty) return 'La date est requise';
            return null;
          },
          ),
         
          SizedBox(height: 6),
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
                await _caisse.add({
                  'designation': _desigController.text.trim(),
                  'montant': _montContoller.text.trim(),
                  'date': _dateController.text,
                });
                _desigController.clear();
                _montContoller.clear();
                _dateController.text = _todayDate();

                setState(() {
                  Navigator.pop(context);
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
