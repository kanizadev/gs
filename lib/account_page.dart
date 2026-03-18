import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_page.dart';
import 'delivery_address_page.dart';
import 'explore_page.dart';
import 'favourite_page.dart';
import 'payment_methods_page.dart';
import 'store_home_page.dart';
import 'data/theme_provider.dart';
import 'edit_profile_page.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> with TickerProviderStateMixin {
  int _currentIndex = 4; // Account is index 4
  late List<AnimationController> _navAnimationControllers;
  late List<Animation<double>> _navScaleAnimations;

  static const Color _accentGreen = Color(0xFF6CC51D);
  static const Color _muted = Color(0xFF7A7D87);
  static const Color _tileBg = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _initializeNavAnimations();
  }

  void _initializeNavAnimations() {
    _navAnimationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _navScaleAnimations = _navAnimationControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut),
      );
    }).toList();
    _navAnimationControllers[_currentIndex].forward();
  }

  @override
  void dispose() {
    for (final c in _navAnimationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 6),
            _profileHeader(
              name: 'Burhan Rahman',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'My Orders',
                    onTap: () => _toast('Orders coming soon'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Coupons',
                    onTap: () => _toast('Coupons coming soon'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.favorite_border,
                    label: 'Wishlist',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavouritePage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _sectionHeader('App Settings'),
            const SizedBox(height: 10),
            _settingsTile(
              icon: ref.watch(themeProvider) == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              title: 'Dark Mode',
              trailing: Switch.adaptive(
                value: ref.watch(themeProvider) == ThemeMode.dark,
                onChanged: (_) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
              onTap: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
            _sectionHeader('Account Settings'),
            const SizedBox(height: 10),
            _settingsTile(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentMethodsPage(),
                  ),
                );
              },
            ),
            _settingsTile(
              icon: Icons.location_on_outlined,
              title: 'Address',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeliveryAddressPage(),
                  ),
                );
              },
            ),
            _settingsTile(
              icon: Icons.lock_outline,
              title: 'Security & Password',
              onTap: () => _toast('Security coming soon'),
            ),
            const SizedBox(height: 18),
            _sectionHeader('Help & Info'),
            const SizedBox(height: 10),
            _settingsTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => _toast('Help & support coming soon'),
            ),
            _settingsTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => _toast('Privacy policy coming soon'),
            ),
            _settingsTile(
              icon: Icons.info_outline,
              title: 'About App',
              onTap: () => _toast('About app coming soon'),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE45151), width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _toast('Log out coming soon'),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFE45151),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  Widget _profileHeader({
    required String name,
    required VoidCallback onEdit,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: _accentGreen,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9EEF9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 44, color: Colors.black54),
              ),
            ),
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 14, color: _accentGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD7DFF2)),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _accentGreen, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _tileBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _accentGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: _muted),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildCustomBottomNavBar() {
    final navItems = [
      {'icon': Icons.storefront_outlined, 'label': 'Shop'},
      {'icon': Icons.explore_outlined, 'label': 'Explore'},
      {'icon': Icons.shopping_cart_outlined, 'label': 'Cart'},
      {'icon': Icons.favorite_border, 'label': 'Favourite'},
      {'icon': Icons.person_outline, 'label': 'Account'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              navItems.length,
              (index) => Expanded(
                child: _buildNavItem(
                  navItems[index]['icon'] as IconData,
                  navItems[index]['label'] as String,
                  index,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == _currentIndex) return;

        _navAnimationControllers[_currentIndex].reverse();
        setState(() {
          _currentIndex = index;
        });
        _navAnimationControllers[index].forward();

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StoreHomePage()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ExplorePage()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CartPage()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FavouritePage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _navScaleAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: isActive ? _navScaleAnimations[index].value : 1.0,
                child: Icon(
                  icon,
                  size: 24,
                  color: isActive ? const Color(0xFF6CC51D) : Colors.black,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? const Color(0xFF6CC51D) : Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

