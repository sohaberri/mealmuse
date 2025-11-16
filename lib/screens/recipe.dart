import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import 'home.dart';
import 'api_service.dart';

// The main screen widget containing the recipe details
class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final String recipeId; // Add this line
  
  const RecipeDetailScreen({
    super.key, 
    required this.recipe,
    required this.recipeId, // Add this parameter
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? _recipeDetails;
  List<dynamic>? _recipeInstructions;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      // Use the recipeId from the constructor
      final recipeId = widget.recipeId;
      if (recipeId.isEmpty) {
        throw Exception('Recipe ID not found');
      }

      // Convert String to int for the API calls
      final int recipeIdInt = int.tryParse(recipeId) ?? 0;
      if (recipeIdInt == 0) {
        throw Exception('Invalid Recipe ID: $recipeId');
      }

      // Fetch recipe details and instructions
      final details = await ApiService.fetchRecipeDetails(recipeIdInt);
      final instructions = await ApiService.fetchRecipeInstructions(recipeIdInt);

      setState(() {
        _recipeDetails = details;
        _recipeInstructions = instructions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Helper method to get ingredients from recipe details
  List<dynamic> get _ingredients {
    return _recipeDetails?['extendedIngredients'] ?? [];
  }

  // Helper method to get recipe instructions
  List<dynamic> get _instructions {
    if (_recipeInstructions == null || _recipeInstructions!.isEmpty) {
      return [];
    }
    return _recipeInstructions!.first['steps'] ?? [];
  }

  // Helper method to get cooking time
  int get _cookingTime {
    return _recipeDetails?['readyInMinutes'] ?? 0;
  }

  // Helper method to get servings
  int get _servings {
    return _recipeDetails?['servings'] ?? 0;
  }

  // Helper widget to build ingredient rows
  Widget _buildIngredientItem(dynamic ingredient) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    final name = ingredient['nameClean'] ?? ingredient['original'] ?? 'Unknown ingredient';
    final amount = ingredient['amount'] ?? '';
    final unit = ingredient['unit'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Color(0xFF5C8A94)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '${amount.toString()} $unit ${name.toString().capitalize()}',
              style: TextStyle(fontSize: 16.0, height: 1.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build recipe steps
  Widget _buildRecipeStep(dynamic step) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    final stepNumber = step['number'] ?? 0;
    final stepText = step['step'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $stepNumber:',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              height: 1.5,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            stepText,
            style: TextStyle(fontSize: 16.0, height: 1.5, color: textColor),
          ),
        ],
      ),
    );
  }

  // Loading widget
  Widget _buildLoadingState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF5C8A94)),
          SizedBox(height: 20),
          Text(
            'Loading recipe details...',
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  // Error widget
  Widget _buildErrorState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 20),
            Text(
              'Failed to load recipe details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchRecipeDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5C8A94),
              ),
              child: Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = Color(0xFF5C8A94);
    final double bottomButtonAreaHeight = 120.0;

    // Use data from the original recipe card as fallback
    final String recipeTitle = _recipeDetails?['title'] ?? widget.recipe['title'] ?? 'Delicious Recipe';
    final String recipeImage = _recipeDetails?['image'] ?? widget.recipe['image'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=1780&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
    final int likes = widget.recipe['likes'] ?? 0;

    if (_isLoading) {
      final isDarkMode = ThemeProvider().darkModeEnabled;
      final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
      final iconColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildLoadingState(),
      );
    }

    if (_hasError) {
      final isDarkMode = ThemeProvider().darkModeEnabled;
      final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
      final iconColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
      
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _buildErrorState(),
      );
    }

    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      
      body: Stack(
        children: [
          // Scrollable Content Area
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1. Image Section (Circular with Shadow)
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100.0),
                      child: Image.network(
                        recipeImage,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator(color: buttonColor));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.fastfood, size: 50, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 32),

                // 2. Title
                Text(
                  recipeTitle,
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 8),

                // 3. Metadata
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Likes: $likes',
                      style: TextStyle(fontSize: 16.0, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ready in: $_cookingTime minutes',
                      style: TextStyle(fontSize: 16.0, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Servings: $_servings',
                      style: TextStyle(fontSize: 16.0, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[700]),
                    ),
                  ],
                ),
                
                Divider(height: 32, thickness: 1, color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200]),
                
                // --- Ingredients Section ---
                Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                
                SizedBox(height: 16),
                
                if (_ingredients.isNotEmpty)
                  ..._ingredients.map(_buildIngredientItem)
                else
                  Text(
                    'No ingredient information available',
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),

                SizedBox(height: 32),

                // --- Recipe Instructions Section ---
                Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 16),
                
                if (_instructions.isNotEmpty)
                  ..._instructions.map(_buildRecipeStep)
                else
                  Text(
                    'No instruction information available',
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),

                // Padding for the fixed button
                SizedBox(height: bottomButtonAreaHeight),
              ],
            ),
          ),
          
          // Fixed Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    _saveRecipe(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Save Recipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveRecipe(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to save recipes'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final recipeId = widget.recipe['id'];
      if (recipeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe ID not found'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save to Firebase Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .add({
        'recipeId': recipeId,
        'title': widget.recipe['title'] ?? 'Untitled Recipe',
        'image': widget.recipe['image'] ?? '',
        'likes': widget.recipe['likes'] ?? 0,
        'missedIngredientCount': widget.recipe['missedIngredientCount'] ?? 0,
        'usedIngredientCount': widget.recipe['usedIngredientCount'] ?? 0,
        'savedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe saved to your collection!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving recipe: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save recipe: $e'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}