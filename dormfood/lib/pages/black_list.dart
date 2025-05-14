import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Blacklist extends StatefulWidget {
  final String docId;
  const Blacklist({super.key, required this.docId});

  @override
  State<Blacklist> createState() => _BlacklistState();
}

class _BlacklistState extends State<Blacklist> {
  late Future<List<String>> _dislikesFuture;

  @override
  void initState() {
    super.initState();
    _dislikesFuture = _fetchBlacklistedFoods();
  }

  Future<List<String>> _fetchBlacklistedFoods() async {
    final doc = await FirebaseFirestore.instance
        .collection('Dislike_Food')
        .doc(widget.docId)
        .get();

    if (doc.exists && doc.data() != null) {
      return List<String>.from((doc.data() as Map<String, dynamic>)['foods'] ?? []);
    } else {
      return [];
    }
  }

  Future<void> _deleteFood(int index, List<String> foods) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Blacklist'),
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
          .collection('Dislike_Food')
          .doc(widget.docId)
          .update({'foods': updatedFoods});

      setState(() {
        _dislikesFuture = Future.value(updatedFoods);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Blacklist", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
       automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<String>>(
        future: _dislikesFuture,
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
                    "No food on your blacklist yet",
                    style: TextStyle(color: Colors.black, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "You can add dishes you dislike from the daily menu to your blacklist.",
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
                      onPressed: () => _deleteFood(index, foods),
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
