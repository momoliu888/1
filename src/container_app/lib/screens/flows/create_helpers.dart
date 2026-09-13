import 'package:flutter/material.dart';
import '../../models/icon_config.dart';
import '../icon_editor_screen.dart';

/// Shared UI components used across all creation flows

Widget buildBackButton(VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: const Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.arrow_back_ios, size: 14, color: Colors.white38),
    SizedBox(width: 4),
    Text('返回', style: TextStyle(fontSize: 13, color: Colors.white38)),
  ]),
);

Widget buildActionButton({
  required String label,
  required VoidCallback? onPressed,
  bool secondary = false,
  IconData? icon,
}) => SizedBox(
  width: double.infinity,
  child: FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: secondary ? const Color(0xFF1A1A2E) : const Color(0xFF0F3460),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      disabledBackgroundColor: const Color(0xFF0F3460).withValues(alpha: 0.3),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (icon != null) ...[Icon(icon, size: 18, color: Colors.white), const SizedBox(width: 8)],
      Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
    ]),
  ),
);

Widget buildIconEditor(IconConfig config, VoidCallback onTap) => Row(
  children: [
    GestureDetector(onTap: onTap, child: IconPreview(config: config, size: 80)),
    const SizedBox(width: 16),
    Expanded(child: GestureDetector(
      onTap: onTap,
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('点击编辑图标', style: TextStyle(fontSize: 13, color: Colors.white54)),
        Text('添加表情、文字，更改颜色', style: TextStyle(fontSize: 11, color: Colors.white24)),
      ]),
    )),
  ],
);

Widget buildModeCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) => GestureDetector(
  onTap: onTap,
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A2E),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF4FC3F7), size: 24),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white38)),
        ],
      )),
      const Icon(Icons.chevron_right, color: Colors.white38, size: 22),
    ]),
  ),
);

