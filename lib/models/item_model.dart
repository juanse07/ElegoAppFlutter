class Item {
  final String id;
  final String serviceType;
  final String zipCode;
  final String name;
  final String phone;
  final int numberOfItems;
  final String tvInches;
  final String additionalInformation;
  final String state;
  final String image1Path;
  final String image2Path;
  final DateTime requestedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.serviceType,
    required this.zipCode,
    required this.name,
    required this.phone,
    required this.numberOfItems,
    required this.tvInches,
    required this.additionalInformation,
    required this.state,
    required this.image1Path,
    required this.image2Path,
    required this.requestedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json'); // Debug print

    try {
      // Parse the ID correctly depending on format
      String id;
      if (json['_id'] is String) {
        id = json['_id'];
      } else if (json['_id'] is Map) {
        id = json['_id']['\$oid'] ?? '';
      } else {
        id = '';
      }
      print('Parsed ID: $id');

      // Parse dates correctly
      DateTime parseDate(dynamic dateValue) {
        print('Parsing date value: $dateValue');
        if (dateValue == null) return DateTime.now();

        try {
          if (dateValue is String) {
            return DateTime.parse(dateValue);
          } else if (dateValue is Map && dateValue['\$date'] != null) {
            if (dateValue['\$date'] is String) {
              return DateTime.parse(dateValue['\$date']);
            } else if (dateValue['\$date'] is Map &&
                dateValue['\$date']['\$numberLong'] != null) {
              return DateTime.fromMillisecondsSinceEpoch(
                int.parse(dateValue['\$date']['\$numberLong']),
              );
            }
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
        return DateTime.now();
      }

      // Extract fields with fallbacks
      final serviceType = json['serviceType'] as String? ?? '';
      final zipCode = json['zipCode'] as String? ?? '';
      final name = json['name'] as String? ?? '';
      final phone = json['phone'] as String? ?? '';

      int numberOfItems = 0;
      try {
        numberOfItems =
            json['numberOfItems'] is int
                ? json['numberOfItems']
                : int.tryParse(json['numberOfItems'].toString()) ?? 0;
      } catch (e) {
        print('Error parsing numberOfItems: $e');
      }

      final tvInches = json['tvInches']?.toString() ?? '';
      final additionalInfo =
          json['additionalInfo'] as String? ??
          json['additionalInformation'] as String? ??
          '';
      final state = json['state'] as String? ?? '';
      final image1Path = json['image1Path'] as String? ?? '';
      final image2Path = json['image2Path'] as String? ?? '';

      final requestedDate = parseDate(json['requestedDate']);
      final createdAt = parseDate(json['createdAt']);
      final updatedAt = parseDate(json['updatedAt']);

      print('Successfully parsed all fields');

      return Item(
        id: id,
        serviceType: serviceType,
        zipCode: zipCode,
        name: name,
        phone: phone,
        numberOfItems: numberOfItems,
        tvInches: tvInches,
        additionalInformation: additionalInfo,
        state: state,
        image1Path: image1Path,
        image2Path: image2Path,
        requestedDate: requestedDate,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error in Item.fromJson: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'zipCode': zipCode,
      'name': name,
      'phone': phone,
      'numberOfItems': numberOfItems,
      'tvInches': tvInches,
      'additionalInformation': additionalInformation,
      'state': state,
      'image1Path': image1Path,
      'image2Path': image2Path,
      'requestedDate': requestedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
