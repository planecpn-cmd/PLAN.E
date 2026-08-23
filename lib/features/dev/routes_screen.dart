// Developer Route Index
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DevRoutesScreen extends StatelessWidget {
  const DevRoutesScreen({super.key});

  static const List<Map<String, String>> routes = [
    {'id': 'PL-01', 'name': 'Splash', 'path': '/'},
    {'id': 'PL-02', 'name': 'Onboarding Slide 1', 'path': '/onboarding/1'},
    {'id': 'PL-03', 'name': 'Onboarding Slide 2', 'path': '/onboarding/2'},
    {'id': 'PL-04', 'name': 'Onboarding Slide 3', 'path': '/onboarding/3'},
    {'id': 'PL-05', 'name': 'Select Interests', 'path': '/interests'},
    {'id': 'RM-01', 'name': 'Sign Up', 'path': '/auth/sign-up'},
    {'id': 'RM-02', 'name': 'Login', 'path': '/auth/login'},
    {'id': 'RM-03', 'name': 'Forgot Password', 'path': '/auth/forgot-password'},
    {'id': 'RM-04', 'name': 'Reset Result', 'path': '/auth/reset-result'},
    {'id': 'RM-05', 'name': 'Auth Required Sheet', 'path': '/auth/required'},
    {'id': 'PL-06', 'name': 'Home', 'path': '/home'},
    {'id': 'PL-07', 'name': 'Explore', 'path': '/explore'},
    {'id': 'PL-08', 'name': 'Search Results', 'path': '/search'},
    {
      'id': 'RM-06',
      'name': 'Collection / See All',
      'path': '/collection/treks',
    },
    {'id': 'RM-07', 'name': 'Filter Sheet', 'path': '/filter'},
    {'id': 'PL-09', 'name': 'Experience Details', 'path': '/experience/1'},
    {'id': 'RM-08', 'name': 'Map View', 'path': '/map'},
    {'id': 'PL-10', 'name': 'Booking Form', 'path': '/booking/1'},
    {
      'id': 'PL-11',
      'name': 'Booking Confirmation',
      'path': '/booking/confirmation/1',
    },
    {'id': 'PL-12', 'name': 'Saved Experiences', 'path': '/saved'},
    {
      'id': 'PL-13/14',
      'name': 'My Plans (Upcoming / Drafts)',
      'path': '/plans',
    },
    {'id': 'RM-10', 'name': 'Interactive Itinerary', 'path': '/itinerary/1'},
    {'id': 'RM-11', 'name': 'Trip Chat', 'path': '/chat/1'},
    {'id': 'RM-12', 'name': 'Gear Checklist', 'path': '/gear/1'},
    {'id': 'RM-13', 'name': 'Budget Tracker', 'path': '/budget/1'},
    {'id': 'RM-25', 'name': 'Delete Draft Dialog', 'path': '/plans'},
    {
      'id': 'PL-15/16',
      'name': 'Plans (Past / Cancelled)',
      'path': '/plans?tab=past',
    },
    {'id': 'RM-14', 'name': 'Leave Review', 'path': '/review/1'},
    {'id': 'RM-15', 'name': 'Review Submitted', 'path': '/review/submitted'},
    {'id': 'PL-17', 'name': 'Profile', 'path': '/profile'},
    {'id': 'RM-16', 'name': 'Edit Profile', 'path': '/profile/edit'},
    {
      'id': 'RM-17',
      'name': 'Payment Methods',
      'path': '/profile/payment-methods',
    },
    {'id': 'RM-18', 'name': 'Notifications', 'path': '/profile/notifications'},
    {'id': 'RM-19', 'name': 'Language & Region', 'path': '/profile/language'},
    {'id': 'RM-20', 'name': 'Help & Support', 'path': '/profile/help'},
    {'id': 'RM-21', 'name': 'More Settings', 'path': '/profile/settings'},
    {'id': 'RM-27', 'name': 'My Reviews', 'path': '/profile/my-reviews'},
    {'id': 'RM-26', 'name': 'Logout Dialog', 'path': '/profile'},
    {'id': 'PL-18', 'name': 'Become a Host', 'path': '/host'},
    {'id': 'RM-22', 'name': 'Host Step 1', 'path': '/host/step-1'},
    {'id': 'PL-19', 'name': 'Host Step 2', 'path': '/host/step-2'},
    {'id': 'RM-23', 'name': 'Host Step 3', 'path': '/host/step-3'},
    {'id': 'RM-24', 'name': 'Host Step 4', 'path': '/host/step-4'},
    {
      'id': 'PL-20',
      'name': 'Host Application Submitted',
      'path': '/host/submitted',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLAN E — 34 Routes Inventory')),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return ListTile(
            leading: CircleAvatar(child: Text(route['id']!.split('-').first)),
            title: Text('${route['id']} — ${route['name']}'),
            subtitle: Text(route['path']!),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push(route['path']!),
          );
        },
      ),
    );
  }
}
