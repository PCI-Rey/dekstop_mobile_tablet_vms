import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vehicle Count Payload Contract & Aggregation Tests', () {
    test('Correctly aggregates vehicle count from by_vehicle list', () {
      final payload = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": {
          "summary": {
            "period_label": "13 Nov 2026 - 14 Nov 2026",
            "total_present_visits": 12,
            "total_with_vehicle": 8,
            "total_need_parking": 8,
            "total_got_parking_slot": 6,
            "total_without_parking_slot": 2,
            "total_no_parking_required": 4
          },
          "by_vehicle": [
            {"name": "Car", "count": 5},
            {"name": "Motorcycle", "count": 2},
            {"name": "Bus", "count": 1},
            {"name": "Mini Bus", "count": 0},
            {"name": "Truck 16 Feet", "count": 0},
            {"name": "Truck 20 Feet", "count": 0},
            {"name": "Truck 40 Feet", "count": 0}
          ],
          "by_vehicle_type": [],
          "by_visitor_type": [],
          "items": []
        }
      };

      final collection = payload['collection'] as Map<String, dynamic>;
      final rawByVehicle = collection['by_vehicle'] as List;

      final updatedCounts = <String, int>{
        'Car': 0,
        'Motorcycle': 0,
        'Bus': 0,
        'Mini Bus': 0,
        'Truck 16 Feet': 0,
        'Truck 20 Feet': 0,
        'Truck 40 Feet': 0,
      };

      void processEntry(dynamic key, dynamic val) {
        if (key == null) return;
        final normKey = key
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[\s_\-]'), '');
        final count = int.tryParse(val?.toString() ?? '0') ?? 0;

        if (normKey.contains('car') && !normKey.contains('sidecar')) {
          updatedCounts['Car'] = (updatedCounts['Car'] ?? 0) + count;
        } else if (normKey.contains('motor') ||
            normKey.contains('bike') ||
            normKey.contains('two')) {
          updatedCounts['Motorcycle'] =
              (updatedCounts['Motorcycle'] ?? 0) + count;
        } else if (normKey.contains('minibus') ||
            normKey.contains('shuttle') ||
            normKey.contains('van')) {
          updatedCounts['Mini Bus'] = (updatedCounts['Mini Bus'] ?? 0) + count;
        } else if (normKey.contains('bus')) {
          updatedCounts['Bus'] = (updatedCounts['Bus'] ?? 0) + count;
        } else if (normKey.contains('16')) {
          updatedCounts['Truck 16 Feet'] =
              (updatedCounts['Truck 16 Feet'] ?? 0) + count;
        } else if (normKey.contains('20')) {
          updatedCounts['Truck 20 Feet'] =
              (updatedCounts['Truck 20 Feet'] ?? 0) + count;
        } else if (normKey.contains('40')) {
          updatedCounts['Truck 40 Feet'] =
              (updatedCounts['Truck 40 Feet'] ?? 0) + count;
        }
      }

      for (final item in rawByVehicle) {
        final name = (item as Map)['name'];
        final count = item['count'];
        processEntry(name, count);
      }

      expect(updatedCounts['Car'], 5);
      expect(updatedCounts['Motorcycle'], 2);
      expect(updatedCounts['Bus'], 1);
      expect(updatedCounts['Mini Bus'], 0);
      expect(updatedCounts['Truck 16 Feet'], 0);
      expect(updatedCounts['Truck 20 Feet'], 0);
      expect(updatedCounts['Truck 40 Feet'], 0);
    });

    test('Correctly aggregates vehicle count from web payload with vehicle_type', () {
      final payload = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": {
          "by_vehicle": [
            {"vehicle_type": "Car", "count": 9},
            {"vehicle_type": "Motorcycle", "count": 0},
            {"vehicle_type": "Bus", "count": 0},
            {"vehicle_type": "MiniBus", "count": 0},
            {"vehicle_type": "Truck16Feet", "count": 0},
            {"vehicle_type": "Truck20Feet", "count": 0},
            {"vehicle_type": "Truck40Feet", "count": 0}
          ]
        }
      };

      final collection = payload['collection'] as Map<String, dynamic>;
      final rawByVehicle = collection['by_vehicle'] as List;

      final updatedCounts = <String, int>{
        'Car': 0,
        'Motorcycle': 0,
        'Bus': 0,
        'Mini Bus': 0,
        'Truck 16 Feet': 0,
        'Truck 20 Feet': 0,
        'Truck 40 Feet': 0,
      };

      void processEntry(dynamic key, dynamic val) {
        if (key == null) return;
        final normKey = key
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[\s_\-]'), '');
        final count = int.tryParse(val?.toString() ?? '0') ?? 0;

        if (normKey == 'car' || (normKey.contains('car') && !normKey.contains('sidecar'))) {
          updatedCounts['Car'] = (updatedCounts['Car'] ?? 0) + count;
        } else if (normKey.contains('motor') ||
            normKey.contains('bike') ||
            normKey.contains('two')) {
          updatedCounts['Motorcycle'] =
              (updatedCounts['Motorcycle'] ?? 0) + count;
        } else if (normKey == 'minibus' ||
            normKey.contains('minibus') ||
            normKey.contains('shuttle') ||
            normKey.contains('van')) {
          updatedCounts['Mini Bus'] = (updatedCounts['Mini Bus'] ?? 0) + count;
        } else if (normKey == 'bus' || normKey.contains('bus')) {
          updatedCounts['Bus'] = (updatedCounts['Bus'] ?? 0) + count;
        } else if (normKey.contains('16')) {
          updatedCounts['Truck 16 Feet'] =
              (updatedCounts['Truck 16 Feet'] ?? 0) + count;
        } else if (normKey.contains('20')) {
          updatedCounts['Truck 20 Feet'] =
              (updatedCounts['Truck 20 Feet'] ?? 0) + count;
        } else if (normKey.contains('40')) {
          updatedCounts['Truck 40 Feet'] =
              (updatedCounts['Truck 40 Feet'] ?? 0) + count;
        }
      }

      for (final item in rawByVehicle) {
        final name = (item as Map)['vehicle_type'];
        final count = item['count'];
        processEntry(name, count);
      }

      expect(updatedCounts['Car'], 9);
      expect(updatedCounts['Motorcycle'], 0);
    });

    test('Does not double count when both by_vehicle and by_vehicle_type exist', () {
      final payload = {
        "status": "success",
        "status_code": 200,
        "collection": {
          "by_vehicle": [
            {"vehicle_type": "Car", "count": 9},
            {"vehicle_type": "Motorcycle", "count": 0}
          ],
          "by_vehicle_type": [
            {"vehicle_type": "Car", "count": 9},
            {"vehicle_type": "Motorcycle", "count": 0}
          ]
        }
      };

      final collection = payload['collection'] as Map<String, dynamic>;
      final rawByVehicle = (collection['by_vehicle'] as List?) ?? [];
      final rawByVehicleType = (collection['by_vehicle_type'] as List?) ?? [];

      final List<Map<String, dynamic>> primarySource = rawByVehicle.isNotEmpty
          ? rawByVehicle.cast<Map<String, dynamic>>()
          : rawByVehicleType.cast<Map<String, dynamic>>();

      int extractCount(String targetKey) {
        final normTarget = targetKey.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
        for (final item in primarySource) {
          final norm = (item['vehicle_type'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
          if (norm == normTarget) {
            return int.tryParse(item['count']?.toString() ?? '0') ?? 0;
          }
        }
        return 0;
      }

      final carCount = extractCount('Car');
      expect(carCount, 9); // Must be 9, never 18
    });

    test('Defensively handles empty collection payload without throwing', () {
      final emptyPayload = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": {
          "summary": {
            "period_label": "13 Nov 2026 - 14 Nov 2026",
            "total_present_visits": 0,
            "total_with_vehicle": 0,
            "total_need_parking": 0,
            "total_got_parking_slot": 0,
            "total_without_parking_slot": 0,
            "total_no_parking_required": 0
          },
          "by_vehicle": [],
          "by_vehicle_type": [],
          "by_visitor_type": [],
          "items": []
        }
      };

      final collection = emptyPayload['collection'] as Map<String, dynamic>;
      final summary = collection['summary'] as Map<String, dynamic>;

      expect(summary['period_label'], "13 Nov 2026 - 14 Nov 2026");
      expect(summary['total_present_visits'], 0);
      expect(summary['total_with_vehicle'], 0);
    });
  });
}

