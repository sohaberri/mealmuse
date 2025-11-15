import 'package:flutter/material.dart';
import 'UsersScreen.dart';
import '../screens/homepage.dart'; // Assuming HomePage is imported
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Admin Account',
      debugShowCheckedModeBanner: false,
      home: AdminAccountScreen(),
    );
  }
}

class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({super.key}); // Remove const from constructor

  // Define the main colors used in the design
  static const Color primaryColor = Color(0xFF6A8E9A); // The teal/blue-grey color
  static const Color accentColor = Colors.white; 

  // Firebase Auth instance - remove 'final' and initialize in build method
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Logout function
  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Navigate to HomePage after successful logout
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false, // Remove all routes from stack
      );
    } catch (e) {
      // Handle any errors that occur during logout
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: accentColor,
      body: Column(
        children: <Widget>[
          // 1. Custom Rounded Header/AppBar Area
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50.0),
                bottomRight: Radius.circular(50.0),
              ),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Welcome to\nAdmin Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // 2. The "Check Users" Button
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
            child: SizedBox(
              height: 70,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsersScreen()),
                  );
                },
                icon: const Icon(
                  Icons.person,
                  size: 24,
                  color: accentColor,
                ),
                label: const Text(
                  'Check Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),

          // 3. Logout Button
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
            child: SizedBox(
              height: 70,
              child: ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(
                  Icons.logout,
                  size: 24,
                  color: Colors.white,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 82, 17, 12), // Different color for logout
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),

          // Takes up remaining space
          const Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}