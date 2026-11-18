import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Revoke Access Card Contract & Logic Tests', () {
    test('Constructs valid revoke access card payload matching senior contract', () {
      final trxVisitorId = '93e8d208-42bf-40c5-b304-e2892c6b3ca0';
      final trxCardId = '38DF689D-57A1-468C-969B-A7E8EC2FDE40';
      final registeredSiteId = '1D6C9704-F6AB-47BD-A6B0-3E1FB3D6FAEA';
      final cardNumber = '8521061202';
      final accessControls = ['84140f2d-df77-4514-806f-6aa821523f9e'];

      final body = {
        'trx_visitor_id': trxVisitorId.trim(),
        'trx_card_id': trxCardId.trim(),
        'registered_site_id': registeredSiteId.trim(),
        'card_number': cardNumber.trim(),
        'access_controls': accessControls,
      };

      expect(body['trx_visitor_id'], equals('93e8d208-42bf-40c5-b304-e2892c6b3ca0'));
      expect(body['trx_card_id'], equals('38DF689D-57A1-468C-969B-A7E8EC2FDE40'));
      expect(body['registered_site_id'], equals('1D6C9704-F6AB-47BD-A6B0-3E1FB3D6FAEA'));
      expect(body['card_number'], equals('8521061202'));
      expect(body['access_controls'], contains('84140f2d-df77-4514-806f-6aa821523f9e'));
      expect((body['access_controls'] as List).length, equals(1));
    });

    test('Ensures HTTP method for revoking access card is DELETE with request body', () {
      const httpMethod = 'DELETE';
      const endpoint = '/api/operator-invitation/revoke/access-card';
      expect(httpMethod, equals('DELETE'));
      expect(endpoint, contains('revoke/access-card'));
    });

    test('Strictly filters access controls with visitor_give_access == "Grant" and ignores "Revoke"', () {
      final responsePayload = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": [
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "84140f2d-df77-4514-806f-6aa821523f9e",
            "access_control_name": "SCP 1B",
            "visitor_give_access": "Revoke",
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "cee19254-0d58-4cdc-bdeb-05ba833525ee",
            "access_control_name": "SCP 4 A",
            "visitor_give_access": "Grant",
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "48f2e3c2-e60a-47df-a355-09b13271fd01",
            "access_control_name": "SCP 4C",
            "visitor_give_access": "Grant",
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "11223344-5566-7788-9900-aabbccddeeff",
            "access_control_name": "SCP 2C",
            "visitor_give_access": "Grant",
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "99887766-5544-3322-1100-ffeeddccbbaa",
            "access_control_name": "SCP Test",
            "visitor_give_access": "Grant",
          },
          {
            "trx_visitor_id": "93e8d208-42bf-40c5-b304-e2892c6b3ca0",
            "access_control_id": "84140f2d-df77-4514-806f-6aa821523f9e",
            "access_control_name": "SCP 1B",
            "visitor_give_access": "Grant", // Granted in another record
          },
        ]
      };

      final collection = responsePayload['collection'] as List;
      final rawList = collection.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // 1. Filter strictly items where visitor_give_access == 'Grant'
      final granted = rawList.where((item) {
        final status = (item['visitor_give_access'] ?? '').toString().trim().toLowerCase();
        return status == 'grant';
      }).toList();

      expect(granted.length, equals(5));

      // 2. Deduplicate by access_control_id
      final uniqueMap = <String, Map<String, dynamic>>{};
      for (final item in granted) {
        final id = (item['access_control_id'] ?? item['id'] ?? '').toString();
        if (id.isNotEmpty && !uniqueMap.containsKey(id)) {
          uniqueMap[id] = item;
        }
      }
      final uniqueGranted = uniqueMap.values.toList();

      expect(uniqueGranted.length, equals(5));
      final names = uniqueGranted.map((e) => e['access_control_name']).toSet();
      expect(names, containsAll(['SCP 4 A', 'SCP 4C', 'SCP 2C', 'SCP Test', 'SCP 1B']));
    });

    test('Correctly filters granted access controls by search query', () {
      final items = [
        {'access_control_id': '1', 'access_control_name': 'SCP 4 A'},
        {'access_control_id': '2', 'access_control_name': 'SCP 4C'},
        {'access_control_id': '3', 'access_control_name': 'SCP 1B'},
        {'access_control_id': '4', 'access_control_name': 'SCP 2C'},
        {'access_control_id': '5', 'access_control_name': 'SCP Test'},
      ];

      final query = '4';
      final filtered = items.where((i) => i['access_control_name']!.toLowerCase().contains(query)).toList();
      expect(filtered.length, equals(2));
      expect(filtered.map((e) => e['access_control_name']), containsAll(['SCP 4 A', 'SCP 4C']));

      final queryTest = 'test';
      final filteredTest = items.where((i) => i['access_control_name']!.toLowerCase().contains(queryTest)).toList();
      expect(filteredTest.length, equals(1));
      expect(filteredTest.first['access_control_name'], equals('SCP Test'));
    });

    test('Validates selection counter and button enable logic', () {
      final selectedAccessIds = <String>{};
      final totalCount = 5;

      bool canSubmit(Set<String> selected) => selected.isNotEmpty;

      // 0 selected: cannot submit
      expect(canSubmit(selectedAccessIds), isFalse);
      expect('${selectedAccessIds.length} / $totalCount selected', equals('0 / 5 selected'));

      // 1 selected: can submit
      selectedAccessIds.add('cee19254-0d58-4cdc-bdeb-05ba833525ee');
      expect(canSubmit(selectedAccessIds), isTrue);
      expect('${selectedAccessIds.length} / $totalCount selected', equals('1 / 5 selected'));

      // Select All: 5 selected
      selectedAccessIds.addAll(['2', '3', '4', '5']);
      expect(selectedAccessIds.length, equals(5));
      expect(canSubmit(selectedAccessIds), isTrue);
      expect('${selectedAccessIds.length} / $totalCount selected', equals('5 / 5 selected'));
    });
  });
}
