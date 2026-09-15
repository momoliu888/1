class AiModel {
  final String id;
  final String name;
  final String? description;
  final int? contextLength;
  final double? pricePer1mTokens;

  const AiModel({required this.id, required this.name, this.description, this.contextLength, this.pricePer1mTokens});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'description': description, 'contextLength': contextLength, 'pricePer1mTokens': pricePer1mTokens};
  factory AiModel.fromJson(Map<String, dynamic> j) => AiModel(
    id: j['id'] as String, name: j['name'] as String,
    description: j['description'] as String?,
    contextLength: j['contextLength'] as int?,
    pricePer1mTokens: (j['pricePer1mTokens'] as num?)?.toDouble(),
  );
}

class AiProvider {
  final String id;
  String name;
  String baseUrl;
  String apiKey;
  String selectedModel;
  List<AiModel> models;

  /// API 协议：'anthropic'（Messages API）或 'openai'（OpenAI 兼容 /chat/completions）。
  /// 内置 OpenRouter 与所有自定义服务商默认走 openai；Anthropic 走 anthropic。
  String protocol;

  AiProvider({required this.id, required this.name, required this.baseUrl, this.apiKey = '', this.selectedModel = '', List<AiModel>? models, this.protocol = 'openai'})
      : models = models ?? [];

  /// 自定义服务商的 id 以 'custom.' 开头。
  bool get isCustom => id.startsWith('custom.');

  bool get isConfigured => apiKey.isNotEmpty;

  /// 生成一个唯一的自定义服务商 id。
  static String nextCustomId() => 'custom.${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'baseUrl': baseUrl,
    'apiKey': apiKey, 'selectedModel': selectedModel,
    'protocol': protocol,
    'models': models.map((m) => m.toJson()).toList(),
  };

  factory AiProvider.fromJson(Map<String, dynamic> j) => AiProvider(
    id: j['id'] as String, name: j['name'] as String, baseUrl: j['baseUrl'] as String,
    apiKey: j['apiKey'] as String? ?? '', selectedModel: j['selectedModel'] as String? ?? '',
    protocol: j['protocol'] as String? ?? (j['id'] == 'anthropic' ? 'anthropic' : 'openai'),
    models: (j['models'] as List?)?.map((m) => AiModel.fromJson(m)).toList(),
  );

  static AiProvider anthropic() => AiProvider(
    id: 'anthropic', name: 'Anthropic', baseUrl: 'https://api.anthropic.com/v1/messages',
    protocol: 'anthropic',
    models: const [
      AiModel(id: 'claude-sonnet-4-20250514', name: 'Claude Sonnet 4', description: '速度快，推荐'),
      AiModel(id: 'claude-opus-4-6', name: 'Claude Opus 4.6', description: '最聪明，但较慢'),
      AiModel(id: 'claude-haiku-4-5-20251001', name: 'Claude Haiku 4.5', description: '最便宜，速度最快'),
    ],
    selectedModel: 'claude-sonnet-4-20250514',
  );

  static AiProvider openRouter() => AiProvider(
    id: 'openrouter', name: 'OpenRouter', baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
    selectedModel: 'anthropic/claude-sonnet-4',
  );

  /// 创建一个自定义服务商。id 可选（默认自动生成），协议默认 OpenAI 兼容。
  static AiProvider custom({required String name, required String baseUrl, String? id, String protocol = 'openai', String apiKey = '', String selectedModel = '', List<AiModel>? models}) => AiProvider(
    id: id ?? nextCustomId(), name: name, baseUrl: baseUrl,
    apiKey: apiKey, selectedModel: selectedModel, models: models,
    protocol: protocol,
  );
}

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}
