import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'navbar.dart';

// --- Data Model for a single expiring item ---
class ExpiringItem {
  final String name;
  final int count;
  final String expiry;
  final IconData icon;
  final DateTime expiryDate; // Added for sorting

  const ExpiringItem({
    required this.name,
    required this.count,
    required this.expiry,
    required this.icon,
    required this.expiryDate,
  });
}

class ExpiringItemsScreen extends StatefulWidget {
  const ExpiringItemsScreen({super.key});

  @override
  State<ExpiringItemsScreen> createState() => _ExpiringItemsScreenState();
}

class _ExpiringItemsScreenState extends State<ExpiringItemsScreen> {
  // --- Color Palette ---
  static const Color _primaryRed = Color(0xFFBC0805);
  static const Color _primaryWhite = Colors.white;
  static const Color _primaryBlack = Colors.black;

  List<ExpiringItem> _expiringItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExpiringItems();
  }

  // Method to load expiring items from Firebase
  Future<void> _loadExpiringItems() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = TranslationHelper.t('User not logged in', 'صارف لاگ ان نہیں ہے');
          _isLoading = false;
        });
        return;
      }

      final inventorySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('inventory')
          .get();

      final List<ExpiringItem> items = [];

      for (final doc in inventorySnapshot.docs) {
        final data = doc.data();
        final expiryDateStr = data['expiryDate'] as String?;

        // Skip items without expiry date
        if (expiryDateStr == null || expiryDateStr.isEmpty) {
          continue;
        }

        try {
          // Parse expiry date
          final expiryDate = DateTime.parse(expiryDateStr);
          final now = DateTime.now();
          final difference = expiryDate.difference(now);

          // Calculate days until expiry
          final daysUntilExpiry = difference.inDays;
          String expiryText;

          if (daysUntilExpiry < 0) {
            expiryText = TranslationHelper.t('Expired', 'ختم شدہ');
          } else if (daysUntilExpiry == 0) {
            expiryText = TranslationHelper.t('Today', 'آج');
          } else if (daysUntilExpiry == 1) {
            expiryText = TranslationHelper.t('1 Day', '1 دن');
          } else if (daysUntilExpiry < 7) {
            expiryText = '$daysUntilExpiry ${TranslationHelper.t('Days', 'دن')}';
          } else if (daysUntilExpiry < 30) {
            final weeks = (daysUntilExpiry / 7).ceil();
            expiryText = weeks == 1 ? TranslationHelper.t('1 Week', '1 ہفتہ') : '$weeks ${TranslationHelper.t('Weeks', 'ہفتے')}';
          } else {
            final months = (daysUntilExpiry / 30).ceil();
            expiryText = months == 1 ? TranslationHelper.t('1 Month', '1 ماہ') : '$months ${TranslationHelper.t('Months', 'مہینے')}';
          }

          // Get appropriate icon based on category
          final category = data['category'] as String? ?? 'Other';
          final icon = _getIconForCategory(category);

          // Parse quantity
          final quantityStr = data['quantity'] as String? ?? '0';
          final quantity = int.tryParse(quantityStr) ?? 0;

          items.add(ExpiringItem(
            name: data['name'] as String? ?? TranslationHelper.t('Unknown Item', 'نامعلوم آئٹم'),
            count: quantity,
            expiry: expiryText,
            icon: icon,
            expiryDate: expiryDate,
          ));
        } catch (e) {
          // Skip items with invalid date format
          continue;
        }
      }

      // Sort items by expiry date (earliest first)
      items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

      setState(() {
        _expiringItems = items;
        _isLoading = false;
      });
    } catch (e) {
        setState(() {
        _errorMessage = "${TranslationHelper.t('Error loading expiring items', 'ختم ہونے والی اشیاء لوڈ کرنے میں خرابی')}: $e";
        _isLoading = false;
      });
    }
  }

  // Helper method to get icon based on category
  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fruit':
        return Icons.local_florist_outlined;
      case 'vegetable':
        return Icons.spa_outlined;
      case 'dairy':
        return Icons.local_cafe_outlined;
      case 'meat':
        return Icons.fastfood_outlined;
      case 'bakery':
        return Icons.bakery_dining;
      case 'grain':
        return Icons.grass_outlined;
      case 'beverage':
        return Icons.local_drink_outlined;
      default:
        return Icons.shopping_basket_outlined;
    }
  }

  // Reusable widget for the item card in the list
  Widget _buildItemCard(ExpiringItem item) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : _primaryWhite;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : _primaryBlack;
    final subtitleColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.grey[600];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: _primaryBlack.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${TranslationHelper.t('Count', 'تعداد')}: ${item.count}',
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${TranslationHelper.t('Expires In', 'میعاد باقی')}: ${item.expiry}',
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryRed,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: _primaryWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavToMainShell(BuildContext context, int index) {
    if (index != 3) {
      Navigator.pop(context);
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: _primaryRed,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExpiringItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: _primaryWhite,
              ),
              child: Text(TranslationHelper.t('Retry', 'دوبارہ کوشش کریں')),
            ),
          ],
        ),
      );
    }

    if (_expiringItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: _primaryRed,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              TranslationHelper.t('No expiring items found', 'کوئی ختم ہونے والی اشیاء نہیں ملیں'),
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              TranslationHelper.t('Add expiry dates to your inventory items to see them here', 'اپنی انوینٹری آئٹمز میں میعاد ختم ہونے کی تاریخیں شامل کریں تاکہ یہاں دکھائی دیں'),
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Padding(
            padding: index == 0 ? const EdgeInsets.only(top: 24.0) : EdgeInsets.zero,
            child: _buildItemCard(_expiringItems[index]),
          );
        },
        childCount: _expiringItems.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void onTabTappedCallback(int index) {
      _handleNavToMainShell(context, index);
    }

    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- Custom AppBar Section ---
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                ),
              ),
              child: ValueListenableBuilder<Locale?>(
                valueListenable: LocaleProvider().localeNotifier,
                builder: (context, locale, _) {
                  return FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    title: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0, left: 15.0, right: 15.0), // ADJUST VERTICAL POSITION: Change top value to move up/down
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 0.0, top: 0.0), // Move back button left/up
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: _primaryWhite, size: 24),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                TranslationHelper.t('Expiring Soon', 'جلد ختم ہونے والی اشیاء'),
                                style: TextStyle(
                                  color: _primaryWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // Spacer to balance the back button
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- Dynamic Content based on state ---
          _isLoading || _errorMessage != null || _expiringItems.isEmpty
              ? SliverFillRemaining(
                  child: _buildContent(),
                )
              : _buildContent(),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        onTabContentTapped: onTabTappedCallback,
        currentIndex: 3,
        navContext: context,
      ),
    );
  }
}