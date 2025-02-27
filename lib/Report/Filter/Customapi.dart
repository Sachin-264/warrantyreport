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

  static Future<List<Map<String, dynamic>>> getItemDetails(
      String invoiceId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl?type=ItemName&InvoiceId=$invoiceId'));
      if (response.statusCode == 200) {
        final List<dynamic> rawData = json.decode(response.body);
        if (rawData.isNotEmpty) {
          return [
            {
              'id': rawData[0]['FieldID']?.toString() ?? '',
              'name': rawData[0]['FieldName']?.toString() ?? '',
              'hsnCode': rawData[0]['HSNCode']?.toString() ?? '',
              'mcNo': rawData[0]['MCNo']?.toString() ?? '',
              'itemRemarks': rawData[0]['itemRemarks']?.toString() ?? '',
              'withSpareParts': rawData[0]['WithSpareParts']?.toString() ?? '',
              'amcStartDate': rawData[0]['AMCStartDate']?.toString() ?? '',
              'amcEndDate': rawData[0]['AMCEndDate']?.toString() ?? '',
              'installationAddress':
              rawData[0]['installationAddress']?.toString() ?? '',
            }
          ];
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
    required List<DateTime> serviceDates,
  }) async {
    // Ensure this is always a POST request
    final url = Uri.parse('http://localhost/addWarratnty.php'); // Use your machine's IP address

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      'firstArray': (mediumSectionData['items'] as List<dynamic>?)?.map((item) {
        return {
          'itemName': item['itemName'] ?? '',
          'mcNo': item['mcNo'] ?? '',
          'itemRemarks': item['itemRemarks'] ?? '',
          'qty': item['qty'] ?? '',
          'sacHsn': item['sacHsn'] ?? '',
          'warrantyFrom': item['warrantyFrom'] ?? '',
          'billNo': item['billNo'] ?? '',
          'billDate': item['billDate'] ?? '',
          'installationAddress': item['installationAddress'] ?? '',
          'toDate': item['toDate'] ?? '',
          'fromDate':item['fromDate']??'',


        };
      }).toList() ?? [],
      // Keep serviceDates linked to item index
      'secondArray': (mediumSectionData['items'] as List<dynamic>?)
          ?.asMap()
          .entries
          .expand((entry) {
        int itemIndex = entry.key; // Get the index of the item
        var item = entry.value;
        return (item['serviceDates'] as List<dynamic>?)
            ?.map((date) => {'itemIndex': itemIndex, 'date': date.toString()}) ??
            [];
      })
          .toList() ?? [],

      'UserCode': double.tryParse(topSectionData['userCode'] ?? '1.0'),
      'CompanyCode': double.tryParse(topSectionData['companyCode'] ?? '1.0'),
      'RecNo': double.tryParse(topSectionData['recNo'] ?? '1.0'),
      'EntryDate': topSectionData['entryDate'] ?? '',
      'SlipNo': double.tryParse(topSectionData['slipNo'] ?? '1.0'),
      'HQCode': double.tryParse(topSectionData['hqCode'] ?? '1.0'),
      'AccountCode': double.tryParse(topSectionData['accountCode'] ?? '1.0'),
      'Remarks': bottomSectionData['remarks'] ?? '',
    };

    // Print the request body for debugging
    print('Request Body: ${json.encode(requestBody)}');

    try {
      // Enforce POST request
      final response = await http.post(
        url,
        // headers: {
        //   'Content-Type': 'application/json',
        //   'Access-Control-Allow-Origin': '*',
        //   'Access-Control-Allow-Methods': 'POST, OPTIONS',
        //   'Access-Control-Allow-Headers': 'Content-Type',
        // },
        body: json.encode(requestBody),
      );

      // Print the response status code and body
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to save data: ${response.statusCode}');
      }
    } catch (e) {
      // Print the error
      print('Error Type: ${e.runtimeType}');
      print('Error Message: ${e.toString()}');
      throw Exception('Error sending data: $e');
    }
  }
}


