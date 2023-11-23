import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'response_list.dart';


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          "max_tokens": 2500,
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

  @override
   initState() {
    // TODO: implement initState
    super.initState();
    InitializeSpeechToText();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          speakResponse(chatGPTResponse);
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset("images/sound.png"),
        ),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Colors.purpleAccent.shade100,
            Colors.deepPurple,
          ])),
        ),
        title: Image.asset(
          "images/logo.png",
          width: 140,
        ),
        titleSpacing: 10,
        elevation: 2,
        actions: [
          //chat
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 4),
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
                  color: Colors.white,
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

          //image
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,

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
                            , size: 300),
                      )
                      : Image.asset(
                    'images/assistant_icon.png',
                    height: 300,
                    width: 300,
                  ),
                ),
              ),

              const SizedBox(
                height: 50,
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
              Text(chatGPTResponse),

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
    );
  }
}
