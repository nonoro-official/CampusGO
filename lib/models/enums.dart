// User Roles
enum Role {
  customer,
  vendor,
  coVendor;

  // Convert String from Firestore to Enum
  static Role fromString(String role) {
    switch (role.toLowerCase()) {
      case 'vendor':
        return Role.vendor;
      case 'covendor':
      case 'co-vendor':
        return Role.coVendor;
      default:
        return Role.customer;
    }
  }

  // Convert Enum to String for Firestore (e.g., "Vendor")
  String get toName => name[0].toUpperCase() + name.substring(1);
}

// Invite Status
enum BusinessPartner {
  campus,
  organization,
  student;

  static BusinessPartner fromString(String value) {
    switch (value.toLowerCase()) {
      case 'campus':
        return BusinessPartner.campus;
      case 'organization':
        return BusinessPartner.organization;
      case 'student':
        return BusinessPartner.student;
      default:
        return BusinessPartner.student; // Default fallback
    }
  }
}

// Invite Status
enum InviteStatus {
  pending,
  accepted,
  declined;

  static InviteStatus fromString(String status) {
    return InviteStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => InviteStatus.pending,
    );
  }
}

// User Tiers
enum UserTier {
  free,
  premium;

  // Convert String from Firestore to Enum
  static UserTier fromString(String userTier) {
    return UserTier.values.firstWhere(
      (e) => e.name == userTier.toLowerCase(),
      orElse: () => UserTier.free, // Fallback
    );
  }

  // Convert Enum to String for Firestore (e.g., "Free")
  String get toName => name[0].toUpperCase() + name.substring(1);
}

// Vendor Status
enum ActiveStatus {
  open,
  onBreak,
  closed;

  // Convert String from Firestore to Enum
  static ActiveStatus fromString(String activeStatus) {
    return ActiveStatus.values.firstWhere(
      (e) => e.name == activeStatus.toLowerCase(),
      orElse: () => ActiveStatus.closed, // Fallback
    );
  }

  // Convert Enum to String for Firestore (e.g., "Open")
  String get toName => name[0].toUpperCase() + name.substring(1);
}

// Product Type
enum ProductType {
  walkIn,
  reservation;

  // Convert String from Firestore to Enum
  static ProductType fromString(String productType) {
    return ProductType.values.firstWhere(
      (e) => e.name == productType.toLowerCase(),
      orElse: () => ProductType.walkIn, // Fallback
    );
  }

  // Convert Enum to String for Firestore (e.g., "Vendor")
  String get toName => name[0].toUpperCase() + name.substring(1);
}

// Listing Type
enum ListingType {
  regular,
  bundle,
  promo,
  discount;

  static ListingType fromString(String type) {
    return ListingType.values.firstWhere(
      (e) => e.name == type.toLowerCase(),
      orElse: () => ListingType.regular,
    );
  }

  String get toName => name[0].toUpperCase() + name.substring(1);
}

// Notification Type

// Announcement Type

// Message Status
