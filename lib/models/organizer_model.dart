import 'enums.dart';
import 'faq_model.dart';

class OrganizerModel {
  final String id;
  final String ownerId;
  final String organizerName;
  final String contactEmail;
  final String contactNumber;
  final OrganizerPartner organizerPartner;
  final String? description;
  final String? imageUrl;
  final ActiveStatus activeStatus;
  final bool isMobile;
  final List<FAQModel> faqs;

  OrganizerModel({
    required this.id,
    required this.ownerId,
    required this.organizerName,
    required this.contactEmail,
    required this.contactNumber,
    required this.organizerPartner,
    this.description,
    this.imageUrl,
    required this.activeStatus,
    this.isMobile = true,
    this.faqs = const [],
  });

  factory OrganizerModel.fromMap(Map<String, dynamic> data, String id) {
    return OrganizerModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      organizerPartner: OrganizerPartner.fromString(
        (data['organizerPartner'] ?? 'student').toString(),
      ),
      description: data['description'],
      imageUrl: data['imageUrl'],
      activeStatus: ActiveStatus.fromString(data['activeStatus'] ?? 'closed'),
      isMobile: data['isMobile'] ?? true,
      faqs: _parseFaqs(data['faqs']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'organizerName': organizerName,
      'contactEmail': contactEmail,
      'contactNumber': contactNumber,
      'organizerPartner': organizerPartner.name,
      'description': description,
      'imageUrl': imageUrl,
      'activeStatus': activeStatus.name,
      'isMobile': isMobile,
      'faqs': faqs.map((f) => f.toMap()).toList(),
    };
  }

  static List<FAQModel> _parseFaqs(dynamic data) {
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list.map((item) => FAQModel.fromMap(Map<String, dynamic>.from(item))).toList();
  }
}
