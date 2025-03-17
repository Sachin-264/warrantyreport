import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class FilterApiService {
  static const String baseUrl = 'http://localhost/allWarrantyGetAPI.php';
  static const String postUrl = 'http://localhost/addWarratnty.php';

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
        };
      }).toList();
    } else {
      throw Exception('Failed to load bill numbers');
    }
  }

  // itemDetailapi

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
            'amcStartDate': item['AMCStartDate']?.toString() ?? '',
            'amcEndDate': item['AMCEndDate']?.toString() ?? '',
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

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      'firstArray': (mediumSectionData['items'] as List<dynamic>?)?.map((item) {
        int currentSNo = item['SNo'] ?? 0;
        return {
          'SNo1': sno1Counter++,
          'SNo': currentSNo,
          'IsEntryType': item['IsEntryType'] ?? '',
          'BillNo': item['BillNo'] ?? '',
          'BillDate': item['BillDate'] ?? '',
          'InvoiceRecNo': topSectionData['InvoiceRecNo'] ?? '',
          'ItemNo': item['ItemNo'] ?? '',
          'MCNo': item['MCNo'] ?? '',
          'HSNCode': item['HSNCode'] ?? '',
          'Qty': item['Qty'] ?? '',
          'AMCStartDate': item['AMCStartDate'] ?? '',
          'AMCEndDate': item['AMCEndDate'] ?? '',
          'WithSpareParts': item['WithSpareParts'] ?? '',
          'InstallationAddress': item['InstallationAddress'] ?? '',
          'ItemRemarks': bottomSectionData['remarks'] ?? '',
        };
      }).toList() ?? [],

      'secondArray': (mediumSectionData['items'] as List<dynamic>?)
          ?.expand((item) {
        int sno = item['SNo'] ?? 0;
        return (item['serviceDates'] as List<dynamic>?)?.map((date) {
          return {
            'SNo': sno,
            'ServiceDate': date.toString(),
          };
        }) ?? [];
      }).toList() ?? [],
      'UserCode': double.tryParse(topSectionData['userCode'] ?? '1.0'),
      'CompanyCode': double.tryParse(topSectionData['companyCode'] ?? '1.0'),
      'RecNo': double.tryParse(topSectionData['recNo'] ?? '1.0'),
      'EntryDate': topSectionData['entryDate'] ?? '',
      'SlipNo': double.tryParse(topSectionData['slipNo'] ?? '1.0'),
      'HQCode': double.tryParse(topSectionData['hqCode'] ?? '1.0'),
      'AccountCode': double.tryParse(topSectionData['accountCode'] ?? '1.0'),
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

