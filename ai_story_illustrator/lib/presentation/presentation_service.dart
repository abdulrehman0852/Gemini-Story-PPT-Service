import 'dart:convert';
import '../gemini_services/gemini_text_service.dart';
import '../gemini_services/gemini_image_service.dart';

class Slide {
  final String title;
  final String content;
  String? imagePrompt;
  String? imageUrl;

  Slide({
    required this.title,
    required this.content,
    this.imagePrompt,
    this.imageUrl,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    String parsedContent;

    if (rawContent is List) {
      // Convert list of bullet points to string
      parsedContent = rawContent.join("\n• ");
      parsedContent = "• $parsedContent";
    } else {
      parsedContent = rawContent?.toString() ?? "";
    }

    return Slide(
      title: json['title']?.toString() ?? "",
      content: parsedContent,
      imagePrompt: json['imagePrompt']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      if (imagePrompt != null) 'imagePrompt': imagePrompt,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class Presentation {
  final String title;
  final String description;
  final List<Slide> slides;

  Presentation({
    required this.title,
    required this.description,
    required this.slides,
  });

  factory Presentation.fromJson(Map<String, dynamic> json) {
    final slidesJson = (json['slides'] as List?) ?? [];

    return Presentation(
      title: json['title']?.toString() ?? "",
      description: json['description']?.toString() ?? "",
      slides: slidesJson
          .map((slideJson) => Slide.fromJson(slideJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'slides': slides.map((slide) => slide.toJson()).toList(),
    };
  }
}

class PresentationService {
  final GeminiTextService _textService;
  final GeminiImageService _imageService;

  PresentationService(this._textService, this._imageService);

  Future<Presentation?> generatePresentation(String topic) async {
    final outlinePrompt =
        '''
    Create a presentation outline for the topic: "$topic". 
    Return a JSON object with the following structure:
    {
      "title": "Main presentation title",
      "description": "Brief description of the presentation",
      "slides": [
        {
          "title": "Slide title",
          "content": "Slide content in bullet points",
          "imagePrompt": "A description for generating an image that represents this slide's content"
        }
      ]
    }
    Make sure the JSON is properly formatted and each slide has meaningful content and an appropriate image prompt.
    ''';

    try {
      final response = await _textService.generateGeminiText(
        prompt: outlinePrompt,
        systemInstruction: '''
          You are a presentation expert that creates well-structured, engaging presentations.
          Always return valid JSON that matches the requested structure exactly.
          Keep slides focused and concise.
          Create descriptive image prompts that will work well with image generation.
        ''',
      );

      if (!response.success || response.text == null) {
        throw Exception('Failed to generate presentation: ${response.error}');
      }

      // Extract JSON safely from response
      final jsonStr = response.text!.trim();
      final startIndex = jsonStr.indexOf('{');
      final endIndex = jsonStr.lastIndexOf('}') + 1;

      if (startIndex == -1 || endIndex <= 0 || endIndex <= startIndex) {
        throw Exception('No valid JSON found in response');
      }

      final jsonContent = jsonStr.substring(startIndex, endIndex);
      final presentationJson = json.decode(jsonContent) as Map<String, dynamic>;

      return Presentation.fromJson(presentationJson);
    } catch (e) {
      print('Error generating presentation: $e');
      return null;
    }
  }

  Future<void> generateImagesForSlides(Presentation presentation) async {
    for (final slide in presentation.slides) {
      if (slide.imagePrompt != null) {
        try {
          final response = await _imageService.generateGeminiImage(
            prompt: slide.imagePrompt!,
          );

          if (response.success && response.imageBytes != null) {
            final base64Image = base64Encode(response.imageBytes!);
            slide.imageUrl = 'data:image/jpeg;base64,$base64Image';
          } else {
            print('Failed to generate image for slide: ${response.error}');
          }
        } catch (e) {
          print('Error generating image for slide: $e');
        }
      }
    }
  }
}
