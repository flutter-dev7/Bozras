class StaffUser {
  const StaffUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.isActive,
    this.email,
    this.emailConfirmed = false,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phone;
  final String role;
  final bool isActive;
  final String? email;
  final bool emailConfirmed;
}

const staffRoleLabels = {
  'Admin': 'Администратор',
  'Agent': 'Агент',
  'Courier': 'Курьер',
  'Shop': 'Магазин',
};

const assignableRoles = ['Agent', 'Courier', 'Admin'];