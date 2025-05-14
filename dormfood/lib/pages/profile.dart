import 'package:dormfood/pages/login_register_pages.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Kullanıcı profil bilgileri. Başlangıçta boş olarak tanımlandı.
  String name = "";
  String surname = "";
  String email = "";

  // Düzenleme modunu kontrol etmek için flag.
  bool isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Bildirim ayarları için toggle'lar.
  bool allNotifications = true;
  bool dailyNotifications = true;
  bool breakfastMenuNotifications = true;
  bool dinnerMenuNotifications = true;
  bool breakfastEndReminder = true;

  // Giriş yapmış kullanıcının UID'si.
  late String uid;

  @override
  void initState() {
    super.initState();

    // Giriş yapmış kullanıcı kontrolü.
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      uid = currentUser.uid;
      _fetchUserProfile();
    } else {
      // Gerçek uygulamada; kullanıcı giriş yapmamışsa uygun yönlendirmeyi yapmalısınız.
      print("Kullanıcı giriş yapmamış.");
    }
  }

  /// Firestore'dan, giriş yapmış kullanıcının profil bilgilerini çeker.
  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          name = userDoc.get('name') ?? "";
          surname = userDoc.get('surname') ?? "";
          email = userDoc.get('email') ?? "";
          _nameController.text = name;
          _surnameController.text = surname;
          _emailController.text = email;
        });
      } else {
        print("Kullanıcı verisi bulunamadı!");
      }
    } catch (e) {
      print("Profil verisi çekilirken hata oluştu: $e");
    }
  }

  /// Profil güncelleme: Kullanıcı sadece isim ve soyisim alanlarını güncelleyebilecek.
  Future<void> _saveProfile() async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(uid).update({
        'name': _nameController.text,
        'surname': _surnameController.text,
      });
      setState(() {
        name = _nameController.text;
        surname = _surnameController.text;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated!")),
      );
    } catch (e) {
      print("Profil güncellenirken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil güncellenirken hata oluştu.")),
      );
    }
  }

  /// Düzenleme modundan çıkarken, yapılan değişiklikleri iptal eder.
  void _cancelEditing() {
    setState(() {
      _nameController.text = name;
      _surnameController.text = surname;
      isEditing = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile Page'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _cancelEditing,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Text(
              "Profile",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // İsim alanı: Düzenleme modunda aktif, değilse pasif.
            TextField(
              controller: _nameController,
              enabled: isEditing,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Soyisim alanı: Düzenleme moduna göre aktif/pasif.
            TextField(
              controller: _surnameController,
              enabled: isEditing,
              decoration: const InputDecoration(
                labelText: "Surname",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Email alanı; salt okunur.
            TextField(
              controller: _emailController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              "Notification Settings",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            // Tüm Bildirimler
            SwitchListTile(
              title: const Text("All Notifications"),
              value: allNotifications,
              onChanged: (bool value) {
                setState(() {
                  allNotifications = value;
                });
              },
            ),
            // Günlük Bildirimler
            SwitchListTile(
              title: const Text("Daily Notifications"),
              value: dailyNotifications,
              onChanged: (bool value) {
                setState(() {
                  dailyNotifications = value;
                });
              },
            ),
            // Kahvaltı Menüsü Bildirimi
            SwitchListTile(
              title: const Text("Breakfast Menu Notification"),
              value: breakfastMenuNotifications,
              onChanged: (bool value) {
                setState(() {
                  breakfastMenuNotifications = value;
                });
              },
            ),
            // Akşam Yemeği Menüsü Bildirimi
            SwitchListTile(
              title: const Text("Dinner Menu Notification"),
              value: dinnerMenuNotifications,
              onChanged: (bool value) {
                setState(() {
                  dinnerMenuNotifications = value;
                });
              },
            ),
            // Kahvaltı Bitiş Hatırlatıcısı
            SwitchListTile(
              title: const Text("Breakfast End Reminder"),
              value: breakfastEndReminder,
              onChanged: (bool value) {
                setState(() {
                  breakfastEndReminder = value;
                });
              },
            ),
            const SizedBox(height: 24),
            // Log Out Butonu: Firebase çıkış yapıp LoginPage'e yönlendirmeCenter(
             ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginRegisterPages()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Log Out",
                style: TextStyle(color: Colors.white,)
                ),
              ),
            ],
        ),
      ),
    );
  }
}
