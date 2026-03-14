class AccountConflictException implements Exception {
  const AccountConflictException({
    required this.previousUserId,
    required this.newUserId,
    required this.newEmail,
  });

  final String previousUserId;
  final String newUserId;
  final String newEmail;
}
