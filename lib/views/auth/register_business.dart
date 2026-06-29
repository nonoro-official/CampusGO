import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unimart/models/enums.dart';
import 'package:unimart/services/auth_service.dart';
import 'package:unimart/services/business_service.dart';
import 'package:unimart/views/home/widgets/top_bar.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({
    super.key,
    this.registrationData,
    this.isCustomer,
  });

  final Map<String, dynamic>? registrationData;
  final bool? isCustomer;

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  BusinessPartner? selectedBusinessPartner;
  bool _isLoading = false;

  Future<void> _onRegister() async {
    final contact = _contactController.text.trim();

    if (_businessNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        contact.isEmpty ||
        selectedBusinessPartner == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Contact number length validation (7-15 digits)
    if (contact.length < 7 || contact.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact number must be between 7 and 15 digits'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUid = AuthService().currentUser?.uid;

      // CASE 1: NEW USER REGISTRATION
      if (currentUid == null && widget.registrationData != null) {
        final regData = widget.registrationData!;
        if (regData['password'] == null) {
          throw Exception("Password missing in registrationData");
        }

        await AuthService().register(
          email: regData['email'] ?? '',
          password: regData['password'],
          firstName: regData['firstName'] ?? '',
          lastName: regData['lastName'] ?? '',
          phoneNumber: regData['phoneNumber'] ?? '',
          role: regData['role'] ?? Role.customer,
        );

        final newUid = AuthService().currentUser?.uid;
        if (newUid == null) throw Exception("Failed to get user ID");

        await BusinessService().createBusiness(
          ownerId: newUid,
          businessName: _businessNameController.text.trim(),
          contactEmail: _emailController.text.trim(),
          contactNumber: contact,
          businessPartner: selectedBusinessPartner!,
        );

        await AuthService().updateUserRoleToVendor();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business registered! Please sign in.')),
        );

        await AuthService().signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      // CASE 2: EXISTING USER
      else if (currentUid != null) {
        await BusinessService().createBusiness(
          ownerId: currentUid,
          businessName: _businessNameController.text.trim(),
          contactEmail: _emailController.text.trim(),
          contactNumber: contact,
          businessPartner: selectedBusinessPartner!,
        );

        await AuthService().updateUserRoleToVendor();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business registered! You are now a vendor.'),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/business-dashboard',
          (route) => false,
        ); // Back to menu
      }
      // ERROR: NO USER
      else {
        throw Exception("No user info available to register business");
      }
    } catch (e) {
      // CLEANUP: If business creation fails, delete the Auth account so it's not "empty"
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(
        title: 'Set Up Your Business',
        showBack: true,
        dark: false,
      ),
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
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
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
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<BusinessPartner>(
                  initialValue: selectedBusinessPartner,
                  decoration: const InputDecoration(
                    labelText: 'Business Partner Type',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 12,
                    ),
                  ),
                  items: BusinessPartner.values.map((partner) {
                    return DropdownMenuItem(
                      value: partner,
                      child: Text(
                        partner.name[0].toUpperCase() +
                            partner.name.substring(1),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBusinessPartner = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
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
    _businessNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }
}
