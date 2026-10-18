String _stringValue(dynamic value) => value?.toString() ?? '';

String _formatCurrency(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return '0 FCFA';
  }

  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;

  return '${parsed.toStringAsFixed(0)} FCFA';
}

Map<String, String> stockDisplayValues(Map<String, dynamic> data) {
  return {
    'nom_produit': _stringValue(data['nom_produit']),
    'prix_achat': _formatCurrency(data['prix_achat']),
    'quantite': _stringValue(data['quantite']),
    'fournisseur': _stringValue(data['fournisseur']),
    'prix_vente': _formatCurrency(data['prix_vente']),
  };
}

Map<String, String> recetteDisplayValues(Map<String, dynamic> data) {
  return {
    'nom_clt': _stringValue(data['nom_clt']),
    'date': _stringValue(data['date']),
    'total_paye': _formatCurrency(data['total_paye'] ?? data['montant']),
    'systeme_paie': _stringValue(data['systeme_paie'] ?? data['paiement']),
  };
}

Map<String, String> caisseDisplayValues(Map<String, dynamic> data) {
  return {
    'designation': _stringValue(data['designation']),
    'montant': _formatCurrency(data['montant']),
    'date': _stringValue(data['date']),
  };
}

Map<String, String> depenseDisplayValues(Map<String, dynamic> data) {
  return {
    'categorie': _stringValue(data['categorie']),
    'designation': _stringValue(data['designation']),
    'montant': _formatCurrency(data['montant']),
    'date': _stringValue(data['date']),
  };
}
