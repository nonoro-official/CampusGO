import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/modal.dart';

void deleteAccount(BuildContext context, WidgetRef ref) {
  final passwordController = TextEditingController();

  ModalContainer.show(
    context: context,
    child: StatefulBuilder(
      builder: (context, setModalState) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> handleDelete() async {
              final password = passwordController.text.trim();

              if (password.isEmpty) {
                _showSnackBar(context, "Password is required", isError: true);
                return;
              }

              setState(() => isLoading = true);

              try {
                await ref
                    .read(authServiceProvider)
                    .deleteAccount(password: password);

                await ref.read(authServiceProvider).signOut();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/",
                    (route) => false,
                  );
                  _showSnackBar(context, "Account deleted successfully");
                }
              } catch (e) {
                _showSnackBar(context, e.toString(), isError: true);
              } finally {
                if (context.mounted) setState(() => isLoading = false);
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Delete Account",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "This action is permanent. Enter your password to confirm.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildField(passwordController, "Password", context),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: isLoading ? null : handleDelete,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Delete Account"),
                    ),
                  ),
                ],
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
  BuildContext context,
) {
  bool isObscured = true;

  return StatefulBuilder(
    builder: (context, setState) => TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
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
