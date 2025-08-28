import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({super.key});

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  Future<void> loadProjects() async {
    final dir = await getApplicationDocumentsDirectory();
    final entries = Directory(dir.path).listSync().whereType<File>().toList();
    setState(() => files = entries);
  }

  Future<void> deleteProject(File file) async {
    if (await file.exists()) await file.delete();
    await loadProjects();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project deleted")));
    }
  }

  Future<void> openProject(File file) async {
    final code = await file.readAsString();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectViewerScreen(fileName: file.path.split("/").last, code: code)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Projects")),
      body: files.isEmpty
          ? const Center(child: Text("No saved files yet."))
          : ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, i) {
                final file = files[i] as File;
                final name = file.path.split("/").last;
                return ListTile(
                  title: Text(name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => deleteProject(file),
                  ),
                  onTap: () => openProject(file),
                );
              },
            ),
    );
  }
}

class ProjectViewerScreen extends StatelessWidget {
  final String fileName;
  final String code;
  const ProjectViewerScreen({super.key, required this.fileName, required this.code});

  @override
  Widget build(BuildContext context) {
    // Try to guess language from extension
    String language = "plaintext";
    if (fileName.endsWith(".py")) language = "python";
    else if (fileName.endsWith(".java")) language = "java";
    else if (fileName.endsWith(".cpp")) language = "cpp";
    else if (fileName.endsWith(".js")) language = "javascript";
    else if (fileName.endsWith(".dart")) language = "dart";
    else if (fileName.endsWith(".html")) language = "xml";

    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: HighlightView(
          code,
          language: language,
          theme: monokaiSublimeTheme,
          padding: const EdgeInsets.all(12),
          textStyle: const TextStyle(fontFamily: "monospace", fontSize: 14),
        ),
      ),
    );
  }
}