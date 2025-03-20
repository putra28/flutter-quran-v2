import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../provider/settings_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({Key? key}) : super(key: key);

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}



class _SettingsWidgetState extends State<SettingsWidget> {
  int _arabicFontSize = 22;
  int _latinFontSize = 16;
  int _translationFontSize = 16;
  String _arabicFontFamily = 'ScheherazadeNew';
  FontWeight _arabicFontWeight = FontWeight.bold;
  List<String> fonts = [];
  List<String> filteredFonts = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    final String response = await rootBundle.loadString('assets/json/fonts/fonts.json');
    final data = json.decode(response);
    setState(() {
      fonts = List<String>.from(data["ArabicFonts"]);
      filteredFonts = List.from(fonts);
      isLoading = false;
    });
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _arabicFontSize = prefs.getInt('arabicFontSize') ?? 22;
      _latinFontSize = prefs.getInt('latinFontSize') ?? 16;
      _translationFontSize = prefs.getInt('translationFontSize') ?? 16;
      _arabicFontFamily = prefs.getString('arabicFontFamily') ?? 'ScheherazadeNew';
      String weightString = prefs.getString('arabicFontWeight') ?? 'normal';
      _arabicFontWeight = (weightString == 'bold') ? FontWeight.bold : FontWeight.normal;
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('arabicFontSize', _arabicFontSize);
    prefs.setInt('latinFontSize', _latinFontSize);
    prefs.setInt('translationFontSize', _translationFontSize);
    prefs.setString('arabicFontFamily', _arabicFontFamily);
    String weightString =
        (_arabicFontWeight == FontWeight.bold) ? 'bold' : 'normal';
    await prefs.setString('arabicFontWeight', weightString);
  }

  void _showFontSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context);
        return StatefulBuilder( // Tambahkan StatefulBuilder di sini
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search Fonts...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                            ),
                          ),
                          onChanged: (query) {
                            setModalState(() { // Gunakan setModalState agar UI modal terupdate
                              searchQuery = query;
                              if (query.isEmpty) {
                                filteredFonts = List.from(fonts);
                              } else {
                                filteredFonts = fonts
                                    .where((font) => font.toLowerCase().startsWith(query.toLowerCase()))
                                    .toList();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  isLoading
                      ? Expanded(child: Center(child: CircularProgressIndicator()))
                      : Expanded(
                          child: ListView.builder(
                            itemCount: filteredFonts.length,
                            itemBuilder: (context, index) {
                              final font = filteredFonts[index];
                              return ListTile(
                                title: Text(font),
                                selected: settings.arabicFontFamily == font,
                                onTap: () {
                                  settings.setArabicFontFamily(font);
                                  setState(() {
                                    _arabicFontFamily = font;
                                  });
                                  _saveSettings();
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  _showFontWeightSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context);
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Regular'),
                selected: settings.arabicFontWeight == 'Regular',
                onTap: () {
                  settings.setArabicFontWeight(FontWeight.normal);
                  setState(() {
                    _arabicFontWeight = FontWeight.normal;
                  });
                  _saveSettings();
                  Navigator.pop(context); // Tutup modal
                },
              ),
              ListTile(
                title: Text('Bold'),
                selected: settings.arabicFontWeight == 'Bold',
                onTap: () {
                  settings.setArabicFontWeight(FontWeight.bold);
                  setState(() {
                    _arabicFontWeight = FontWeight.bold;
                  });
                  _saveSettings();
                  Navigator.pop(context); // Tutup modal
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
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
            const Text(
              'Font Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // **Arabic Font Selection**
            ListTile(
              title: const Text('Arabic Font', style: TextStyle(fontSize: 16)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _arabicFontFamily,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _showFontSelection,
            ),

            ListTile(
              title: const Text('Arabic Font Weight', style: TextStyle(fontSize: 16)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _arabicFontWeight == FontWeight.bold ? 'Bold' : 'Regular',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: _showFontWeightSelection,
            ),

            const Divider(),

            // **Arabic Font Size Slider**
            ListTile(
              title: const Text(
                'Arabic Font Size',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Text(
                '$_arabicFontSize',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Slider(
              value: _arabicFontSize.toDouble(),
              min: 20,
              max: 34,
              divisions: 14,
              label: _arabicFontSize.toString(),
              onChanged: (value) {
                settings.setArabicFontSize(value);
                setState(() => _arabicFontSize = value.round());
                _saveSettings();
              },
            ),

            const Divider(),

            // **Latin Font Size Slider**
            ListTile(
              title: const Text(
                'Latin Font Size',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Text(
                '$_latinFontSize',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Slider(
              value: _latinFontSize.toDouble(),
              min: 14,
              max: 34,
              divisions: 20,
              label: _latinFontSize.toString(),
              onChanged: (value) {
                settings.setlatinFontSize(value);
                setState(() => _latinFontSize = value.round());
                _saveSettings();
              },
            ),

            const Divider(),

            // **Translation Font Size Slider**
            ListTile(
              title: const Text(
                'Translation Font Size',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Text(
                '$_translationFontSize',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Slider(
              value: _translationFontSize.toDouble(),
              min: 14,
              max: 34,
              divisions: 20,
              label: _translationFontSize.toString(),
              onChanged: (value) {
                settings.setTranslationFontSize(value);
                setState(() => _translationFontSize = value.round());
                _saveSettings();
              },
            ),

            const Divider(),

            // **Copyright**
            Column(
              children: [
                const Text(
                  "Thanks For Using This App ❤️",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  "Made By Putra Suyapratama",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
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
