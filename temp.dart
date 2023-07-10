import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:price_comparison/barcode_lookup.dart';
import 'package:price_comparison/google_results.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CameraDescription>? _cameras;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } else {
      debugPrint("No cameras available. Running on emulator?");
    }
  }

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      var prodTitle = await getProductInfo(result.rawContent);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodInformationPage(barcodeResult: result.rawContent, title: prodTitle),
        ),
      );
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text("Similar Prices")),
        body: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
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
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanBarcode,
        child: const Icon(Icons.qr_code),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class FoodInformationPage extends StatelessWidget {
  final String barcodeResult;
  final String title;

  const FoodInformationPage({Key? key, required this.barcodeResult, required this.title}) : super(key: key);

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

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

                      return GestureDetector(
                        child: Card(
                          child: ListTile(
                            leading: Image.network(imageUrl),
                            title: Text(title),
                            subtitle: Text(source + ": " + price),
                            trailing: CupertinoButton(
                              onPressed: () {
                                launchUrl(productUrl);
                                print(productUrl);
                              },
                              child: const Text('Buy'),
                            ),
                          ),
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
