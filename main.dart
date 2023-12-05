import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:math_expressions/math_expressions.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'HortSens AI Assistant',
      home: ChatPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];
  late AnimationController _controller;
  late Animation<Alignment> _animation;
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _animation.value,
                    end: const Alignment(1.0, 1.0),
                    colors: [Colors.blue[800]!, Colors.pink[800]!],
                  ),
                ),
              );
            },
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final message = _messages[index];
                    final isUser = index % 2 == 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Opacity(
                              opacity: 0.8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.lightBlue[800]
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(isUser ? 20 : 0),
                                    topRight: Radius.circular(isUser ? 0 : 20),
                                    bottomLeft: const Radius.circular(20),
                                    bottomRight: const Radius.circular(20),
                                  ),
                                ),
                                child: Text(message,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      color:
                                          isUser ? Colors.white : Colors.black,
                                      fontSize: 16,
                                    )),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Saisir un message...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: _handleSendMessage,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: _handleMicButtonPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMicButtonPressed() {
    // Handle speech recognition here
    // You can use a speech recognition package like speech_to_text or speech_recognition
    // to implement speech recognition functionality.
  }

  double evalExpression(String expression) {
    Parser p = Parser();
    Expression exp = p.parse(expression);
    ContextModel cm = ContextModel();
    return exp.evaluate(EvaluationType.REAL, cm);
  }

  void _handleSendMessage() async {
    final message = _textController.text.trim();
    _textController.clear();
    if (message.isEmpty) {
      return;
    }

    String response = '';

    if (message.toLowerCase().contains('search')) {
      String searchQuery =
          message.replaceAll(RegExp('search|search for'), '').trim();
      if (searchQuery.isNotEmpty) {
        // Search using DuckDuckGo API
        String searchUrl =
            'https://api.duckduckgo.com/?q=${Uri.encodeComponent(searchQuery)}&format=json&lang=en';
        var searchResponse = await http.get(Uri.parse(searchUrl));

        if (searchResponse.statusCode == 200) {
          var data = jsonDecode(searchResponse.body);
          var abstractText = data['AbstractText'];
          if (abstractText.isNotEmpty) {
            response = abstractText;
          } else {
            response = 'Sorry, no results found for your search.';
          }
        } else {
          response = 'Sorry, an error occurred while searching for the answer.';
        }
      }
    } else if (message.toLowerCase().startsWith('weather')) {
      // Open a weather website
      // ignore: deprecated_member_use
      launch('https://www.accuweather.com/');
    } else if (message.toLowerCase().startsWith('who are you?') ||
        message.toLowerCase().startsWith('what are you?')) {
      response =
          'I am HortSens Chat NLP, a language model, a vocal assistant, and a search assistant, created by HortSens, I can do a variety of tasks, from chatting with you, to generating text, codes, and translating languages, and opening productive apps, and playing music, how can I help you today?';
    } else if (message.toLowerCase().contains('open phone app') ||
        message.toLowerCase().contains('launch phone app') ||
        message.toLowerCase().contains('start phone app')) {
      // Open the phone app and respond with a message
      response = 'Opening the phone app';
      // ignore: deprecated_member_use
      await launch("tel://");
    } else if (message.toLowerCase().contains('open spotify')) {
      // Open Spotify app
      response = 'Opening Spotify';
      // ignore: deprecated_member_use
      await launch('spotify:');
    } else if (message.toLowerCase().startsWith('calculate')) {
      // Evaluate mathematical expression
      String mathExpression = message.substring(9).trim();
      try {
        Parser p = Parser();
        Expression exp = p.parse(mathExpression);
        ContextModel cm = ContextModel();
        double eval = exp.evaluate(EvaluationType.REAL, cm);
        response = eval.toString();
      } catch (e) {
        response = 'Sorry, I could not evaluate that expression.';
      }
    } else if (message.toLowerCase().startsWith('solve')) {
      // Solve equation using Wolfram Alpha API
      String equation = message.substring(5).trim();
      if (equation.isNotEmpty) {
        // Query using Wolfram Alpha API
        String wolframUrl =
            'https://api.wolframalpha.com/v2/query?input=${Uri.encodeComponent(equation)}&appid=KH8L8U-L6YQEY82WH&output=json';
        var wolframResponse = await http.get(Uri.parse(wolframUrl));

        if (wolframResponse.statusCode == 200) {
          var data = jsonDecode(wolframResponse.body);
          var pods = data['queryresult']['pods'];
          var solution = '';

          // Find the pod with the primary solution
          for (var pod in pods) {
            if (pod['primary'] == true) {
              var subpods = pod['subpods'];
              if (subpods.isNotEmpty) {
                solution = subpods[0]['plaintext'];
              }
              break;
            }
          }

          if (solution.isNotEmpty) {
            response = solution;
          } else {
            response = 'Sorry, no solution found for your equation.';
          }
        } else {
          response = 'Sorry, an error occurred while solving the equation.';
        }
      }
    } else if (message.toLowerCase().startsWith('get news')) {
      // News retrieval
      String topic = message.substring(9).trim();
      if (topic.isNotEmpty) {
        response = await _fetchNews(topic);
      } else {
        response = 'Please provide a topic to search for news.';
      }
    } else {
      // Use Microsoft's DialoGPT API for general chatbot responses
      const apiKey = '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';
      var gptResponse = await http.post(
        Uri.parse(
            'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode({
          'inputs': message,
          'parameters': {
            'max_new_tokens': 100,
            'temperature': 0.0,
          },
        }),
      );

      if (gptResponse.statusCode == 200) {
        var data = jsonDecode(gptResponse.body);
        response = data['generated_text'].trim();
      } else {
        response = "Sorry, an error occurred while searching for the answer.";
      }
    }

    _messages.insert(0, message);
    _messages.insert(0, response);

    try {
      await flutterTts.stop();

      await flutterTts.setLanguage('en-GB');
      await flutterTts.setPitch(1.3);
      await flutterTts.setSpeechRate(1.0);
      await flutterTts.setVoice({
        'name': 'en-gb-x-rjs-network',
        'locale': 'en-GB',
      });

      await flutterTts.speak(response);
    } catch (e) {
      print("Error: $e");
    }

    setState(() {});
  }

  Future<String> _fetchNews(String topic) async {
    // Fetch news articles using an API (e.g., News API, GNews API, etc.)
    // and return a formatted response
    return 'News about $topic';
  }
}
