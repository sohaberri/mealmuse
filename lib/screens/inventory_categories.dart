import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'add_item_screen.dart';
import 'navbar.dart';

// --- Data Models ---
class InventoryItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final String category;
  final String? purchaseDate;
  final String? expiryDate;
  final DateTime createdAt;
  final String userId;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.purchaseDate,
    this.expiryDate,
    required this.createdAt,
    required this.userId,
  });

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      quantity: (data['quantity'] is String) 
          ? int.tryParse(data['quantity']) ?? 0 
          : (data['quantity'] ?? 0).toInt(),
      unit: data['unit'] ?? 'pieces',
      category: data['category'] ?? 'Uncategorized',
      purchaseDate: data['purchaseDate'],
      expiryDate: data['expiryDate'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Helper method to calculate days until expiry
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    try {
      final expiry = DateTime.parse(expiryDate!);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      return difference;
    } catch (e) {
      return null;
    }
  }

  // Helper method to get expiry display text
  String get expiryDisplay {
    final days = daysUntilExpiry;
    if (days == null) return 'No expiry';
    if (days < 0) return 'Expired ${days.abs()} days ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return '1 day';
    return '$days days';
  }

  // Helper method to get background color based on category
  Color get backgroundColor {
    switch (category.toLowerCase()) {
      case 'fruit':
        return const Color(0xFF5C8A94);
      case 'vegetable':
        return const Color(0xFF5C8A94);
      case 'meat':
        return const Color(0xFF5C8A94);
      case 'dairy':
        return const Color(0xFF5C8A94);
      case 'grains':
        return const Color(0xFF5C8A94);
      case 'beverages':
        return const Color(0xFF5C8A94);
      default:
        return const Color(0xFF5C8A94);
    }
  }
}

