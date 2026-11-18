import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Detail Access Card Contract & Logic Tests', () {
    test('Correctly extracts and formats access control items with Grant and Revoke status', () {
      final responsePayload = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": [
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "cee19254-0d58-4cdc-bdeb-05ba833525ee",
            "access_control_name": "SCP 4 A",
            "visitor_give_access": "Grant",
            "grant_at": "2026-11-17T10:00:00.000",
            "revoke_at": null,
            "sort": 1,
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "48f2e3c2-e60a-47df-a355-09b13271fd01",
            "access_control_name": "SCP 4C",
            "visitor_give_access": "Grant",
            "grant_at": "2026-11-17T10:00:00.000",
            "revoke_at": null,
            "sort": 2,
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "84140f2d-df77-4514-806f-6aa821523f9e",
            "access_control_name": "SCP 1B",
            "visitor_give_access": "Revoke",
            "grant_at": "2026-11-17T10:02:25.766",
            "revoke_at": "2026-11-17T10:04:17.263",
            "sort": 3,
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "11223344-5566-7788-9900-aabbccddeeff",
            "access_control_name": "SCP 2C",
            "visitor_give_access": "Grant",
            "grant_at": "2026-11-17T10:00:00.000",
            "revoke_at": null,
            "sort": 4,
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "99887766-5544-3322-1100-ffeeddccbbaa",
            "access_control_name": "SCP Test",
            "visitor_give_access": "Grant",
            "grant_at": "2026-11-17T10:00:00.000",
            "revoke_at": null,
            "sort": 5,
          },
        ]
      };

      final collection = responsePayload['collection'] as List;
      final rawList = collection.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      expect(rawList.length, equals(5));

      // Check status strings
      final grantItems = rawList.where((e) => (e['visitor_give_access'] ?? '').toString().toLowerCase() == 'grant').toList();
      final revokeItems = rawList.where((e) => (e['visitor_give_access'] ?? '').toString().toLowerCase() == 'revoke').toList();

      expect(grantItems.length, equals(4));
      expect(revokeItems.length, equals(1));
      expect(revokeItems.first['access_control_name'], equals('SCP 1B'));
    });

    test('Deduplicates by access_control_id, keeping the latest status record', () {
      final historyList = [
        {
          "access_control_id": "door-1",
          "access_control_name": "SCP 1B",
          "visitor_give_access": "Grant",
          "grant_at": "2026-11-17T09:00:00.000",
          "revoke_at": null,
          "sort": 1,
        },
        {
          "access_control_id": "door-1",
          "access_control_name": "SCP 1B",
          "visitor_give_access": "Revoke",
          "grant_at": "2026-11-17T09:00:00.000",
          "revoke_at": "2026-11-17T09:30:00.000",
          "sort": 2,
        },
        {
          "access_control_id": "door-2",
          "access_control_name": "SCP 4 A",
          "visitor_give_access": "Grant",
          "grant_at": "2026-11-17T09:00:00.000",
          "revoke_at": null,
          "sort": 1,
        },
      ];

      final uniqueMap = <String, Map<String, dynamic>>{};
      for (final item in historyList) {
        final id = (item['access_control_id'] ?? '').toString();
        if (id.isEmpty) continue;

        if (!uniqueMap.containsKey(id)) {
          uniqueMap[id] = item;
        } else {
          final existing = uniqueMap[id]!;
          final existingRevoke = DateTime.tryParse(existing['revoke_at']?.toString() ?? '');
          final existingGrant = DateTime.tryParse(existing['grant_at']?.toString() ?? '');
          final newRevoke = DateTime.tryParse(item['revoke_at']?.toString() ?? '');
          final newGrant = DateTime.tryParse(item['grant_at']?.toString() ?? '');

          final existingLatest = (existingRevoke != null && (existingGrant == null || existingRevoke.isAfter(existingGrant)))
              ? existingRevoke
              : existingGrant;
          final newLatest = (newRevoke != null && (newGrant == null || newRevoke.isAfter(newGrant)))
              ? newRevoke
              : newGrant;

          if (newLatest != null && (existingLatest == null || newLatest.isAfter(existingLatest))) {
            uniqueMap[id] = item;
          }
        }
      }

      final result = uniqueMap.values.toList();
      expect(result.length, equals(2));

      final door1 = result.firstWhere((e) => e['access_control_id'] == 'door-1');
      expect(door1['visitor_give_access'], equals('Revoke'));

      final door2 = result.firstWhere((e) => e['access_control_id'] == 'door-2');
      expect(door2['visitor_give_access'], equals('Grant'));
    });

    test('Correctly filters detail access controls by search query', () {
      final items = [
        {'access_control_name': 'SCP 4 A', 'visitor_give_access': 'Grant'},
        {'access_control_name': 'SCP 4C', 'visitor_give_access': 'Grant'},
        {'access_control_name': 'SCP 1B', 'visitor_give_access': 'Revoke'},
        {'access_control_name': 'SCP 2C', 'visitor_give_access': 'Grant'},
        {'access_control_name': 'SCP Test', 'visitor_give_access': 'Grant'},
      ];

      final filteredScp4 = items.where((i) => i['access_control_name']!.toLowerCase().contains('4')).toList();
      expect(filteredScp4.length, equals(2));

      final filtered1b = items.where((i) => i['access_control_name']!.toLowerCase().contains('1b')).toList();
      expect(filtered1b.length, equals(1));
      expect(filtered1b.first['visitor_give_access'], equals('Revoke'));
    });
  });
}
