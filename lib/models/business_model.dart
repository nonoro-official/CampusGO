import 'business_hours.dart';
import 'enums.dart';
import 'faq_model.dart';

class BusinessModel {
  final String id;
  final String ownerId;
  final String businessName;
  final String contactEmail;
  final String contactNumber;
  final BusinessPartner businessPartner;
  final String? description;
  final String? category;
  final String? imageUrl;
  final ActiveStatus activeStatus;
  final Map<String, BusinessHours>? businessHours;
  final bool isMobile;
  final List<FAQModel> faqs;

  BusinessModel({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.contactEmail,
    required this.contactNumber,
    required this.businessPartner,
    this.description,
    this.category,
    this.imageUrl,
    required this.activeStatus,
    this.isMobile = true,
    this.businessHours,
    this.faqs = const [],
  });

  factory BusinessModel.fromMap(Map<String, dynamic> data, String id) {
    return BusinessModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      businessName: data['businessName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      businessPartner: BusinessPartner.fromString(
        (data['businessPartner'] ?? 'student').toString(),
      ),
      description: data['description'],
      category: data['category'] ?? 'Others',
      imageUrl: data['imageUrl'],
      activeStatus: ActiveStatus.fromString(data['activeStatus'] ?? 'closed'),
      isMobile: data['isMobile'] ?? true,
      businessHours: _parseHours(data['businessHours']),
      faqs: _parseFaqs(data['faqs']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'businessName': businessName,
      'contactEmail': contactEmail,
      'contactNumber': contactNumber,
      'businessPartner': businessPartner.name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'activeStatus': activeStatus.name,
      if (businessHours != null)
        'businessHours': businessHours!.map((k, v) => MapEntry(k, v.toMap())),
      'isMobile': isMobile,
      'faqs': faqs.map((f) => f.toMap()).toList(),
    };
  }

  static Map<String, BusinessHours>? _parseHours(dynamic data) {
    if (data == null) return null;
    final map = data as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, BusinessHours.fromMap(value)));
  }

  static List<FAQModel> _parseFaqs(dynamic data) {
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list.map((item) => FAQModel.fromMap(Map<String, dynamic>.from(item))).toList();
  }
}
