enum UserRole {
  user,
  admin,
  superAdmin,
  pharmacist,
  supportAgent;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.user;
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'pharmacist':
        return UserRole.pharmacist;
      case 'support_agent':
      case 'supportagent':
        return UserRole.supportAgent;
      default:
        return UserRole.user;
    }
  }

  String get id => name;

  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.supportAgent:
        return 'Support Agent';
    }
  }

  String get homeRoute {
    switch (this) {
      case UserRole.user:
        return '/home';
      case UserRole.admin:
        return '/admin';
      case UserRole.superAdmin:
        return '/admin';
      case UserRole.pharmacist:
        return '/admin';
      case UserRole.supportAgent:
        return '/admin';
    }
  }
}

enum Gender { male, female, other }

enum OrderStatus {
  placed,
  confirmed,
  processing,
  dispatched,
  outForDelivery,
  delivered,
  cancelled,
  failed;

  String get label {
    switch (this) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
    }
  }
}

enum PaymentMethod {
  cod,
  bkash,
  nagad,
  rocket,
  card;

  String get label {
    switch (this) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.bkash:
        return 'bKash';
      case PaymentMethod.nagad:
        return 'Nagad';
      case PaymentMethod.rocket:
        return 'Rocket';
      case PaymentMethod.card:
        return 'Card Payment';
    }
  }
}

enum LabBookingStatus {
  upcoming,
  processing,
  collected,
  resultReady,
  completed,
  cancelled,
}
