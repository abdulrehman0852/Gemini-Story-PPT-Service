import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:ai_story_illustrator/gemini_services/gemini_image_service.dart';
import 'package:ai_story_illustrator/gemini_services/gemini_text_service.dart';
import 'package:ai_story_illustrator/presentation/presentation_service.dart';
import 'package:ai_story_illustrator/presentation/widgets/presentation_screen.dart';

void main() {
  runApp(const AIStoryIllustratorApp());
}

class AIStoryIllustratorApp extends StatelessWidget {
  const AIStoryIllustratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Story Illustrator',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late final GeminiTextService _textService;
  late final GeminiImageService _imageService;
  late final PresentationService _presentationService;

  @override
  void initState() {
    super.initState();
    _textService = GeminiTextService();
    _imageService = GeminiImageService();
    _presentationService = PresentationService(_textService, _imageService);

    // Initialize services with API key
    const apiKey = 'AIzaSyBTx1eLCsF47fqfjCxaGQbARPjQIANP63U';
    _textService.initialize(apiKey);
    _imageService.initialize(apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Content Creator'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Story Illustrator'),
              Tab(text: 'Presentation Maker'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StoryHomePage(
              textService: _textService,
              imageService: _imageService,
            ),
            PresentationScreen(presentationService: _presentationService),
          ],
        ),
      ),
    );
  }
}

class StoryHomePage extends StatefulWidget {
  final GeminiTextService textService;
  final GeminiImageService imageService;

  const StoryHomePage({
    super.key,
    required this.textService,
    required this.imageService,
  });

  @override
  StoryHomePageState createState() => StoryHomePageState();
}

class StoryHomePageState extends State<StoryHomePage> {
  final _promptController = TextEditingController();
  String? _storyText;
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with your actual API key
    // Services are already initialized
  }

  Future<void> _generateStoryAndImage() async {
    setState(() {
      _loading = true;
      _error = null;
      _storyText = null;
      _imageBytes = null;
    });
    try {
      final enhancedPrompt =
          '''
Tell me a simple, fun story about: ${_promptController.text}

Make sure to:
- Keep sentences short and simple
- Use everyday words that everyone knows
- Include 2-3 friendly characters
- Add some natural dialogue
- Keep the story around 250 words
- Make it fun and positive
- Have a clear beginning, middle, and end

Just tell the story - don't explain anything about the topic.
''';

      final textResponse = await widget.textService.generateGeminiText(
        prompt: enhancedPrompt,
        systemInstruction:
            "You are a friendly storyteller who writes simple, clear stories that everyone can understand. Use everyday language and natural dialogue.",
        // generationConfig: GenerationConfig(
        //   temperature: 0.7, // Balanced between creativity and clarity
        //   topK: 20, // Limited vocabulary for simpler language
        //   topP: 0.85, // Natural but controlled language
        //   maxOutputTokens: 400, // Enforces medium length
        // ),
      );
      if (!textResponse.success) {
        setState(() {
          _error = textResponse.error;
          _loading = false;
        });
        return;
      }
      setState(() {
        _storyText = textResponse.text;
      });
      final imageResponse = await widget.imageService.generateGeminiImage(
        prompt: _storyText ?? _promptController.text,
      );
      if (!imageResponse.success) {
        setState(() {
          _error = imageResponse.error;
          _loading = false;
        });
        return;
      }
      setState(() {
        _imageBytes = imageResponse.imageBytes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Story Illustrator')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: 'Enter a story prompt',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _generateStoryAndImage,
                child: _loading
                    ? CircularProgressIndicator()
                    : Text('Generate Story & Image'),
              ),
              SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Colors.red)),
              if (_storyText != null)
                Container(
                  width: double.infinity,
                  child: Text(
                    _storyText!,
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.left,
                  ),
                ),
              SizedBox(height: 16),
              if (_imageBytes != null)
                Container(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
