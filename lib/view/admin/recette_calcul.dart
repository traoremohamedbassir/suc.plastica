import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
class ProductRowData {
  ProductRowData();

  String? selectedProduit;
  final TextEditingController produitController = TextEditingController();
  final TextEditingController fournisseurController = TextEditingController();
  final TextEditingController prixController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
}

class RecetteCalcul extends StatefulWidget {
  const RecetteCalcul({super.key});

  @override
  State<RecetteCalcul> createState() => _RecetteCalculState();
}

class _RecetteCalculState extends State<RecetteCalcul> {
  final CollectionReference _stocks = FirebaseFirestore.instance.collection(
    'stocks',
  );
  final CollectionReference _recette = FirebaseFirestore.instance.collection(
    "recettes",
  );
  String? selectedpaie = "espece";
  final List<ProductRowData> _rows = [ProductRowData()];
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nomcltController = TextEditingController();
  final TextEditingController _sommeController = TextEditingController();
  final TextEditingController _numfactController = TextEditingController();
  final List<String> _produits = [];
  final Map<String, dynamic> _produitPrix = {};
  final Map<String, dynamic> _produitAchat = {};
  final Map<String, dynamic> _produitFournisseur = {};
  Map<String, dynamic>? _lastInvoice;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = _todayDate();
    _loadNextInvoiceNumber();
    _loadProduits();
    _sommeController.addListener(_updateTotal);
  }
// num facture
  Future<void> _loadNextInvoiceNumber() async {
    final counter = await FirebaseFirestore.instance
        .collection('parametres')
        .doc('compteur_facture')
        .get();
    if (!mounted) return;
    final nextNumber = (counter.data()?['next'] as num?)?.toInt() ?? 1;
    _numfactController.text = nextNumber.toString();
  }

// qte
  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }
