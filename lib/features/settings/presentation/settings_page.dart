import 'package:flutter/material.dart';

import '../application/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0014),
          appBar: AppBar(
            title: const Text('媒体库设置'),
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: <Widget>[
                    const Text(
                      '配置扫描目录后，后续点歌页会基于这个目录建立扫描范围。取消目录选择后会回到这个设置页。',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F2FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            '扫描目录',
                            style: TextStyle(
                              color: Color(0xFF1D1230),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            controller.currentDirectoryPath ?? '当前还没有配置扫描目录。',
                            style: const TextStyle(
                              color: Color(0xFF6B5D7C),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: controller.isPickingDirectory
                          ? null
                          : () async {
                              final String? directory = await controller
                                  .pickDirectory();
                              if (!context.mounted || directory == null) {
                                return;
                              }
                              Navigator.of(context).pop(directory);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6E67),
                      ),
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(
                        controller.isPickingDirectory ? '选择中' : '选择目录',
                      ),
                    ),
                    if (controller.errorMessage != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          controller.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF9C2F2F),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
