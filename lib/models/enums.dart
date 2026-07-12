// User Roles
enum Role {
  customer,
  organizer,
  coOrganizer;

  // Convert String from Firestore to Enum
  static Role fromString(String role) {
    switch (role.toLowerCase()) {
      case 'organizer':
        return Role.organizer;
      case 'coorganizer':
      case 'co-organizer':
        return Role.coOrganizer;
      default:
        return Role.customer;
    }
  }

  // Convert Enum to String for Firestore (e.g., "Organizer")
  String get toName => name[0].toUpperCase() + name.substring(1);
}

// Invite Status
enum OrganizerPartner {
  campus,
  organization,
  student;

  static OrganizerPartner fromString(String value) {
    switch (value.toLowerCase()) {
      case 'campus':
        return OrganizerPartner.campus;
      case 'organization':
        return OrganizerPartner.organization;
      case 'student':
        return OrganizerPartner.student;
      default:
        return OrganizerPartner.student; // Default fallback
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

// Organizer Status
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

// Reward Type
enum RewardType {
  walkIn,
  reservation;

  // Convert String from Firestore to Enum
  static RewardType fromString(String rewardType) {
    return RewardType.values.firstWhere(
      (e) => e.name == rewardType.toLowerCase(),
      orElse: () => RewardType.walkIn, // Fallback
    );
  }

  // Convert Enum to String for Firestore (e.g., "Organizer")
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
