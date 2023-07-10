import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getProductInfo(String barcode) async {
  const apiKey = 'ruru7rbar09opsp0ckku7iq2v2d0ak';
  final url = Uri.parse('https://api.barcodelookup.com/v3/products?barcode=$barcode&formatted=y&key=$apiKey');
  var title = '';

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final decodedBody = json.decode(responseBody);

      if (decodedBody['products'] != null && decodedBody['products'].length > 0) {
        final product = decodedBody['products'][0];
        final barcodeNumber = product['barcode_number'];
        title = product['title'];

        print('Barcode Number: $barcodeNumber');
      } else {
        print('Product not found.');
      }
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('An error occurred: $e');
  }

  return title;

  
}

void main() {
  getProductInfo('0811620021951');
}