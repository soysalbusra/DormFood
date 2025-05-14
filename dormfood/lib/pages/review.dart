import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _suggestionController = TextEditingController();

  final Map<String, double> breakfastRatings = {
    "Taste": 0,
    "Hygiene": 0,
    "Portion": 0,
  };

  final Map<String, double> dinnerRatings = {
    "Taste": 0,
    "Hygiene": 0,
    "Portion": 0,
  };

  List<String> breakfastMenu = [];
  List<String> dinnerMenu = [];

  @override
  void initState() {
    super.initState();
    fetchTodaysMeals();
  }

  Future<void> fetchTodaysMeals() async {
    final today = DateTime.now();
    final formattedDate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final snapshot = await FirebaseFirestore.instance
        .collection('Meals')
        .doc(formattedDate)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      setState(() {
        breakfastMenu = List<String>.from(data?['breakfast'] ?? []);
        dinnerMenu = List<String>.from(data?['dinner'] ?? []);
      });
    }
  }

  Widget buildRatingRow(String label, Map<String, double> ratingMap) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        RatingBar.builder(
          initialRating: ratingMap[label]!,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 24,
          unratedColor: const Color.fromARGB(255, 241, 229, 203),
          itemBuilder:
              (context, _) => const Icon(Icons.star, color: Colors.orange),
          onRatingUpdate: (rating) {
            setState(() {
              ratingMap[label] = rating;
            });
          },
        ),
      ],
    );
  }

  Widget buildReviewCard(
      String meal, Map<String, double> ratings, List<String> menuItems) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            ...menuItems.map((item) => Text("- $item")),
            const SizedBox(height: 12),
            buildRatingRow("Taste", ratings),
            buildRatingRow("Hygiene", ratings),
            buildRatingRow("Portion", ratings),
          ],
        ),
      ),
    );
  }

void handleSubmit() async {
  final user = FirebaseAuth.instance.currentUser;
  final userId = user?.uid ?? 'anonymous';

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  try {
    // Aynı gün içinde daha önce değerlendirme yapıldı mı?
    final existingReviews = await FirebaseFirestore.instance
        .collection('Review')
        .where('userID', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .get();

    if (existingReviews.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Already Submitted"),
          content: const Text("You have already submitted a review today."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Firestore dokümanı oluştur
    await FirebaseFirestore.instance.collection('Review').add({
      'date': now,
      'bhygene': breakfastRatings['Hygiene'],
      'bportion': breakfastRatings['Portion'],
      'btaste': breakfastRatings['Taste'],
      'dhygene': dinnerRatings['Hygiene'],
      'dportion': dinnerRatings['Portion'],
      'dtaste': dinnerRatings['Taste'],
      'textbox': _suggestionController.text.trim(),
      'userID': userId,
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Submission Successful"),
        content: const Text("Thank you for your reviews and suggestions!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _suggestionController.clear();
                breakfastRatings.updateAll((key, value) => 0);
                dinnerRatings.updateAll((key, value) => 0);
              });
            },
            child: const Text("OK", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text("An error occurred while submitting: $e"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate =
        "${today.day} ${_monthName(today.month)} ${_weekDayName(today.weekday)}";

    return Scaffold(
      appBar: AppBar(title: const Text("Meal Review"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Meals – $formattedDate\n",
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            buildReviewCard("Breakfast", breakfastRatings, breakfastMenu),
            const SizedBox(height: 20),
            buildReviewCard("Dinner", dinnerRatings, dinnerMenu),
            const SizedBox(height: 20),
            TextField(
              controller: _suggestionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Any suggestions or complaints?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: handleSubmit,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Submit",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  String _weekDayName(int day) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return days[day - 1];
  }
}
