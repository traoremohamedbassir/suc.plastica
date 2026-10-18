import 'package:flutter_test/flutter_test.dart';
import 'package:plastica_suc/view/shared/display_fields.dart';

void main() {
  test('stock display values expose all requested fields', () {
    final data = {
      'nom_produit': 'PVC',
      'prix_achat': 800,
      'quantite': 25,
      'fournisseur': 'Plastique Plus',
      'prix_vente': 1200,
    };

    expect(stockDisplayValues(data), {
      'nom_produit': 'PVC',
      'prix_achat': '800 FCFA',
      'quantite': '25',
      'fournisseur': 'Plastique Plus',
      'prix_vente': '1200 FCFA',
    });
  });

  test('recette display values resolve client, date, amount and payment system', () {
    final data = {
      'nom_clt': 'Jean Dupont',
      'date': '18/10/2026',
      'total_paye': 15000,
      'systeme_paie': 'Mobile Money',
    };

    expect(recetteDisplayValues(data), {
      'nom_clt': 'Jean Dupont',
      'date': '18/10/2026',
      'total_paye': '15000 FCFA',
      'systeme_paie': 'Mobile Money',
    });
  });
}
