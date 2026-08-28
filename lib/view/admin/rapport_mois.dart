import 'package:flutter/material.dart';
import 'package:plastica_suc/view/admin/rapport_resultats.dart';

class RapportMois extends StatelessWidget {
	const RapportMois({super.key, required this.month, required this.year});

	final int month;
	final int year;

	@override
	Widget build(BuildContext context) {
		return RapportResultats(
      
			title: 'Rapport mensuel',
			description: 'Recettes du mois $month/$year',
			filterDate: (value) => value != null && value.year == year && value.month == month,
		);
	}
}
