import 'package:flutter/material.dart';
import 'package:health_care/screens/doctor/add_prescription_screen.dart';
import 'package:health_care/screens/doctor/medical_notes_screen.dart';

// Auth Screens
import '../screens/admin/analytics_screen.dart';
import '../screens/admin/medical_records_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/admin/users_management_screen.dart';
import '../screens/admin/verify_users_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

// Patient Screens
import '../screens/doctor/add_medical_record_screen.dart';
import '../screens/doctor/doctor_appointments_screen.dart';
import '../screens/doctor/doctor_medical_records_screen.dart';
import '../screens/doctor/doctor_profile_screen.dart';
import '../screens/doctor/patient_details_screen.dart';
import '../screens/doctor/patients_list_screen.dart';
import '../screens/doctor/prescriptions_screen.dart';
import '../screens/doctor/schedule_screen.dart';
import '../screens/patient/book_appointment_screen.dart';
import '../screens/patient/doctor_selection_screen.dart';
import '../screens/patient/medical_history_screen.dart';
import '../screens/patient/patient_home_screen.dart';
import '../screens/patient/appointments_screen.dart';
import '../screens/patient/find_doctor_screen.dart';
import '../screens/patient/medical_records_screen.dart';
import '../screens/patient/profile_screen.dart';
import '../screens/patient/upload_screen.dart';
// import '../screens/patient/profile_screen.dart';
// import '../screens/patient/history_screen.dart';

// Doctor Screens
import '../screens/doctor/doctor_home_screen.dart';
// import '../screens/doctor/doctor_appointments_screen.dart';
// import '../screens/doctor/patients_list_screen.dart';
// import '../screens/doctor/doctor_medical_records_screen.dart';
// import '../screens/doctor/prescriptions_screen.dart';
// import '../screens/doctor/doctor_profile_screen.dart';
// import '../screens/doctor/schedule_screen.dart';

// Admin Screens
import '../screens/admin/admin_home_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Auth Routes
      '/': (context) => const LoginScreen(),
      '/login': (context) => const LoginScreen(),
      '/register': (context) => const RegisterScreen(),

      // Patient Routes
      '/patient/home': (context) => const PatientHomeScreen(),
      '/patient/appointments': (context) =>  PatientAppointmentsScreen(),
      '/patient/select-doctor': (context) => const DoctorSelectionScreen(),
      '/patient/find-doctor': (context) => const FindDoctorScreen(),
      '/patient/medical-records': (context) =>  PatientMedicalRecordsScreen(),
      '/patient/upload': (context) => const UploadDocumentScreen(),
      '/patient/profile': (context) => const PatientProfileScreen(),
      '/patient/history': (context) =>  PatientHistoryScreen(),
      '/patient/book-appointment': (context) {
        final doctor = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return BookAppointmentScreen(doctor: doctor);
      },

      // Doctor Routes
      '/doctor/home': (context) => const DoctorHomeScreen(),
      '/doctor/appointments': (context) => const DoctorAppointmentsScreen(),
      '/doctor/patients': (context) => const PatientListScreen(),
      '/doctor/medical-records': (context) => const DoctorMedicalRecordsScreen(),
      '/doctor/prescriptions': (context) => const PrescriptionsScreen(),
      '/doctor/prescriptions/add': (context) => const AddPrescriptionScreen(),
      '/doctor/medical-records/add': (context) => const AddMedicalRecordScreen(),
      // '/doctor/medical-notes': (context) => const MedicalNotesScreen(args: args),
      '/doctor/profile': (context) => const DoctorProfileScreen(),
      '/doctor/schedule': (context) => const ScheduleScreen(),
      '/doctor/patient-details': (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return PatientDetailsScreen(args: args);
      },

      // Admin Routes
      '/admin/home': (context) => const AdminHomeScreen(),
      '/admin/users': (context) => const UsersManagementScreen(),
      '/admin/verify-users': (context) => const VerifyUsersScreen(),
      '/admin/analytics': (context) => const AnalyticsScreen(),
      // '/admin/billing': (context) => const BillingScreen(),
      '/admin/medical-records': (context) => const AdminMedicalRecordsScreen(),
      '/admin/settings': (context) => const AdminSettingsScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {

    return MaterialPageRoute(
      builder: (context) {
        return const Scaffold(
          body: Center(
            child: Text('Route not found!'),
          ),
        );
      },
    );
  }

  // Navigation helpers
  static void navigateToHome(BuildContext context, String userType) {
    Navigator.pushReplacementNamed(context, '/$userType/home');
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Route protection middleware
  static Widget protectRoute(BuildContext context, Widget screen, List<String> allowedRoles) {
    // Add your route protection logic here
    // Example: check if user is authenticated and has the required role
    return screen;
  }
}

// Extension method for easier navigation
extension NavigationExtension on BuildContext {
  void navigateTo(String route, {Object? arguments}) {
    Navigator.pushNamed(this, route, arguments: arguments);
  }

  void replaceTo(String route, {Object? arguments}) {
    Navigator.pushReplacementNamed(this, route, arguments: arguments);
  }
}