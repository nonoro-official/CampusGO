import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/modal.dart';

void termsAndConditions(BuildContext context, WidgetRef ref) {
  ModalContainer.show(
    context: context,
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Terms and Conditions",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              "Last Updated: March 23, 2026",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Sections
            _buildSection(
              context,
              "Welcome",
              "Welcome to UniMart! By using our service, you agree to the following terms:",
            ),
            _buildSection(
              context,
              "Eligibility",
              "• You must be an enrolled student to use this service. "
                  "\n• By creating an account, you confirm that you meet this requirement.",
            ),
            _buildSection(
              context,
              "Using Our Service",
              "• You agree to use the service legally and responsibly.",
            ),
            _buildSection(
              context,
              "Your Account",
              "• You are responsible for your account information.\n"
                  "\n• Keep your password safe. You are responsible for all activity under your account.",
            ),
            _buildSection(
              context,
              "Privacy",
              "• We collect and use your information according to our Privacy Policy. "
                  "\n• Please review our Privacy Policy to understand how we handle your data.",
            ),
            _buildSection(
              context,
              "Content",
              "• You are responsible for what you post or share. "
                  "\n• Do not post anything illegal, harmful, or offensive.",
            ),
            _buildSection(
              context,
              "Intellectual Property",
              "• All content on this service belongs to us or our partners. "
                  "\n• You cannot copy, sell, or distribute our content without permission.",
            ),
            _buildSection(
              context,
              "Termination",
              "• We may suspend or close your account if you break these terms.",
            ),
            _buildSection(
              context,
              "Disclaimers",
              "• We provide our service 'as is' and do not guarantee it will always be error-free. "
                  "\n• We are not responsible for losses caused by using the service.",
            ),
            _buildSection(
              context,
              "Changes to Terms",
              "• We can update these terms at any time. You should check this page regularly for updates.",
            ),
            _buildSection(
              context,
              "Contact Us",
              "• If you have questions about these terms, contact us at:\n- noah.penaranda@ciit.edu.ph\n- rysa.abadier@ciit.edu.ph\n- danielle.serrato@ciit.edu.ph.",
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
