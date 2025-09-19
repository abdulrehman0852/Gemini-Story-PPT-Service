import 'package:flutter/material.dart';
import '../presentation_service.dart';

class PresentationScreen extends StatefulWidget {
  final PresentationService presentationService;

  const PresentationScreen({
    Key? key,
    required this.presentationService,
  }) : super(key: key);

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final _topicController = TextEditingController();
  Presentation? _presentation;
  bool _isLoading = false;
  String? _error;
  int _currentSlideIndex = 0;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generatePresentation() async {
    if (_topicController.text.isEmpty) {
      setState(() => _error = 'Please enter a topic');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final presentation = await widget.presentationService
          .generatePresentation(_topicController.text);

      if (presentation != null) {
        // Generate images for all slides
        await widget.presentationService.generateImagesForSlides(presentation);

        setState(() {
          _presentation = presentation;
          _currentSlideIndex = 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to generate presentation';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presentation Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Enter presentation topic',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generatePresentation,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Presentation'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (_presentation != null) ...[
              const SizedBox(height: 24),
              Text(
                _presentation!.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(_presentation!.description),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _presentation!.slides[_currentSlideIndex].title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (_presentation!
                                .slides[_currentSlideIndex].imageUrl !=
                            null)
                          Expanded(
                            flex: 2,
                            child: Image.network(
                              _presentation!
                                  .slides[_currentSlideIndex].imageUrl!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: 1,
                          child: SingleChildScrollView(
                            child: Text(_presentation!
                                .slides[_currentSlideIndex].content),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentSlideIndex > 0
                        ? () => setState(() => _currentSlideIndex--)
                        : null,
                  ),
                  Text(
                      '${_currentSlideIndex + 1}/${_presentation!.slides.length}'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed:
                        _currentSlideIndex < _presentation!.slides.length - 1
                            ? () => setState(() => _currentSlideIndex++)
                            : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
