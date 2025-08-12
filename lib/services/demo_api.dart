class DemoApi {
  static Future<String> chat(String input) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return "Demo agent: got ‘$input’. In Step 2 I’ll route to Claude + ChatGPT and start scaffolding.";
  }
}
