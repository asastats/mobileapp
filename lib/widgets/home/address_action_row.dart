import 'package:asa_stats/config/color.dart';
import 'package:asa_stats/screens/menu/menu_screen.dart';
import 'package:flutter/material.dart';

class AddressActionRow extends StatelessWidget {
  const AddressActionRow(
      {super.key, required this.status, required this.exportUrl});
  final bool status;
  final String exportUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        Visibility(visible: status, child: const ParticipationStatus()),
        CsvExport(exportUrl: exportUrl)
      ],
    );
  }
}

class CsvExport extends StatelessWidget {
  final String exportUrl;

  const CsvExport({super.key, required this.exportUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchURLApp(
          exportUrl,
        );
      },
      child: const Text(
        'CSV EXPORT',
        style: TextStyle(
          color: ColorResources.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ParticipationStatus extends StatelessWidget {
  const ParticipationStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
        text: const TextSpan(
            text: 'ONLINE',
            style: TextStyle(
                color: ColorResources.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600)));
  }
}
