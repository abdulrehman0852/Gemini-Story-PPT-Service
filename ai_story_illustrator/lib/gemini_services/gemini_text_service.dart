import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiTextResponse {
  final bool success;
  final String? text;
  final String? error;

  GeminiTextResponse({required this.success, this.text, this.error});
}

class GeminiTextService {
  GenerativeModel? _model;

  void initialize(String apiKey) {
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  Future<GeminiTextResponse> generateGeminiText({
    required String prompt,
    String? systemInstruction,
    List<Uint8List>? images,
  }) async {
    if (_model == null) {
      return GeminiTextResponse(
        success: false,
        error: 'API key not initialized',
      );
    }

    try {
      final contents = <Content>[];

      if (systemInstruction != null) {
        contents.add(Content.text(systemInstruction));
      }

      contents.add(Content.text(prompt));

      if (images != null) {
        for (final image in images) {
          contents.add(Content.data('image/jpeg', image));
        }
      }

      final response = await _model!.generateContent(contents);

      if (response.text == null || response.text!.isEmpty) {
        return GeminiTextResponse(
          success: false,
          error: 'Empty response from Gemini',
        );
      }

      return GeminiTextResponse(success: true, text: response.text);
    } catch (e) {
      return GeminiTextResponse(success: false, error: e.toString());
    }
  }
}
