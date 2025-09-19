import 'dart:convert';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

final _logger = Logger();

class GeminiImageService {
  static String? _apiKey;
  static bool _initialized = false;

  void initialize(String apikey) {
    _apiKey = apikey;
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  Future<GeminiImageResponse> generateGeminiImage({
    required String prompt,
    List<Uint8List>? images,
  }) async {
    String? message;
    Uint8List? imagebytes;

    if (_apiKey == null || _apiKey!.isEmpty) {
      return GeminiImageResponse(
        success: false,
        error: "API key not initialized",
      );
    }
    final apiKey = _apiKey!;
    _logger.d('Using API key: $apiKey');
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent?key=$apiKey',
    );

    final headers = {'Content-Type': 'application/json'};
    // final headers = {'Content-Type': 'application/json'};

    final parts = <Map<String, dynamic>>[];
    parts.add({"text": "Generate a high-quality, detailed image: $prompt"});

    if (images != null && images.isNotEmpty) {
      for (final image in images) {
        parts.add({
          "inlineData": {"mimeType": "image/jpeg", "data": base64Encode(image)},
        });
      }
    }

    final body = jsonEncode({
      "contents": [
        {"parts": parts},
      ],
      "generationConfig": {
        "responseModalities": ["IMAGE", "TEXT"],
        "temperature": 0.7,
      },
    });

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return GeminiImageResponse(
          success: false,
          error: 'No internet connection',
        );
      }

      _logger.i('Making API request to Gemini for prompt: $prompt');
      final response = await http.post(url, headers: headers, body: body);
      _logger.d('Response code: ${response.statusCode}');
      _logger.d('API Response body length: ${response.body.length}');

      if (response.statusCode != 200) {
        _logger.e('API Error: ${response.body}');
        return GeminiImageResponse(
          success: false,
          error:
              'API request failed with status ${response.statusCode}: ${response.body}',
        );
      }

      final decoded = json.decode(response.body);
      _logger.d('Decoded response structure: ${decoded.keys}');

      // Check if response has candidates
      if (decoded['candidates'] == null || decoded['candidates'].isEmpty) {
        return GeminiImageResponse(
          success: false,
          error: 'No candidates in API response',
        );
      }

      final candidate = decoded['candidates'][0];
      _logger.d('Candidate keys: ${candidate.keys}');

      // Check for safety blocks
      if (candidate['finishReason'] == 'SAFETY' ||
          candidate['finishReason'] == 'IMAGE_SAFETY') {
        return GeminiImageResponse(
          success: false,
          error: 'Image generation blocked due to safety filters.',
        );
      }

      // Check if content exists
      if (candidate['content'] == null ||
          candidate['content']['parts'] == null) {
        return GeminiImageResponse(
          success: false,
          error: 'No content in API response',
        );
      }

      final parts = candidate['content']['parts'] as List;
      _logger.d('Number of parts in response: ${parts.length}');

      // Look for image data in any part
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        _logger.d('Part $i keys: ${part.keys}');

        if (part['inlineData'] != null && part['inlineData']['data'] != null) {
          final base64Image = part['inlineData']['data'] as String;
          _logger.d('Found image data, base64 length: ${base64Image.length}');

          try {
            imagebytes = base64Decode(base64Image);
            _logger.d('Successfully decoded image bytes: ${imagebytes.length}');

            // Validate that we have actual image data
            if (imagebytes.length > 1000) {
              message = 'Image generated successfully';
              return GeminiImageResponse(
                success: true,
                imageBytes: imagebytes,
                message: message,
              );
            } else {
              _logger.w('Image bytes too small: ${imagebytes.length}');
            }
          } catch (e) {
            _logger.e('Error decoding base64: $e');
          }
        }
      }

      return GeminiImageResponse(
        success: false,
        error: 'No valid image data found in API response',
      );
    } catch (e) {
      _logger.e('Exception in generateGeminiImage: $e');
      return GeminiImageResponse(
        success: false,
        error: "Network or parsing error: $e",
      );
    }
  }
}

class GeminiImageResponse {
  final bool success;
  final String? message;
  final String? error;
  final Uint8List? imageBytes;

  GeminiImageResponse({
    required this.success,
    this.message,
    this.error,
    this.imageBytes,
  });
}
