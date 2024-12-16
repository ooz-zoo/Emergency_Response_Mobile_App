// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
//
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
//
// class WebViewPage extends StatefulWidget {
//   final String url;
//
//   WebViewPage({required this.url});
//
//   @override
//   _WebViewPageState createState() => _WebViewPageState();
// }
//
// class _WebViewPageState extends State<WebViewPage> {
//   bool isLoading = true; // For loading indicator
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('WebView'),
//       ),
//       body: Stack(
//         children: [
//           WebView(
//             initialUrl: widget.url,
//             javascriptMode: JavascriptMode.unrestricted,
//             onPageFinished: (_) {
//               setState(() {
//                 isLoading = false;
//               });
//             },
//           ),
//           if (isLoading)
//             Center(
//               child: CircularProgressIndicator(),
//             ),
//         ],
//       ),
//     );
//   }
// }
