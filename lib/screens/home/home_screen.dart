import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/constants.dart';
import '../directory/directory_screen.dart';
import '../my_listings/my_listings_screen.dart';
import '../map_view/map_view_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DirectoryScreen(),
    MyListingsScreen(),
    MapViewScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initListings();
    });
  }

  void _initListings() {
    final listingProv = context.read<ListingProvider>();
    final authProv = context.read<AuthProvider>();

    listingProv.subscribeToAllListings();

    if (authProv.userModel != null) {
      listingProv.subscribeToUserListings(authProv.userModel!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // When switching to My Listings, ensure user listings are loaded
            if (index == 1) {
              final uid =
                  context.read<AuthProvider>().userModel?.uid;
              if (uid != null) {
                context
                    .read<ListingProvider>()
                    .subscribeToUserListings(uid);
              }
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Directory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: 'My Listings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map_rounded),
              label: 'Map View',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
