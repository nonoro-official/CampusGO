import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unimart/views/home/settings/close_business.dart';
import 'package:unimart/views/home/settings/privacy_policy.dart';
import 'package:unimart/views/home/settings/terms_and_conditions.dart';
import 'package:unimart/views/home/widgets/top_bar.dart';
import 'settings/profile_edit.dart';
import 'settings/help_center.dart';
import 'settings/business_edit.dart';
import 'settings/password_edit.dart';
import 'settings/delete_account.dart';
import 'widgets/pfp_edit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the stream directly ensures the UI reacts to account switches
    final userAsync = ref.watch(userDocProvider);
    final businessAsync = ref.watch(myBusinessProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text("No account found")));
        }

        return Scaffold(
          appBar: TopBar(
            title: 'Account',
            showBack: true,
            dark: false,
            center: true,
            alignLogout: 'R',
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  const EditProfilePicture(),
                  const SizedBox(height: 10),
                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),

                  _buildList(context, [
                    {
                      'icon': Icons.person_outline,
                      'label': 'Edit Profile',
                      'action': () => editUserProfile(context, user, ref),
                    },
                    {
                      'icon': Icons.password,
                      'label': 'Change Password',
                      'action': () => editPassword(context, ref),
                    },
                  ]),

                  _header(context, "Business Settings", false),
                  if (user.role == Role.vendor) ...[
                    businessAsync.when(
                      data: (biz) => _buildList(context, [
                        {
                          'icon': Icons.storefront,
                          'label': 'Edit Business Profile',
                          'action': () => biz != null
                              ? editBusinessProfile(context, biz, ref)
                              : null,
                        },
                      ]),
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text("Error loading business"),
                    ),
                  ] else ...[
                    _buildList(context, [
                      {
                        'icon': Icons.storefront,
                        'label': 'Add Business',
                        'action': () {
                          Navigator.pushNamed(context, '/register-business');
                        },
                      },
                    ]),
                  ],

                  _header(context, "Support", false),
                  _buildList(context, [
                    {
                      'icon': Icons.help_outline,
                      'label': 'Help Center',
                      'action': () => helpCenter(context, ref),
                    },
                    {
                      'icon': Icons.edit_note,
                      'label': 'Terms and Conditions',
                      'action': () => termsAndConditions(context, ref),
                    },
                    {
                      'icon': Icons.privacy_tip_outlined,
                      'label': 'Privacy Policy',
                      'action': () => privacyPolicy(context, ref),
                    },
                    {
                      'icon': Icons.feedback_outlined,
                      'label': 'Feedback Survey',
                      'action': () async {
                        final uri = Uri.parse(
                          "https://forms.gle/Bbc5dqyPJTFwVF2F7",
                        );

                        try {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open survey link"),
                            ),
                          );
                        }
                      },
                    },
                    {
                      'icon': Icons.logout,
                      'label': 'Logout',
                      'action': () async {
                        await ref.read(authServiceProvider).signOut();

                        // Invalidate everything to be 100% safe
                        ref.invalidate(authStateProvider);
                        ref.invalidate(userDocProvider);
                        ref.invalidate(myBusinessProvider);

                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (r) => false,
                          );
                        }
                      },
                    },
                  ]),

                  _header(context, "Danger Zone", true),
                  _buildList(context, [
                    if (user.role == Role.vendor) ...[
                      {
                        'icon': Icons.storefront,
                        'label': 'Close Business',
                        'action': () => closeBusiness(context, ref),
                      },
                    ],
                    {
                      'icon': Icons.delete_outline,
                      'label': 'Delete Account',
                      'action': () => deleteAccount(context, ref),
                    },
                  ]),
                ],
              ),
            ),
          ),
        );
      }, // Corrected semicolon/closing here
    );
  }

  Widget _header(BuildContext context, String text, bool isDangerous) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDangerous ? Theme.of(context).primaryColor : null,
        ),
      ),
    ),
  );

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items) {
    return Column(
      children: items
          .map(
            (item) => ListTile(
              leading: Icon(
                item['icon'],
                color: Theme.of(context).primaryColor,
              ),
              title: Text(item['label']),
              onTap: item['action'],
            ),
          )
          .toList(),
    );
  }
}
