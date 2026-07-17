import 'package:saefra_run/core/models/emergency_contact_model.dart';
import 'package:saefra_run/core/utils/api_response_parser.dart';

class SosActivateResponse {
  const SosActivateResponse({
    this.sosId,
    this.message,
    this.addressLink,
    this.contacts = const [],
  });

  final String? sosId;
  final String? message;
  final String? addressLink;
  final List<EmergencyContactModel> contacts;

  factory SosActivateResponse.fromApiMap(Map<String, dynamic> map) {
    final payload = ApiResponseParser.payload(map);
    final message = map['message'] as String? ?? payload['message'] as String?;

    final sosRaw = payload['sos'] ?? payload['sos_session'] ?? payload;
    final sosMap = sosRaw is Map
        ? Map<String, dynamic>.from(sosRaw)
        : payload;

    final contacts = _parseContacts(map, payload, sosMap);

    final id = sosMap['id'] ?? sosMap['sos_id'] ?? payload['id'];

    return SosActivateResponse(
      sosId: id == null ? null : '$id',
      message: message,
      addressLink: sosMap['address_link'] as String? ??
          payload['address_link'] as String?,
      contacts: contacts,
    );
  }

  static List<EmergencyContactModel> _parseContacts(
    Map<String, dynamic> map,
    Map<String, dynamic> payload,
    Map<String, dynamic> sosMap,
  ) {
    for (final source in [
      sosMap['contacts'],
      sosMap['emergency_contacts'],
      sosMap['notified_contacts'],
      payload['contacts'],
      payload['emergency_contacts'],
      payload['notified_contacts'],
      map['contacts'],
      map['emergency_contacts'],
    ]) {
      final parsed = _contactsFromRaw(source);
      if (parsed.isNotEmpty) return parsed;
    }
    return [];
  }

  static List<EmergencyContactModel> _contactsFromRaw(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (item) => EmergencyContactModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((c) => c.name.isNotEmpty || c.phone.isNotEmpty)
        .toList();
  }
}

class SosCancelResponse {
  const SosCancelResponse({this.message});

  final String? message;

  factory SosCancelResponse.fromApiMap(Map<String, dynamic> map) {
    final payload = ApiResponseParser.payload(map);
    return SosCancelResponse(
      message: map['message'] as String? ?? payload['message'] as String?,
    );
  }
}
