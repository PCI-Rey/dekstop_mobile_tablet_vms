import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository(this._dioClient);

  // Get Captcha from official endpoint /api/captcha/generate
  Future<({String captchaId, String captchaCode, String svgBackground})?> getCaptcha() async {
    final result = await _dioClient.getCaptcha();
    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final captchaId = data['captchaId']?.toString() ?? '';
      final rawImage = data['image']?.toString() ?? '';

      String svgContent = '';
      if (rawImage.startsWith('data:image/svg+xml;base64,')) {
        final base64Part =
            rawImage.substring('data:image/svg+xml;base64,'.length);
        svgContent = utf8.decode(base64Decode(base64Part));
      } else if (rawImage.contains(',')) {
        final base64Part = rawImage.split(',').last;
        svgContent = utf8.decode(base64Decode(base64Part));
      } else {
        svgContent = rawImage;
      }

      // Extract captcha code text from SVG <text> element
      final match = RegExp(r'>([^<]+)<\/text>').firstMatch(svgContent);
      final captchaCode = match?.group(1)?.trim() ?? '';

      // Extract SVG background without text
      final svgBackground = svgContent.replaceAll(
        RegExp(r'<text[^>]*>[\s\S]*?<\/text>'),
        '',
      );

      return (
        captchaId: captchaId,
        captchaCode: captchaCode,
        svgBackground: svgBackground,
      );
    }
    return null;
  }

  // Login via official endpoint /api/_Auth/RequestToken
  Future<ApiResult<Map<String, dynamic>>> login(
    String username,
    String password, {
    String? captchaId,
    String? captchaAnswer,
  }) async {
    final Map<String, dynamic> headers = {
      'X-Use-Token': DioClient.xUseToken,
      'X-Platform-Id': DioClient.xPlatformId,
      'X-UserAgent': DioClient.xUserAgent,
    };

    if (captchaId != null &&
        captchaId.isNotEmpty &&
        captchaAnswer != null &&
        captchaAnswer.isNotEmpty) {
      headers['X-Captcha-Id'] = captchaId;
      headers['X-Captcha-Answer'] = captchaAnswer;
    }

    return await _dioClient.post<Map<String, dynamic>>(
      '/api/_Auth/RequestToken',
      data: {
        'username': username,
        'password': password,
      },
      options: Options(headers: headers),
    );
  }
}
