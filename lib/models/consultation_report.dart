class ConsultationReport {
  final String id;
  final String patientName;
  final String language;
  final DateTime dateTime;
  final String duration;
  final String chiefComplaint;
  final String symptoms;
  final String diagnosis;
  final String prescription;
  final String notes;

  ConsultationReport({
    required this.id,
    required this.patientName,
    required this.language,
    required this.dateTime,
    required this.duration,
    required this.chiefComplaint,
    required this.symptoms,
    required this.diagnosis,
    required this.prescription,
    required this.notes,
  });

  // Static sample data for UI development
  static List<ConsultationReport> sampleReports = [
    ConsultationReport(
      id: '1',
      patientName: 'Rajesh Kumar',
      language: 'Hindi',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      duration: '12:34',
      chiefComplaint: 'Persistent headache and mild fever',
      symptoms: 'Headache for 3 days, fever (99.5°F), mild body ache, loss of appetite',
      diagnosis: 'Viral fever with tension headache',
      prescription: '1. Paracetamol 500mg - 1 tablet thrice daily after meals\n2. Cetirizine 10mg - 1 tablet at night\n3. Plenty of fluids and rest',
      notes: 'Patient advised to return if fever persists beyond 3 days or if symptoms worsen. Follow-up in 5 days if needed.',
    ),
    ConsultationReport(
      id: '2',
      patientName: 'Priya Sharma',
      language: 'Tamil',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      duration: '08:45',
      chiefComplaint: 'Stomach pain and indigestion',
      symptoms: 'Epigastric pain, bloating after meals, occasional nausea, no vomiting',
      diagnosis: 'Acute gastritis',
      prescription: '1. Pantoprazole 40mg - 1 tablet before breakfast\n2. Domperidone 10mg - 1 tablet before meals\n3. Avoid spicy and oily food',
      notes: 'Dietary modifications advised. Patient to avoid NSAIDs. Review in 1 week.',
    ),
    ConsultationReport(
      id: '3',
      patientName: 'Mohammed Ali',
      language: 'Telugu',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      duration: '15:20',
      chiefComplaint: 'Joint pain in knees',
      symptoms: 'Bilateral knee pain, morning stiffness for 30 mins, difficulty climbing stairs, no swelling',
      diagnosis: 'Early osteoarthritis of both knees',
      prescription: '1. Glucosamine 1500mg - once daily\n2. Diclofenac gel - apply twice daily\n3. Physiotherapy exercises recommended',
      notes: 'X-ray advised if pain persists. Weight reduction counseling done. Follow-up in 2 weeks.',
    ),
    ConsultationReport(
      id: '4',
      patientName: 'Lakshmi Devi',
      language: 'Kannada',
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      duration: '10:15',
      chiefComplaint: 'Skin rash on arms',
      symptoms: 'Itchy red patches on both forearms, started 5 days ago, no fever, no new medications',
      diagnosis: 'Contact dermatitis',
      prescription: '1. Hydroxyzine 25mg - at night\n2. Betamethasone cream - apply twice daily\n3. Moisturizer after bath',
      notes: 'Advised to identify and avoid potential allergens. Review in 1 week.',
    ),
  ];
}

