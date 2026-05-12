import 'package:translator/translator.dart';
import 'package:flutter/material.dart';
import 'package:photopia/core/localization/app_localizations.dart';

class TranslationService {
  static final GoogleTranslator _translator = GoogleTranslator();

  static Future<String> translate(String text, String targetLanguage) async {
    if (text.isEmpty) return text;
    try {
      var translation = await _translator.translate(text, to: targetLanguage);
      return translation.text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text; // Fallback to original text
    }
  }
}

extension DynamicTranslation on String {
  /// Translates the string to the current app language if it's not English.
  /// Use this for backend-driven data or dynamic strings.
  Future<String> translateDynamic(BuildContext context) async {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en') return this;
    
    return await TranslationService.translate(this, locale.languageCode);
  }
}

/// A widget that automatically translates its text content.
class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    // If English, just return normal Text
    if (locale.languageCode == 'en') {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return FutureBuilder<String>(
      future: TranslationService.translate(text, locale.languageCode),
      initialData: text,
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}
