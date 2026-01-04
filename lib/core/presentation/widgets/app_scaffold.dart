import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool safeTop;
  final bool safeBottom;
  final EdgeInsetsGeometry padding;
  final bool dismissKeyboardOnTap;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.centerTitle = true,
    this.safeTop = true,
    this.safeBottom = true,
    this.padding = const EdgeInsets.all(20),
    this.dismissKeyboardOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      top: safeTop,
      bottom: safeBottom,
      child: Padding(padding: padding, child: body),
    );

    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
        title: Text(title!),
        centerTitle: centerTitle,
        actions: actions,
      ),
      body: dismissKeyboardOnTap
          ? GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: content,
      )
          : content,
    );
  }
}
