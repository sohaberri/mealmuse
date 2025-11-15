// dishes.dart
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'home.dart';
import 'api_service.dart';
import 'recipe.dart';

// Define the primary color based on the hex code #5C8A94
const Color _primaryColor = Color(0xFF5C8A94);
const Color _primaryColor30 = Color(0x4D5C8A94); // 30% opacity of #5C8A94 (0x4D is 30% of 0xFF)

// --- Main Application Entry Point ---
void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipes App',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blueGrey)
            .copyWith(primary: _primaryColor),
      ),
      home: const RecipesScreen(),
    );
  }
}

// --- 1. The Filter Screen (Updated) ---
class FilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersApplied;
  
  const FilterScreen({super.key, required this.onFiltersApplied});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Data for the filter categories
  final List<String> sortOptions = [
    'popularity',
    'healthiness',
    'time',
    'random'
  ];
  
  final List<String> cuisineOptions = [
    'American',
    'British',
    'Cajun',
    'Caribbean',
    'Chinese',
    'European',
    'Indian',
    'Italian',
    'Korean',
    'Middle Eastern'
  ];

  // State to track selected items
  String selectedSort = 'popularity';
  Set<String> selectedCuisines = {};

  // Helper function to build a list of selectable filter items
  Widget _buildFilterSection(
      String title, List<String> items, bool isSingleSelection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: items.map((item) {
            final isSelected = isSingleSelection 
                ? selectedSort == item
                : selectedCuisines.contains(item);
                
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSingleSelection) {
                    selectedSort = item;
                  } else {
                    if (isSelected) {
                      selectedCuisines.remove(item);
                    } else {
                      selectedCuisines.add(item);
                    }
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryColor
                      : _primaryColor30,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  void _applyFilters() {
    final filters = {
      'sort': selectedSort,
      'cuisines': selectedCuisines.toList(),
    };
    widget.onFiltersApplied(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      selectedSort = 'popularity';
      selectedCuisines.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: const BoxDecoration(
            color: _primaryColor30,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.0)),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 48.0),
                      child: Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildFilterSection('Sort By', sortOptions, true),
            const SizedBox(height: 10.0),
            _buildFilterSection('Cuisine', cuisineOptions, false),
            
            // Apply and Reset Buttons
            const SizedBox(height: 40.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. The Main Screen (Recipes Screen) - UPDATED ---
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Filter state
  Map<String, dynamic> _currentFilters = {
    'sort': 'popularity',
    'cuisines': [],
  };

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes({Map<String, dynamic>? filters}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<dynamic> recipes;
      
      if (filters != null && (filters['cuisines'] as List).isNotEmpty) {
        print('Using complexSearch with filters: $filters');
        // Use complexSearch API when filters are applied
        recipes = await ApiService.fetchRecipesWithComplexSearch(
          sort: filters['sort'] ?? 'popularity',
          cuisines: List<String>.from(filters['cuisines'] ?? []),
          number: 10,
        );
      } else {
        print('Using findByIngredients (no cuisine filters)');
        // Use findByIngredients API when no cuisine filters
        recipes = await ApiService.fetchRecipesByIngredients(
          number: 10,
          ranking: 1,
          ignorePantry: false,
        );
      }
      
      print('Received ${recipes.length} recipes');
      if (recipes.isNotEmpty) {
        print('First recipe: ${recipes[0]}');
      }
      
      setState(() {
        _recipes = recipes;
        _isLoading = false;
        if (filters != null) {
          _currentFilters = filters;
        }
      });
    } catch (e) {
      print('Error in _fetchRecipes: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToFilterScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(
          onFiltersApplied: (filters) {
            _fetchRecipes(filters: filters);
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    _fetchRecipes(filters: {
      'sort': 'popularity',
      'cuisines': [],
    });
  }

  void _navigateToRecipeDetail(Map<String, dynamic> recipe) {
    final recipeId = recipe['id']?.toString() ?? '';
    
    if (recipeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe ID not found'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          recipe: recipe,
          recipeId: recipeId,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    // Handle different response formats
    final String recipeTitle = recipe['title'] ?? 'Untitled Recipe';
    final String imageUrl = recipe['image'] ?? 'https://via.placeholder.com/100x100';
    final int? missedIngredientCount = recipe['missedIngredientCount'];
    final int? readyInMinutes = recipe['readyInMinutes'];
    final int? healthScore = recipe['healthScore'];
    final int? aggregateLikes = recipe['aggregateLikes'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: GestureDetector(
        onTap: () => _navigateToRecipeDetail(recipe),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Recipe Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipeTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Show information based on available data
                    if (missedIngredientCount != null)
                      Text(
                        'Missing ingredients: $missedIngredientCount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    
                    if (readyInMinutes != null)
                      Text(
                        'Ready in: $readyInMinutes minutes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    
                    if (healthScore != null)
                      Text(
                        'Health score: $healthScore',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    
                    if (aggregateLikes != null)
                      Text(
                        'Likes: $aggregateLikes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    
                    // Fallback if no specific data is available
                    if (missedIngredientCount == null && 
                        readyInMinutes == null && 
                        healthScore == null && 
                        aggregateLikes == null)
                      Text(
                        'Tap for details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip() {
    final hasActiveFilters = (_currentFilters['cuisines'] as List).isNotEmpty;
    
    if (!hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Chip(
            label: Text(
              '${(_currentFilters['cuisines'] as List).length} cuisine(s) selected',
            ),
            backgroundColor: _primaryColor30,
            deleteIcon: const Icon(Icons.close),
            onDeleted: _clearFilters,
          ),
          const SizedBox(width: 8),
          Text(
            'Sorted by: ${_currentFilters['sort']}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]!;
    final iconColor = isDarkMode ? const Color(0xFF4A4A4A) : Colors.grey[300]!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.search,
              size: 150.0,
              color: iconColor,
            ),
            const SizedBox(height: 30.0),
            Text(
              'No Recipes Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Try adjusting your filters or adding items to your inventory',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Filters'),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 150.0,
              color: Colors.red[300],
            ),
            const SizedBox(height: 30.0),
            const Text(
              'Error Loading Recipes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _fetchRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              child: const Text('Retry'),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Finding recipes based on your inventory...'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainHomeScreen()),
            );
          },
        ),
        title: Text('Recipes', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.filter_list, size: 28.0, color: textColor),
            onPressed: () => _navigateToFilterScreen(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 28.0, color: textColor),
            onPressed: _fetchRecipes,
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChip(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _hasError
                    ? _buildErrorState()
                    : _recipes.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () => _fetchRecipes(),
                            child: ListView.builder(
                              itemCount: _recipes.length,
                              itemBuilder: (context, index) {
                                return _buildRecipeCard(_recipes[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}