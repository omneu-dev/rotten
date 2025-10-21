import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const WebViewScreen({super.key, required this.title, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              print('페이지 로딩 시작: $url');
            },
            onPageFinished: (url) {
              print('페이지 로딩 완료: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (error) {
              print('WebView 오류: ${error.description}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                  _errorMessage = error.description;
                });
              }
            },
          ),
        );

      // URL 유효성 검사
      final uri = Uri.tryParse(widget.url);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        _controller.loadRequest(uri);
      } else {
        print('유효하지 않은 URL: ${widget.url}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '유효하지 않은 URL입니다.';
          });
        }
      }
    } catch (e) {
      print('WebView 초기화 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '페이지를 로드할 수 없습니다: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFFF7F7F7)),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: 6,
              ),
              child: Stack(
                children: [
                  // 중앙 텍스트 (절대 중앙 정렬)
                  const Center(
                    child: Text(
                      '로튼 이야기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF363A48),
                        letterSpacing: -0.3,
                        height: 22 / 16,
                      ),
                    ),
                  ),

                  // 좌측 뒤로가기 버튼
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(4),
                        child: Transform.rotate(
                          angle: 1.5708, // -90도 (라디안)
                          child: SvgPicture.asset(
                            'assets/images/arrow_dropdown.svg',
                            width: 24,
                            height: 24,
                            color: const Color(0xFF686C75),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (!_hasError) WebViewWidget(controller: _controller),
          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFBDBDBD),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '페이지를 로드할 수 없습니다',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF676C74),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Color(0xFFBDBDBD),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializeWebView();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          if (_isLoading && !_hasError)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF363A48)),
            ),
        ],
      ),
    );
  }
}
