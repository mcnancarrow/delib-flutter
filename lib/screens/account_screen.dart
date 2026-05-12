import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getMe();
      setState(() {
        _user    = data;
        _loading = false;
      });
    } catch (_) {
      // Fall back to cached user
      final cached = await ApiService.getUser();
      setState(() {
        _user    = cached;
        _loading = false;
      });
    }
  }

  Future<void> _openBilling() async {
    try {
      final url = await ApiService.getBillingPortal();
      if (url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open billing: $e'),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  Future<void> _openCheckout(String plan) async {
    try {
      final url = await ApiService.createCheckout(plan);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start checkout: $e'),
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Account',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_user != null) ...[
                    _profileCard(),
                    const SizedBox(height: 16),
                    _planCard(),
                    const SizedBox(height: 16),
                  ],
                  _pricingSection(),
                  const SizedBox(height: 16),
                  _section('Links', [
                    _row(Icons.open_in_new_rounded, 'Open Delib.io in browser',
                        onTap: () => launchUrl(
                            Uri.parse('https://www.delib.io'),
                            mode: LaunchMode.externalApplication)),
                    _row(Icons.description_outlined, 'Terms of Service',
                        onTap: () => launchUrl(
                            Uri.parse('https://www.delib.io/terms'),
                            mode: LaunchMode.externalApplication)),
                    _row(Icons.privacy_tip_outlined, 'Privacy Policy',
                        onTap: () => launchUrl(
                            Uri.parse('https://www.delib.io/privacy'),
                            mode: LaunchMode.externalApplication)),
                  ]),
                  const SizedBox(height: 16),
                  _section('Account', [
                    _row(Icons.logout_rounded, 'Sign out',
                        color: Colors.redAccent, onTap: _logout),
                  ]),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text('Delib.io v1.0',
                        style: TextStyle(color: AppColors.subtle, fontSize: 12)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _profileCard() {
    final name  = _user?['name']  ?? 'User';
    final email = _user?['email'] ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard() {
    final plan  = (_user?['plan'] ?? 'free').toString();
    final quota = _user?['quota'];
    final used  = _user?['used'] ?? 0;

    Color planColor;
    String planLabel;
    switch (plan) {
      case 'starter':
        planColor = AppColors.primary;
        planLabel = 'Starter';
        break;
      case 'pro':
        planColor = AppColors.purple;
        planLabel = 'Pro';
        break;
      default:
        planColor = AppColors.muted;
        planLabel = 'Free';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: planColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: planColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(planLabel,
                    style: TextStyle(
                        color: planColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              if (plan != 'free')
                GestureDetector(
                  onTap: _openBilling,
                  child: const Text('Manage billing',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (quota != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Deliberations used',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
                Text('$used / $quota',
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: quota > 0 ? (used / quota).clamp(0.0, 1.0) : 0,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(planColor),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Plans',
            style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _planTile(
          name: 'Starter',
          price: '\$10/mo',
          features: ['100 deliberations/mo', 'Claude, ChatGPT & Grok (API Only)', 'All verdict styles'],
          color: AppColors.primary,
          plan: 'starter',
        ),
        const SizedBox(height: 10),
        _planTile(
          name: 'Pro',
          price: '\$25/mo',
          features: ['300 deliberations/mo', 'All 5 voices (Full Board)', 'Custom verdict styles', 'Priority access'],
          color: AppColors.purple,
          plan: 'pro',
        ),
      ],
    );
  }

  Widget _planTile({
    required String name,
    required String price,
    required List<String> features,
    required Color color,
    required String plan,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(name,
                  style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Text(price,
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => _openCheckout(plan),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: plan == 'pro'
                          ? [AppColors.primary, AppColors.purple]
                          : [AppColors.primary, const Color(0xFF3a58e8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Upgrade',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 14),
                  const SizedBox(width: 7),
                  Text(f,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ),
          const Divider(color: AppColors.border, height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label, {
    Color? color,
    Future<void> Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap != null ? () => onTap() : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.muted, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: color ?? AppColors.text, fontSize: 14)),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.subtle, size: 18),
          ],
        ),
      ),
    );
  }
}
