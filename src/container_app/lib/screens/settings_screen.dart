// MIT License
//
// Copyright (c) 2026 iappyx
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// Settings screen for AI provider config, custom prompts, and app management.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings_service.dart';
import '../services/prompt_builder.dart';
import '../services/app_storage.dart';
import '../services/generator.dart';
import '../models/ai_provider.dart';
import 'create_screen.dart' show ProviderSetupPage;

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onAppsImported;
  const SettingsScreen({super.key, this.onAppsImported});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AiProvider? _activeProvider;
  bool _hasCustomPrompt = false;
  bool _promptOutdated = false;
  String _packagePrefix = '';
  final _prefixController = TextEditingController();
  String? _prefixError;
  int _appCount = 0;
  Map<String, dynamic> _keyInfo = {};
  String _stylePreset = 'default';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final activeProvider = await Settings.getActiveProvider();
    final hasCustom = await Settings.hasCustomPrompt();
    final promptOutdated = await PromptBuilder.isPromptOutdated();
    if (!hasCustom) await PromptBuilder.markPromptAsSeen(); // track hash on first launch / after reset
    final prefix = await Settings.getPackagePrefix();
    final apps = await AppStorage.loadAll();
    Map<String, dynamic> keyInfo = {};
    try { keyInfo = await Generator.getKeyInfo(); } catch (_) {}
    final style = await Settings.getCssStylePreset();
    if (mounted) {
      setState(() {
        _activeProvider = activeProvider;
        _hasCustomPrompt = hasCustom;
        _promptOutdated = promptOutdated;
        _packagePrefix = prefix;
        _prefixController.text = prefix;
        _appCount = apps.length;
        _keyInfo = keyInfo;
        _stylePreset = style;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loaded ? SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/ic_launcher.png', width: 44, height: 44),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('iappyxOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('设置', style: TextStyle(fontSize: 12, color: Colors.white38)),
                ]),
              ]),

              const SizedBox(height: 24),

              // Support
              _card(children: [
                InkWell(
                  onTap: () { try { Generator.openUrl('https://ko-fi.com/iappyx'); } catch (_) {} },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5E5B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('\u2764', style: TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('支持 iappyxOS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('在 Ko-fi 上请我喝杯咖啡', style: TextStyle(fontSize: 11, color: Colors.white38)),
                          ],
                        )),
                        const Icon(Icons.open_in_new, size: 16, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // AI Prompt
              _sectionTitle('AI 系统提示词'),
              _card(children: [
                _row('状态', _hasCustomPrompt ? (_promptOutdated ? '自定义（已过时）' : '自定义') : '默认'),
                if (_promptOutdated) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E2723),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber, color: Color(0xFFFFB74D), size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text('已添加新的桥接。重置为默认即可获取。',
                          style: TextStyle(fontSize: 11, color: Color(0xFFFFB74D)))),
                      ]),
                    ),
                  ),
                ],
                const Divider(height: 1, color: Color(0xFF0D0D1A)),
                _actionRow('查看 / 编辑提示词', Icons.edit_outlined, _editPrompt),
                if (_hasCustomPrompt) ...[
                  const Divider(height: 1, color: Color(0xFF0D0D1A)),
                  _actionRow('重置为默认', Icons.restore, _resetPrompt, color: const Color(0xFFFF6B6B)),
                ],
              ]),

              const SizedBox(height: 24),

              // App Style
              _sectionTitle('应用样式'),
              _card(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('应用于所有生成应用的 CSS 样式', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    const SizedBox(height: 12),
                    ..._styleOptions.map((opt) {
                      final selected = _stylePreset == opt.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _stylePreset = opt.id);
                          Settings.setCssStylePreset(opt.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? const Color(0xFF4FC3F7) : Colors.transparent, width: 1.5),
                          ),
                          child: Column(children: [
                            // Preview
                            if (opt.id != 'default')
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  color: const Color(0xFF0D0D1A),
                                  child: opt.preview,
                                ),
                              ),
                            // Label bar
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF0F3460) : const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.vertical(
                                  top: opt.id == 'default' ? const Radius.circular(11) : Radius.zero,
                                  bottom: const Radius.circular(11),
                                ),
                              ),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(opt.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.white70)),
                                  Text(opt.subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                ])),
                                if (selected) const Icon(Icons.check_circle, color: Color(0xFF4FC3F7), size: 18),
                              ]),
                            ),
                          ]),
                        ),
                      );
                    }),
                  ]),
                ),
              ]),

              const SizedBox(height: 24),

              // AI Configuration
              _sectionTitle('AI 配置'),
              _card(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('服务商', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    const SizedBox(height: 6),
                    Row(children: [
                      _providerButton('anthropic', 'Anthropic', Icons.auto_awesome),
                      const SizedBox(width: 8),
                      _providerButton('openrouter', 'OpenRouter', Icons.shuffle),
                    ]),
                    const SizedBox(height: 14),
                    _actionRow('配置 API 密钥与模型', Icons.settings, () async {
                      final provider = _activeProvider ?? AiProvider.anthropic();
                      final result = await Navigator.push<AiProvider>(
                        context,
                        MaterialPageRoute(builder: (_) => ProviderSetupPage(provider: provider)),
                      );
                      if (result != null) {
                        await Settings.setActiveProvider(result);
                        _load();
                      }
                    }),
                    if (_activeProvider != null && _activeProvider!.isConfigured) ...[
                      const Divider(height: 16, color: Color(0xFF0D0D1A)),
                      Row(children: [
                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF69F0AE)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          '${_activeProvider!.name} · ${_activeProvider!.selectedModel.split('/').last}',
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        )),
                      ]),
                    ] else ...[
                      const Divider(height: 16, color: Color(0xFF0D0D1A)),
                      const Text('未配置 — AI API 流程不可用',
                          style: TextStyle(fontSize: 11, color: Colors.white24)),
                    ],
                  ]),
                ),
              ]),

              const SizedBox(height: 24),

              // App ID Prefix
              _sectionTitle('应用 ID 前缀'),
              _card(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('你的所有应用都会获得一个以此前缀开头的唯一 ID（例如 myprefix.appname12345）。',
                          style: TextStyle(fontSize: 11, color: Colors.white38)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _prefixController,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          filled: true, fillColor: const Color(0xFF0D0D1A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          errorText: _prefixError,
                          suffixText: '${_prefixController.text.length}/${Settings.maxPrefixLength}',
                          suffixStyle: const TextStyle(fontSize: 10, color: Colors.white24),
                        ),
                        onChanged: (v) {
                          final val = v.toLowerCase();
                          if (val != v) {
                            _prefixController.value = TextEditingValue(
                              text: val,
                              selection: TextSelection.collapsed(offset: val.length),
                            );
                          }
                          setState(() {
                            if (val.isEmpty) {
                              _prefixError = null;
                            } else if (!Settings.validatePrefix(val)) {
                              _prefixError = '小写字母、数字、点。以字母开头。最多 ${Settings.maxPrefixLength} 个字符。';
                            } else {
                              _prefixError = null;
                            }
                          });
                        },
                        onSubmitted: (v) => _savePrefix(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '预览：${_prefixController.text.isNotEmpty && Settings.validatePrefix(_prefixController.text) ? _prefixController.text : _packagePrefix}.myapp12345678',
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white24),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _prefixError == null ? _savePrefix : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F3460),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('保存', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final prefs = await Settings.getPrefs();
                              await prefs.remove('package_prefix');
                              final fresh = await Settings.getPackagePrefix();
                              _prefixController.text = fresh;
                              setState(() { _packagePrefix = fresh; _prefixError = null; });
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('前缀已重置为 $fresh')),
                              );
                            },
                            child: const Text('随机生成', style: TextStyle(fontSize: 12, color: Colors.white38)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // Data Management
              _sectionTitle('数据管理'),
              _card(children: [
                _row('已保存应用', '$_appCount'),
                const Divider(height: 1, color: Color(0xFF0D0D1A)),
                _actionRow('导出应用', Icons.upload, _exportApps),
                const Divider(height: 1, color: Color(0xFF0D0D1A)),
                _actionRow('导入应用', Icons.download, _importApps),
                const Divider(height: 1, color: Color(0xFF0D0D1A)),
                _actionRow('清除全部应用', Icons.delete_forever, _clearApps, color: const Color(0xFFFF6B6B)),
              ]),

              const SizedBox(height: 24),

              // Signing Key
              _sectionTitle('签名密钥'),
              _card(children: [
                _row('状态', _keyInfo['exists'] == true ? '有效' : '未找到'),
                if (_keyInfo['fingerprint'] != null) ...[
                  const Divider(height: 1, color: Color(0xFF0D0D1A)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('指纹', style: TextStyle(fontSize: 11, color: Colors.white38)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _keyInfo['fingerprint']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('指纹已复制。')),
                            );
                          },
                          child: Row(children: [
                            Expanded(child: Text(
                              _keyInfo['fingerprint'],
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white54),
                            )),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy, size: 14, color: Colors.white24),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),

              const SizedBox(height: 24),

              // Showcase
              _sectionTitle('作品展示'),
              _card(children: [
                _actionRow('GitHub Token', Icons.key, () async {
                  final current = await Settings.getGithubToken();
                  final controller = TextEditingController(text: current);
                  final String? result;
                  try {
                    result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A2E),
                        title: const Text('GitHub Token'),
                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('提交 Showcase 作品时需要。请在 github.com/settings/tokens 创建，并勾选 public_repo 权限。',
                            style: TextStyle(fontSize: 12, color: Colors.white54)),
                          const SizedBox(height: 12),
                          TextField(controller: controller, style: const TextStyle(color: Colors.white, fontSize: 13),
                            obscureText: true,
                            decoration: const InputDecoration(hintText: 'ghp_...', filled: true, fillColor: Color(0xFF0D0D1A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none))),
                        ]),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('保存')),
                        ],
                      ),
                    );
                  } finally {
                    controller.dispose();
                  }
                  if (result != null) {
                    await Settings.setGithubToken(result);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.isEmpty ? 'GitHub Token 已移除' : 'GitHub Token 已保存')));
                  }
                }),
              ]),

              const SizedBox(height: 24),

              // About
              _sectionTitle('关于'),
              _card(children: [
                _row('版本', '0.1.0'),
                const Divider(height: 1, color: Color(0xFF0D0D1A)),
                _row('示例模板', '23'),
                const Divider(height: 1, color: Color(0xFF0D0D1A)),
                _row('平台', 'Android（设备端）'),
              ]),

              const SizedBox(height: 40),
            ],
          ),
        ) : const Center(child: CircularProgressIndicator(color: Color(0xFF4FC3F7))),
      ),
    );
  }

  // ── UI helpers ──

  Widget _providerButton(String id, String name, IconData icon) {
    final selected = _activeProvider?.id == id;
    return Expanded(child: GestureDetector(
      onTap: () async {
        if (_activeProvider?.id == id) return; // already selected
        final provider = id == 'anthropic' ? AiProvider.anthropic() : AiProvider.openRouter();
        // Restore previously saved key if switching back
        final saved = await Settings.getProvider(id);
        if (saved != null && saved.apiKey.isNotEmpty) {
          provider.apiKey = saved.apiKey;
          provider.selectedModel = saved.selectedModel;
          provider.models = saved.models;
        }
        await Settings.setActiveProvider(provider);
        _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F3460) : const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF4FC3F7) : Colors.white12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? const Color(0xFF4FC3F7) : Colors.white38),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(fontSize: 13, color: selected ? Colors.white : Colors.white54)),
        ]),
      ),
    ));
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w600)),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(14),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.white54)),
      ],
    ),
  );

  Widget _actionRow(String label, IconData icon, VoidCallback onTap, {Color? color}) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? const Color(0xFF4FC3F7)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: color))),
          Icon(Icons.chevron_right, size: 18, color: color ?? Colors.white24),
        ],
      ),
    ),
  );

  // ── Actions ──

  Future<void> _savePrefix() async {
    final val = _prefixController.text.trim();
    if (val.isEmpty || !Settings.validatePrefix(val)) return;
    await Settings.setPackagePrefix(val);
    if (!mounted) return;
    setState(() { _packagePrefix = val; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('应用 ID 前缀已保存。'), backgroundColor: Color(0xFF1A1A2E), duration: Duration(seconds: 4)),
    );
  }

  Future<void> _editPrompt() async {
    final current = await PromptBuilder.getSystemPrompt();
    final controller = TextEditingController(text: current);
    if (!mounted) { controller.dispose(); return; }
    final result = await Navigator.push<String>(context, MaterialPageRoute(
      builder: (_) => _PromptEditorPage(controller: controller),
    ));
    controller.dispose();
    if (result != null) {
      final defaultPrompt = await PromptBuilder.getDefaultPrompt();
      if (result == defaultPrompt) {
        await Settings.setCustomPrompt(null);
      } else {
        await Settings.setCustomPrompt(result);
      }
      _load();
    }
  }

  Future<void> _resetPrompt() async {
    await Settings.setCustomPrompt(null);
    await PromptBuilder.markPromptAsSeen();
    _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('提示词已重置为默认。'), backgroundColor: Color(0xFF1A1A2E), duration: Duration(seconds: 4)),
    );
  }

  Future<void> _exportApps() async {
    final apps = await AppStorage.loadAll();
    if (apps.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可导出的应用。'), backgroundColor: Color(0xFF1A1A2E), duration: Duration(seconds: 4)),
      );
      return;
    }
    final json = jsonEncode(apps.map((a) => a.toJson()).toList());
    try {
      await Generator.shareText(content: json, filename: 'iappyxos_apps.json');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e'), backgroundColor: const Color(0xFFFF6B6B)),
      );
    }
  }

  Future<void> _importApps() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    try {
      final content = await File(result.files.single.path!).readAsString();
      final list = jsonDecode(content) as List;
      final newApps = list.map((item) => AppData.fromJson(item as Map<String, dynamic>)).toList();
      await AppStorage.importBatch(newApps);
      final imported = newApps.length;
      widget.onAppsImported?.call();
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 $imported 个应用。')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('文件无效。应为 iappyxOS JSON 导出文件。', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFFFF6B6B), duration: const Duration(seconds: 4)),
      );
    }
  }

  Future<void> _clearApps() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('清除所有已保存的应用？'),
        content: const Text('这将删除 iappyxOS 中的所有应用数据。设备上已安装的应用不受影响。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('全部清除', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final apps = await AppStorage.loadAll();
        for (final app in apps) {
          await AppStorage.delete(app.id);
        }
      } catch (_) {}
      widget.onAppsImported?.call();
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有应用已清除。'), backgroundColor: Color(0xFF1A1A2E), duration: Duration(seconds: 4)),
      );
    }
  }
}

