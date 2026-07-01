import 'package:flutter/material.dart';

import '../../../../core/constants/terms_urls.dart';
import '../../../../core/widgets/common_app_bar.dart';
import 'terms_webview_page.dart';

class OpenSourceCopyrightPage extends StatelessWidget {
  const OpenSourceCopyrightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '오픈소스 및 저작권', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSimpleTile(
            'Flutter 라이선스 보기',
            onTap: () => showLicensePage(
              context: context,
              applicationName: '작은결',
              applicationVersion: '1.0.0',
              applicationLegalese: '© SmallStep',
            ),
          ),
          _buildSimpleTile(
            '저작권/출처 보기',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TermsWebViewPage(
                  title: '저작권/출처',
                  url: TermsUrls.openSourceLicenses,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTile(String title, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
