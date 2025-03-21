import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_quran/widget/JadwalCard_widget.dart';
import 'package:flutter_quran/widget/JadwalList_widget.dart';
import 'package:flutter_quran/widget/SettingsModal_widget.dart';
import 'package:flutter_quran/widget/KotaListModal_widget.dart';
import 'package:flutter_quran/widget/KiblahModal_widget.dart';
import 'package:hijri/hijri_calendar.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  _JadwalPageState createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  Map<String, String>? jadwalHariIni;
  bool isLoading = true;
  String? keteranganWaktu;
  String? estimasi;
  String lokasiUrl = 'bandung';  // Nama kota untuk URL (tanpa spasi)
  String lokasiAsli = 'Bandung'; // lokasiasli adalah lokasiurl 
  var _format = HijriCalendar.now();

  @override
  void initState() {
    super.initState();
    loadSavedLocation();
  }

  Future<void> loadSavedLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLocation = prefs.getString('selected_location');
    if (savedLocation != null) {
      setState(() {
        lokasiAsli = savedLocation; // Gunakan untuk tampilan
        lokasiUrl = savedLocation.replaceAll(' ', '').toLowerCase(); // Gunakan untuk URL
      });
    }
    fetchJadwalSholat();
  }

  Future<void> fetchJadwalSholat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tahun = DateFormat('yyyy').format(DateTime.now());
    String bulan = DateFormat('MM').format(DateTime.now());
    String tanggalHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? cachedData = prefs.getString('jadwal_sholat_$lokasiUrl');
    String? cachedDate = prefs.getString('tanggal_sholat_$lokasiUrl');

    if (cachedData != null && cachedDate == tanggalHariIni) {
      setState(() {
        jadwalHariIni = Map<String, String>.from(json.decode(cachedData));
        isLoading = false;
        updateKeteranganWaktu();
      });
      return;
    }

    String url =
        'https://raw.githubusercontent.com/lakuapik/jadwalsholatorg/master/adzan/$lokasiUrl/$tahun/$bulan.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        var jadwal = data.firstWhere(
          (item) => item['tanggal'] == tanggalHariIni,
          orElse: () => null,
        );

        if (jadwal != null) {
          jadwalHariIni = {
            'Imsak': jadwal['imsyak'],
            'Subuh': jadwal['shubuh'],
            'Terbit': jadwal['terbit'],
            'Dhuha': jadwal['dhuha'],
            'Dzuhur': jadwal['dzuhur'],
            'Ashar': jadwal['ashr'],
            'Maghrib': jadwal['magrib'],
            'Isya': jadwal['isya'],
          };
          prefs.setString('jadwal_sholat_$lokasiUrl', json.encode(jadwalHariIni));
          prefs.setString('tanggal_sholat_$lokasiUrl', tanggalHariIni);
        }
      }
    } catch (e) {
      jadwalHariIni = {'Koneksi Internet Tidak Tersedia :(': '-'};
    }

    setState(() {
      isLoading = false;
      updateKeteranganWaktu();
    });
  }

  void updateKeteranganWaktu() {
    try {
      if (jadwalHariIni == null || jadwalHariIni!.isEmpty) return;

      DateTime now = DateTime.now();
      List<String> waktuSholat = jadwalHariIni!.values.toList();
      List<String> namaSholat = jadwalHariIni!.keys.toList();

      for (int i = 0; i < waktuSholat.length; i++) {
        DateTime waktu = DateFormat("HH:mm").parse(waktuSholat[i]);
        DateTime waktuSholatDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          waktu.hour,
          waktu.minute,
        );

        if (now.isBefore(waktuSholatDateTime)) {
          int selisihMenit = waktuSholatDateTime.difference(now).inMinutes;
          int selisihJam = selisihMenit ~/ 60;
          int sisaMenit = selisihMenit % 60;

          if (waktuSholatDateTime.difference(now).inMinutes <= 30) {
            keteranganWaktu = "Menjelang Waktu ${namaSholat[i]}";
          } else {
            keteranganWaktu =
                i > 0
                    ? "Waktu ${namaSholat[i - 1]}"
                    : "Menunggu Waktu ${namaSholat[i]}";
          }
          estimasi =
              selisihJam > 0
                  ? "$selisihJam Jam $sisaMenit Menit menuju ${namaSholat[i]}"
                  : "$selisihMenit Menit menuju ${namaSholat[i]}";
          return;
        }
      }

      // Jika sekarang sudah melewati semua jadwal sholat
      if (keteranganWaktu == null) {
        DateTime waktuTerakhir = DateFormat("HH:mm").parse(waktuSholat.last);
        DateTime waktuTerakhirDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          waktuTerakhir.hour,
          waktuTerakhir.minute,
        );

        int selisihMenit = now.difference(waktuTerakhirDateTime).inMinutes;
        int selisihJam = selisihMenit ~/ 60;
        int sisaMenit = selisihMenit % 60;

        keteranganWaktu = "Waktu ${namaSholat.last}";
        estimasi =
            selisihJam > 0
                ? "$selisihJam Jam $sisaMenit Menit semenjak ${namaSholat.last}"
                : "$selisihMenit Menit semenjak ${namaSholat.last}";
      }
    } catch (e) {
      keteranganWaktu = "Yahh Butuh Internet :((";
      estimasi = "-";
    }
  }

  void showSettingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SettingsWidget();
      },
    );
  }

  void showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return LocationPickerWidget(
          onLocationSelected: (selectedLocation) {
            setState(() {
              lokasiAsli = selectedLocation; // Tetap dalam format aslinya
              lokasiUrl = selectedLocation.replaceAll(' ', '').toLowerCase(); // Format untuk URL
            });
            fetchJadwalSholat();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            "Jadwal Sholat Hari Ini",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.explore,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const QiblahCompassWidget(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_format.toFormat("dd MMMM yyyy")}',
                  style: TextStyle(
                    fontSize: width * 0.044,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: width * 0.044,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            JadwalCard(
              keterangan: keteranganWaktu ?? "Loading...",
              estimasi: estimasi ?? "-",
              lokasi: lokasiAsli,
              onTapLocation: () => showLocationPicker(context),
            ),
            SizedBox(height: 15),
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: jadwalHariIni?.length ?? 0,
                        itemBuilder: (context, index) {
                          String key = jadwalHariIni!.keys.elementAt(index);
                          return JadwalItem(
                            title: key,
                            time: jadwalHariIni![key]!,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                spreadRadius: 0,
                blurRadius: 10,
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                label: 'Jadwal Adzan',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                label: 'Settings',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/home');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/jadwal');
                  break;
                case 2:
                  showSettingBottomSheet(context);
                  break;
              }
            },
          ),
        ),
      ),
    );
  }
}
