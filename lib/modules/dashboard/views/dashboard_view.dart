import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';
import '../../home/views/home_view.dart';
import '../../analytics/views/analytics_view.dart';
import '../../appliances/views/appliances_view.dart';
import '../../profile/views/profile_view.dart';
import '../../feedback/views/feedback_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeView(),
      AnalyticsView(),
      AppliancesView(),
      ProfileView(),
      FeedbackView(),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: pages,
      )),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changePage,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_outlined),
              activeIcon: Icon(Icons.bolt),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.kitchen_outlined),
              activeIcon: Icon(Icons.kitchen),
              label: 'Appliances',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              activeIcon: Icon(Icons.rate_review),
              label: 'Feedback',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout_outlined),
              activeIcon: Icon(Icons.logout),
              label: 'Logout',
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      )),
    );
  }
}
