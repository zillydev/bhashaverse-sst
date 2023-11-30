import 'package:bhashverse/common/widgets/common_app_bar.dart';
import 'package:bhashverse/localization/localization_keys.dart';
import 'package:bhashverse/presentation/webpage/controller/webpage_controller.dart';
import 'package:bhashverse/routes/app_routes.dart';
import 'package:bhashverse/utils/constants/app_constants.dart';
import 'package:bhashverse/utils/theme/app_text_style.dart';
import 'package:bhashverse/utils/theme/app_theme_provider.dart';
import 'package:bhashverse/utils/api2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class WebpageScreen extends StatefulWidget {
  const WebpageScreen({super.key});

  @override
  State<WebpageScreen> createState() => _WebpageScreenState();
}

class _WebpageScreenState extends State<WebpageScreen> {
  late WebpageController _textController;
  final FocusNode _urlFocusNode = FocusNode();
  late bool isLoading;
  bool isWebPageVisible = false;

  @override
  void initState() {
    _textController = Get.find();
    isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14).w,
              child: Column(
                children: [
                  SizedBox(
                    height: 16.h,
                  ),
                  CommonAppBar(
                    title: link.tr,
                    onBackPress: () => Get.back(),
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                  Container(
                    margin: const EdgeInsets.all(14).w,
                    height: 120.h,
                    decoration: BoxDecoration(
                        color: context.appTheme.normalTextFieldColor,
                        borderRadius: const BorderRadius.all(
                            Radius.circular(textFieldRadius)),
                        border: Border.all(
                            color: context.appTheme.disabledBGColor)),
                    child: Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 16.w),
                        child: _buildUrlInputTextField()),
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                  ElevatedButton(
                      onPressed: _pasteFromClipboard,
                      child: const Text("Paste")),
                  SizedBox(
                    height: 8.h,
                  ),
                  ElevatedButton(
                      onPressed: _generateWebPage,
                      child: const Text("Generate Web Page")),
                  SizedBox(
                    height: 12.h,
                  ),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  SizedBox(
                    height: 10.h,
                  ),
                  if (isLoading)
                    const Text(
                      "Generating web page",
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputTextField() {
    return TextField(
      controller: _textController.urlController,
      focusNode: _urlFocusNode,
      style: regular18Primary(context),
      maxLines: null,
      expands: false,
      maxLength: textCharMaxLength,
      autocorrect: false,
      decoration: InputDecoration(
          hintText: "Write or paste the url here ...",
          hintStyle: regular18Primary(context)
              .copyWith(color: context.appTheme.hintTextColor),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          counterText: ''),
    );
  }

  void _pasteFromClipboard() async {
    ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null) {
      setState(() {
        _textController.urlController.text = clipboardData.text ?? '';
      });
    }
  }

  void _generateWebPage() async {
    // String url = _textController.urlController.text;
    // if (url.isNotEmpty) {
    setState(() {
      isLoading = true;
    });
    String result = await getHtmlString("https://example.com");
    setState(() {
      isLoading = false;
    });
    Get.toNamed(AppRoutes.webViewRoute, arguments: result);
    // }
  }

  /* Future<String> getHtmlString(String url) async {
    final params = {'url': url};
    const String serverUrl = 'http://192.168.187.98:3000/translate';
    try {
      final request = http.Request(
        'GET',
        Uri.parse(serverUrl),
      )..headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode(params);
      final response = await request.send();

      if (response.statusCode == 200) {
        return response.stream.bytesToString();
      } else {
        print("Not able to fetch");
      }
    } catch (e) {
      print(e);
    }
    return "";
  } */

  Future<String> getHtmlString(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final bodyElement = document.body;

      Map<String, List<dom.Element>> map = {};
      mapNodesAndText(bodyElement!, map);

      var translationFutures = <Future>[];

      for (var entry in map.entries) {
        var text = entry.key;
        var nodes = entry.value;
        var translationFuture = translate(text, "en", "hi").then((translated) {
          print(translated);
          for (var element in nodes) {
            element.text = translated;
          }
        });
        translationFutures.add(translationFuture);
      }

      await Future.wait(translationFutures);

      return bodyElement.outerHtml;
    }
    return "";
  }

  void mapNodesAndText(
      dom.Element element, Map<String, List<dom.Element>> map) {
    element.text.trim().replaceAll("\n", "");
    const ignoreNodes = ["SCRIPT", "STYLE"];
    bool nodeExists = false;
    for (var node in element.nodes) {
      if (node is dom.Element) {
        nodeExists = true;
      }
    }
    if (!nodeExists &&
        !ignoreNodes.contains(element.localName?.toUpperCase())) {
      print("${element.localName},  $nodeExists");
      var text = element.text.trim();
      print(text);
      if (map.containsKey(text)) {
        map[text]!.add(element);
      } else {
        map[text] = [element];
      }
    } else if (element.nodeType == dom.Node.ELEMENT_NODE &&
        !ignoreNodes.contains(element.localName)) {
      // print("here");
      for (var element in element.children) {
        // print(element.nodeType);
        mapNodesAndText(element, map);
      }
    }
  }
}
