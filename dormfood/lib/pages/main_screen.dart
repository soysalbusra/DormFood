import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'daily_menu.dart';
import 'week_menu.dart';
import 'favorite_list.dart';
import 'black_list.dart';
import 'profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentPageIndex = 0;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  final List<NavigationDestination> _navigationDestinations = const [
    NavigationDestination(
      selectedIcon: Icon(Icons.calendar_today),
      icon: Icon(Icons.calendar_today_outlined),
      label: 'Daily',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.calendar_view_week),
      icon: Icon(Icons.calendar_view_week_outlined),
      label: 'Weekly',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.favorite),
      icon: Icon(Icons.favorite_border),
      label: 'Favorites',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.block),
      icon: Icon(Icons.block_outlined),
      label: 'Blacklist',
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.person),
      icon: Icon(Icons.person_outline),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Eğer kullanıcı oturumu yoksa boş ekran göster
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('User session not found')),
      );
    }

    final List<Widget> pages = [
      const DailyMenuPage(),
      const WeeklyMenuPage(),
      Favorites(docId: _userId!), 
      Blacklist(docId: _userId!),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentPageIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentPageIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        indicatorColor: const Color.fromRGBO(241, 168, 9, 1),
        destinations: _navigationDestinations,
      ),
    );
  }
}
