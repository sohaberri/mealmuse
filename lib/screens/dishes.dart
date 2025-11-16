// dishes.dart
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'home.dart';
import 'api_service.dart';
import 'recipe.dart';
import 'navbar.dart';

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

  @override
  void initState() {
    super.initState();
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  bool get _isUrdu => LocaleProvider().localeNotifier.value?.languageCode == 'ur';

  String _translateSort(String value) {
    if (!_isUrdu) return value;
    switch (value) {
      case 'popularity': return 'مقبولیت';
      case 'healthiness': return 'صحت';
      case 'time': return 'وقت';
      case 'random': return 'بے ترتیب';
      default: return value;
    }
  }

  String _translateCuisine(String value) {
    if (!_isUrdu) return value;
    switch (value) {
      case 'American': return 'امریکی';
      case 'British': return 'برطانوی';
      case 'Cajun': return 'کیجون';
      case 'Caribbean': return 'کریبین';
      case 'Chinese': return 'چینی';
      case 'European': return 'یورپی';
      case 'Indian': return 'بھارتی';
      case 'Italian': return 'اطالوی';
      case 'Korean': return 'کوریائی';
      case 'Middle Eastern': return 'مشرقِ وسطی';
      default: return value;
    }
  }

  // Helper function to build a list of selectable filter items
  // Legacy _buildFilterSection replaced by dark-mode aware helper.

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
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final filterTitle = TranslationHelper.t('Filter', 'فلٹر');
    final sortByLabel = TranslationHelper.t('Sort By', 'ترتیب دیں');
    final cuisineLabel = TranslationHelper.t('Cuisine', 'کھانا');
    final resetLabel = TranslationHelper.t('Reset', 'دوبارہ سیٹ کریں');
    final applyFiltersLabel = TranslationHelper.t('Apply Filters', 'فلٹر لاگو کریں');

    // Dark / light adaptive colors
    final background = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final headerBackground = isDarkMode ? const Color(0xFF1E1E1E) : _primaryColor30;
    final primaryText = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final chipUnselected = isDarkMode ? const Color(0xFF2A2A2A) : _primaryColor30;
    final chipSelectedText = Colors.white;
    final chipUnselectedText = primaryText;
    final resetBtnBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[300];
    final resetBtnFg = isDarkMode ? primaryText : Colors.black;
    final applyBtnBg = _primaryColor;
    final applyBtnFg = Colors.white;

    return Scaffold(
      backgroundColor: background,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 1,
        navContext: context,
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: BoxDecoration(
            color: headerBackground,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30.0)),
          ),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: primaryText),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48.0),
                      child: Text(
                        filterTitle,
                        style: TextStyle(
                          fontSize: 28.0,
                          color: primaryText,
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
            // Inject colors through theme by temporarily overriding defaults
            _buildFilterSectionWithColors(sortByLabel, sortOptions, true, chipSelectedText, chipUnselectedText, chipUnselected),
            const SizedBox(height: 10.0),
            _buildFilterSectionWithColors(cuisineLabel, cuisineOptions, false, chipSelectedText, chipUnselectedText, chipUnselected),
            
            // Apply and Reset Buttons
            const SizedBox(height: 40.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resetBtnBg,
                      foregroundColor: resetBtnFg,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(resetLabel),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: applyBtnBg,
                      foregroundColor: applyBtnFg,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(applyFiltersLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Wrapper to allow dark-mode aware chip colors without rewriting original method drastically
  Widget _buildFilterSectionWithColors(String title, List<String> items, bool isSingleSelection,
      Color selectedTextColor, Color unselectedTextColor, Color unselectedBgColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 24.0,
              color: unselectedTextColor,
            ),
          ),
        ),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: items.map((item) {
            final isSelected = isSingleSelection ? selectedSort == item : selectedCuisines.contains(item);
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : unselectedBgColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  isSingleSelection ? _translateSort(item) : _translateCuisine(item),
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isSelected ? selectedTextColor : unselectedTextColor,
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
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
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
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    
    // Handle different response formats
    final String recipeTitle = recipe['title'] ?? 'Untitled Recipe';
    final String imageUrl = recipe['image'] ?? 'https://via.placeholder.com/100x100';
    final int? missedIngredientCount = recipe['missedIngredientCount'];
    final int? readyInMinutes = recipe['readyInMinutes'];
    final int? healthScore = recipe['healthScore'];
    final int? aggregateLikes = recipe['aggregateLikes'];

    return Card(
      color: cardBg,
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
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        // fontWeight removed due to analyzer constraint
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
                          color: subtitleColor,
                        ),
                      ),
                    
                    if (readyInMinutes != null)
                      Text(
                        'Ready in: $readyInMinutes minutes',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    
                    if (healthScore != null)
                      Text(
                        'Health score: $healthScore',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    
                    if (aggregateLikes != null)
                      Text(
                        'Likes: $aggregateLikes',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
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
                          color: subtitleColor,
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
    
    final noRecipesFoundLabel = TranslationHelper.t('No Recipes Found', 'کوئی ریسیپیز نہیں ملیں');
    final tryAdjustingLabel = TranslationHelper.t('Try adjusting your filters or adding items to your inventory', 'اپنی فلٹرز کو ایڈجسٹ کرنے یا اپنی انوینٹری میں آئٹمز شامل کرنے کی کوشش کریں');
    final clearFiltersLabel = TranslationHelper.t('Clear Filters', 'فلٹرز صاف کریں');
    
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
              noRecipesFoundLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                // fontWeight removed due to analyzer constraint
                color: textColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              tryAdjustingLabel,
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
              child: Text(clearFiltersLabel),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final errorLoadingLabel = TranslationHelper.t('Error Loading Recipes', 'ریسیپیز لوڈ کرنے میں خرابی');
    final retryLabel = TranslationHelper.t('Retry', 'دوبارہ کوشش کریں');

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
            Text(
              errorLoadingLabel,
              style: const TextStyle(
                fontSize: 20.0,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage,
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
              child: Text(retryLabel),
            ),
            const SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final findingRecipesLabel = TranslationHelper.t('Finding recipes based on your inventory...', 'آپ کی انوینٹری کی بنیاد پر ریسیپیز تلاش کی جا رہی ہے...');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 20),
          Text(findingRecipesLabel, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    final recipesTitle = TranslationHelper.t('Recipes', 'ریسیپیز');
    
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 1,
        navContext: context,
      ),
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
        title: Text(recipesTitle, style: TextStyle(color: textColor)),
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