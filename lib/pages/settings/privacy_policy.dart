import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modal.dart';

void privacyPolicy(BuildContext context, WidgetRef ref) {
  ModalContainer.show(
    context: context,
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              "Last Updated: March 23, 2026",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            _buildSection(
              context,
              "Introduction",
              "We value your privacy. By using campusgo, you agree to the practices outlined in this policy. "
                  "This applies to all enrolled students using the service.",
            ),
            _buildSection(
              context,
              "Information We Collect",
              "• Personal information: Name, email, student ID, and account details.\n"
                  "• Usage information: Actions within the app, features used, and session data.\n"
                  "• Device information: IP address, device type, operating system.",
            ),
            _buildSection(
              context,
              "How We Use Information",
              "• To provide and improve our services.\n"
                  "• To communicate updates, notices, or account-related messages.\n"
                  "• To personalize the user experience.\n"
                  "• To comply with legal obligations.",
            ),
            _buildSection(
              context,
              "Data Sharing",
              "We do not sell your information. We may share data with:\n"
                  "• Partners or service providers for app functionality.\n"
                  "• Authorities if legally required.\n"
                  "• Researchers or internal teams in aggregated/anonymized form.",
            ),
            _buildSection(
              context,
              "Your Rights",
              "• You can access, update, or delete your account information.\n"
                  "• You may withdraw consent for certain uses of your data.\n"
                  "• Contact support if you wish to exercise your rights.",
            ),
            _buildSection(
              context,
              "Data Security",
              "• We implement reasonable measures to protect your information from unauthorized access, alteration, or disclosure.",
            ),
            _buildSection(
              context,
              "Students",
              "• Our app is intended for enrolled students. We do not knowingly collect data from individuals not meeting this requirement.",
            ),
            _buildSection(
              context,
              "Changes to Privacy Policy",
              "• We may update this policy periodically. Users should review it regularly for any changes.",
            ),
            _buildSection(
              context,
              "Contact Us",
              "• For questions regarding your privacy, please contact us at:\n- noah.penaranda@ciit.edu.ph\n- rysa.abadier@ciit.edu.ph\n- danielle.serrato@ciit.edu.ph.",
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSection(BuildContext context, String title, String content) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight(600),
          ),
        ),
        const SizedBox(height: 5),
        Text(content, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}
