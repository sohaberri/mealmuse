import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginScreen
import 'register.dart'; // Import the RegisterScreen

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Custom color from the design (5C8A94)
  static const Color primaryTeal = Color(0xFF5C8A94);
  
  // Using a network placeholder for the image since the Google Drive link
  // is not directly usable as a Flutter asset or network URL.
  // You should replace this with Image.asset('path/to/your/image.png') 
  // after adding the image to your project's assets folder.
  // 
  final String foodImage = "assets/images/logo.png";

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // Background for the top content area
      body: Column(
        children: [
          // === TOP SECTION (Image and Title) ===
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration Image
                    // IMPORTANT: Replace Image.network with Image.asset after adding your image.
                    Image.asset(
                      foodImage,
                      height: screenHeight * 0.3,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    // Main Title
                    const Text(
                      'Meal Muse',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    const Text(
                      'Your go to pantry assistant!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === BOTTOM SECTION (Buttons) ===
          Container(
            height: screenHeight * 0.35, // Proportional height for the button area
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryTeal,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50.0), // Rounded top-left corner
                topRight: Radius.circular(50.0), // Rounded top-right corner
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Login Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to LoginScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- 'Or' Text ---
                  const Text(
                    'Or',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- Register Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to RegisterScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