// enregistrement
  Future<void> _saveInvoice() async {
    if (_isSaving) return;

    if (_nomcltController.text.trim().isEmpty) {
      _showMessage('Le nom du client est requis.');
      return;
    }

    for (final row in _rows) {
      final nomProduit = row.produitController.text.trim();
      if (nomProduit.isEmpty) continue;

      final quantite = double.tryParse(row.quantiteController.text.trim().replaceAll(',', '.')) ?? 0;
      if (quantite <= 0) {
        _showMessage('La quantité du produit "$nomProduit" est requise.');
        return;
      }

      final prixAchat = _toDouble(_produitAchat[nomProduit]);
      if (prixAchat > 0) {
        final prixVente = double.tryParse(
              row.prixController.text.trim().replaceAll(',', '.'),
            ) ??
            0;

        if (prixVente < prixAchat) {
          _showMessage(
            'Le prix de vente de "$nomProduit" est inférieur au prix d\'achat ($prixAchat FCFA).',
          );
          return;
        }
      }
    }

    final products = _rows
        .where((row) => row.produitController.text.trim().isNotEmpty)
        .map(
          (row) => {
            'nom_produit': row.produitController.text.trim(),
            'fournisseur': row.fournisseurController.text.trim(),
            'quantite': double.tryParse(row.quantiteController.text) ?? 0,
            'prix_unitaire': double.tryParse(row.prixController.text) ?? 0,
            'prix_achat': _produitAchat[row.produitController.text.trim()] ?? 0,
          },
        )
        .toList();

    if (products.isEmpty) {
      _showMessage('Ajoutez au moins un produit.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final counterRef = FirebaseFirestore.instance
          .collection('parametres')
          .doc('compteur_facture');
      final invoiceRef = _recette.doc();
      late int invoiceNumber;

      final stockSnapshot = await _stocks.get();
      final stockByProductName = <String, QueryDocumentSnapshot>{};
      for (final stockDoc in stockSnapshot.docs) {
        final name = (stockDoc.data() as Map<String, dynamic>? ?? {})['nom_produit']
            ?.toString()
            .trim();
        if (name != null && name.isNotEmpty) {
          stockByProductName[name] = stockDoc;
        }
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterRef);
        invoiceNumber = (counterSnapshot.data()?['next'] as num?)?.toInt() ?? 1;
        transaction.set(counterRef, {'next': invoiceNumber + 1});
// qte
        for (final product in products) {
          final productName = (product['nom_produit'] as String).trim();
          final qtyToRemove = _toDouble(product['quantite']);

          if (qtyToRemove <= 0) continue;

          final stockDoc = stockByProductName[productName];
          if (stockDoc == null) {
            throw Exception('Le produit "$productName" n’existe pas dans le stock.');
          }

          final stockData = stockDoc.data() as Map<String, dynamic>? ?? {};
          final currentStock = _toDouble(stockData['quantite']);
          final newStock = currentStock - qtyToRemove;

          if (newStock < 0) {
            throw Exception('Stock insuffisant pour "$productName".');
          }

          transaction.update(stockDoc.reference, {
            'quantite': newStock,
          });
        }

        final currentUser = FirebaseAuth.instance.currentUser;
        transaction.set(invoiceRef, {
          'date': _dateController.text,
          'nom_clt': _nomcltController.text.trim(),
          'montant': double.tryParse(_sommeController.text) ?? 0,
          'paiement': selectedpaie ?? 'espece',
          'num_facture': invoiceNumber,
          'produits': products,
          'created_at': FieldValue.serverTimestamp(),
          'user_id': currentUser?.uid ?? '',
          'user_email': currentUser?.email ?? '',
        });
      });

      _lastInvoice = {
        'date': _dateController.text,
        'nom_clt': _nomcltController.text.trim(),
        'montant': double.tryParse(_sommeController.text) ?? 0,
        'paiement': selectedpaie ?? 'espece',
        'num_facture': invoiceNumber,
        'produits': products,
      };
      _showMessage('Facture N° $invoiceNumber enregistrée.');
      _clearForm();
    } catch (_) {
      _showMessage('Impossible d’enregistrer la facture.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _numfactController.clear();
    _nomcltController.clear();
    _sommeController.clear();
    setState(() {
      selectedpaie = 'espece';
      _rows
        ..clear()
        ..add(ProductRowData());
    });
    _loadNextInvoiceNumber();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  // BL

  Future<void> _printBL() async {
    final invoice = _lastInvoice;
    if (invoice == null) {
      _showMessage('Enregistrez une facture avant d’imprimer un bon de livraison.');
      return;
    }

    final products = (invoice['produits'] as List).cast<Map<String, dynamic>>();
    final fournisseur = products.isNotEmpty
        ? (products.first['fournisseur']?.toString() ?? '—')
        : '—';
    final clientOuFournisseur =
        (invoice['nom_clt'] as String? ?? '').trim().isNotEmpty
            ? invoice['nom_clt']
            : fournisseur;
    final dateLivraison = invoice['date']?.toString() ?? _todayDate();
    // final dateReception = _dateController.text.trim().isNotEmpty
    //     ? _dateController.text
    //     : _todayDate();

    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
              'BON DE LIVRAISON',
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            // pw.Container(
            //   width: 100,
            //   height: 100,
            //   decoration: pw.BoxDecoration(
                
            //   ),
            //   child: pw.Image.asset('assets/images/logo.png'),
                  
                
            // ),
              ]
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('N° ${invoice['num_facture']}'),
                pw.Text('Date : $dateLivraison'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
               pw.Text('N° RCCM : CI-ABJ-1999-B-249382'),
               pw.Text('CONTACT : 0788881419'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                 pw.Text('IFU/IDU/NINFA :'),
                pw.Text('Emis par : DIABATE MOCTAR'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('client : $clientOuFournisseur'),
            pw.Table.fromTextArray(
              headers: ['Produit', 'Quantité', 'Prix unitaire'],
              data: products.map((product) {
                final quantity = (product['quantite'] as num).toDouble();
                final price = (product['prix_unitaire'] as num).toDouble();
                return [
                  product['nom_produit'],
                  quantity.toString(),
                  price.toStringAsFixed(0),
                  // (product['fournisseur']?.toString() ?? '—'),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 28),
            
            pw.Text('Client / Fournisseur : '),
            pw.Text('Livré le : '),
            pw.Text('Reçu le : '),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature livreur :'),
                    pw.SizedBox(height: 40),
                    pw.Container(
                      width: 180,
                      height: 1,
                      color: PdfColors.black,
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature client :'),
                    pw.SizedBox(height: 40),
                    pw.Container(
                      width: 180,
                      height: 1,
                      color: PdfColors.black,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }
//  print
  Future<void> _printInvoice() async {
    final invoice = _lastInvoice;
    if (invoice == null) {
      _showMessage('Enregistrez une facture avant de l’imprimer.');
      return;
    }
 // remise
    final remiseController = TextEditingController(text: '0');
    final remise = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Remise'),
        content: TextField(
          controller: remiseController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Montant de la remise',
            suffixText: 'FCFA',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                    remiseController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;
              Navigator.of(context).pop(value < 0 ? 0 : value);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    remiseController.dispose();
    if (remise == null) return;
// calcule
    final document = pw.Document();
    final products = (invoice['produits'] as List).cast<Map<String, dynamic>>();
    final totalHt = (invoice['montant'] as num).toDouble();
    final montantTva = totalHt * 0.18;
    final totalTtc = totalHt + montantTva;
    final netAPayer = (totalTtc - remise).clamp(0, double.infinity).toDouble();

    String formatAmount(double amount) => amount.toStringAsFixed(0);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('FACTURE', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('N° ${invoice['num_facture']}'),
                pw.Text('Date : ${invoice['date']}'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
               pw.Text('N° RCCM : CI-ABJ-1999-B-249382'),
               pw.Text('CONTACT : 0788881419'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                 pw.Text('IFU/IDU/NINFA :'),
                pw.Text('VENDEUR : DIABATE MOCTAR'),
              ],
            ),
            pw.SizedBox(height: 10),
             pw.Row(
              children: [
                pw.Text('Client : ${invoice['nom_clt']}'),
              ],
            ),
           
            pw.SizedBox(height: 24),
            pw.Table.fromTextArray(
              headers: ['Produit', 'Quantité', 'Prix unitaire', 'Total'],
              data: products.map((product) {
                final quantity = (product['quantite'] as num).toDouble();
                final price = (product['prix_unitaire'] as num).toDouble();
                return [
                  product['nom_produit'],
                  quantity.toString(),
                  price.toStringAsFixed(0),
                  (quantity * price).toStringAsFixed(0),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  
                  
                 
                  pw.SizedBox(height: 12),
                  pw.Text('Total HT : ${formatAmount(totalHt)} FCFA'),
                  pw.Text('TVA (18%) : ${formatAmount(montantTva)} FCFA'),
                  pw.Text('Total TTC : ${formatAmount(totalTtc)} FCFA'),
                  pw.Text('Remise : ${formatAmount(remise)} FCFA'),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Net à payer : ${formatAmount(netAPayer)} FCFA',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold,fontSize: 25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  @override
  void dispose() {
    _sommeController.removeListener(_updateTotal);
    _dateController.dispose();
    _nomcltController.dispose();
    for (final row in _rows) {
      row.produitController.dispose();
      row.fournisseurController.dispose();
      row.prixController.dispose();
      row.quantiteController.dispose();
    }
    super.dispose();
  }
// pu
  void _validatePrixVente(ProductRowData row) {
    final nomProduit = row.produitController.text.trim();
    if (nomProduit.isEmpty) return;

    final prixAchat = _toDouble(_produitAchat[nomProduit]);
    if (prixAchat <= 0) return;

    final prixSaisi = double.tryParse(
          row.prixController.text.trim().replaceAll(',', '.'),
        ) ??
        0;

    if (prixSaisi < prixAchat) {
      _showMessage(
        'Le prix de vente ne peut pas être inférieur au prix d\'achat (${prixAchat.toStringAsFixed(0)} FCFA).',
      );
    }
  }

  // somme totale
  void _updateTotal() {
    double total = 0;

    for (final row in _rows) {
      final prix = double.tryParse(row.prixController.text) ?? 0;
      final quantite = double.tryParse(row.quantiteController.text) ?? 0;
      total += prix * quantite;
    }

    final totalText = total.toStringAsFixed(0);
    if (_sommeController.text != totalText) {
      _sommeController.value = TextEditingValue(
        text: totalText,
        selection: TextSelection.collapsed(offset: totalText.length),
      );
    }
  }

  // funct produit auto
  Future<void> _loadProduits() async {
    final snapshot = await _stocks.get();
    final produits = <String>[];
    final prixParProduit = <String, dynamic>{};
    final prixAchatParProduit = <String, dynamic>{};
    final fournisseurParProduit = <String, dynamic>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final nomProduit = data?['nom_produit']?.toString();
      final prixVente = data?['prix_vente'] ?? data?['prix_vente'];
      final prixAchat = data?['prix_achat'];
      final fournisseur = data?['fournisseur']?.toString();

      if (nomProduit != null && nomProduit.isNotEmpty) {
        produits.add(nomProduit);
        prixParProduit[nomProduit] = prixVente ?? '';
        prixAchatParProduit[nomProduit] = prixAchat ?? '';
        fournisseurParProduit[nomProduit] = fournisseur ?? '';
      }
    }

    if (!mounted) return;

    setState(() {
      _produits
        ..clear()
        ..addAll(produits.toSet().toList()..sort());
      _produitPrix.clear();
      _produitPrix.addAll(prixParProduit);
      _produitAchat.clear();
      _produitAchat.addAll(prixAchatParProduit);
      _produitFournisseur.clear();
      _produitFournisseur.addAll(fournisseurParProduit);
    });
  }

  // date
  String _todayDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Cal'),
        actions: [
           
          IconButton(
            tooltip: 'BL',
            onPressed: _lastInvoice == null ? null : _printBL,
            icon: const Icon(Icons.fact_check),
          ),
          
          IconButton(
            tooltip: 'credit',
            onPressed: () async {
              final result = await showDialog<Map<String, String>>(
                context: context,
                builder: (context) => Ajoutclt(),
              );
              if (result != null) {
                setState(() {
                  // _nomcltController.text = result['nom_clt'] ?? '';
                  _dateController.text = result['date'] ?? _todayDate();
                });
              }
            },
            icon: const Icon(Icons.credit_card),
          ),
          IconButton(
            tooltip: 'Imprimer la facture enregistrée',
            onPressed: _lastInvoice == null ? null : _printInvoice,
            icon: const Icon(Icons.print),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveInvoice,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          setState(() {
            // ajouter un ligne
            _rows.add(ProductRowData());
          });
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        children: [
          // Section Total Montant
          Container(
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
                TextField(
                  controller: _sommeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'somme',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nomcltController,
                    decoration: InputDecoration(
                      hintText: 'Nom du client',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButton<String>(
                      value: selectedpaie,
                      isExpanded: true,
                      hint: Text('Paiement'),

                      underline: SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 'espece',
                          child: Text('espece'),
                        ),
                        DropdownMenuItem(
                          value: 'mobile',
                          child: Text('mobile money'),
                        ),
                        DropdownMenuItem(
                          value: 'credit',
                          child: Text('credit'),
                        ),
                        DropdownMenuItem(
                          value: 'virement',
                          child: Text('virement'),
                        ),
                         DropdownMenuItem(
                          value: 'cheque',
                          child: Text('cheque'),
                        ),
                        DropdownMenuItem(
                          value: 'en attente',
                          child: Text('en attente'),
                        ),
                        // DropdownMenuItem(value: 'Option 3', child: Text('Option 3')),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          selectedpaie = value ?? 'espece';
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: TextField(
                      controller: _numfactController,
                      readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'N.fact',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lignes de produits dynamiques
          ..._rows.asMap().entries.map((entry) {
            return _buildProductRow(entry.key);
          }),
        ],
      ),
    );
  }

  //  config pro auto
  Widget _buildProductRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  return _produits.where(
                    (produit) => produit.toLowerCase().contains(
                      value.text.toLowerCase(),
                    ),
                  );
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      textEditingController.text = row.produitController.text;
                      textEditingController
                          .selection = TextSelection.fromPosition(
                        TextPosition(offset: textEditingController.text.length),
                      );

                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onSubmitted: (_) => onFieldSubmitted(),
                        decoration: InputDecoration(
                          hintText: 'Nom du produit',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      );
                    },
                onSelected: (String selection) {
                  setState(() {
                    row.selectedProduit = selection;
                    row.produitController.text = selection;
                    final prix = _produitPrix[selection];
                    final fournisseur = _produitFournisseur[selection];
                    row.prixController.text = prix?.toString() ?? '';
                    row.fournisseurController.text =
                        fournisseur?.toString() ?? '';
                        // pu
                    _validatePrixVente(row);
                    _updateTotal();
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.fournisseurController,
              decoration: InputDecoration(
                hintText: 'Fournisseur',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.prixController,
              keyboardType: TextInputType.number,
              onChanged: (_) {
                _validatePrixVente(row);
                _updateTotal();
              },
              onSubmitted: (_) => _validatePrixVente(row),
              onTapOutside: (_) => _validatePrixVente(row),
              decoration: InputDecoration(
                hintText: 'Prix unitaire',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.quantiteController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateTotal(),
              decoration: InputDecoration(
                hintText: 'Q',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Ajoutclt extends StatefulWidget {
  const Ajoutclt({super.key});

  @override
  State<Ajoutclt> createState() => _AjoutcltState();
}

class _AjoutcltState extends State<Ajoutclt> {
  final TextEditingController _nomcltController = TextEditingController();

  final TextEditingController _sommeContoller = TextEditingController();

  final TextEditingController _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
  final CollectionReference _credit = FirebaseFirestore.instance.collection(
    "credits",
  );
 

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      // title: Text('Ajoutclter un article'),
      
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            SizedBox(height: 10),
            TextFormField(
              controller: _nomcltController,
              decoration: InputDecoration(
                hintText: 'Nom clt',
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
        
            SizedBox(height: 6),
            TextFormField(
              controller: _sommeContoller,
              decoration: InputDecoration(
                hintText: "montant",
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
                    return null;
                  },
            ),
        
            SizedBox(height: 6),
            TextFormField(
              
              controller: _dateController,
                    readOnly: true,
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
                
                await _credit.add({
                  'nom_clt': _nomcltController.text,
                  'date': _dateController.text,
                  'montant': _sommeContoller.text,
                  
                });
                _nomcltController.clear();
                _dateController.clear();
                _sommeContoller.clear();
                
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