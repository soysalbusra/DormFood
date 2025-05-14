import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Favorites extends StatelessWidget {
  final String docId;
  const Favorites({super.key, required this.docId});

  Stream<List<String>> _favoriteFoodsStream() {
    return FirebaseFirestore.instance
        .collection('Like_Food')
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return List<String>.from(doc.data()!['foods'] ?? []);
      } else {
        return [];
      }
    });
  }

  Future<void> _deleteFood(BuildContext context, int index, List<String> foods) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove From Favorite'),
        content: const Text('Are you sure you want to delete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedFoods = List<String>.from(foods)..removeAt(index);

      await FirebaseFirestore.instance
          .collection('Like_Food')
          .doc(docId)
          .update({'foods': updatedFoods});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Favorites", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<String>>(
        stream: _favoriteFoodsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred.'));
          }

          final foods = snapshot.data ?? [];

          if (foods.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_meals, color: Colors.blueGrey, size: 80),
                  SizedBox(height: 20),
                  Text(
                    "No food added to favorites yet",
                    style: TextStyle(color: Colors.black, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "You can add your favorite dishes from the daily menu to favorites.",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: foods.length,
            separatorBuilder: (context, index) => const Divider(
              thickness: 1,
              color: Colors.grey,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    leading: const Icon(Icons.fastfood, color: Colors.orange),
                    title: Text(
                      foods[index],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFood(context, index, foods),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
