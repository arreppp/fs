import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavBar({required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color(0xFF758467),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '', // Empty label
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_rounded),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inbox_sharp),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      onTap: onItemTapped,
      showSelectedLabels: false, // Hide selected labels
      showUnselectedLabels: false, // Hide unselected labels
    );
  }
}
