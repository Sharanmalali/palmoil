    import 'package:cloud_firestore/cloud_firestore.dart';

    enum ApplicationStatus { applied, pending_verification, field_verified, approved, paid, rejected }

    class SubsidyApplication {
      final String id;
      final String schemeName;
      final ApplicationStatus status;
      final Timestamp appliedAt;
      final String? rejectionReason;

      SubsidyApplication({
        required this.id,
        required this.schemeName,
        required this.status,
        required this.appliedAt,
        this.rejectionReason,
      });

      factory SubsidyApplication.fromFirestore(DocumentSnapshot doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return SubsidyApplication(
          id: doc.id,
          schemeName: data['schemeName'] ?? 'Unknown Scheme',
          status: ApplicationStatus.values.firstWhere(
            (e) => e.toString() == 'ApplicationStatus.${data['status']}',
            orElse: () => ApplicationStatus.applied,
          ),
          appliedAt: data['appliedAt'] as Timestamp,
          rejectionReason: data['rejectionReason'],
        );
      }
    }
    
