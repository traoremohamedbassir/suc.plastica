import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:plastica_suc/view/constants/drawer.dart';

class Perte extends StatefulWidget {
  const Perte({super.key});

  @override
  State<Perte> createState() => _PerteState();
}

class _PerteState extends State<Perte> {
  
  final CollectionReference _perte = FirebaseFirestore.instance
      .collection("pertes");

      Future<void> _updateperte(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final _nomContoller = TextEditingController(
      text: data['nom']?.toString() ?? '',
    );
    final _qteContoller = TextEditingController(
      text: data['quantite']?.toString() ?? '',
    );

    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Modifier le fournisseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nomContoller, decoration: const InputDecoration(labelText: 'Nom'),
             validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Le nom est requis';
                    return null;
                  },
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _qteContoller, decoration: const InputDecoration(labelText: 'Reste'),
            validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'La quantite est requise';
                    if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Entrez un montant valide';
                    return null;
                  },
            ),
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
                'nom': _nomContoller.text.trim(),
                'quantite': _qteContoller.text.trim(),
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    _nomContoller.dispose();
    _qteContoller.dispose();

    if (updated == null) return;
    await _perte.doc(doc.id).update(updated);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pertes'),
         backgroundColor: Color(0xFFF5F7FB),
      ),
      drawer: Drawers(),
      body: ListView(
        children: [
          Ajoutperte(),
          SizedBox(height: 10),
          Center(
            child: Text(
              'liste des pertes',
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
              SizedBox(
                height: 500,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _perte.snapshots(),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      return ListView(
                        children: snapshot.data!.docs.map((doc) {
                          return Slidable(
                            startActionPane: ActionPane(
                              motion: StretchMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) =>
                                  _updateperte(doc),
                                  backgroundColor: Colors.green,
                                  icon: Icons.edit,
                                ),
                                SlidableAction(
                                  onPressed: ((context) async {
                                    await _perte
                                        .doc(doc.reference.id)
                                        .delete();
                                    //                               },
                                  }),
                                  backgroundColor: Colors.red,
                                  icon: Icons.delete,
                                ),
                              ],
                            ),
                            child: Card(
                              elevation: 20,
                              child: ListTile(
                                title: Text(
                                  (doc['nom'] ?? '').toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  (doc['date'] ?? '').toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: Text(
                                  (doc['quantite'] ?? 0).toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
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
        ])
    );
  }
}

class Ajoutperte extends StatefulWidget {
  const Ajoutperte({super.key});

  @override
  State<Ajoutperte> createState() => _AjoutperteState();
}

class _AjoutperteState extends State<Ajoutperte> {
  final TextEditingController _nomContoller = TextEditingController();
  final TextEditingController _qteContoller = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final CollectionReference _perte = FirebaseFirestore.instance.collection("pertes");
  final CollectionReference _stocks = FirebaseFirestore.instance.collection("stocks");
  final List<String> _produits = [];

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  Future<void> _loadProduits() async {
    final snapshot = await _stocks.get();
    final produits = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final nomProduit = data['nom_produit']?.toString().trim();
      if (nomProduit != null && nomProduit.isNotEmpty) {
        produits.add(nomProduit);
      }
    }

    if (!mounted) return;
    setState(() {
      _produits
        ..clear()
        ..addAll(produits.toList()..sort());
    });
  }

  Future<void> _ajouterPerte() async {
    if (!_formKey.currentState!.validate()) return;

    final nomProduit = _nomContoller.text.trim();
    final quantitePerte = double.tryParse(_qteContoller.text.replaceAll(',', '.')) ?? 0;

    if (quantitePerte <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La quantité doit être supérieure à 0.')),
      );
      return;
    }

    final stockSnapshot = await _stocks
        .where('nom_produit', isEqualTo: nomProduit)
        .limit(1)
        .get();

    if (stockSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produit introuvable dans le stock : $nomProduit')),
      );
      return;
    }

    final stockDoc = stockSnapshot.docs.first;
    final stockData = stockDoc.data() as Map<String, dynamic>? ?? {};
    final stockActuel = _toDouble(stockData['quantite']);

    if (stockActuel < quantitePerte) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuffisant pour $nomProduit. Stock actuel : $stockActuel')),
      );
      return;
    }

    final nouveauStock = stockActuel - quantitePerte;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.update(stockDoc.reference, {'quantite': nouveauStock});
      transaction.set(_perte.doc(), {
        'nom': nomProduit,
        'quantite': quantitePerte,
        'date': _dateController.text,
      });
    });

    _nomContoller.clear();
    _qteContoller.clear();
    _dateController.text = _todayDate();
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = _todayDate();
    _loadProduits();
  }
// date
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
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue value) {
                      if (value.text.isEmpty) return const Iterable<String>.empty();
                      return _produits.where(
                        (produit) => produit.toLowerCase().contains(value.text.toLowerCase()),
                      );
                    },
                    onSelected: (String selection) {
                      _nomContoller.text = selection;
                    },
                    fieldViewBuilder: (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      textEditingController.text = _nomContoller.text;
                      textEditingController.selection = TextSelection.fromPosition(
                        TextPosition(offset: textEditingController.text.length),
                      );

                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'nom',
                          fillColor: Colors.white,
                          filled: true,
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
                      );
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
                    controller: _qteContoller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'quantite',
                      fillColor: Colors.white,
                      filled: true,
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
                      if (value == null || value.trim().isEmpty) return 'La quantité est requise';
                      if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Entrez une quantité valide';
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'date',
                      fillColor: Colors.white,
                      filled: true,
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
                    onPressed: _ajouterPerte,
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
      ),
    );
  }
}