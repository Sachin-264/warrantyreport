import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:warrantyreport/Report/Filter/TopSection.dart'; // Add this for date formatting

class FilterApiService {
  static const String baseUrl = 'http://localhost/allWarrantyGetAPI.php';
  static const String postUrl = 'http://localhost/addWarratnty.php';

  // Helper function to format dates to "DD-MMM-YYYY"
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MMM-yyyy').format(date); // e.g., "19-Mar-2025"
    } catch (e) {
      log('Date parsing error: $e');
      return dateStr; // Return original string if parsing fails
    }
  }

  static Future<List<Map<String, String>>> fetchSlipNo() async {
    final response = await http.get(Uri.parse('$baseUrl?type=SlipNo'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      log('Slip Numbers: $jsonResponse');
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
      log('Headquarter: $jsonResponse');
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

  static Future<List<Map<String, String>>> fetchBillNumbers(
      String customerId) async {
    final response = await http
        .get(Uri.parse('$baseUrl?type=BillNo&customerID=$customerId'));
    log('Bill number: $response');
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
            'amcStartDate': formatDate(item['AMCStartDate']?.toString()), // Format date
            'amcEndDate': formatDate(item['AMCEndDate']?.toString()),     // Format date
            'installationAddress': item['InstallationAddress']?.toString() ?? '',
          }).toList();
        } else {
          throw Exception('No item details found');
        }
      } else {
        throw Exception('Failed to load item details');
      }
    } catch (e) {
      log('Item Details fetch error: $e', name: 'WarrantyService');
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

    // Prepare the request body with formatted dates
    final Map<String, dynamic> requestBody = {
      'firstArray': (mediumSectionData['items'] as List<dynamic>?)?.map((item) {
        int currentSNo = item['SNo'] ?? 0;
        return {
          'SNo': currentSNo,
          'IsEntryType': item['IsEntryType'] ?? '',
          'BillNo':topSectionData['BillNo'] ?? '',
          'BillDate': topSectionData['BillDate'] ?? '',
          'InvoiceRecNo': topSectionData['InvoiceRecNo'] ?? '',
          'ItemNo': item['ItemNo'] ?? '',
          'MCNo': item['MCNo'] ?? '',
          'HSNCode': item['HSNCode'] ?? '',
          'Qty': item['Qty'] ?? '',
          'AMCStartDate': formatDate(item['AMCStartDate'] ?? ''), // Format date
          'AMCEndDate': formatDate(item['AMCEndDate'] ?? ''),     // Format date
          'WithSpareParts': item['WithSpareParts'] ?? '',
          'InstallationAddress': item['InstallationAddress'] ?? '',
          'ItemRemarks': item['itemRemarks'] ?? '',
        };
      }).toList() ?? [],

      'secondArray': (mediumSectionData['items'] as List<dynamic>?)
          ?.expand((item) {
        int sno = item['SNo'] ?? 0;
        return (item['serviceDates'] as List<dynamic>?)?.map((date) {
          return {
            'SNo': sno,
            'SNo1': sno1Counter++,
            'TentativeServiceDate': formatDate(date.toString()), // Format date
          };
        }) ?? [];
      }).toList() ?? [],
      'UserCode': double.tryParse(topSectionData['userCode'] ?? '1.0'),
      'CompanyCode': double.tryParse(topSectionData['companyCode'] ?? '101'),
      'RecNo': double.tryParse(topSectionData['recNo'] ?? '1.0'),
      'EntryDate': formatDate(topSectionData['entryDate'] ?? ''), // Format date
      'SlipNo': double.tryParse(topSectionData['slipNo'] ?? '1.0'),
      'HQCode': double.tryParse(topSectionData['hqCode'] ?? '1.0'),
      'AccountCode': topSectionData['accountCode'] ?? '1.0',
      'Remarks': bottomSectionData['remarks'] ?? '',
    };

    print('Request Body: ${json.encode(requestBody)}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to save data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error sending data: $e');
    }
  }
}