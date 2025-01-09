class MedicalRecordType {
  static const String labResult = 'Lab Result';
  static const String imaging = 'Imaging Report';
  static const String diagnosis = 'Diagnosis';
  static const String treatment = 'Treatment Plan';
  static const String medicalCertificate = 'Medical Certificate';
  static const String referralLetter = 'Referral Letter';
  static const String dischargeSummary = 'Discharge Summary';
  static const String progressNote = 'Progress Note';
  static const String other = 'Other';

  static List<String> get allTypes => [
    labResult,
    imaging,
    diagnosis,
    treatment,
    medicalCertificate,
    referralLetter,
    dischargeSummary,
    progressNote,
    other,
  ];
}