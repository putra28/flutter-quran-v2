import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';

class DoaBottomSheet extends StatelessWidget {
  final String title;
  final String arabicText;
  final String latinText;
  final String translation;

  const DoaBottomSheet({
    Key? key,
    required this.title,
    required this.arabicText,
    required this.latinText,
    required this.translation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.5, // Setengah layar
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          arabicText,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.getFont(
                            settings.arabicFontFamily,
                            fontSize: settings.arabicFontSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    latinText,
                    style: GoogleFonts.baloo2(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: settings.latinFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    translation,
                    style: TextStyle(fontSize: settings.translationFontSize, color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
