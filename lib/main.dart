import 'package:camera/camera.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/home.dart';
import 'package:flutter/material.dart';

void main() async {
  setupServices();

  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

  runApp(MyApp(frontCamera: frontCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription frontCamera;

  const MyApp({Key? key, required this.frontCamera}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(camera: frontCamera,),
    );
  }
}
