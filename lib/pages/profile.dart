import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../screens/home_screen.dart';
import '../screens/response_list.dart';
import 'home.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class Profile extends StatefulWidget {
   Profile(this.username, {Key? key, required this.imagePath, required this.camera})
      : super(key: key);
  final String username;
  final String imagePath;
  final CameraDescription camera;


  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  // late CameraDescription frontCamera;


  var _controller;
  var  _faceDetector;
  var  isLoggedIn;
  var referenceImagePath; // Path to the reference image



  @override
  void initState()  {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium, enableAudio: false);
    _faceDetector = GoogleMlKit.vision.faceDetector();
    isLoggedIn = true; // Set to true initially, assuming the user is logged in.

    _initializeCamera();

    super.initState();
    InitializeSpeechToText();


  }

  Future<void> _initializeCamera() async {
    await _controller.initialize();
    if (mounted) {
      setState(() {});
    }

    // Take and store the reference picture when the app is built
    referenceImagePath = await _controller.takePicture();

    // Set up a timer to take pictures every 60 seconds
    Timer.periodic(Duration(seconds: 45), (timer) async {
      if (isLoggedIn) {
        // Only capture and process images if the user is logged in
        var imageFile = await _controller.takePicture();
        _compareFace(imageFile.path);
      }
    });
  }

  Future<void> _compareFace(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final List<Face> faces = await _faceDetector.processImage(inputImage);

    final double similarityThreshold = 0.9; // Adjust as needed

    if (faces.isEmpty){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(camera: widget.camera,)),
      );

      setState(() {
        isLoggedIn = false;
      });
    }
    if (faces.isNotEmpty) {
      // Compare faces with the reference image
      final double similarity = await _compareImages(imagePath, referenceImagePath);

      if (similarity < similarityThreshold) {
        // Logout the user if faces don't match
        print("Face does not match. Logging out...");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(camera: widget.camera,)),
        );
        setState(() {
          isLoggedIn = false;
        });
      }
    }
  }

  Future<double> _compareImages(String imagePath1, String imagePath2) async {
    final hash1 = await _calculateImageHash(imagePath1);
    final hash2 = await _calculateImageHash(imagePath2);

    final double similarity = _calculateHashSimilarity(hash1, hash2);
    return similarity;
  }

  Future<String> _calculateImageHash(String imagePath) async {
    final File imageFile = File(imagePath);
    final List<int> bytes = await imageFile.readAsBytes();
    final img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;
    final img.Image resizedImage = img.copyResize(image, width: 8, height: 8);
    final List<int> pixels = resizedImage.getBytes();

    int totalColor = 0;
    for (int pixel in pixels) {
      totalColor += pixel;
    }

    final int averageColor = (totalColor / pixels.length).round();
    final String hash = pixels.map((int pixel) => (pixel >= averageColor) ? '1' : '0').join();

    return hash;
  }

  double _calculateHashSimilarity(String hash1, String hash2) {
    int differenceCount = 0;
    for (int i = 0; i < hash1.length; i++) {
      if (hash1[i] != hash2[i]) {
        differenceCount++;
      }
    }

    return 1 - (differenceCount / hash1.length);
  }















  TextEditingController userInputTextEditingController =
  TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioText = '';
  bool isLoading = false;
  String chatGPTResponse = "";
  final apiKey = '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';
  final FlutterTts flutterTts = FlutterTts();
  //String chatGPTResponse = "";

  Future<void> sendToChatGPT(String inputText) async {

    setState(() => chatGPTResponse = 'Loading...');

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey'
      },
      body: jsonEncode(
        {
          "model": "text-davinci-003",
          "prompt": inputText,
          "max_tokens": 4000,
          "temperature": 0,
          "top_p": 1,
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final completion = data['choices'][0]['text'];
      setState(() {
        chatGPTResponse = completion;
      });
    }
else{
  print(response.statusCode);
    }
    final prefs = await SharedPreferences.getInstance();
    final responses = prefs.getStringList('responses') ?? [];
    responses.add(chatGPTResponse);
    await prefs.setStringList('responses', responses);

  }


  Future<void> speakResponse(String text) async {
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }




  void InitializeSpeechToText() async{
    await speechToTextInstance.initialize();

    setState(() {

    });
  }



  void startListeningNow() async{
    FocusScope.of(context).unfocus();

    await speechToTextInstance.listen(onResult: OnSpeechToTextResult);
    setState(() {


    });
  }

  void stopListening()async{
    await speechToTextInstance.stop();
    setState(() {

    });
  }
  void OnSpeechToTextResult(SpeechRecognitionResult recognitionResult)
  {
    recordedAudioText =   recognitionResult.recognizedWords;
    userInputTextEditingController.text = recordedAudioText;
    // print("speech result:");
    // print(recordedAudioText);
  }

  // final String githubURL =
  @override
  Widget build(BuildContext context) {
    // Timer.periodic(Duration(seconds: 60), (timer) async {
    //   if (isLoggedIn) {
    //     // Only capture and process images if the user is logged in
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(builder: (context) => MyHomePage(camera: widget.camera,)),
    //     );
    //   }
    // });
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     speakResponse(chatGPTResponse);
      //   },
      //   child: Padding(
      //     padding: const EdgeInsets.all(4.0),
      //     child: Image.asset("images/sound.png"),
      //   ),
      // ),
      appBar: null,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CameraPreview(_controller),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                     Colors.purpleAccent.shade100,
                    Colors.deepPurple,]),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(widget.imagePath)),
                    ),
                  ),
                  margin: EdgeInsets.all(20),
                  width: 50,
                  height: 50,
                ),
                Text(
                  'Hi ' + widget.username.toUpperCase() + '!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 2, top: 2),
                  child: InkWell(
                    onTap: () {},
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResponseListPage(),
                          ),
                        );
                      },
                      child: const Icon(

                        Icons.chat,
                        size: 40,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                ),


                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 4),
                  child: InkWell(
                    onTap: () {},
                    child: const Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
            Container(
              child:
              Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  children: [
                    //image
                    Center(
                      child: InkWell(
                        onTap: () {
                          speechToTextInstance.isListening ? stopListening() : startListeningNow();
                        },
                        child:speechToTextInstance.isListening ?
                        Center(
                          child: LoadingAnimationWidget.beat(color: speechToTextInstance.isListening ?
                          Colors.deepPurple: isLoading?
                          Colors.deepPurple[400]! :Colors.deepPurple[200]!
                              , size: 250),
                        )
                            : Image.asset(
                          'images/assistant_icon.png',
                          height: 200,
                          width: 200,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    //text field
                    Row(
                      children: [

                        const SizedBox(height: 40,),
                        //text field
                        Expanded(

                          child: Padding(

                            padding: const EdgeInsets.only(left: 4.0),
                            child: TextField(
                              controller: userInputTextEditingController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "How can I help you",
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 10.0,
                        ),

                        //button
                        InkWell(
                          onTap: () {
                            print("I am Emrich");
                          },
                          child: AnimatedContainer(
                            padding: const EdgeInsets.all(15),
                            decoration: const BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: Colors.deepPurpleAccent),
                            duration: const Duration(
                              milliseconds: 1000,
                            ),
                            curve: Curves.bounceInOut,
                            child: GestureDetector(
                              onTap:(){  sendToChatGPT(userInputTextEditingController.text);},
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),

                    SizedBox(height: 20),
                    Text(
                      "FaceNet Response:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    Text(chatGPTResponse, style: TextStyle(
                      color: Colors.deepPurpleAccent

                    ),),

                    //
                    // ElevatedButton(
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => ResponseListPage(),
                    //       ),
                    //     );
                    //   },
                    //   child: Text("View Responses"),
                    // ),
                  ],
                ),
              ),
            ),
            Spacer(),
            Row(
              children : [
              AppButton(
                text: "LOG OUT",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage(camera: widget.camera,)),
                  );
                },
                icon: Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                color: Color(0xFFFF6161),
              ),
                SizedBox(width: 10.0,),
                FloatingActionButton(
                  onPressed: () {
                    speakResponse(chatGPTResponse);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset("images/sound.png"),
                  ),
                ),
    ]
            ),

            SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }



}
