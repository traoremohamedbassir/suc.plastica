import 'package:flutter/material.dart';
import 'package:plastica_suc/view/admin/rapport_ann.dart';
import 'package:plastica_suc/view/admin/rapport_jrs.dart';
import 'package:plastica_suc/view/admin/rapport_mois.dart';
import 'package:plastica_suc/view/constants/drawer.dart';
import 'package:table_calendar/table_calendar.dart';


class Rapport extends StatefulWidget {
  const Rapport({super.key});

  @override
  State<Rapport> createState() => _RapportState();
}

class _RapportState extends State<Rapport> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late int _selectedMonth;
  late int _selectedYear;
  _ReportPeriod _selectedPeriod = _ReportPeriod.daily;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = today;
    _focusedDay = today;
    _selectedMonth = today.month;
    _selectedYear = today.year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Rapports'),
          backgroundColor: const Color(0xFFF5F7FB),
        ),
        drawer: Drawers(),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Choisissez une période',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Consultez les rapports selon le jour, le mois ou l’année.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            _buildPeriodSection(
              period: _ReportPeriod.daily,
              title: 'Rapport journalier',
              subtitle: 'Sélectionner un jour',
              icon: Icons.today_outlined,
            ),
            const SizedBox(height: 12),
            _buildPeriodSection(
              period: _ReportPeriod.monthly,
              title: 'Rapport mensuel',
              subtitle: 'Sélectionner un mois',
              icon: Icons.calendar_month_outlined,
            ),
            const SizedBox(height: 12),
            _buildPeriodSection(
              period: _ReportPeriod.annual,
              title: 'Rapport annuel',
              subtitle: 'Sélectionner une année',
              icon: Icons.event_note_outlined,
            ),
          ],
        ),
    );
  }

  Widget _buildPeriodSection({
    required _ReportPeriod period,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPeriod == period;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selectedPeriod = period),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    child: Icon(icon),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 3),
                        Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Icon(isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          if (isSelected) _buildCalendar(period),
        ],
      ),
    );
  }

  Widget _buildCalendar(_ReportPeriod period) {
    switch (period) {
      case _ReportPeriod.daily:
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: TableCalendar<void>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RapportJrs(date: selectedDay)),
              );
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
        );
      case _ReportPeriod.monthly:
        return _buildMonthGrid();
      case _ReportPeriod.annual:
        return _buildYearGrid();
    }
  }

  Widget _buildMonthGrid() {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: months.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
        ),
        itemBuilder: (context, index) => _periodChoice(
          label: months[index],
          isSelected: _selectedMonth == index + 1,
          onTap: () {
            setState(() => _selectedMonth = index + 1);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RapportMois(month: index + 1, year: _selectedYear),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildYearGrid() {
    final currentYear = DateTime.now().year;
    final years = List.generate(12, (index) => currentYear - 5 + index);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: years.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
        ),
        itemBuilder: (context, index) => _periodChoice(
          label: years[index].toString(),
          isSelected: _selectedYear == years[index],
          onTap: () {
            setState(() => _selectedYear = years[index]);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RapportAnn(year: years[index])),
            );
          },
        ),
      ),
    );
  }

  Widget _periodChoice({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

enum _ReportPeriod { daily, monthly, annual }
