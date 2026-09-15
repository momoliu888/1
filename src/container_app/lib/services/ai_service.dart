import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';

class AiService {
  /// Generate a response from the AI provider.
  /// Returns the assistant's message content.
  static Future<String> generate({
    required AiProvider provider,
    required String systemPrompt,
    required List<ChatMessage> messages,
  }) async {
    return _withRetry(() {
      if (provider.protocol == 'anthropic') {
        return _callAnthropic(provider, systemPrompt, messages);
      } else if (provider.protocol == 'openai') {
        return _callOpenAICompatible(provider, systemPrompt, messages);
      }
      throw Exception('未知的 API 协议：${provider.protocol}');
    });
  }

  /// Retry on transient connection errors (reset by peer, timeout).
  static Future<String> _withRetry(Future<String> Function() call, {int maxRetries = 2}) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await call();
      } on SocketException catch (e) {
        if (attempt == maxRetries) rethrow;
        debugPrint('[AI] Connection error, retrying (${attempt + 1}/$maxRetries): $e');
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } on HttpException catch (e) {
        if (attempt == maxRetries) rethrow;
        debugPrint('[AI] HTTP error, retrying (${attempt + 1}/$maxRetries): $e');
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    throw Exception('Request failed after $maxRetries retries');
  }

  /// Test the provider connection with a simple prompt.
  static Future<bool> testConnection(AiProvider provider) async {
    try {
      final result = await generate(
        provider: provider,
        systemPrompt: 'Respond with exactly: OK',
        messages: [ChatMessage(role: 'user', content: 'Test')],
      );
      return result.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── URL normalization ──

  /// Trim trailing slashes.
  static String _trimSlash(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Given a user-supplied base URL, return the full chat completions endpoint.
  /// Accepts: "https://api.example.com/v1", "https://api.example.com/v1/chat/completions",
  /// "https://api.example.com" — always resolves to ".../chat/completions".
  static String _chatEndpoint(String baseUrl) {
    var u = _trimSlash(baseUrl);
    if (u.isEmpty) return '';
    if (u.endsWith('/chat/completions')) return u;
    if (u.endsWith('/messages')) return u; // Anthropic-style full endpoint
    return '$u/chat/completions';
  }

  /// Given a user-supplied base URL, return the models listing endpoint.
  /// Strip a trailing "/chat/completions" or "/messages" if present.
  static String _modelsEndpoint(String baseUrl) {
    var u = _trimSlash(baseUrl);
    if (u.isEmpty) return '';
    if (u.endsWith('/chat/completions')) {
      u = u.substring(0, u.length - '/chat/completions'.length);
    } else if (u.endsWith('/messages')) {
      u = u.substring(0, u.length - '/messages'.length);
    }
    return '$u/models';
  }

  // ── Model fetching ──

  /// Generic model fetch for any provider, dispatching by protocol.
  static Future<List<AiModel>> fetchModels(AiProvider provider) async {
    if (provider.protocol == 'anthropic') {
      return fetchAnthropicModels(provider.apiKey);
    }
    return fetchOpenAICompatibleModels(provider.baseUrl, provider.apiKey);
  }

  /// Fetch available models from an OpenAI-compatible endpoint (custom providers,
  /// OpenRouter, and any OpenAI-style API). Does not require a key for public
  /// endpoints, but sends it when present.
  static Future<List<AiModel>> fetchOpenAICompatibleModels(String baseUrl, String apiKey) async {
    final endpoint = _modelsEndpoint(baseUrl);
    final headers = <String, String>{};
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    final response = await http.get(
      Uri.parse(endpoint),
      headers: headers,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('获取模型列表失败：${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final models = (data['data'] as List?) ?? (data['models'] as List?) ?? [];
    final list = models.map((m) {
      final raw = m as Map;
      final id = raw['id'] as String? ?? raw['name'] as String? ?? '';
      final ctx = raw['context_length'] ?? raw['max_input_tokens'];
      return AiModel(
        id: id,
        name: raw['name'] as String? ?? raw['display_name'] as String? ?? id,
        contextLength: ctx is num ? ctx.toInt() : null,
      );
    }).where((m) => m.id.isNotEmpty).toList();

    // Sort: Claude first, then GPT, then others
    list.sort((a, b) {
      int score(AiModel m) {
        if (m.id.contains('claude')) return 0;
        if (m.id.contains('gpt')) return 1;
        if (m.id.contains('llama')) return 2;
        if (m.id.contains('mistral')) return 3;
        return 4;
      }
      return score(a).compareTo(score(b));
    });

    return list;
  }

  /// Fetch available models from Anthropic.
  static Future<List<AiModel>> fetchAnthropicModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('https://api.anthropic.com/v1/models?limit=1000'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) throw Exception('获取模型列表失败：${response.statusCode}');

    final data = jsonDecode(response.body);
    final models = (data['data'] as List).map((m) {
      return AiModel(
        id: m['id'] as String,
        name: m['display_name'] as String? ?? m['id'] as String,
        contextLength: m['max_input_tokens'] as int?,
      );
    }).toList();

    // Sort: newest families first (opus > sonnet > haiku), then by id descending for version
    models.sort((a, b) {
      int family(AiModel m) {
        final id = m.id.toLowerCase();
        if (id.contains('opus')) return 0;
        if (id.contains('sonnet')) return 1;
        if (id.contains('haiku')) return 2;
        return 3;
      }
      final fc = family(a).compareTo(family(b));
      if (fc != 0) return fc;
      return b.id.compareTo(a.id); // newer versions first within same family
    });

    return models;
  }

  /// Fetch available models from OpenRouter (public endpoint, no key needed).
  static Future<List<AiModel>> fetchOpenRouterModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('https://openrouter.ai/api/v1/models'),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) throw Exception('获取模型列表失败：${response.statusCode}');

    final data = jsonDecode(response.body);
    final models = (data['data'] as List).map((m) {
      final pricing = m['pricing'] as Map?;
      final prompt = pricing != null ? double.tryParse(pricing['prompt']?.toString() ?? '') : null;
      return AiModel(
        id: m['id'] as String,
        name: m['name'] as String? ?? m['id'] as String,
        contextLength: m['context_length'] as int?,
        pricePer1mTokens: prompt != null ? prompt * 1000000 : null,
      );
    }).toList();

    // Sort: Claude first, then GPT, then others
    models.sort((a, b) {
      int score(AiModel m) {
        if (m.id.contains('claude')) return 0;
        if (m.id.contains('gpt')) return 1;
        if (m.id.contains('llama')) return 2;
        if (m.id.contains('mistral')) return 3;
        return 4;
      }
      return score(a).compareTo(score(b));
    });

    return models;
  }

  // ── Anthropic ──

  static Future<String> _callAnthropic(AiProvider provider, String systemPrompt, List<ChatMessage> messages) async {
    final body = jsonEncode({
      'model': provider.selectedModel,
      'max_tokens': 16000,
      // System prompt as a cached content block — Anthropic stores the tokenized
      // prefix server-side for 5 minutes. Repeat calls (edits, retries) within
      // that window skip re-processing the ~51KB bridge reference: ~90% cheaper
      // on input tokens, slightly faster.
      'system': [
        {
          'type': 'text',
          'text': systemPrompt,
          'cache_control': {'type': 'ephemeral'},
        }
      ],
      'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
    });

    final response = await http.post(
      Uri.parse(provider.baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': provider.apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-beta': 'prompt-caching-2024-07-31',
      },
      body: body,
    ).timeout(const Duration(seconds: 300));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'API error ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final content = data['content'] as List?;
    if (content == null || content.isEmpty) throw Exception('Empty response from API');
    return content.first['text'] as String;
  }

  // ── OpenAI-compatible (OpenRouter, custom providers) ──

  static Future<String> _callOpenAICompatible(AiProvider provider, String systemPrompt, List<ChatMessage> messages) async {
    final allMessages = [
      {'role': 'system', 'content': systemPrompt},
      ...messages.map((m) => {'role': m.role, 'content': m.content}),
    ];

    final body = jsonEncode({
      'model': provider.selectedModel,
      'max_tokens': 16000,
      'messages': allMessages,
    });

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (provider.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${provider.apiKey}';
    }
    // OpenRouter-specific attribution headers (ignored by other providers).
    headers['HTTP-Referer'] = 'https://iappyx.com';
    headers['X-Title'] = 'iappyxOS';

    final response = await http.post(
      Uri.parse(_chatEndpoint(provider.baseUrl)),
      headers: headers,
      body: body,
    ).timeout(const Duration(seconds: 300));

    if (response.statusCode != 200) {
      // Some providers return non-JSON error pages; guard the decode.
      String message;
      try {
        final error = jsonDecode(response.body);
        final errObj = error['error'];
        message = errObj is Map ? (errObj['message'] as String? ?? 'API error ${response.statusCode}') : 'API error ${response.statusCode}';
      } catch (_) {
        message = 'API error ${response.statusCode}';
      }
      throw Exception(message);
    }

    final data = jsonDecode(response.body);
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) throw Exception('Empty response from API');
    final msg = choices[0]['message'] as Map?;
    final content = msg?['content'];
    if (content == null) throw Exception('Empty response from API');
    return content as String;
  }
}