class LabResult {
  final String recordId;
  final String testName;
  final Map<String, dynamic> results;
  final String labName;
  final String? referenceRange;
  final String? interpretation;

  LabResult({
    required this.recordId,
    required this.testName,
    required this.results,
    required this.labName,
    this.referenceRange,
    this.interpretation,
  });

  Map<String, dynamic> toMetadata() {
    return {
      'testName': testName,
      'results': results,
      'labName': labName,
      'referenceRange': referenceRange,
      'interpretation': interpretation,
    };
  }
}