import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navbar.dart';

// The primary color derived from the selected 'Vegetable' pill in the screenshot
const Color primaryColor = Color(0xFF5B8A8A);
const Color backgroundColor = Color(0xFFFFFFFF);
// The light gray background color for input fields and unselected pills
const Color cardColor = Color(0xFFF0F0F0);

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // State variable to hold the currently selected category (null if none selected)
  String? _selectedCategory;
  
  // State variable to hold the currently selected quantity unit
  String _selectedUnit = 'units';
  
  // Text editing controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
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
  
  // Helper to translate category names
  String _translateCategory(String category) {
    final isUrdu = LocaleProvider().localeNotifier.value?.languageCode == 'ur';
    if (!isUrdu) return category; // Keep English labels in English mode
    const categoryMapUrdu = {
      'Fruit': 'پھل',
      'Protein': 'پروٹین',
      'Vegetable': 'سبزی',
      'Dairy': 'ڈیری',
      'Grain': 'اناج',
      'Beverage': 'مشروب',
      'Snack': 'اسنیکس',
      'Spices': 'مسالے',
      'Other': 'دوسرا',
    };
    return categoryMapUrdu[category] ?? category;
  }

  final List<String> _unitOptions = [
    'units',
    'grams',
    'KGs',
    'liters'
  ];

  // Save item to Firebase
  Future<void> _saveItemToInventory() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorDialog(TranslationHelper.t('Authentication Error', 'توثیق کی خرابی'), TranslationHelper.t('Please log in to add items.', 'براہ کرم اشیاء شامل کرنے کے لیے لاگ ان کریں۔'));
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog(TranslationHelper.t('Missing Information', 'معلومات موجود نہیں'), TranslationHelper.t('Item name is required.', 'چیز کا نام ضروری ہے۔'));
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

      // Prepare item data
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
        'notes': _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid, // Store user ID for security rules
      };

      // Remove null values from the map
      itemData.removeWhere((key, value) => value == null);

      // Save to Firebase
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .add(itemData);

      // TODO: TESTING ONLY - Check notifications for newly added item
      // This can be removed later if not needed in production
      final notificationService = NotificationService();
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      
      if (notificationsEnabled) {
        // Note: forceCheck parameter not needed since daily limit is commented out
        await notificationService.checkExpiringItems();
      }

      // Dismiss loading indicator
      Navigator.of(context).pop();

      // Show success message and go back
      _showSuccessDialog();
      
    } catch (e) {
      // Dismiss loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      _showErrorDialog(TranslationHelper.t('Error', 'خرابی'), '${TranslationHelper.t('Failed to save item', 'چیز کو محفوظ کرنے میں ناکامی')}: $e');
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
              child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
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
          title: Text(TranslationHelper.t('Success', 'کامیابی'), style: TextStyle(color: textColor)),
          content: Text(TranslationHelper.t('Item added to inventory successfully!', 'چیز انوینٹری میں کامیابی سے شامل کی گئی!'), style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text(TranslationHelper.t('OK', 'ٹھیک ہے')),
            ),
          ],
        );
      },
    );
  }

  // Helper to translate field labels
  String _getUrduLabel(String label) {
    const labelMap = {
      'Name': 'نام',
      'Category': 'قسم',
      'Quantity': 'مقدار',
      'Purchase Date': 'خریداری کی تاریخ',
      'Expiry Date': 'میعاد ختم ہونے کی تاریخ',
      'Notes': 'نوٹس',
    };
    return labelMap[label] ?? label;
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
          // fontWeight removed due to analyzer constraint
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
    final inputBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final inputBorder = isDarkMode ? const Color(0xFF3A3A3A) : Colors.transparent;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400]!;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(TranslationHelper.t(label, _getUrduLabel(label))),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
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
                      primary: primaryColor,
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
                  color: primaryColor,
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
    final inputBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final inputBorder = isDarkMode ? const Color(0xFF3A3A3A) : Colors.transparent;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400]!;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle(TranslationHelper.t(label, _getUrduLabel(label))),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 18,
                  // fontWeight removed due to analyzer constraint
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
            fillColor: inputBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  // Section for category selection (using InkWell and Container for custom styling)
  Widget _buildCategorySection() {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final unselectedBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final unselectedText = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(TranslationHelper.t('Category', 'قسم')),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : unselectedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _translateCategory(category),
                  style: TextStyle(
                    color: isSelected ? Colors.white : unselectedText,
                    // fontWeight removed due to analyzer constraint
                    fontSize: 14,
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
    final inputBg = isDarkMode ? const Color(0xFF2A2A2A) : cardColor;
    final inputBorder = isDarkMode ? const Color(0xFF3A3A3A) : Colors.transparent;
    final hintColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[400]!;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    final dropdownIconColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(TranslationHelper.t('Quantity', 'مقدار')),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: inputBorder),
                ),
                child: Row(
                  children: [
                    // Decrement button
                    IconButton(
                      icon: Icon(Icons.remove, color: textColor),
                      onPressed: () {
                        setState(() {
                          int current = int.tryParse(_quantityController.text) ?? 1;
                          if (current > 1) {
                            _quantityController.text = (current - 1).toString();
                          }
                        });
                      },
                    ),
                    // Text field
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: TranslationHelper.t('Amount', 'رقم'),
                          hintStyle: TextStyle(color: hintColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          // Ensure minimum value of 1
                          int? num = int.tryParse(value);
                          if (num != null && num < 1) {
                            _quantityController.text = '1';
                          }
                        },
                      ),
                    ),
                    // Increment button
                    IconButton(
                      icon: Icon(Icons.add, color: textColor),
                      onPressed: () {
                        setState(() {
                          int current = int.tryParse(_quantityController.text) ?? 0;
                          _quantityController.text = (current + 1).toString();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: inputBorder),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  icon: Icon(Icons.keyboard_arrow_down, color: dropdownIconColor),
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
    final bgColor = isDarkMode ? const Color(0xFF121212) : backgroundColor;
    final appBarBg = isDarkMode ? const Color(0xFF1E1E1E) : backgroundColor;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: (index) {},
        currentIndex: 1,
        navContext: context,
      ),
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 28),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          TranslationHelper.t('Add Item', 'چیز شامل کریں'),
          style: TextStyle(
            color: textColor,
            // fontWeight removed due to analyzer constraint
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
              _buildCategorySection(),
              const SizedBox(height: 30),
              _buildCustomTextField(
                label: 'Name',
                hintText: TranslationHelper.t('eg. Apple', 'مثال کے طور پر سیب'),
                controller: _nameController,
                isRequired: true,
              ),
              const SizedBox(height: 30),
              _buildQuantitySection(),
              const SizedBox(height: 30),
              _buildDatePickerField(
                label: 'Purchase Date',
                hintText: TranslationHelper.t('YYYY-MM-DD', 'سال-ماہ-دن'),
                controller: _purchaseDateController,
              ),
              const SizedBox(height: 30),
              _buildDatePickerField(
                label: 'Expiry Date',
                hintText: TranslationHelper.t('YYYY-MM-DD', 'سال-ماہ-دن'),
                controller: _expiryDateController,
              ),
              const SizedBox(height: 30),
              _buildCustomTextField(
                label: 'Notes',
                hintText: '...',
                controller: _notesController,
                maxLines: 5,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _saveItemToInventory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    TranslationHelper.t('Add', 'شامل کریں'),
                    style: const TextStyle(
                      fontSize: 18,
                      // fontWeight removed due to analyzer constraint
                      color: Colors.white,
                    ),
                  ),
                ),
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