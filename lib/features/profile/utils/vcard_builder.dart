String buildVCard(Map<String, String> values) {
  final lines = <String>['BEGIN:VCARD', 'VERSION:3.0'];

  // Name
  final firstName = values['firstName']?.trim() ?? '';
  final lastName = values['lastName']?.trim() ?? '';
  final middleName = values['middleName']?.trim() ?? '';

  final displayName = values['displayName']?.trim().isNotEmpty == true
      ? values['displayName']!.trim()
      : '$firstName $lastName'.trim().isNotEmpty
      ? '$firstName $lastName'.trim()
      : 'Unknown Contact';

  if (firstName.isNotEmpty || lastName.isNotEmpty || middleName.isNotEmpty) {
    lines.add('N:$lastName;$firstName;$middleName;;');
  }

  // Always provide a display name
  lines.add('FN:$displayName');

  // Organization
  final company = values['company']?.trim() ?? '';
  final department = values['department']?.trim() ?? '';

  if (company.isNotEmpty || department.isNotEmpty) {
    lines.add('ORG:$company;$department');
  }

  final jobTitle = values['jobTitle']?.trim() ?? '';
  if (jobTitle.isNotEmpty) {
    lines.add('TITLE:$jobTitle');
  }

  // Phone numbers
  final primaryPhone = values['primaryPhone']?.trim() ?? '';
  final secondaryPhone = values['secondaryPhone']?.trim() ?? '';
  final workPhone = values['workPhone']?.trim() ?? '';

  if (primaryPhone.isNotEmpty) {
    lines.add('TEL;TYPE=CELL:$primaryPhone');
  }

  if (secondaryPhone.isNotEmpty) {
    lines.add('TEL;TYPE=HOME:$secondaryPhone');
  }

  if (workPhone.isNotEmpty) {
    lines.add('TEL;TYPE=WORK:$workPhone');
  }

  // Email
  final email = values['email']?.trim() ?? '';
  final alternateEmail = values['alternateEmail']?.trim() ?? '';
  final workEmail = values['workEmail']?.trim() ?? '';

  if (email.isNotEmpty) {
    lines.add('EMAIL;TYPE=INTERNET:$email');
  }

  if (alternateEmail.isNotEmpty) {
    lines.add('EMAIL;TYPE=INTERNET:$alternateEmail');
  }

  if (workEmail.isNotEmpty) {
    lines.add('EMAIL;TYPE=WORK:$workEmail');
  }

  // Address
  final addressLine1 = values['addressLine1']?.trim() ?? '';
  final city = values['city']?.trim() ?? '';
  final state = values['state']?.trim() ?? '';
  final postalCode = values['postalCode']?.trim() ?? '';
  final country = values['country']?.trim() ?? 'India';

  if (addressLine1.isNotEmpty ||
      city.isNotEmpty ||
      state.isNotEmpty ||
      postalCode.isNotEmpty ||
      country.isNotEmpty) {
    final addressParts = [
      '',
      '',
      addressLine1,
      city,
      state,
      postalCode,
      country,
    ];

    lines.add('ADR;TYPE=HOME:${addressParts.join(';')}');
  }

  // Social / web profiles
  final profileKeys = ['website', 'linkedin', 'github', 'instagram', 'twitter'];

  for (final key in profileKeys) {
    final url = values[key]?.trim() ?? '';

    if (url.isNotEmpty) {
      lines.add('URL:$url');
    }
  }

  // Date of birth
  final dateOfBirth = values['dateOfBirth']?.trim() ?? '';
  if (dateOfBirth.isNotEmpty) {
    lines.add('BDAY:$dateOfBirth');
  }

  // Notes
  final notes = values['notes']?.trim() ?? '';
  if (notes.isNotEmpty) {
    lines.add('NOTE:$notes');
  }

  // Custom fields
  final pronouns = values['pronouns']?.trim() ?? '';
  if (pronouns.isNotEmpty) {
    lines.add('X-PRONOUNS:$pronouns');
  }

  final employeeId = values['employeeId']?.trim() ?? '';
  if (employeeId.isNotEmpty) {
    lines.add('X-EMPLOYEE-ID:$employeeId');
  }

  lines.add('END:VCARD');

  return lines.join('\r\n');
}