// ── Prompt editor page ──

class _PromptEditorPage extends StatelessWidget {
  final TextEditingController controller;
  const _PromptEditorPage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('系统提示词', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存', style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: controller,
          maxLines: null,
          expands: true,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white70),
          decoration: const InputDecoration(
            border: InputBorder.none,
            filled: true,
            fillColor: Color(0xFF0A0A14),
          ),
          textAlignVertical: TextAlignVertical.top,
        ),
      ),
    );
  }
}

class _StyleOption {
  final String id, title, subtitle;
  final Widget preview;
  const _StyleOption({required this.id, required this.title, required this.subtitle, required this.preview});
}

final _styleOptions = [
  _StyleOption(
    id: 'default',
    title: '无',
    subtitle: '让 AI 决定样式',
    preview: const SizedBox.shrink(),
  ),
  _StyleOption(
    id: 'material',
    title: 'Material',
    subtitle: '水波纹效果、层级阴影、Roboto 字体',
    preview: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('示例卡片', style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, height: 36,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24, width: 1))),
            alignment: Alignment.centerLeft,
            child: const Text('文本输入...', style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Colors.white24)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: const Text('操作', style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Colors.white)),
          ),
        ]),
      ),
    ]),
  ),
  _StyleOption(
    id: 'glassmorphic',
    title: 'Glassmorphic',
    subtitle: '毛玻璃、模糊、细腻边框',
    preview: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('示例卡片', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity, height: 36, padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0x4D000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            alignment: Alignment.centerLeft,
            child: const Text('文本输入...', style: TextStyle(fontSize: 12, color: Colors.white24)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x990F3460),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x334FC3F7)),
            ),
            child: const Text('操作', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ]),
      ),
    ]),
  ),
  _StyleOption(
    id: 'dynamic',
    title: '动态',
    subtitle: '使用设备上的 Material You 壁纸颜色（Android 12+）',
    preview: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B1F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFD0BCFF), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFCCC2DC), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFEFB8C8), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('你的壁纸颜色', style: TextStyle(fontSize: 10, color: Colors.white38)),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity, height: 36, padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2930),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerLeft,
            child: const Text('文本输入...', style: TextStyle(fontSize: 12, color: Colors.white24)),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4F378B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('操作', style: TextStyle(fontSize: 12, color: Colors.white)),
          ),
        ]),
      ),
    ]),
  ),
  _StyleOption(
    id: 'minimal',
    title: 'Minimal',
    subtitle: '极简整洁、描边按钮、纤细字体',
    preview: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x0FFFFFFF)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('示例卡片', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: Colors.white)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x26FFFFFF), width: 1))),
            padding: const EdgeInsets.only(bottom: 8),
            child: const Text('文本输入...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Colors.white24)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4FC3F7)),
            ),
            child: const Text('操作', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF4FC3F7))),
          ),
        ]),
      ),
    ]),
  ),
];