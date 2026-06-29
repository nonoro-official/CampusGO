import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modal.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

void editUserProfile(BuildContext context, UserModel user, WidgetRef ref) {
  final firstNameController = TextEditingController(text: user.firstName);
  final lastNameController = TextEditingController(text: user.lastName);
  final phoneController = TextEditingController(text: user.phoneNumber);
  final emailController = TextEditingController(text: user.email);

  ModalContainer.show(
    context: context,
    child: StatefulBuilder(
      builder: (context, setModalState) {
        bool isLoading = false;

        Future<void> handleSave() async {
          final fName = firstNameController.text.trim();
          final lName = lastNameController.text.trim();
          final phone = phoneController.text.trim();
          final email = emailController.text.trim();

          // 1. Validation logic
          if (fName.isEmpty || lName.isEmpty) {
            _showSnackBar(context, "Names cannot be empty", isError: true);
            return;
          }

          if (phone.length < 7 || phone.length > 15) {
            _showSnackBar(
              context,
              "Phone number must be between 7 and 15 digits",
              isError: true,
            );
            return;
          }

          if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$").hasMatch(email)) {
            _showSnackBar(context, "Please enter a valid email", isError: true);
            return;
          }

          setModalState(() => isLoading = true);

          try {
            // 2. Execute update via AuthService
            await ref
                .read(authServiceProvider)
                .updateUserProfile(
                  uid: user.uid,
                  data: {
                    'firstName': fName,
                    'lastName': lName,
                    'phoneNumber': phone,
                    'email': email,
                  },
                );

            if (context.mounted) {
              Navigator.pop(context);

              // Custom message if email was changed
              String message = 'Profile updated!';
              if (email != user.email) {
                message =
                    'Profile updated! Please check $email to verify your new email.';
              }

              _showSnackBar(context, message);
            }
          } catch (e) {
            if (context.mounted) {
              _showSnackBar(context, e.toString(), isError: true);
            }
          } finally {
            if (context.mounted) setModalState(() => isLoading = false);
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Edit Profile",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(firstNameController, "First Name", context),
              const SizedBox(height: 10),
              _buildTextField(lastNameController, "Last Name", context),
              const SizedBox(height: 10),
              _buildTextField(
                phoneController,
                "Phone Number",
                context,
                type: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 15,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                emailController,
                "Email",
                context,
                type: TextInputType.emailAddress,
                helper: "Changing email may require re-verification.",
              ),
              // const SizedBox(height: 15),
              // TextButton(
              //   onPressed: () => editPassword(context, ref),
              //   child: const Text("Change Password"),
              // ),
              // TextButton(
              //   onPressed: () => deleteAccount(context, ref),
              //   child: const Text(
              //     "Delete Account",
              //     style: TextStyle(color: Colors.red),
              //   ),
              // ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleSave,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// UI Helper for TextFields to keep the main code readable
Widget _buildTextField(
  TextEditingController controller,
  String label,
  BuildContext context, {
  TextInputType type = TextInputType.text,
  String? helper,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
}) {
  return TextField(
    controller: controller,
    keyboardType: type,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    style: Theme.of(context).textTheme.bodyMedium,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      border: const OutlineInputBorder(),
    ),
  );
}

// Utility for feedback
void _showSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
