import 'package:cloud_firestore/cloud_firestore.dart';

enum PickupStatus { requested, scheduled, completed, disputed }

class FfbLog {
  final String id;
  final PickupStatus status;
  final Timestamp requestedAt;
  final double estimatedQuantityKg;
  // We can add more fields like scheduledFor, processorId, etc. later

  FfbLog({
    required this.id,
    required this.status,
    required this.requestedAt,
    required this.estimatedQuantityKg,
  });

  factory FfbLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FfbLog(
      id: doc.id,
      status: PickupStatus.values.firstWhere(
        (e) => e.toString() == 'PickupStatus.${data['status']}',
        orElse: () => PickupStatus.requested,
      ),
      requestedAt: data['requestedAt'] as Timestamp,
      estimatedQuantityKg: (data['estimatedQuantityKg'] as num).toDouble(),
    );
  }
}
