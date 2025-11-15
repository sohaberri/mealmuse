// lang.dart
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import 'dishes.dart';
import 'inventory_screen.dart';
import 'expiring.dart';
import 'home.dart';

// --------------------------------------------------------------------------
// --- COLOR CONSTANTS (Consistent with account_screen.dart) ---
// --------------------------------------------------------------------------
const Color _kButtonColor = Color(0xFF5B8A94);
const Color _kScreenBackgroundColor = Colors.white;
const Color _kSearchBorderColor = Color(0xFFF3F3F3);
const Color _kSubtleGray = Color(0xFFF5F5F5); 
// --------------------------------------------------------------------------


class Lang extends StatefulWidget {
	const Lang({super.key});
	@override
		LangState createState() => LangState();
	}

class LangState extends State<Lang> {
  @override
	Widget build(BuildContext context) {
		final isDarkMode = ThemeProvider().darkModeEnabled;
		final backgroundColor = isDarkMode ? const Color(0xFF121212) : _kScreenBackgroundColor;
		final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
		final dividerColor = isDarkMode ? const Color(0xFF3A3A3A) : _kSearchBorderColor;
		
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
											"Language",
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
											// Only English is available and selected (as requested)
											_LanguageSelectionTile(
												language: "English",
												isSelected: true,
												onTap: () {
													debugPrint('English is already selected and cannot be deselected.');
												},
											),
											// All other language options are removed
										],
									)
								),
							),
						],
					),
				),
			),
      // bottomNavigationBar: _BottomNavigationBar(
      //   navigateTo: _navigateTo,
      //   navigateHome: _navigateHome,
      //   // Active Profile Icon in the Nav Bar for this screen
      //   navigateToProfile: () => _navigateTo(context, const ProfileNSettings()),
      //   activeIcon: Icons.person,
      // ),
		);
	}
}

// --------------------------------------------------------------------------
// --- WIDGET: Language Selection Tile (New) ---
// --------------------------------------------------------------------------
class _LanguageSelectionTile extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageSelectionTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final unselectedColor = isDarkMode ? const Color(0xFF2A2A2A) : _kSubtleGray;
    final unselectedTextColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _kButtonColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kButtonColor : unselectedColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _kButtonColor.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: TextStyle(
                color: isSelected ? Colors.white : unselectedTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}