import 'package:flutter/material.dart';
import 'UserProfileScreen.dart';
import 'UserSettingsScreen.dart';
import 'ListEventScreen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  int _hoveredIndex = -1;

  Widget buildHoverableTile({
    required int index,
    required Icon icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: Container(
        color: isHovered ? Colors.green.withOpacity(0.1) : Colors.transparent,
        child: ListTile(
          leading: icon,
          title: Text(title),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          buildHoverableTile(
            index: 0,
            icon: const Icon(Icons.person),
            title: 'Profile',
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()));
            },
          ),
          buildHoverableTile(
            index: 1,
            icon: const Icon(Icons.settings),
            title: 'Change Password',
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
            },
          ),
          buildHoverableTile(
            index: 2,
            icon: const Icon(Icons.list_alt_rounded, color: Colors.green),
            title: 'Upcoming Events',
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EventListScreen()));
            },
          ),
          buildHoverableTile(
            index: 3,
            icon: const Icon(Icons.logout),
            title: 'Logout',
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
