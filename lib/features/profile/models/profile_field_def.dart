enum FieldInputType { text, phone, email, date, multiline }

class ProfileFieldDef {
  final String key;
  final String label;
  final String section;
  final FieldInputType type;

  const ProfileFieldDef(this.key, this.label, this.section, this.type);
}

const List<ProfileFieldDef> profileFieldDefs = [
  ProfileFieldDef('firstName', 'First Name', 'Basic', FieldInputType.text),
  ProfileFieldDef('middleName', 'Middle Name', 'Basic', FieldInputType.text),
  ProfileFieldDef('lastName', 'Last Name', 'Basic', FieldInputType.text),
  ProfileFieldDef('displayName', 'Display Name', 'Basic', FieldInputType.text),
  ProfileFieldDef('pronouns', 'Pronouns', 'Basic', FieldInputType.text),
  ProfileFieldDef('dateOfBirth', 'Date of Birth', 'Basic', FieldInputType.date),

  ProfileFieldDef(
    'primaryPhone',
    'Primary Phone',
    'Contact',
    FieldInputType.phone,
  ),
  ProfileFieldDef(
    'secondaryPhone',
    'Secondary Phone',
    'Contact',
    FieldInputType.phone,
  ),
  ProfileFieldDef('email', 'Email', 'Contact', FieldInputType.email),
  ProfileFieldDef(
    'alternateEmail',
    'Alternate Email',
    'Contact',
    FieldInputType.email,
  ),

  ProfileFieldDef('company', 'Company', 'Professional', FieldInputType.text),
  ProfileFieldDef('jobTitle', 'Job Title', 'Professional', FieldInputType.text),
  ProfileFieldDef(
    'department',
    'Department',
    'Professional',
    FieldInputType.text,
  ),
  ProfileFieldDef(
    'employeeId',
    'Employee ID',
    'Professional',
    FieldInputType.text,
  ),
  ProfileFieldDef(
    'workPhone',
    'Work Phone',
    'Professional',
    FieldInputType.phone,
  ),
  ProfileFieldDef(
    'workEmail',
    'Work Email',
    'Professional',
    FieldInputType.email,
  ),

  ProfileFieldDef(
    'addressLine1',
    'Address Line 1',
    'Address',
    FieldInputType.text,
  ),
  ProfileFieldDef(
    'addressLine2',
    'Address Line 2',
    'Address',
    FieldInputType.text,
  ),
  ProfileFieldDef('city', 'City', 'Address', FieldInputType.text),
  ProfileFieldDef('state', 'State', 'Address', FieldInputType.text),
  ProfileFieldDef('country', 'Country', 'Address', FieldInputType.text),
  ProfileFieldDef('postalCode', 'Postal Code', 'Address', FieldInputType.text),

  ProfileFieldDef('website', 'Website', 'Online', FieldInputType.text),
  ProfileFieldDef('linkedin', 'LinkedIn', 'Online', FieldInputType.text),
  ProfileFieldDef('github', 'GitHub', 'Online', FieldInputType.text),
  ProfileFieldDef('instagram', 'Instagram', 'Online', FieldInputType.text),
  ProfileFieldDef('twitter', 'X / Twitter', 'Online', FieldInputType.text),

  ProfileFieldDef('notes', 'Notes', 'Additional', FieldInputType.multiline),
];

const List<String> profileSectionOrder = [
  'Basic',
  'Contact',
  'Professional',
  'Address',
  'Online',
  'Additional',
];
