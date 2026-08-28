import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CaisseDepense extends StatefulWidget {
  const CaisseDepense({super.key});

  @override
  State<CaisseDepense> createState() => _CaisseDepenseState();
}

class _CaisseDepenseState extends State<CaisseDepense> {
  final CollectionReference _depense = FirebaseFirestore.instance.collection(
    "depenses",
  );
  // mise a jour

  Future<void> _updateDepense(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final categorieController = TextEditingController(
      text: data['categorie']?.toString() ?? '',
    );
    final montantController = TextEditingController(
      text: data['montant']?.toString() ?? '',
    );
    final designationController = TextEditingController(
      text: data['designation']?.toString() ?? '',
    );

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Modifier la dépense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: categorieController, decoration: const InputDecoration(labelText: 'Catégorie')),
              const SizedBox(height: 8),
              TextField(controller: montantController, decoration: const InputDecoration(labelText: 'Montant')),
              const SizedBox(height: 8),
              TextField(controller: designationController, decoration: const InputDecoration(labelText: 'Désignation')),
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
                'categorie': categorieController.text.trim(),
                'montant': montantController.text.trim(),
                'designation': designationController.text.trim(),
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    categorieController.dispose();
    montantController.dispose();
    designationController.dispose();

    if (updated == null) return;
    await _depense.doc(doc.id).update(updated);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Depenses'),
        backgroundColor: Color(0xFFF5F7FB),
      ),
      body: ListView(
        children: [
          Ajoutdep(),
          Center(
            child: Text(
              'liste des depenses',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 25,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 20),
           StreamBuilder<QuerySnapshot>(
              stream: _depense.snapshots(),
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
                      DataCell(Text(doc['categorie']?.toString() ?? '')),
                      DataCell(Text(doc['designation']?.toString() ?? '')),
                       DataCell(Text(doc['montant']?.toString() ?? '')),
                      DataCell(Text(doc['date']?.toString() ?? '')),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await _depense
                                        .doc(doc.reference.id)
                                        .delete();
                                    //  
                              },
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                            IconButton(
                              onPressed: () =>  _updateDepense(doc),
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
                            'categorie',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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
        ])
    );
  }
}

class Ajoutdep extends StatefulWidget {
  const Ajoutdep({super.key});

  @override
  State<Ajoutdep> createState() => _AjoutdepState();
}

class _AjoutdepState extends State<Ajoutdep> {
  final TextEditingController _desigController = TextEditingController();
  final TextEditingController _montContoller = TextEditingController();
  final TextEditingController _categContoller = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final CollectionReference _depense = FirebaseFirestore.instance.collection(
    "depenses",
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _categContoller,
                  decoration: InputDecoration(
                    hintText: 'categorie',
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
                    if (value == null || value.trim().isEmpty) return 'La catégorie est requise';
                    return null;
                  },
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: TextFormField(
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
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
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
              ),
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    hintText: "date",
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
                    if (!_formKey.currentState!.validate()) return;
                    await _depense.add({
                      'categorie': _categContoller.text.trim(),
                      'designation': _desigController.text.trim(),
                      'montant': _montContoller.text.trim(),
                      'date': _dateController.text,
                    });
                    _categContoller.clear();
                    _desigController.clear();
                    _montContoller.clear();
                    _dateController.text = _todayDate();
                  },
                  child: Text(
                    'Ajouter',
                    style: TextStyle(
                      color: Colors.black,

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


