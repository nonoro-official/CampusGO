import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modal.dart';

void helpCenter(BuildContext context, WidgetRef ref) {
  ModalContainer.show(
    context: context,
    child: StatefulBuilder(
      builder: (context, setState) {
        // Example FAQ data
        final faqList = [
          {
            "question": "About Us",
            "answer":
                "CampusGO is a centralized campus e-commerce platform designed to bring student Organizers into one accessible space, making it easier for the campus community to discover, support, and engage with them.\n\nPrototype for Mobile Application Development 2 and Science, Technology, and Society.",
          },
          {
            "question": "Contact Tech and Support",
            "answer":
                "noah.penaranda@ciit.edu.ph\nrysa.abadier@ciit.edu.ph\ndanielle.serrato@ciit.edu.ph",
          },
          {
            "question": "Contact Branding",
            "answer": "rysa.abadier@ciit.edu.ph\nace.saman@ciit.edu.ph",
          },
          {
            "question": "Contact Logistics",
            "answer": "zach.nogueras@ciit.edu.ph\nsamuel.sanluis@ciit.edu.ph",
          },
        ];

        // Track which FAQ is currently expanded
        int? expandedIndex;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Help Center",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 15),

                ...faqList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final faq = entry.value;

                  return ExpansionTile(
                    key: Key(index.toString()),
                    title: Text(
                      faq["question"]!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    initiallyExpanded: expandedIndex == index,
                    onExpansionChanged: (isExpanded) {
                      setState(() {
                        expandedIndex = isExpanded ? index : null;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        child: Text(
                          faq["answer"]!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    ),
  );
}
