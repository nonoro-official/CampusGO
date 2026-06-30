import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/modal.dart';

void editPassword(BuildContext context, WidgetRef ref) {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  ModalContainer.show(
    context: context,
    child: StatefulBuilder(
      builder: (context, setModalState) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleChange() async {
              final current = currentController.text.trim();
              final newPass = newController.text.trim();
              final confirm = confirmController.text.trim();

              if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                _showSnackBar(
                  context,
                  "All fields are required",
                  isError: true,
                );
                return;
              }

              if (newPass.length < 6) {
                _showSnackBar(
                  context,
                  "Password must be at least 6 characters",
                  isError: true,
                );
                return;
              }

              if (newPass != confirm) {
                _showSnackBar(context, "Passwords do not match", isError: true);
                return;
              }

              setState(() => isLoading = true);

              try {
                await ref
                    .read(authServiceProvider)
                    .updatePassword(
                      currentPassword: current,
                      newPassword: newPass,
                    );

                await ref.read(authServiceProvider).signOut();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/",
                    (route) => false,
                  );
                  _showSnackBar(
                    context,
                    "Password updated. Please log in again.",
                  );
                }
              } catch (e) {
                _showSnackBar(context, e.toString(), isError: true);
              } finally {
                if (context.mounted) setState(() => isLoading = false);
              }
            }

            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Change Password",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildField(currentController, "Current Password", context),
                    const SizedBox(height: 10),

                    _buildField(newController, "New Password", context),
                    const SizedBox(height: 10),

                    _buildField(
                      confirmController,
                      "Confirm Password",
                      context,
                      helper: "Changing password will require you to relogin.",
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleChange,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Update Password"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

Widget _buildField(
  TextEditingController controller,
  String label,
  BuildContext context, {
  String? helper,
}) {
  bool isObscured = true;

  return StatefulBuilder(
    builder: (context, setState) => TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        helperText: helper,
        labelText: label,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            size: 18,
            isObscured ? Icons.visibility_off : Icons.visibility,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => setState(() => isObscured = !isObscured),
        ),
      ),
      obscureText: isObscured,
    ),
  );
}

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
