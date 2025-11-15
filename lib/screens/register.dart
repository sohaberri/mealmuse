import 'package:flutter/material.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const Color _cardColor = Color(0xFF5C8A94);
  static const Color _black = Colors.black;
  static const Color _primaryText = Colors.white;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Check if username is unique
  Future<bool> _isUsernameUnique(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print("Error checking username uniqueness: $e");
      return false;
    }
  }

  // Save user data to Firestore and create subcollections
  Future<void> _saveUserToFirestore(User user, String username) async {
    try {
      // Create the main user document
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'username': username.toLowerCase(),
        'displayName': username,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Create empty inventory subcollection with a default document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc('default')
          .set({
            'createdAt': FieldValue.serverTimestamp(),
            'items': [], // Empty array to store inventory items
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      // Create empty saved_recipes subcollection with a default document
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .doc('default')
          .set({
            'createdAt': FieldValue.serverTimestamp(),
            'recipes': [], // Empty array to store saved recipe IDs or data
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      print("User data and subcollections created successfully");
    } catch (e) {
      print("Error saving user to Firestore: $e");
      rethrow;
    }
  }

  // Password validation function
  String? _validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // Username validation function
  String? _validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    if (username.length > 20) {
      return 'Username cannot exceed 20 characters';
    }
    return null;
  }

  // Reusable text field builder for consistent styling
  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controller,
    VoidCallback? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.black87),
        onChanged: (value) {
          if (onChanged != null) {
            onChanged();
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        ),
      ),
    );
  }

  Future<void> _registerUser(BuildContext context) async {
    // Validate all fields are filled
    if (_emailController.text.isEmpty || 
        _usernameController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog(context, 'Missing Information', 'Please fill in all fields.');
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showErrorDialog(context, 'Invalid Email', 'Please enter a valid email address.');
      return;
    }

    // Validate username format
    final usernameError = _validateUsername(_usernameController.text.trim());
    if (usernameError != null) {
      _showErrorDialog(context, 'Invalid Username', usernameError);
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(context, 'Password Mismatch', 'Passwords do not match. Please try again.');
      return;
    }

    // Validate password strength
    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      _showErrorDialog(context, 'Weak Password', 
          '$passwordError.\n\nPassword requirements:\n• At least 6 characters\n• At least one number (0-9)\n• At least one special character (!@#\$%^&* etc.)');
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Check if username is unique
      final isUnique = await _isUsernameUnique(_usernameController.text.trim());
      if (!isUnique) {
        Navigator.of(context).pop(); // Dismiss loading
        _showErrorDialog(context, 'Username Taken', 'This username is already taken. Please choose a different one.');
        return;
      }

      // Firebase authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user data to Firestore and create subcollections
      await _saveUserToFirestore(
        userCredential.user!, 
        _usernameController.text.trim()
      );

      // Optional: Update user display name in Auth
      if (userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(_usernameController.text.trim());
        } catch (e) {
          print("Error updating display name: $e");
          // Continue even if display name update fails
        }
      }

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Show success message and navigate to login
      _showSuccessDialog(context);
    } on FirebaseAuthException catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Handle errors
      String errorMessage = 'An error occurred during registration';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Email/password accounts are not enabled.';
      }

      _showErrorDialog(context, 'Registration Failed', errorMessage);
    } catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show generic error
      _showErrorDialog(context, 'Error', 'An unexpected error occurred: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Successful'),
          content: const Text('Your account has been created successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login screen
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Widget to show password requirements
  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: TextStyle(
              color: _primaryText.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          _buildRequirementLine('At least 6 characters', password.length >= 6),
          _buildRequirementLine('At least one number', RegExp(r'[0-9]').hasMatch(password)),
          _buildRequirementLine('At least one special character', 
              RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)),
        ],
      ),
    );
  }

  // Widget to show username requirements
  // Widget _buildUsernameRequirements() {
  //   final username = _usernameController.text;
    
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'Username requirements:',
  //           style: TextStyle(
  //             color: _primaryText.withOpacity(0.8),
  //             fontSize: 12,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         _buildRequirementLine('3-20 characters', username.length >= 3 && username.length <= 20),
  //         _buildRequirementLine('Letters, numbers, underscores only', 
  //             username.isEmpty || RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRequirementLine(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isMet ? Colors.green : Colors.grey,
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isMet ? Colors.green : Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: _primaryText,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Top Section: Logo and Title ---
            Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.1,
                left: 30.0,
                right: 30.0,
                bottom: 30.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.red,
                        size: 60,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lets Create\nYour Account!',
                    style: TextStyle(
                      color: _black,
                      fontSize: size.width * 0.09,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // --- Bottom Section: Form Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 50,
                left: 30,
                right: 30,
                bottom: 50,
              ),
              decoration: const BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50.0),
                  topRight: Radius.circular(50.0),
                ),
              ),
              child: Column(
                children: [
                  // Text Fields
                  _buildTextField(
                    hintText: 'Email', 
                    icon: Icons.mail_outline,
                    controller: _emailController,
                  ),
                  _buildTextField(
                    hintText: 'Username', 
                    icon: Icons.person_outline,
                    controller: _usernameController,
                    onChanged: () => setState(() {}), // Trigger rebuild when username changes
                  ),
                  // Username requirements
                  // _buildUsernameRequirements(),
                  _buildTextField(
                    hintText: 'Password', 
                    icon: Icons.lock_outline, 
                    isPassword: true,
                    controller: _passwordController,
                    onChanged: () => setState(() {}), // Trigger rebuild when password changes
                  ),
                  // Password requirements
                  _buildPasswordRequirements(),
                  _buildTextField(
                    hintText: 'Retype Password', 
                    icon: Icons.lock_outline, 
                    isPassword: true,
                    controller: _confirmPasswordController,
                    onChanged: () => setState(() {}), // Trigger rebuild when confirm password changes
                  ),
                  
                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _registerUser(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryText,
                        foregroundColor: _black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // "Sign In" link
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ));
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: _primaryText.withOpacity(0.8), fontSize: 16),
                        children: const <TextSpan>[
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: _primaryText,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}