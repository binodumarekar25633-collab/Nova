import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'project_manager.dart';
import 'voice_helper.dart';

// API key is injected by Codemagic using --dart-define=OPENAI_API_KEY=...
// You can also hardcode for local tests, e.g. const openAIApiKey = "sk-...";
const String openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');

class CodeGenScreen extends StatefulWidget {
  const CodeGenScreen({super.key});

  @override
  State<CodeGenScreen> createState() => _CodeGenScreenState();
}

class _CodeGenScreenState extends State<CodeGenScreen> {
  final TextEditingController _prompt = TextEditingController();
  String generatedCode = "";
  bool isLoading = false;
  String selectedLanguage = "python";
  final VoiceHelper voice = VoiceHelper();

  final List<String> languages = const ["python","java","cpp","javascript","html","dart","csharp"];

  String _extForLang(String lang) {
    switch (lang) {
      case "python": return "py";
      case "java": return "java";
      case "cpp": return "cpp";
      case "javascript": return "js";
      case "html": return "html";
      case "dart": return "dart";
      case "csharp": return "cs";
      default: return "txt";
    }
  }

  Future<void> _generateCode(String prompt) async {
    if (openAIApiKey.isEmpty) {
      setState(() => generatedCode = "ERROR: OPENAI_API_KEY is not set. Configure it in Codemagic or hardcode it.");
      return;
    }
    setState(() => isLoading = true);

    final uri = Uri.parse("https://api.openai.com/v1/completions");
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $openAIApiKey",
    };
    final body = jsonEncode({
      "model": "gpt-3.5-turbo-instruct",
      "prompt": "Write clean, well-commented $selectedLanguage code for: $prompt",
      "max_tokens": 500,
      "temperature": 0.2
    });

    try {
      final res = await http.post(uri, headers: headers, body: body);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => generatedCode = (data['choices'][0]['text'] ?? "").toString().trim());
        // Speak in Hindi if prompt looks Hindi (naive check), else English
        final isHindi = RegExp(r'[\u0900-\u097F]').hasMatch(prompt);
        await voice.speak(isHindi ? "Aapka code taiyār hai." : "Your code is ready.", lang: isHindi ? "hi-IN" : "en-US");
      } else {
        setState(() => generatedCode = "Error ${res.statusCode}: ${res.body}");
        await voice.speak("Sorry, I couldn't generate the code.", lang: "en-US");
      }
    } catch (e) {
      setState(() => generatedCode = "Request failed: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProjectDialog() async {
    if (generatedCode.isEmpty) return;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Save Project"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter file name (without extension)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim().isEmpty ? "nova_code" : controller.text.trim();
              await _saveProject(name);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProject(String name) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = _extForLang(selectedLanguage);
      final file = File("${dir.path}/$name.$ext");
      await file.writeAsString(generatedCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved: ${file.path}")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova • AI Code Assistant"),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: "Speak (Hindi/English)",
            onPressed: () async {
              if (!voice.isListening) {
                // Try Hindi first; user can long press to switch to English in a real app
                await voice.startListening((text) {
                  _prompt.text = text;
                }, localeId: "hi-IN");
              } else {
                await voice.stopListening();
              }
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectManagerScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Language:"),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedLanguage,
                  items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => selectedLanguage = v ?? "python"),
                ),
                const SizedBox(width: 12),
                Text(voice.isListening ? "Listening..." : "Tap mic to speak"),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _prompt,
              decoration: const InputDecoration(
                hintText: "Describe code you want (Hindi/English)...",
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _generateCode(_prompt.text),
                child: const Text("Generate Code"),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: generatedCode.isEmpty
                          ? const Text("Your generated code will appear here...")
                          : HighlightView(
                              generatedCode,
                              language: selectedLanguage,
                              theme: monokaiSublimeTheme,
                              padding: const EdgeInsets.all(12),
                              textStyle: const TextStyle(fontFamily: "monospace", fontSize: 14),
                            ),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: generatedCode));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
                  },
                  child: const Text("Copy"),
                ),
                ElevatedButton(
                  onPressed: _saveProjectDialog,
                  child: const Text("Save"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}