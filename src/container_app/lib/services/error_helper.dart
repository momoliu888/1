class AppError {
  final String message;
  final String? hint;

  const AppError(this.message, [this.hint]);

  @override
  String toString() => hint != null ? '$message\n$hint' : message;
}

AppError friendlyError(String? raw) {
  if (raw == null || raw.isEmpty) return const AppError('出错了');
  final e = raw.toLowerCase();

  // Install errors
  if (e.contains('install_failed_update_incompatible'))
    return const AppError('应用由另一台设备签名', '请先卸载旧版本，再重新构建');
  if (e.contains('install_failed_insufficient_storage'))
    return const AppError('存储空间不足', '请清理存储空间后重试');
  if (e.contains('install_failed_older_sdk'))
    return const AppError('Android 版本过低', '此应用需要更高的 Android 版本');
  if (e.contains('install_failed_duplicate_permission'))
    return const AppError('与另一个应用的权限冲突', '请先卸载冲突的应用');
  if (e.contains('install_failed_conflicting_provider'))
    return const AppError('与另一个应用的 Provider 冲突', '请先卸载另一个版本');
  if (e.contains('install_failed'))
    return AppError('安装失败', _shorten(raw));

  // Build errors
  if (e.contains('a build is already in progress'))
    return const AppError('构建进行中', '请等待当前构建完成');
  if (e.contains('label required'))
    return const AppError('应用名称不能为空');
  if (e.contains('html required'))
    return const AppError('HTML 内容不能为空');

  // API / network errors
  if (e.contains('api error 401') || e.contains('unauthorized') || e.contains('invalid.*api.*key'))
    return const AppError('API Key 无效', '请在设置中检查你的 API Key');
  if (e.contains('api error 429') || e.contains('rate limit'))
    return const AppError('请求过于频繁', '请稍候再试');
  if (e.contains('api error 5') || e.contains('internal server error'))
    return const AppError('AI 服务出错', '请几秒后重试');
  if (e.contains('empty response'))
    return const AppError('AI 返回了空响应', '请尝试换一种描述');
  if (e.contains('request failed after'))
    return const AppError('多次重试后连接失败', '请检查你的网络连接');
  if (e.contains('socketexception') || e.contains('no address associated'))
    return const AppError('无网络连接', '请检查 WiFi 或移动数据');
  if (e.contains('connection refused'))
    return const AppError('无法连接服务器', '请检查地址后重试');
  if (e.contains('timeout') || e.contains('timed out'))
    return const AppError('请求超时', '请重试或检查网络连接');
  if (e.contains('handshake') || e.contains('ssl') || e.contains('certificate'))
    return const AppError('安全连接失败', '服务器证书可能无效');

  // Permission errors — only match explicit denial, not every string containing "permission"
  if (e.contains('permission denied'))
    return const AppError('需要权限', '请授予权限后重试');

  // Fallback: show shortened raw error
  return AppError('出错了', _shorten(raw));
}

String _shorten(String s) {
  final clean = s.replaceAll(RegExp(r'Exception:|PlatformException\([^,]*,\s*'), '').trim();
  return clean.length > 120 ? '${clean.substring(0, 120)}...' : clean;
}
