import 'package:flutter/material.dart';
import 'package:plastica_suc/view/admin/rapport_resultats.dart';

class RapportJrs extends StatelessWidget {
	const RapportJrs({super.key, required this.date});

	final DateTime date;

	@override
	Widget build(BuildContext context) {
		return RapportResultats(
			title: 'Rapport journalier',
			description: 'Recettes du ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
			filterDate: (value) => value != null && value.year == date.year && value.month == date.month && value.day == date.day,
		);
	}
}
