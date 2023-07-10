import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<dynamic>> getShoppingResults(String title) async {
  // Set the query parameters
  Map<String, String> params = {
    "api_key": "c7b106022c885417564cc937c5eb169acfb8b0570b84b9112e8cc6911e8bad3e",
    "engine": "google",
    "q": title,
    "tbm": "shop",
  };

  // Build the request URL
  Uri uri = Uri.https("serpapi.com", "/search", params);

  // Send the request to the API
  http.Response response = await http.get(uri);

  // Parse the JSON response
  Map<String, dynamic> responseData = jsonDecode(response.body);

  // Get the shopping results from the response
  List<dynamic> shoppingResults = responseData['shopping_results'] ?? [];

  return shoppingResults;
}

void main() async {
  // Call the function to get the shopping results
  List<dynamic> shoppingResults = await getShoppingResults("Core Power Protein by Fairlife, 26G Chocolate Protein Shake - 14 Oza");

  // Print the shopping results
  print(jsonEncode(shoppingResults));
}
