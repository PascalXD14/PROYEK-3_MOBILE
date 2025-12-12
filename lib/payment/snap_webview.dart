import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../pesanan/pesanan.dart';

class SnapWebView extends StatefulWidget {
  final String url;
  final int userId;

  const SnapWebView({super.key, required this.url, required this.userId});

  @override
  State<SnapWebView> createState() => _SnapWebViewState();
}

class _SnapWebViewState extends State<SnapWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;

            // deteksi pembayaran suses
            if (url.contains("status_code=200") ||
                url.contains("transaction_status=settlement") ||
                url.contains("finish")) {
              Navigator.pop(context);
              Future.microtask(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderListPage(userId: widget.userId),
                  ),
                );
              });

              return NavigationDecision.prevent;
            }

            // deteksi pembayaran gagal
            if (url.contains("status_code=202") ||
                url.contains("deny") ||
                url.contains("expire") ||
                url.contains("cancel")) {
              Navigator.pop(context);

              Future.microtask(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderListPage(userId: widget.userId),
                  ),
                );
              });

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