/// Demo template data
/// Demo template data — (id, emoji, name, description)
/// Section headers use empty id with '---' prefix in name
const demoTemplates = [
  // ── Apps ──
  ('',           '\u2500', '── 应用',             ''),
  ('todo',       '\u2705', '待办清单',         '带复选框的任务'),
  ('notes',      '\uD83D\uDCDD', '备忘录',       '创建、编辑和删除笔记'),
  ('counter',    '\uD83D\uDD22', '计数器',      '带计圈的点击计数器'),
  ('timer',      '\u23F1\uFE0F', '秒表',    '带计圈时间的秒表'),
  ('calculator', '\uD83E\uDDEE', '计算器',   '基础计算器'),
  ('photoeditor','\uD83D\uDDBC\uFE0F', '照片编辑器', '相机 + 滤镜 + 表情'),
  ('dashboard',  '\uD83D\uDCCA', '仪表盘',    '跟踪数据与图表 (Chart.js)'),
  ('runtracker', '\uD83C\uDFC3', '跑步追踪',  'GPS 定位、计步、地理围栏'),
  // ── Camera & ML ──
  ('',           '\u2500', '── 相机与机器学习',    ''),
  ('camera',     '\uD83D\uDCF8', '相机',       '拍照、录像、分享'),
  ('qrscanner',  '\uD83D\uDCF7', '二维码扫描',   '扫描二维码与条形码'),
  ('ocrtest',    '\uD83D\uDD0D', '文字扫描',  'OCR——从照片中识别文字'),
  ('classifier', '\uD83E\uDDE0', '图像分类','机器学习物体/植物/动物识别'),
  ('bgremover',  '\u2702\uFE0F', '背景移除',    '移除照片背景（机器学习）'),
  ('qrgen',      '\uD83D\uDD33', '二维码生成',  '文字、URL、WiFi、联系人二维码'),
  // ── Audio & Voice ──
  ('',           '\u2500', '── 音频与语音',  ''),
  ('audiotest',  '\uD83C\uDFB5', '音频播放器',  '后台音频播放'),
  ('voicerecorder','\uD83C\uDFA4', '录音机','录音并播放'),
  ('speechtest', '\uD83C\uDF99\uFE0F', '语音转文字','语音识别'),
  ('soundtools', '\uD83C\uDF9B\uFE0F', '声音工具','麦克风频谱、音效、音量'),
  ('tts',        '\uD83D\uDDE3\uFE0F', '文字转语音', 'TTS 引擎测试'),
  ('mediatest',  '\uD83C\uDFA5', '媒体流',  'getUserMedia 相机 + 麦克风'),
  // ── Location & Sensors ──
  ('',           '\u2500', '── 定位与传感器', ''),
  ('location',   '\uD83D\uDCCD', '定位',      'GPS 定位测试'),
  ('sensor',     '\uD83D\uDCE1', '传感器',        '加速度计与陀螺仪'),
  ('compass',    '\uD83E\uDDED', '指南针',        '朝向、方向、方位角'),
  ('stepcounter','\uD83D\uDEB6', '计步器',   '计步传感器'),
  // ── Device & System ──
  ('',           '\u2500', '── 设备与系统', ''),
  ('device',     '\uD83D\uDCF1', '设备信息',    '电池、型号、振动'),
  ('connectivity','\uD83D\uDCF6', '网络连接',  '网络状态与设备信息'),
  ('flashlight', '\uD83D\uDD26', '手电筒',     '手电、亮度、主题检测'),
  ('wallpaper',  '\uD83C\uDFA8', '壁纸',      '从照片设置设备壁纸'),
  ('screentest', '\uD83D\uDCA1', '屏幕',         '亮度、唤醒锁、触感反馈'),
  ('clipboard',  '\uD83D\uDCCB', '剪贴板',      '剪贴板桥接测试'),
  ('smartnotif', '\uD83D\uDD14', '智能通知','操作、闹钟、应用快捷方式'),
  ('sharemedia', '\uD83D\uDD17', '分享与媒体',  '分享目标、媒体会话控制'),
  ('reminders',  '\u23F0', '提醒事项',         '定时通知、重复、免打扰、角标'),
  ('powertools', '\uD83D\uDD27', '实用工具',  '剪贴板监控、读取下载、文本选择'),
  // ── Communication ──
  ('',           '\u2500', '── 通信',   ''),
  ('contactstest','\uD83D\uDC65', '联系人',     '读取设备联系人'),
  ('smstest',    '\uD83D\uDCAC', '发送短信',      '发送真实短信'),
  ('calendartest','\uD83D\uDCC5', '日历',     '读取和添加日程'),
  ('nfctest',    '\uD83D\uDCE1', 'NFC 扫描',   '读取与写入 NFC 标签'),
  ('blescan',    '\uD83D\uDD35', 'BLE 扫描',  '扫描并连接低功耗蓝牙'),
  ('biotest',    '\uD83D\uDD10', '生物识别',     '指纹/人脸认证'),
  // ── Data & Export ──
  ('',           '\u2500', '── 数据与导出',   ''),
  ('sqlitetest', '\uD83D\uDDC4\uFE0F', 'SQLite',  '完整 SQL 数据库'),
  ('pdftest',    '\uD83D\uDCC4', 'PDF 创建',   '创建与查看 PDF (pdf-lib)'),
  ('printexport','\uD83D\uDDA8\uFE0F', '打印与导出','打印、保存到下载、分享'),
  ('filepicker', '\uD83D\uDCC1', '文件选择',   '从存储中选择文件'),
  ('mediagallery','\uD83D\uDDBC\uFE0F', '媒体库','浏览照片、视频、音乐'),
  ('downloadmgr','\u2B07\uFE0F', '下载器',   '带进度下载文件'),
  ('alarmtest',  '\u23F0', '闹钟',              '关闭后仍会响的闹钟'),
  // ── Network ──
  ('',           '\u2500', '── 网络',         ''),
  ('lanshare',   '\uD83D\uDCE1', '局域网分享',   '通过 WiFi 分享文字与照片'),
  ('wifidirect', '\uD83D\uDCF6', 'WiFi Direct', '无需路由器的点对点分享'),
  ('httpclient', '\uD83C\uDF10', 'HTTP 客户端', '原生 HTTPS + 自签名证书'),
  ('sshclient',  '\uD83D\uDDA5\uFE0F', 'SSH 客户端', '远程终端与 SFTP'),
  ('networkfiles','\uD83D\uDCC2', '网络文件', '浏览 Windows/NAS 共享 (SMB)'),
  ('tcpsocket',  '\uD83D\uDD0C', 'TCP Socket',  '持久的双向连接'),
  ('udpchat',    '\uD83D\uDCE8', 'UDP 聊天',    '通过 UDP 数据报聊天'),
  // ── Bluetooth ──
  ('',           '\u2500', '── 蓝牙',        ''),
  ('btserial',   '\uD83D\uDD35', 'BT 串口',     '蓝牙经典串口终端'),
  // ── Widget & Tasks ──
  ('',           '\u2500', '── 小组件与任务',  ''),
  ('widgetdemo', '\uD83D\uDCF2', '小组件仪表盘', '带统计信息的主屏小组件'),
  ('taskdemo',   '\u23F0', '后台任务',   '定时任务 + 小组件刷新'),
  ('triggerdemo','\u26A1', '触发器',           '在充电/耳机/蓝牙/WiFi 事件时触发操作'),
  // ── Data & Files ──
  ('',           '\u2500', '── 数据与文件',    ''),
  ('bundledemo', '\uD83D\uDCE6', '资源包浏览',  '测试打包的应用文件（数据库、JSON、图片）'),
];
