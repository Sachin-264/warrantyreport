import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FilterApiService {
  static const String baseUrl = 'http://localhost/allWarrantyGetAPI.php';
  static const String postUrl = 'http://localhost/addWarratnty.php';
  static const String loadWarrantyUrl = 'http://localhost/sp_LoadWarrantyAMCMaster.php';

  // Helper function to format dates to "DD-MMM-YYYY"
  static String formatDate(dynamic date) {
    if (date == null) {
      return '';
    }
    if (date is! String) {
      return date.toString();
    }
    try {
      // Check if the date is in the format "yyyy-MM-dd HH:mm:ss.SSS"
      if (date.contains(' ')) {
        final apiDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
        final parsedDate = apiDateFormat.parse(date);
        final desiredFormat = DateFormat('dd-MMM-yyyy');
        return desiredFormat.format(parsedDate);
      } else {
        // Handle other date formats if necessary
        final apiDateFormat = DateFormat('dd-MMM-yyyy');
        final parsedDate = apiDateFormat.parseLoose(date);
        return apiDateFormat.format(parsedDate);
      }
    } catch (e) {
      return date; // Return the original date if parsing fails
    }
  }

  static Future<List<Map<String, String>>> fetchSlipNo() async {
    final response = await http.get(Uri.parse('$baseUrl?type=SlipNo'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse.isNotEmpty) {
        return [
          {'NextCode': jsonResponse[0]['NextCode'] as String}
        ];
      } else {
        throw Exception('No slip number found');
      }
    } else {
      throw Exception('Failed to load slip numbers');
    }
  }

  static Future<List<Map<String, String>>> fetchHeadquarters() async {
    final response = await http.get(Uri.parse('$baseUrl?type=HeadQuarter'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);

      return jsonResponse.map((item) {
        return {
          'id': item['FieldID'].toString(),
          'name': item['FieldName'].toString(),
        };
      }).toList();
    } else {
      throw Exception('Failed to load headquarters');
    }
  }

  static Future<List<Map<String, String>>> fetchCustomers() async {
    final response = await http.get(Uri.parse('$baseUrl?type=CustomerName'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) {
        return {
          'id': item['FieldID'].toString(),
          'name': item['FieldName'].toString(),
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch customers');
    }
  }

  static Future<List<Map<String, String>>> fetchBillNumbers(String customerId) async {
    final response = await http.get(Uri.parse('$baseUrl?type=BillNo&customerID=$customerId'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((item) {
        return {
          'id': item['FieldID'].toString(),
          'name': item['FieldName'].toString(),
          'BillDate': item['InvoiceDate'].toString(),
        };
      }).toList();
    } else {
      throw Exception('Failed to load bill numbers');
    }
  }

  static Future<List<Map<String, dynamic>>> getItemDetails(String invoiceId) async {
    try {
      final url = Uri.parse('$baseUrl?type=ItemName&InvoiceId=$invoiceId');
      final response = await http.get(url);
      print('Api url : $url');

      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        if (rawData.isNotEmpty) {
          return rawData.map((item) => {
            'id': item['FieldID']?.toString() ?? '',
            'name': item['FieldName']?.toString() ?? '',
            'hsnCode': item['HSNCode']?.toString() ?? '',
            'mcNo': item['MCNo']?.toString() ?? '',
            'itemRemarks': item['ItemRemarks']?.toString() ?? '',
            'withSpareParts': item['WithSpareParts']?.toString() ?? '',
            'amcStartDate': formatDate(item['AMCStartDate']?.toString()),
            'amcEndDate': formatDate(item['AMCEndDate']?.toString()),
            'installationAddress': item['InstallationAddress']?.toString() ?? '',
          }).toList();
        } else {
          throw Exception('No item details found');
        }
      } else {
        throw Exception('Failed to load item details');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> saveWarrantyData({
    required Map<String, String> topSectionData,
    required Map<String, dynamic> mediumSectionData,
    required Map<String, String> bottomSectionData,
  }) async {
    final url = Uri.parse('$postUrl');

    int sno1Counter = 1;

    final Map<String, dynamic> requestBody = {
      'firstArray': (mediumSectionData['items'] as List<dynamic>?)?.map((item) {
        int currentSNo = item['SNo'] ?? 0;
        return {
          'SNo': currentSNo,
          'IsEntryType': item['IsEntryType'] ?? '',
          'BillNo': topSectionData['BillNo'] ?? '',
          'BillDate': topSectionData['BillDate'] ?? '',
          'InvoiceRecNo': topSectionData['InvoiceRecNo'] ?? '',
          'ItemNo': item['ItemNo'] ?? '',
          'MCNo': item['MCNo'] ?? '',
          'HSNCode': item['HSNCode'] ?? '',
          'Qty': item['Qty'] ?? '',
          'AMCStartDate': formatDate(item['AMCStartDate'] ?? ''),
          'AMCEndDate': formatDate(item['AMCEndDate'] ?? ''),
          'WithSpareParts': item['WithSpareParts'] ?? '',
          'InstallationAddress': item['InstallationAddress'] ?? '',
          'ItemRemarks': item['ItemRemarks'] ?? '',
        };
      }).toList() ?? [],

      'secondArray': (mediumSectionData['items'] as List<dynamic>?)
          ?.expand((item) {
        int sno = item['SNo'] ?? 0;
        return (item['serviceDates'] as List<dynamic>?)?.map((date) {
          return {
            'SNo': sno,
            'SNo1': sno1Counter++,
            'TentativeServiceDate': formatDate(date.toString()),
          };
        }) ?? [];
      }).toList() ?? [],
      'UserCode': double.tryParse(topSectionData['userCode'] ?? '1.0'),
      'CompanyCode': double.tryParse(topSectionData['companyCode'] ?? '101'),
      'RecNo': double.tryParse(topSectionData['recNo'] ?? '1.0'),
      'EntryDate': formatDate(topSectionData['entryDate'] ?? ''),
      'SlipNo': double.tryParse(topSectionData['slipNo'] ?? '1.0'),
      'HQCode': double.tryParse(topSectionData['hqCode'] ?? '1.0'),
      'AccountCode': topSectionData['accountCode'] ?? '1.0',
      'Remarks': bottomSectionData['remarks'] ?? '',
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Log only the response body
      log('Save Warranty Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending data: $e');
    }
  }

  static Future<Map<String, dynamic>> editSaveWarrantyData({
    required Map<String, dynamic> topSectionData,
    required Map<String, dynamic> mediumSectionData,
    required Map<String, String> bottomSectionData,
  }) async {
    final url = Uri.parse('$postUrl');

    int sno1Counter = 1;

    final Map<String, dynamic> requestBody = {
      'firstArray': (mediumSectionData['items'] as List<dynamic>?)?.map((item) {
        int currentSNo = item['SNo'] is int ? item['SNo'] : int.tryParse(item['SNo'].toString()) ?? 0;
        return {
          'SNo': currentSNo,
          'IsEntryType': item['IsEntryType']?.toString() ?? '',
          'BillNo': topSectionData['BillNo']?.toString() ?? '',
          'BillDate': topSectionData['BillDate']?.toString() ?? '',
          'InvoiceRecNo': topSectionData['InvoiceRecNo']?.toString() ?? '',
          'ItemNo': item['ItemNo']?.toString() ?? '',
          'MCNo': item['MCNo']?.toString() ?? '',
          'HSNCode': item['HSNCode']?.toString() ?? '',
          'Qty': item['Qty']?.toString() ?? '',
          'AMCStartDate': formatDate(item['AMCStartDate'] ?? ''),
          'AMCEndDate': formatDate(item['AMCEndDate'] ?? ''),
          'WithSpareParts': item['WithSpareParts']?.toString() ?? '',
          'InstallationAddress': item['InstallationAddress']?.toString() ?? '',
          'ItemRemarks': item['ItemRemarks']?.toString() ?? '',
        };
      }).toList() ?? [],

      'secondArray': (mediumSectionData['items'] as List<dynamic>?)
          ?.expand((item) {
        int sno = item['SNo'] is int ? item['SNo'] : int.tryParse(item['SNo'].toString()) ?? 0;
        return (item['serviceDates'] as List<dynamic>?)?.map((date) {
          return {
            'SNo': sno,
            'SNo1': sno1Counter++,
            'TentativeServiceDate': formatDate(date.toString()),
          };
        }) ?? [];
      }).toList() ?? [],

      'UserCode': topSectionData['userCode'] is num
          ? topSectionData['userCode']
          : double.tryParse(topSectionData['userCode']?.toString() ?? '1.0') ?? 1.0,
      'CompanyCode': topSectionData['companyCode'] is num
          ? topSectionData['companyCode']
          : double.tryParse(topSectionData['companyCode']?.toString() ?? '101') ?? 101.0,
      'RecNo': topSectionData['recNo'] is num
          ? topSectionData['recNo']
          : double.tryParse(topSectionData['recNo']?.toString() ?? '1.0') ?? 1.0,
      'EntryDate': formatDate(topSectionData['entryDate'] ?? ''),
      'SlipNo': topSectionData['slipNo'] is num
          ? topSectionData['slipNo']
          : double.tryParse(topSectionData['slipNo']?.toString() ?? '1.0') ?? 1.0,
      'HQCode': topSectionData['hqCode'] is num
          ? topSectionData['hqCode']
          : double.tryParse(topSectionData['hqCode']?.toString() ?? '1.0') ?? 1.0,
      'AccountCode': topSectionData['accountCode']?.toString() ?? '1.0',
      'Remarks': bottomSectionData['remarks'] ?? '',
    };

    try {
      log('Request Body: ${json.encode(requestBody)}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Log only the response body
      log('Edit Warranty Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending data: $e');
    }
  }

  static Future<Map<String, dynamic>> loadWarrantyData({
    required String userCode,
    required String companyCode,
    required String recNo,
  }) async {
    final url = Uri.parse('$loadWarrantyUrl?UserCode=$userCode&CompanyCode=$companyCode&RecNo=$recNo');
    log('Loading warranty data from: $url');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        if (jsonData.length >= 3) {
          final topSection = Map<String, dynamic>.from(jsonData[0][0]);
          log('Raw Top Section: $topSection');
          topSection['ComplaintDate'] = formatDate(topSection['ComplaintDate']);

          final items = (jsonData[1] as List<dynamic>).map((item) {
            final itemMap = Map<String, dynamic>.from(item);
            itemMap['BillDate'] = formatDate(itemMap['BillDate']);
            itemMap['AMCStartDate'] = formatDate(itemMap['AMCStartDate']);
            itemMap['AMCEndDate'] = formatDate(itemMap['AMCEndDate']);
            return itemMap;
          }).toList();

          final serviceDates = (jsonData[2] as List<dynamic>).map((date) {
            final dateMap = Map<String, dynamic>.from(date);
            dateMap['TentativeServiceDate'] = formatDate(dateMap['TentativeServiceDate']);
            return dateMap;
          }).toList();

          log('Final Parsed Data: Top Section - $topSection, Items - ${items.length}, Service Dates - ${serviceDates.length}');
          return {
            'topSection': topSection,
            'items': items,
            'serviceDates': serviceDates,
          };
        } else {
          log('Error: Incomplete warranty data received');
          throw Exception('Incomplete warranty data received');
        }
      } else {
        log('Error: Failed to load warranty data - Status Code: ${response.statusCode}');
        throw Exception('Failed to load warranty data: ${response.statusCode}');
      }
    } catch (e) {
      log('Exception: Error loading warranty data - $e');
      throw Exception('Error loading warranty data: $e');
    }
  }
}