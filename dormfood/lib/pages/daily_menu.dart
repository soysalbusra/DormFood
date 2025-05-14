import 'package:dormfood/pages/review.dart';
import 'package:flutter/material.dart';
import 'package:date_picker_timetable/date_picker_timetable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


/// Yemek verisinin modellenmesi için FoodItem sınıfı.
   class FoodItem {
  final String name;
  final int calories;
  // Bu alanlar artık Firestore'daki like/dislike durumuyla örtüşmeyecek, 
  // bunun yerine direkt veritabanından gelen array'lerle kontrol edilecek.
  FoodItem({
    required this.name,
    required this.calories,
  });
}

   class DailyMenuPage extends StatefulWidget {
  const DailyMenuPage({Key? key}) : super(key: key);

  @override
  State<DailyMenuPage> createState() => _DailyMenuPageState();
}

   class _DailyMenuPageState extends State<DailyMenuPage> {
  DateTime selectedDate = DateTime.now();
  String selectedMealOption = 'Breakfast';

  // Kullanıcı uid'sini ve favori/dislike arraylerini tutuyoruz.
  String? userId;
  List<String> favoriteFoods = [];
  List<String> dislikedFoods = [];

  @override
  void initState() {
    super.initState();
    // FirebaseAuth ile mevcut kullanıcıyı alıyoruz.
    userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      // Like_Food koleksiyonundan kullanıcının favori yemeklerini dinliyoruz.
      FirebaseFirestore.instance
          .collection("Like_Food")
          .doc(userId)
          .snapshots()
          .listen((docSnap) {
        if (docSnap.exists) {
          final data = docSnap.data()!;
          setState(() {
            favoriteFoods = data["foods"] != null
                ? List<String>.from(data["foods"])
                : [];
          });
        } else {
          // Doküman yoksa boş liste belirleyelim
          setState(() {
            favoriteFoods = [];
          });
        }
      });

      // Dislike_Food koleksiyonundan kullanıcının dislike yemeklerini dinliyoruz.
      FirebaseFirestore.instance
          .collection("Dislike_Food")
          .doc(userId)
          .snapshots()
          .listen((docSnap) {
        if (docSnap.exists) {
          final data = docSnap.data()!;
          setState(() {
            dislikedFoods = data["foods"] != null
                ? List<String>.from(data["foods"])
                : [];
          });
        } else {
          setState(() {
            dislikedFoods = [];
          });
        }
      });
    }
  }

  // Favori butonunun işlevi: ilgili yemeği ekle ya da çıkar.
  Future<void> _toggleFavorite(String foodName) async {
    if (userId == null) return;
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("Like_Food").doc(userId);
    if (favoriteFoods.contains(foodName)) {
      // Ekli ise, array'den çıkar.
      await docRef.set({
        'foods': FieldValue.arrayRemove([foodName])
      }, SetOptions(merge: true));
    } else {
      // Ekli değilse ekle.
      await docRef.set({
        'foods': FieldValue.arrayUnion([foodName])
      }, SetOptions(merge: true));
    }
  }

  // Dislike (kara liste) butonunun işlevi: ilgili yemeği ekle ya da çıkar.
  Future<void> _toggleDislike(String foodName) async {
    if (userId == null) return;
    DocumentReference docRef =
        FirebaseFirestore.instance.collection("Dislike_Food").doc(userId);
    if (dislikedFoods.contains(foodName)) {
      await docRef.set({
        'foods': FieldValue.arrayRemove([foodName])
      }, SetOptions(merge: true));
    } else {
      await docRef.set({
        'foods': FieldValue.arrayUnion([foodName])
      }, SetOptions(merge: true));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Üst kısım: İleri/geri butonları ve seçili tarih gösterimi.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  selectedDate = selectedDate.subtract(const Duration(days: 1));
                });
              },
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            ),
            Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  selectedDate = selectedDate.add(const Duration(days: 1));
                });
              },
              icon: const Icon(Icons.arrow_forward, color: Colors.black),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarih seçimi için takvim widget'ı.
            DatePicker(
              DateTime.now().subtract(const Duration(days: 10)),
              key: ValueKey(selectedDate.toIso8601String()),
              initialSelectedDate: selectedDate,
              selectionColor: const Color.fromRGBO(241, 168, 9, 1),
              selectedTextColor: Colors.white,
              daysCount: 20,
              dateTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              monthTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              onDateChange: (date) {
                setState(() {
                  selectedDate = date;
                });
              },
              locale: "en_US",
            ),
            const SizedBox(height: 16),
            // Öğün seçenekleri: Kahvaltı ve Akşam Yemeği.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMealOptionButton('Breakfast'),
                const SizedBox(width: 16),
                _buildMealOptionButton('Dinner'),
              ],
            ),
            // "Review Menu" butonu; öğün seçim butonlarının hemen altına eklendi.const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context,).push(MaterialPageRoute(builder: (context) => const ReviewPage()));
                
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:  const Color.fromRGBO(241, 168, 9, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Review Menu',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            // Seçilen öğüne ait yemek listesini ve favori/dislike işlemlerini gösteriyoruz.
            Expanded(child: _buildMealMenu()),
          ],
        ),
      ),
    );
  }

  /// Seçili öğün için buton widget'ı.
  Widget _buildMealOptionButton(String option) {
    final bool isSelected = selectedMealOption == option;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedMealOption = option;
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white :  const Color.fromRGBO(241, 168, 9, 1),
        backgroundColor: isSelected ?  const Color.fromRGBO(241, 168, 9, 1) : Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(option, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  /// Firestore’dan seçili gün (tüm gün) ve öğüne göre yemek verilerini çekip görüntüleyen widget.
  Widget _buildMealMenu() {
    // Seçili gün için günün başlangıcı (00:00) belirleniyor.
    DateTime startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    // Gün sonuna kadar olan aralık: bir sonraki günün başlangıcı.
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    Stream<QuerySnapshot> menuStream = FirebaseFirestore.instance
        .collection('Food')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('meal', isEqualTo: selectedMealOption)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: menuStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Menu not found!',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        // Firestore'dan çekilen yemekleri modele dönüştürüyoruz.
        List<FoodItem> menuItems = docs.map((doc) {
          return FoodItem(
            name: doc.get('name'),
            calories: doc.get('calorie'),
          );
        }).toList();

        int totalCalories =
            menuItems.fold(0, (sum, item) => sum + item.calories);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Öğün başlığı ve toplam kalori gösterimi.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedMealOption,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total Calories: $totalCalories',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Yemeklerin listelendiği alan.
            Expanded(
              child: ListView.separated(
                itemCount: menuItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final foodItem = menuItems[index];
                  return ListTile(
                    title: Text(
                      foodItem.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      '${foodItem.calories} Kalori',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dislike (kara liste) butonu.
                        IconButton(
                          icon: Icon(
                            Icons.block,
                            color: dislikedFoods.contains(foodItem.name)
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () {
                            _toggleDislike(foodItem.name);
                          },
                        ),
                        // Favori (beğeni) butonu.
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: favoriteFoods.contains(foodItem.name)
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () {
                            _toggleFavorite(foodItem.name);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tarihi "Tuesday, 15 April" formatında döndüren yardımcı fonksiyon.
  String _formatDate(DateTime date) {
    const List<String> weekDaysEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const List<String> monthsEn = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    String dayName = weekDaysEn[date.weekday - 1];
    String dayNumber = date.day.toString();
    String monthName = monthsEn[date.month];
    return '$dayName, $dayNumber $monthName';
  }
}
