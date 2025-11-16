import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'dishes.dart';
import 'inventory_screen.dart';
import 'expiring.dart';
import 'home.dart';
import 'languages.dart';
import 'navbar.dart';
import 'homepage.dart';
import 'account_screen.dart'; // Import ProfileCheck

// --------------------------------------------------------------------------
// --- COLOR CONSTANTS (Consistent with account_screen.dart) ---
// --------------------------------------------------------------------------
const Color _kButtonColor = Color(0xFF5B8A94);
const Color _kScreenBackgroundColor = Colors.white;
const Color _kSearchBorderColor = Color(0xFFF3F3F3);
const Color _kSubtleGray = Color(0xFFF5F5F5); 
const Color _kLogoutRed = Color(0xFFE57373); // Red color for logout button
// --------------------------------------------------------------------------


class Setting_menu extends StatefulWidget {
  const Setting_menu({super.key});
  @override
  _Setting_menuState createState() => _Setting_menuState();
}

class _Setting_menuState extends State<Setting_menu> {
  // State variables for toggles
  late bool _darkModeEnabled;
  bool _notificationsEnabled = true;
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = _themeProvider.darkModeEnabled;
    _themeProvider.addListener(_onThemeChanged);
    LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
  }

  void _onThemeChanged() {
    setState(() {
      _darkModeEnabled = _themeProvider.darkModeEnabled;
    });
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

  // Helper method to navigate to a new screen
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  // Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      // Show confirmation dialog
      final bool? shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(TranslationHelper.t('Logout', 'لاگ آؤٹ')),
            content: Text(TranslationHelper.t('Are you sure you want to logout?', 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟')),
            actions: <Widget>[
              TextButton(
                child: Text(TranslationHelper.t('Cancel', 'منسوخ کریں')),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text(
                  TranslationHelper.t('Logout', 'لاگ آؤٹ'),
                  style: const TextStyle(color: _kLogoutRed),
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      // If user confirms logout
      if (shouldLogout == true) {
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

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Navigate to homepage and clear all routes
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : _kScreenBackgroundColor;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtleTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    final dividerColor = isDarkMode ? const Color(0xFF3A3A3A) : _kSearchBorderColor;
    
    final settingsTitle = TranslationHelper.get('settings');
    final preferencesLabel = TranslationHelper.t('Preferences', 'ترجیحات');
    final languageLabel = TranslationHelper.t('Language', 'زبان');
    final darkModeLabel = TranslationHelper.get('darkMode');
    final notificationsLabel = TranslationHelper.t('Notifications', 'اطلاعات');
    final accountLabel = TranslationHelper.t('Account', 'اکاؤنٹ');
    final logoutLabel = TranslationHelper.t('Logout', 'لاگ آؤٹ');
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sleek Header Section (Consistent with account_screen.dart)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (Functional)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 28),
                    ),
                    Text(
                      settingsTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 34), // Spacer
                  ]
                ),
              ),
              Divider(color: dividerColor, thickness: 1.5, height: 0),
                            
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card Section
                      _ProfileCard(
                        onTap: () => _navigateTo(context, const ProfileCheck()),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Settings Section Title
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 10),
                        child: Text(
                          preferencesLabel,
                          style: TextStyle(
                            color: subtleTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Language Tile
                      _SettingsTile(
                        label: languageLabel,
                        icon: Icons.language,
                        onTap: () => _navigateTo(context, const Lang()),
                      ),
                      
                      // Dark Mode Tile with Switch
                      _SettingsTile(
                        label: darkModeLabel,
                        icon: Icons.dark_mode,
                        trailing: Switch(
                          value: _darkModeEnabled,
                          onChanged: (bool newValue) async {
                            await _themeProvider.setDarkMode(newValue);
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: _kButtonColor,
                          inactiveThumbColor: Colors.grey[400],
                          inactiveTrackColor: Colors.grey[300],
                        ),
                        onTap: () async {
                          await _themeProvider.setDarkMode(!_darkModeEnabled);
                        },
                      ),

                      // Notifications Tile with Switch
                      _SettingsTile(
                        label: notificationsLabel,
                        icon: Icons.notifications,
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (bool newValue) {
                            setState(() {
                              _notificationsEnabled = newValue;
                            });
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: _kButtonColor,
                          inactiveThumbColor: Colors.grey[400],
                          inactiveTrackColor: Colors.grey[300],
                        ),
                        onTap: () {
                          // Toggle on tap of the whole tile area
                          setState(() {
                            _notificationsEnabled = !_notificationsEnabled;
                          });
                        },
                      ),

                      // The 'About' Tile has been REMOVED as requested.

                      const SizedBox(height: 30),
                      
                      // Account Section Title
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 10),
                        child: Text(
                          accountLabel,
                          style: TextStyle(
                            color: subtleTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Logout Tile - Added with red color
                      _LogoutTile(
                        label: logoutLabel,
                        onTap: () => _logout(context),
                      ),
                    ],
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Profile Card with User Info ---
// --------------------------------------------------------------------------
class _ProfileCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final cardColor = isDarkMode 
        ? const Color(0xFF1E1E1E) 
        : _kButtonColor.withOpacity(0.1);
    final borderColor = isDarkMode 
        ? _kButtonColor.withOpacity(0.5) 
        : _kButtonColor.withOpacity(0.3);
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    final subtleTextColor = isDarkMode ? const Color(0xFFB0B0B0) : Colors.black54;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Picture
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _kButtonColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 15),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Name
                  StreamBuilder<DocumentSnapshot>(
                    stream: user != null 
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      String displayName = 'User';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        displayName = userData?['displayName'] ?? user?.displayName ?? 'User';
                      }
                      
                      return Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Email
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      color: subtleTextColor,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Tap to view profile text
                  Text(
                    'Tap to view profile',
                    style: TextStyle(
                      color: _kButtonColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron Icon
            Icon(
              Icons.arrow_forward_ios,
              color: _kButtonColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Reusable Settings Tile (Unchanged design) ---
// --------------------------------------------------------------------------
class _SettingsTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.label,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final tileColor = isDarkMode ? const Color(0xFF2A2A2A) : _kSubtleGray;
    final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Icon(icon, color: _kButtonColor, size: 28),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
            // Show a chevron if it's a navigational tile and no custom trailing widget is provided
            if (trailing == null && onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: isDarkMode ? const Color(0xFF808080) : Colors.grey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// --- WIDGET: Logout Tile with Red Styling ---
// --------------------------------------------------------------------------
class _LogoutTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LogoutTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final tileColor = isDarkMode 
        ? const Color(0xFF3A1F1F) 
        : _kLogoutRed.withOpacity(0.1);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: tileColor, // Light red background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: _kLogoutRed.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Icon(Icons.logout, color: _kLogoutRed, size: 28),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                color: _kLogoutRed,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: _kLogoutRed.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}