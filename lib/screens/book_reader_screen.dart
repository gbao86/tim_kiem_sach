import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/loading_indicator.dart';

class BookReaderScreen extends StatefulWidget {
  final String title;
  final String url;

  const BookReaderScreen({Key? key, required this.title, required this.url}) : super(key: key);

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    String cleanUrl = widget.url;
    if (cleanUrl.contains('books.google') && !cleanUrl.contains('output=embed')) {
      cleanUrl += (cleanUrl.contains('?') ? '&' : '?') + 'output=embed';
    }
    if (cleanUrl.startsWith('http://')) {
      cleanUrl = cleanUrl.replaceFirst('http://', 'https://');
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent('Mozilla/5.0 (iPad; CPU OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (!mounted) return;

            final isDark = Theme.of(context).brightness == Brightness.dark;

            // 🚀 BỘ CHẶN QUẢNG CÁO PRO MAX (CSS + TẦM SOÁT JS) 🚀
            String jsInject = '''
              // 1. Bức tường CSS: Chặn quảng cáo tĩnh và các class phổ biến
              var style = document.createElement('style');
              style.innerHTML = 'iframe, ins, .ads, .adsbygoogle, .banner, .ad-container, [id^="div-gpt-ad"], [id^="ads"], [class*="quangcao"], .popup-ad { display: none !important; opacity: 0 !important; pointer-events: none !important; z-index: -9999 !important; }';
              document.head.appendChild(style);
              
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
              document.head.appendChild(meta);

              // 2. Đội tuần tra JS: Quét mỗi 0.5s để đập tan Popup tải ngầm
              setInterval(function() {
                var ads = document.querySelectorAll('iframe, ins, .adsbygoogle, [id^="div-gpt-ad"], [id*="google_ads"]');
                for (var i = 0; i < ads.length; i++) {
                  ads[i].style.display = 'none';
                  ads[i].style.width = '0px';
                  ads[i].style.height = '0px';
                }
                
                // Cố gắng tìm và ẩn các nút "Đóng" (X) ảo hoặc overlay che màn hình
                var overlays = document.querySelectorAll('[style*="z-index: 2147483647"], [style*="z-index: 999999"]');
                for (var j = 0; j < overlays.length; j++) {
                  overlays[j].style.display = 'none';
                }
              }, 500);
            ''';

            if (isDark) {
              jsInject += '''
                var darkStyle = document.createElement('style');
                darkStyle.innerHTML = 'html { filter: invert(95%) hue-rotate(180deg) !important; background: #121212 !important; }';
                document.head.appendChild(darkStyle);
              ''';
            }

            _controller.runJavaScript(jsInject);

            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) setState(() => _isLoading = false);
            debugPrint('Lỗi tải trang: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(cleanUrl));
  }

  void _prevPage() {
    _controller.runJavaScript('''
      window.scrollBy({ top: -window.innerHeight * 0.8, left: -window.innerWidth * 0.8, behavior: 'smooth' });
      var divs = document.querySelectorAll('div');
      for (var i = 0; i < divs.length; i++) {
        var style = window.getComputedStyle(divs[i]);
        if (style.overflowY === 'auto' || style.overflowY === 'scroll' || style.overflowX === 'auto') {
          divs[i].scrollBy({ top: -divs[i].clientHeight * 0.8, left: -divs[i].clientWidth * 0.8, behavior: 'smooth' });
        }
      }
    ''');
  }

  void _nextPage() {
    _controller.runJavaScript('''
      window.scrollBy({ top: window.innerHeight * 0.8, left: window.innerWidth * 0.8, behavior: 'smooth' });
      var divs = document.querySelectorAll('div');
      for (var i = 0; i < divs.length; i++) {
        var style = window.getComputedStyle(divs[i]);
        if (style.overflowY === 'auto' || style.overflowY === 'scroll' || style.overflowX === 'auto') {
          divs[i].scrollBy({ top: divs[i].clientHeight * 0.8, left: divs[i].clientWidth * 0.8, behavior: 'smooth' });
        }
      }
    ''');
  }

  void _scrollToTop() {
    _controller.runJavaScript('''
      window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
      var divs = document.querySelectorAll('div');
      for (var i = 0; i < divs.length; i++) {
        var style = window.getComputedStyle(divs[i]);
        if (style.overflowY === 'auto' || style.overflowY === 'scroll' || style.overflowX === 'auto') {
          divs[i].scrollTo({ top: 0, left: 0, behavior: 'smooth' });
        }
      }
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(color: theme.scaffoldBackgroundColor),
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: theme.scaffoldBackgroundColor,
                child: const Center(
                  child: LoadingIndicator(),
                ),
              ),

            Positioned(
              bottom: 100,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'btn_scroll_top',
                backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 4,
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_upward_rounded),
              ),
            ),

            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTransparentNavButton(
                    context: context,
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Trang trước',
                    onTap: _prevPage,
                    alignment: Alignment.centerLeft,
                  ),
                  _buildTransparentNavButton(
                    context: context,
                    icon: Icons.arrow_forward_ios_rounded,
                    label: 'Trang sau',
                    onTap: _nextPage,
                    alignment: Alignment.centerRight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparentNavButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Alignment alignment,
  }) {
    return Container(
      height: 70,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: alignment,
            children: [
              Positioned(
                left: alignment == Alignment.centerLeft ? 16 : null,
                right: alignment == Alignment.centerRight ? 16 : null,
                child: Icon(icon, color: Colors.white70, size: 28),
              ),
              Center(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}