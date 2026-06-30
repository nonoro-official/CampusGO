import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:campusgo/models/enums.dart';
import 'package:campusgo/services/auth_service.dart';
import 'package:campusgo/widgets/top_bar.dart';
import 'register_organizer.dart';

class RedirectScreen extends StatelessWidget {
  const RedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopBar(title: 'Register', showBack: true, dark: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Image.asset('assets/images/campusgo_logo.png', width: 235),
            ),
            const SizedBox(height: 10),
            Text('Buy and Sell', style: textTheme.bodyMedium),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const RegisterScreen(accountType: 'Customer'),
                ),
              ),
              child: const Text('Customer'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const RegisterScreen(accountType: 'Vendor'),
                ),
              ),
              child: const Text('Vendor'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.accountType});

  final String accountType;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool isObscured = true;

  Future<void> _onNext() async {
    // 1. Extract and trim the email for consistent checking
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    // 2. Original empty field validation
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Phone number length validation (7-15 digits)
    if (phone.length < 7 || phone.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be between 7 and 15 digits'),
        ),
      );
      return;
    }

    // Password validation: 8-64 chars, must have uppercase and lowercase
    if (password.length < 8 || password.length > 64) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be between 8 and 64 characters'),
        ),
      );
      return;
    }

    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must contain both uppercase and lowercase letters',
          ),
        ),
      );
      return;
    }

    // 3. NEW: The Domain Lockdown
    // This stops the request before it even hits Firebase
    if (!email.endsWith('@ciit.edu.ph')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only @ciit.edu.ph emails are allowed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cleanEmail = email.trim().toLowerCase();

      if (widget.accountType == 'Vendor') {
        // DON'T register yet if Vendor. Pass data to the next screen.
        // This prevents "empty vendor" accounts if they quit mid-setup.
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterOrganizerScreen(
              registrationData: {
                'email': cleanEmail,
                'password': password,
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'phoneNumber': phone,
                'role': Role.fromString(widget.accountType),
              },
            ),
          ),
        );
      } else {
        // Customer flow remains the same (immediate registration)
        await AuthService().register(
          email: cleanEmail,
          password: password,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: phone,
          role: Role.fromString(widget.accountType),
        );

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Clean up the error message for the user
      String errorMessage = e.toString();
      if (errorMessage.contains('permission-denied')) {
        errorMessage = "Security check failed. Use your CIIT email.";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVendor = widget.accountType == 'Vendor';

    return Scaffold(
      appBar: const TopBar(title: 'Register', showBack: true, dark: false),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: isObscured,
                  maxLength: 64,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    counterText: '',
                    helperText:
                        '8-64 characters, must include Uppercase and Lowercase',
                    helperMaxLines: 2,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        size: 18,
                        isObscured ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => setState(() => isObscured = !isObscured),
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onNext,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : isVendor
                        ? const Text('Next')
                        : const Text('Register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
