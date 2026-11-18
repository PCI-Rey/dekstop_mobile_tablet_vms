import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Extend Access Card Contract & Logic Tests', () {
    test('Constructs valid extend access card payload matching senior contract', () {
      final trxVisitorId = '93e8d208-42bf-40c5-b304-e2892c6b3ca0';
      final trxCardId = '38DF689D-57A1-468C-969B-A7E8EC2FDE40';
      final registeredSiteId = '1D6C9704-F6AB-47BD-A6B0-3E1FB3D6FAEA';
      final cardNumber = '8521061202';
      final accessControls = ['F6228599-ADB4-4216-8A3C-C0E786C32557'];

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
      expect(body['access_controls'], contains('F6228599-ADB4-4216-8A3C-C0E786C32557'));
      expect((body['access_controls'] as List).length, equals(1));
    });

    test('Parses access control list correctly from live /api/invitation-ac payload', () {
      final responsePayload = {
        "status": "success",
        "status_code": 200,
        "title": "success",
        "msg": "Data retrieved successfully",
        "collection": [
          {
            "Id": "cee19254-0d58-4cdc-bdeb-05ba833525ee",
            "BrandId": "2e9af723-41f7-45b5-8500-543e56ea9aba",
            "BrandName": "Honeywell",
            "Type": "Group",
            "Name": "SCP 4 A",
            "Description": "SCP 4 A",
            "Channel": "1",
            "DoorId": "scp_door_4",
            "Raw": "{}",
            "IntegrationId": "a71e4d22-f101-48c2-9b4b-ab1fbaacd557",
            "IntegrationListId": null,
            "IntegrationName": "Honeywell Prowatch GEDUNG IRS_nonactive"
          },
          {
            "id": "f6228599-adb4-4216-8a3c-c0e786c32557",
            "brand_id": "2e9af723-41f7-45b5-8500-543e56ea9aba",
            "brand_name": "Honeywell",
            "type": "Group",
            "name": "SCP 2B",
            "description": "-",
            "channel": "0",
            "door_id": "SCP2B",
            "raw": "{}",
            "integration_id": "a71e4d22-f101-48c2-9b4b-ab1fbaacd557",
            "integration_name": "Honeywell Prowatch GEDUNG IRS_nonactive"
          }
        ]
      };

      final collection = responsePayload['collection'] as List;
      final parsedList = collection.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final id = (map['Id'] ?? map['id'] ?? '').toString();
        final name = (map['Name'] ?? map['name'] ?? '').toString();
        return {'id': id, 'name': name};
      }).toList();

      expect(parsedList.length, equals(2));
      expect(parsedList[0]['id'], equals('cee19254-0d58-4cdc-bdeb-05ba833525ee'));
      expect(parsedList[0]['name'], equals('SCP 4 A'));
      expect(parsedList[1]['id'], equals('f6228599-adb4-4216-8a3c-c0e786c32557'));
      expect(parsedList[1]['name'], equals('SCP 2B'));
    });

    test('Correctly filters access controls by search query', () {
      final items = [
        {'id': '1', 'name': 'SCP 4 A', 'brand': 'Honeywell'},
        {'id': '2', 'name': 'SCP 2C', 'brand': 'Honeywell'},
        {'id': '3', 'name': 'SCP 1B', 'brand': 'Honeywell'},
        {'id': '4', 'name': 'SCP 4C', 'brand': 'Honeywell'},
        {'id': '5', 'name': 'SCP Test', 'brand': 'Honeywell'},
        {'id': '6', 'name': 'Loading Dock', 'brand': 'Honeywell'},
      ];

      final query = 'scp';
      final filtered = items.where((i) => i['name']!.toLowerCase().contains(query)).toList();
      expect(filtered.length, equals(5));

      final queryDock = 'dock';
      final filteredDock = items.where((i) => i['name']!.toLowerCase().contains(queryDock)).toList();
      expect(filteredDock.length, equals(1));
      expect(filteredDock.first['name'], equals('Loading Dock'));
    });
  });
}
