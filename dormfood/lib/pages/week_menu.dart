import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hexcolor/hexcolor.dart';

class WeeklyMenuPage extends StatefulWidget {
  const WeeklyMenuPage({Key? key}) : super(key: key);

  @override
  _WeeklyMenuPageState createState() => _WeeklyMenuPageState();
}

class _WeeklyMenuPageState extends State<WeeklyMenuPage> {
  // Seçilen haftayı tutuyor: true -> bu hafta, false -> gelecek hafta
  bool isThisWeekSelected = true;

  // Bu hafta için başlangıç ve bitiş tarihleri (haftanın Pazartesi başlangıcı kabul edilmiştir)
  DateTime get startOfThisWeek {
    DateTime now = DateTime.now();
    int weekday = now.weekday; // Pazartesi = 1
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
  }

  DateTime get endOfThisWeek {
    return startOfThisWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  // Gelecek hafta için tarih aralığı
  DateTime get startOfNextWeek {
    return startOfThisWeek.add(const Duration(days: 7));
  }

  DateTime get endOfNextWeek {
    return startOfNextWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  /// Belirtilen tarih aralığı ve yemek tipi için Firestore sorgusu
  Future<List<Map<String, dynamic>>> fetchMealData(
      DateTime start, DateTime end, String mealType) async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('Food')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .where('meal', isEqualTo: mealType)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Firestore'dan çekilen yemek verilerini, gün bazında gruplandırır.
  /// Her document’te “date” (Timestamp) ve “name” (yemek adı) alanı olduğunu varsayıyoruz.
  List<Map<String, dynamic>> groupMealsByDay(
      List<Map<String, dynamic>> mealsData) {
    Map<String, List<String>> grouped = {};
    for (var mealData in mealsData) {
      DateTime dt = mealData['date'].toDate();
      String dayKey =
          "${dt.day} ${_monthName(dt.month)} ${_weekdayName(dt.weekday)}";
      String mealName = mealData['name'] ?? '';
      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(mealName);
    }
    List<Map<String, dynamic>> result = [];
    grouped.forEach((day, meals) {
      result.add({
        "day": day,
        "meals": meals,
      });
    });
    return result;
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month - 1];
  }

  String _weekdayName(int weekday) {
    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];
    return weekdays[weekday - 1];
  }

  /// Belirli bir yemek tipi için liste oluşturur (örneğin "Breakfast" veya "Dinner")
  Widget buildMealList(String mealType) {
    // Seçilen haftaya göre tarih aralığını belirleyelim
    DateTime start = isThisWeekSelected ? startOfThisWeek : startOfNextWeek;
    DateTime end = isThisWeekSelected ? endOfThisWeek : endOfNextWeek;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchMealData(start, end, mealType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
        } else {
          final groupedData = groupMealsByDay(snapshot.data!);
          // Bugünü aynı formatta hazırlıyoruz
          final DateTime today = DateTime.now();
          final String todayKey =
              "${today.day} ${_monthName(today.month)} ${_weekdayName(today.weekday)}";
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: groupedData.length,
            itemBuilder: (context, index) {
              final dayInfo = groupedData[index];
              final bool isToday = dayInfo["day"] == todayKey;
              return DayMealCard(
                dateTitle: dayInfo["day"],
                meals: List<String>.from(dayInfo["meals"]),
                // Sadece bugüne ait kart turuncu, diğerleri varsayılan rengi alır.
                color: isToday ? HexColor("#F1A809") : HexColor("#F4F8FF"),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Breakfast ve Dinner olmak üzere iki sekme
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Weekly Menu"),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color.fromARGB(255, 243, 190, 111),
            overlayColor: MaterialStatePropertyAll(
              Color.fromARGB(255, 238, 206, 138),
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.free_breakfast, color: Colors.orange),
                child: Text(
                  "Breakfast",
                  style: TextStyle(
                    color: Color.fromARGB(255, 75, 74, 74),
                  ),
                ),
              ),
              Tab(
                icon: Icon(Icons.dinner_dining, color: Colors.orange),
                child: Text(
                  "Dinner",
                  style: TextStyle(
                    color: Color.fromARGB(255, 75, 74, 74),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            ToggleButtonsSection(
              isThisWeek: isThisWeekSelected,
              onThisWeekSelected: () {
                setState(() {
                  isThisWeekSelected = true;
                });
              },
              onNextWeekSelected: () {
                setState(() {
                  isThisWeekSelected = false;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: [
                  // "Breakfast" sekmesi için yemek listesi
                  buildMealList("Breakfast"),
                  // "Dinner" sekmesi için yemek listesi
                  buildMealList("Dinner"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToggleButtonsSection extends StatelessWidget {
  final bool isThisWeek;
  final VoidCallback onThisWeekSelected;
  final VoidCallback onNextWeekSelected;

  const ToggleButtonsSection({
    Key? key,
    required this.isThisWeek,
    required this.onThisWeekSelected,
    required this.onNextWeekSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Chip(
          label: const Text(
            "7 meals",
            style: TextStyle(color: Color.fromARGB(255, 75, 74, 74)),
          ),
          avatar: const Icon(
            Icons.restaurant_menu,
            color: Colors.orange,
            size: 18,
          ),
        ),
        ElevatedButton(
          onPressed: onThisWeekSelected,
          style: ElevatedButton.styleFrom(
            backgroundColor: isThisWeek ? HexColor("#F1A809") : Colors.grey[300],
          ),
          child: const Text(
            "This Week",
            style: TextStyle(
              color: Color.fromARGB(255, 75, 74, 74),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: onNextWeekSelected,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isThisWeek ? Colors.grey : HexColor("#F1A809"),
            ),
          ),
          child: Text(
            "Next Week",
            style: TextStyle(
              color:
                  isThisWeek ? const Color.fromARGB(255, 75, 74, 74) : HexColor("#F1A809"),
            ),
          ),
        ),
      ],
    );
  }
}

class DayMealCard extends StatelessWidget {
  final String dateTitle;
  final List<String> meals;
  final Color color;

  const DayMealCard({
    Key? key,
    required this.dateTitle,
    required this.meals,
    this.color = const Color(0xFFF4F8FF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateTitle,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...meals.map(
              (meal) => ListTile(
                dense: true,
                leading: Icon(
                  Icons.restaurant,
                  size: 20,
                  color: HexColor("#0f0909"),
                ),
                title: Text(
                  meal,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 75, 74, 74),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
