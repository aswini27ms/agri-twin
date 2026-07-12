import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'twin_dashboard_screen.dart';
import 'village_dashboard_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import '../providers/app_providers.dart';

class MainNavigationWrapper extends ConsumerStatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  ConsumerState<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends ConsumerState<MainNavigationWrapper> {

  List<Widget> get _pages => const [
    HomeScreen(),
    TwinDashboardScreen(),
    VillageDashboardScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFA),
      body: Stack(
        children: [
          _pages[currentIndex],
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Dark blue/black bar
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) => ref.read(navigationIndexProvider.notifier).state = index,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: Colors.white, // Selected icon color
                  unselectedItemColor: Colors.white54,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentIndex == 0 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.home_rounded),
                      ),
                      label: "Home"
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentIndex == 1 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.grid_view_rounded),
                      ),
                      label: "Twin"
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentIndex == 2 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.hub_rounded),
                      ),
                      label: "Village"
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentIndex == 3 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_rounded),
                      ),
                      label: "Chat"
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentIndex == 4 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.document_scanner),
                      ),
                      label: "Scan"
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
