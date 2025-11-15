import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
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
          _errorMessage = "User not logged in";
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
            expiryText = 'Expired';
          } else if (daysUntilExpiry == 0) {
            expiryText = 'Today';
          } else if (daysUntilExpiry == 1) {
            expiryText = '1 Day';
          } else if (daysUntilExpiry < 7) {
            expiryText = '$daysUntilExpiry Days';
          } else if (daysUntilExpiry < 30) {
            final weeks = (daysUntilExpiry / 7).ceil();
            expiryText = weeks == 1 ? '1 Week' : '$weeks Weeks';
          } else {
            final months = (daysUntilExpiry / 30).ceil();
            expiryText = months == 1 ? '1 Month' : '$months Months';
          }

          // Get appropriate icon based on category
          final category = data['category'] as String? ?? 'Other';
          final icon = _getIconForCategory(category);

          // Parse quantity
          final quantityStr = data['quantity'] as String? ?? '0';
          final quantity = int.tryParse(quantityStr) ?? 0;

          items.add(ExpiringItem(
            name: data['name'] as String? ?? 'Unknown Item',
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
        _errorMessage = "Error loading expiring items: $e";
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: _primaryWhite,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Count: ${item.count}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Expires In: ${item.expiry}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              item.icon,
              color: _primaryRed,
              size: 40,
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
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExpiringItems,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                foregroundColor: _primaryWhite,
              ),
              child: const Text('Retry'),
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
            const SizedBox(height: 16),
            const Text(
              'No expiring items found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add expiry dates to your inventory items to see them here',
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
          return _buildItemCard(_expiringItems[index]);
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
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.0),
                  bottomRight: Radius.circular(30.0),
                ),
              ),
              child: const FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.only(left: 60, bottom: 16),
                title: Text(
                  'Expiring Soon',
                  style: TextStyle(
                    color: _primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _primaryWhite),
              onPressed: () {
                Navigator.pop(context);
              },
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