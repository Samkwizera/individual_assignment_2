import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationNotifications = true;
  bool _newListingNotifications = true;
  bool _reviewNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _locationNotifications =
            prefs.getBool('pref_location_notifications') ?? true;
        _newListingNotifications =
            prefs.getBool('pref_new_listing_notifications') ?? true;
        _reviewNotifications =
            prefs.getBool('pref_review_notifications') ?? false;
      });
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.userModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.displayName ?? 'User',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded,
                              color: AppColors.success, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified Account',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user?.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Member since ${DateFormat('MMMM yyyy').format(user!.createdAt)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),


              _SectionHeader(title: 'Notifications'),
              _SettingsTile(
                icon: Icons.location_on_rounded,
                title: 'Location-Based Alerts',
                subtitle:
                    'Get notified about services near your current location',
                trailing: Switch.adaptive(
                  value: _locationNotifications,
                  onChanged: (v) {
                    setState(() => _locationNotifications = v);
                    _savePreference('pref_location_notifications', v);
                  },
                  activeColor: AppColors.accent,
                ),
              ),
              _SettingsTile(
                icon: Icons.add_location_alt_rounded,
                title: 'New Listings',
                subtitle:
                    'Get notified when new services are added in Kigali',
                trailing: Switch.adaptive(
                  value: _newListingNotifications,
                  onChanged: (v) {
                    setState(() => _newListingNotifications = v);
                    _savePreference('pref_new_listing_notifications', v);
                  },
                  activeColor: AppColors.accent,
                ),
              ),
              _SettingsTile(
                icon: Icons.star_rounded,
                title: 'Review Notifications',
                subtitle:
                    'Get notified when someone reviews your listings',
                trailing: Switch.adaptive(
                  value: _reviewNotifications,
                  onChanged: (v) {
                    setState(() => _reviewNotifications = v);
                    _savePreference('pref_review_notifications', v);
                  },
                  activeColor: AppColors.accent,
                ),
              ),


              _SectionHeader(title: 'App'),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Kigali City Directory v1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () {},
              ),


              _SectionHeader(title: 'Account'),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                titleColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => _confirmSignOut(context),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Sign Out', style: AppTextStyles.heading3),
        content: const Text(
          'Are you sure you want to sign out?',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Kigali City Directory',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Kigali City Directory',
      children: const [
        SizedBox(height: 12),
        Text(
          'A comprehensive directory of services and places in Kigali, Rwanda. '
          'Helping residents and visitors navigate the city.',
          style: AppTextStyles.bodySecondary,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.accent).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.accent,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: titleColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: AppTextStyles.caption)
            : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  )
                : null),
      ),
    );
  }
}
