import 'package:camera/camera.dart'; // Importing the camera package for accessing the device camera
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Importing the Flutter Material library for UI components
import 'package:barcode_scan2/barcode_scan2.dart'; // Importing the barcode_scan2 package for scanning barcodes
import 'package:price_comparison/barcode_lookup.dart'; // Importing a custom package for barcode lookup
import 'package:price_comparison/google_results.dart';
import 'package:url_launcher/url_launcher.dart';


class HomePage extends StatefulWidget { // Defining a stateful widget for the home page
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> { // State class for the home page
  late List<CameraDescription>? _cameras; // Variable to store available camera descriptions
  CameraController? _cameraController; // Variable to control the camera

  @override
  void initState() { // Method called when the state is initialized
    super.initState();
    initializeCamera(); // Initializing the camera
  }

  @override
  void dispose() { // Method called when the state is disposed
    _cameraController?.dispose(); // Disposing the camera controller
    super.dispose();
  }

  Future<void> initializeCamera() async { // Asynchronous method to initialize the camera
    _cameras = await availableCameras(); // Getting available cameras
    if (_cameras != null && _cameras!.isNotEmpty) { // Checking if cameras are available
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high); // Creating a camera controller with the first camera
      await _cameraController!.initialize(); // Initializing the camera controller
      if (mounted) { // Checking if the widget is still mounted
        setState(() {}); // Triggering a rebuild of the widget tree
      }
    } else {
      debugPrint("No cameras available. Running on emulator?"); // Printing a debug message if no cameras are available
      // You can show an error message or provide a fallback behavior here if no cameras are available
    }
  }

  Future<void> scanBarcode() async { // Asynchronous method for scanning barcodes
    try {
      var result = await BarcodeScanner.scan(); // Scanning a barcode and storing the result
      var prodTitle = await getProductInfo(result.rawContent); // Retrieving product information based on the barcode result

      Navigator.push( // Navigating to the food information page
        context,
        MaterialPageRoute(
          builder: (context) => FoodInformationPage(barcodeResult: result.rawContent, title: prodTitle),
        ),
      );
    } catch (e) {
      print('Error: $e'); // Printing an error message if barcode scanning fails
    }
  }

  @override
  Widget build(BuildContext context) { // Building the UI for the home page
    if (_cameraController == null || !_cameraController!.value.isInitialized) { // Checking if the camera is not initialized
      return Scaffold(
        appBar: AppBar(title: const Text("Similar Prices")), // Displaying an app bar with the title "Food Scanner"
        body: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()), // Displaying a loading indicator
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: null,
      body: Stack(
        children: [
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio, // Setting the aspect ratio of the camera preview
              child: CameraPreview(_cameraController!), // Displaying the camera preview
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanBarcode, // Assigning the scanBarcode function to the button's onPressed event
        child: const Icon(Icons.qr_code), // Displaying a QR code icon
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class FoodInformationPage extends StatelessWidget {
  final String barcodeResult;
  final String title;

  const FoodInformationPage({Key? key, required this.barcodeResult, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Similar Products"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: getShoppingResults(title),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error fetching shopping results: ${snapshot.error}');
                } else {
                  List<dynamic>? shoppingResults = snapshot.data;
                  return ListView.builder(
                    itemCount: shoppingResults?.length ?? 0,
                    itemBuilder: (context, index) {

                        var result = shoppingResults![index];
                        var title = result['title'];
                        var price = result['price'];
                        var imageUrl = result['thumbnail'];
                        var source = result['source'];
                        var productUrl = result['link'];

                        print(title);
                        print(price);
                        print(source);

                        return Card(
                            child: ListTile(
                              leading: Image.network(imageUrl),
                              title: Text(title),
                              subtitle: Text(source + ": " + price),
                              trailing: CupertinoButton(
                                onPressed: () {
                                  print(productUrl);
                                  launchUrl(productUrl);
                                },
                                child: const Text('Buy'),
                              )

                            ),
                          );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}