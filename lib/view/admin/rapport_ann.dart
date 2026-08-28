import 'package:flutter/material.dart';
import 'package:plastica_suc/view/admin/rapport_resultats.dart';

class RapportAnn extends StatelessWidget {
	const RapportAnn({super.key, required this.year});

	final int year;

	@override
	Widget build(BuildContext context) {
		return RapportResultats(
			title: 'Rapport annuel',
			description: 'Recettes de l’année $year',
			filterDate: (value) => value != null && value.year == year,
		);
	}
}