// --- Main Inventory Screen Widget ---
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.category,
  });

  final String category;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late ThemeProvider _themeProvider;
  
  late Stream<QuerySnapshot> _inventoryStream;
  Color? _categoryColor;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.addListener(_onThemeChanged);
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
    _inventoryStream = _getCategoryItems();
    _categoryColor = _getCategoryColor(widget.category);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
    super.dispose();
  }

  Stream<QuerySnapshot> _getCategoryItems() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('inventory')
        .where('category', isEqualTo: widget.category)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return const Color(0xFF5C8A94);
      case 'vegetable':
        return const Color(0xFF5C8A94);
      case 'meat':
        return const Color(0xFF5C8A94);
      case 'dairy':
        return const Color(0xFF5C8A94);
      case 'grains':
        return const Color(0xFF5C8A94);
      case 'beverages':
        return const Color(0xFF5C8A94);
      default:
        return const Color(0xFF5C8A94);
    }
  }

  String _translateCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return 'پھل';
      case 'vegetable':
        return 'سبزی';
      case 'protein':
        return 'پروٹین';
      case 'dairy':
        return 'ڈیری';
      case 'grain':
        return 'اناج';
      case 'beverage':
        return 'مشروب';
      case 'snack':
        return 'اسنیکس';
      case 'spices':
        return 'مصالحے';
      case 'other':
        return 'دیگر';
      default:
        return category;
    }
  }

  // Delete item function
  Future<void> _deleteItem(InventoryItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(item.id)
          .delete();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} ${TranslationHelper.t('deleted successfully', 'کامیابی سے حذف ہو گیا')}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationHelper.t('Error deleting', 'حذف کرتے وقت خرابی')} ${item.name}: $e'),
            backgroundColor: Color.fromARGB(255, 144, 11, 9),
          ),
        );
      }
    }
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(InventoryItem item) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(TranslationHelper.t('Delete Item', 'آئٹم حذف کریں'), style: TextStyle(color: textColor)),
          content: Text(TranslationHelper.t('Are you sure you want to delete ${item.name}?', 'کیا آپ یقینی ہیں کہ آپ ${item.name} کو حذف کرنا چاہتے ہیں؟'), style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(TranslationHelper.t('Cancel', 'منسوخ')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(item);
              },
              child: Text(
                TranslationHelper.t('Delete', 'حذف'),
                style: const TextStyle(color: Color.fromARGB(255, 144, 11, 9)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Navigate to edit screen
  void _navigateToEditItem(BuildContext context, InventoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItemScreen(item: item),
      ),
    );
  }

  // Helper function for navigating to AddItemScreen
  void _navigateToAddItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );
  }

  // Navigate to category-specific search screen
  void _navigateToSearchScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategorySearchScreen(
          category: widget.category,
          categoryColor: _categoryColor!,
        ),
      ),
    );
  }

  // Widget for edit/delete dropdown button
  Widget _buildEditDeleteDropdown(InventoryItem item) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final menuBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final menuTextColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey),
      color: menuBg,
      onSelected: (value) {
        if (value == 'edit') {
          _navigateToEditItem(context, item);
        } else if (value == 'delete') {
          _showDeleteDialog(item);
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, color: Colors.blue),
              const SizedBox(width: 8),
              Text(TranslationHelper.t('Edit', 'ترمیم'), style: TextStyle(color: menuTextColor)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Color.fromARGB(255, 144, 11, 9)),
              const SizedBox(width: 8),
              Text(TranslationHelper.t('Delete', 'حذف'), style: TextStyle(color: menuTextColor)),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for a single list item
  Widget _buildInventoryItem(BuildContext context, InventoryItem item) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey;
    
    Color expiryColor = Colors.grey;
    if (item.daysUntilExpiry != null) {
      if (item.daysUntilExpiry! < 0) {
        expiryColor = Colors.red;
      } else if (item.daysUntilExpiry! <= 3) {
        expiryColor = Colors.orange;
      } else if (item.daysUntilExpiry! <= 7) {
        expiryColor = Colors.yellow[700]!;
      } else {
        expiryColor = Colors.green;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 20,
                              color: textColor,
                            ),
                          ),
                        ),
                        // Edit/Delete dropdown button
                        _buildEditDeleteDropdown(item),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          TranslationHelper.t('Quantity', 'مقدار') + ': ${item.quantity} ${item.unit}',
                          style: TextStyle(fontSize: 14, color: subtitleColor),
                        ),
                      ],
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


  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final searchBarBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[300]!;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 0,
        navContext: context,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 28.0,
                      color: textColor,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  Text(
                    TranslationHelper.t(widget.category, _translateCategory(widget.category)),
                    style: TextStyle(
                      fontSize: 32.0,
                      color: textColor,
                    ),
                  ),
                  // Plus Button (Navigates to AddItemScreen)
                  IconButton(
                    icon: Icon(Icons.add, size: 32.0, color: textColor),
                    onPressed: () => _navigateToAddItem(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _navigateToSearchScreen(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: searchBarBg,
                          borderRadius: BorderRadius.circular(25.0),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey, size: 24.0),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                TranslationHelper.t('Search in ${widget.category}', 'میں تلاش کریں ${_translateCategory(widget.category)}'),
                                style: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600], fontSize: 16.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Curved Background and List
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _inventoryStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2, size: 64, color: Colors.white54),
                              const SizedBox(height: 16),
                              Text(
                                TranslationHelper.t('No items found', 'کوئی آئٹمز نہیں ملے'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                TranslationHelper.t('Add some ${widget.category.toLowerCase()} to your inventory', 'اپنی انوینٹری میں کچھ ${_translateCategory(widget.category).toLowerCase()} شامل کریں'),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _navigateToAddItem(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _categoryColor,
                                ),
                                child: Text(TranslationHelper.t('Add Item', 'آئٹم شامل کریں')),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = snapshot.data!.docs
                          .map((doc) => InventoryItem.fromFirestore(doc))
                          .toList();

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildInventoryItem(context, items[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Edit Item Screen ---
class EditItemScreen extends StatefulWidget {
  final InventoryItem item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  // State variable to hold the currently selected category
  String? _selectedCategory;
  
  // State variable to hold the currently selected quantity unit
  String _selectedUnit = 'units';
  
  // Text editing controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _categoryOptions = [
    'Fruit',
    'Protein',
    'Vegetable',
    'Dairy',
    'Grain',
    'Beverage',
    'Snack',
    'Spices',
    'Other'
  ];

  final List<String> _unitOptions = [
    'units',
    'grams',
    'KGs',
    'liters'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing item data
    _nameController.text = widget.item.name;
    _selectedCategory = widget.item.category;
    _quantityController.text = widget.item.quantity.toString();
    _selectedUnit = widget.item.unit;
    _purchaseDateController.text = widget.item.purchaseDate ?? '';
    _expiryDateController.text = widget.item.expiryDate ?? '';
  }

  // Update item in Firebase
  Future<void> _updateItemInInventory() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorDialog('Authentication Error', 'Please log in to edit items.');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog('Missing Information', 'Item name is required.');
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

      // Prepare updated item data
      final itemData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'quantity': _quantityController.text.trim().isNotEmpty 
            ? _quantityController.text.trim() 
            : null,
        'unit': _selectedUnit,
        'purchaseDate': _purchaseDateController.text.trim().isNotEmpty
            ? _purchaseDateController.text.trim()
            : null,
        'expiryDate': _expiryDateController.text.trim().isNotEmpty
            ? _expiryDateController.text.trim()
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Remove null values from the map
      itemData.removeWhere((key, value) => value == null);

      // Update in Firebase
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(widget.item.id)
          .update(itemData);

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Show success message and go back
      _showSuccessDialog();
      
    } catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _showErrorDialog('Error', 'Failed to update item: $e');
    }
  }

  void _showErrorDialog(String title, String content) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(title, style: TextStyle(color: textColor)),
          content: Text(content, style: TextStyle(color: textColor)),
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

  void _showSuccessDialog() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Success', style: TextStyle(color: textColor)),
          content: Text('Item updated successfully!', style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper widget to consistently style section titles
  Widget _buildSectionTitle(String title) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: textColor,
        ),
      ),
    );
  }

  // Helper widget for date picker fields
  Widget _buildDatePickerField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool isRequired = false,
  }) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final inputBg = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final inputBorder = isDarkMode ? const Color(0xFF3A3A3A) : Colors.transparent;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400]!;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(label),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: const Color(0xFF5B8A8A),
                      onPrimary: Colors.white,
                      surface: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      onSurface: isDarkMode ? const Color(0xFFE1E1E1) : Colors.black,
                    ),
                    dialogBackgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  ),
                  child: child!,
                );
              },
            );
            
            if (picked != null) {
              setState(() {
                controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: inputBg,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: inputBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.text.isEmpty ? hintText : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? hintColor : textColor,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF5B8A8A),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for standard text inputs (Name, Date, Notes)
  Widget _buildCustomTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final fieldBg = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF707070) : Colors.grey[400];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(label),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFF5B8A8A), width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  // Section for category selection
  Widget _buildCategorySection() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final unselectedBg = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final unselectedText = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Category'),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _categoryOptions.map((category) {
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5B8A8A) : unselectedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF5B8A8A) : (isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[300]!),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : unselectedText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Section for Quantity (Number input + Unit Dropdown)
  Widget _buildQuantitySection() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final fieldBg = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0);
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final hintColor = isDarkMode ? const Color(0xFF707070) : Colors.grey[400];
    final dropdownIconColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quantity'),
        Row(
          children: [
            // Quantity number input
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: fieldBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFF5B8A8A), width: 2.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Unit dropdown
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
                  dropdownColor: fieldBg,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: _unitOptions.map((String unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(
                        unit,
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedUnit = newValue;
                      });
                    }
                  },
                  style: TextStyle(fontSize: 16, color: textColor),
                  isExpanded: true,
                ),
              ),
            ),
          ],
        ),
      ],
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
          icon: Icon(Icons.arrow_back_ios_new, size: 28, color: textColor),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Edit Item',
          style: TextStyle(
            color: textColor,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // 1. Category Selection
              _buildCategorySection(),
              const SizedBox(height: 30),

              // 2. Name (Required field)
              _buildCustomTextField(
                label: 'Name',
                hintText: 'eg. Apple',
                controller: _nameController,
                isRequired: true,
              ),
              const SizedBox(height: 30),

              // 3. Quantity (Number input + Unit Dropdown)
              _buildQuantitySection(),
              const SizedBox(height: 30),

              // 4. Purchase Date
              _buildDatePickerField(
                label: 'Purchase Date',
                hintText: 'YYYY-MM-DD',
                controller: _purchaseDateController,
              ),
              const SizedBox(height: 30),

              // 5. Expiry Date
              _buildDatePickerField(
                label: 'Expiry Date',
                hintText: 'YYYY-MM-DD',
                controller: _expiryDateController,
              ),
              const SizedBox(height: 30),

              // 6. Notes
              _buildCustomTextField(
                label: 'Notes',
                hintText: '...',
                controller: _notesController,
                maxLines: 5,
              ),
              const SizedBox(height: 40),

              // 7. Buttons Row
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          side: const BorderSide(color: Color(0xFF5B8A8A)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5B8A8A),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Save Changes Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateItemInInventory();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B8A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _purchaseDateController.dispose();
    _expiryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// --- Category-Specific Search Screen ---
class CategorySearchScreen extends StatefulWidget {
  final String category;
  final Color categoryColor;

  const CategorySearchScreen({
    super.key,
    required this.category,
    required this.categoryColor,
  });

  @override
  State<CategorySearchScreen> createState() => _CategorySearchScreenState();
}

class _CategorySearchScreenState extends State<CategorySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  String _translateCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return 'پھل';
      case 'vegetable':
        return 'سبزی';
      case 'protein':
        return 'پروٹین';
      case 'dairy':
        return 'ڈیری';
      case 'grain':
        return 'اناج';
      case 'beverage':
        return 'مشروب';
      case 'snack':
        return 'اسنیکس';
      case 'spices':
        return 'مصالحے';
      case 'other':
        return 'دیگر';
      default:
        return category;
    }
  }

  void _performCategorySearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('inventory')
          .where('category', isEqualTo: widget.category)
          .get();

      // Perform client-side fuzzy filtering within the category
      final filteredResults = snapshot.docs.where((doc) {
        final String name = doc['name'].toString().toLowerCase();
        final String searchQuery = query.toLowerCase();
        return name.contains(searchQuery);
      }).toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });
    } catch (e) {
      print('Error performing category search: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildSearchResultItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final item = InventoryItem.fromFirestore(doc);
    
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    
    Color expiryColor = Colors.grey;
    if (item.daysUntilExpiry != null) {
      if (item.daysUntilExpiry! < 0) {
        expiryColor = Colors.red;
      } else if (item.daysUntilExpiry! <= 3) {
        expiryColor = Colors.orange;
      } else if (item.daysUntilExpiry! <= 7) {
        expiryColor = Colors.yellow[700]!;
      } else {
        expiryColor = Colors.green;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      color: cardBg,
      child: ListTile(
        title: Text(
          data['name'] ?? 'Unknown Item',
          style: TextStyle(fontSize: 16, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${data['quantity'] ?? ''} ${data['unit'] ?? ''}',
              style: TextStyle(color: subtitleColor),
            ),
            Text(
              'Expires: ${item.expiryDisplay}',
              style: TextStyle(
                color: expiryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          icon: Icon(Icons.arrow_back_ios_new, size: 28, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: TranslationHelper.t('Search in ${widget.category}...', 'میں تلاش کریں ${_translateCategory(widget.category)}...'),
            border: InputBorder.none,
            hintStyle: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600]),
          ),
          onChanged: (value) {
            _performCategorySearch(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey),
              onPressed: () {
                _searchController.clear();
                _performCategorySearch('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search info
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                TranslationHelper.t('Search for items in ${widget.category}', 'میں آئٹمز کے لیے تلاش کریں ${_translateCategory(widget.category)}'),
                style: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Loading indicator
          if (_isSearching)
            CircularProgressIndicator(
              color: isDarkMode ? const Color(0xFF5C8A94) : null,
            ),
          
          // Search results
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty && !_isSearching
                ? Center(
                    child: Text(
                      TranslationHelper.t('No items found in this category', 'اس کیٹیگری میں کوئی آئٹمز نہیں ملے'),
                      style: TextStyle(color: isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultItem(_searchResults[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Updated Detail Screen with Delete Option ---
class ItemDetailScreen extends StatelessWidget {
  final InventoryItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 0,
        navContext: context,
      ),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(item.name, style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 144, 11, 9)),
            onPressed: () => _showDeleteDialog(context, item),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: cardBg,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: Icon(Icons.inventory_2, size: 40, color: item.backgroundColor),
                      title: Text(
                        item.name,
                        style: TextStyle(fontSize: 24, color: textColor),
                      ),
                      subtitle: Text(item.category, style: TextStyle(color: subtitleColor)),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Quantity', '${item.quantity} ${item.unit}'),
                    _buildDetailRow('Purchase Date', item.purchaseDate ?? 'Not set'),
                    _buildDetailRow('Expiry Date', item.expiryDate ?? 'Not set'),
                    _buildDetailRow('Expires In', item.expiryDisplay),
                    _buildDetailRow('Added On', 
                      '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final labelColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black87;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 16, color: labelColor),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: textColor),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, InventoryItem item) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final dialogBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Delete Item', style: TextStyle(color: textColor)),
          content: Text('Are you sure you want to delete ${item.name}?', style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(context, item);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color.fromARGB(255, 144, 11, 9)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(BuildContext context, InventoryItem item) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    
    if (user == null) return;

    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .doc(item.id)
          .delete();
      
      Navigator.of(context).pop(); // Go back to previous screen
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting ${item.name}: $e'),
          backgroundColor: Color.fromARGB(255, 144, 11, 9),
        ),
      );
    }
  }
}

// --- Usage Example ---
class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Manager',
      debugShowCheckedModeBanner: false,
      home: InventoryScreen(
        category: 'Fruit', // Only parameter needed - the rest is automatic
      ),
    );
  }
}