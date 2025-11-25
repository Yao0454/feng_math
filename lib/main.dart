import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:http/http.dart' as http;
import 'package:math_keyboard/math_keyboard.dart';
import 'widgets/custom_math_keyboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Solver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 33, 87, 131)),
        useMaterial3: true,
      ),
      home: const MathSolverPage(),
    );
  }
}

class MathSolverPage extends StatefulWidget {
  const MathSolverPage({super.key});

  @override
  State<MathSolverPage> createState() => _MathSolverPageState();
}

class _MathSolverPageState extends State<MathSolverPage> {
  // 使用 MathFieldEditingController 替代 TextEditingController
  final MathFieldEditingController _mathController = MathFieldEditingController();
  
  // FocusNode to manage focus for the input field
  final FocusNode _focusNode = FocusNode();
  bool _showKeyboard = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showKeyboard = _focusNode.hasFocus;
      });
    });
  }

  // Store backend result
  String _resultLatex = '';
  List<String> _steps = [];
  bool _isLoading = false;
  String? _errorMessage;

  String get _backendUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/solve';
    }
    return 'http://127.0.0.1:8000/solve';
  }

  Future<void> _solveMath() async {
    // 获取输入的 LaTeX 字符串
    final String inputLatex = _mathController.currentEditingValue();

    if (inputLatex.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入数学公式')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultLatex = '';
      _steps = [];
    });

    try {
      print('Sending LaTeX to $_backendUrl: $inputLatex');
      
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latex': inputLatex}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resultLatex = data['result'];
          if (data['steps'] != null) {
            _steps = List<String>.from(data['steps']);
          }
        });
      } else {
        setState(() {
          try {
            final errorData = jsonDecode(response.body);
            _errorMessage = '计算错误: ${errorData['detail']}';
          } catch (_) {
            _errorMessage = '服务器错误: ${response.statusCode}';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '连接失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mathController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高等数学解题器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GestureDetector(
        onTap: () => _focusNode.unfocus(),
        child: Column(
          children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '输入公式:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Input Display Area - 使用 MathField
                  GestureDetector(
                    onTap: () {
                      if (!_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: Listener(
                      onPointerDown: (_) {
                        if (!_focusNode.hasFocus) {
                          _focusNode.requestFocus();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MathField(
                          controller: _mathController,
                          focusNode: _focusNode,
                          keyboardType: MathKeyboardType.expression,
                          // Disable the default math keyboard since we are using a custom one
                          opensKeyboard: false,
                          variables: const ['x', 'y', 'z', 't', 'a', 'b'],
                          decoration: const InputDecoration(
                            hintText: '点击此处输入...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (value) => _solveMath(),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    '计算结果:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.red.shade100,
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  // Result Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : _resultLatex.isEmpty
                            ? const Center(
                                child: Text(
                                  '等待输入...',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              )
                            : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '最终结果:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Math.tex(
                                    _resultLatex,
                                    textStyle: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              if (_steps.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                const Divider(),
                                const Text(
                                  '计算步骤:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                                const SizedBox(height: 10),
                                ..._steps.map((step) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Math.tex(
                                      step,
                                      textStyle: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )).toList(),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Custom Keyboard at the bottom
          if (_showKeyboard)
            CustomMathKeyboard(
              controller: _mathController,
              onSubmit: _solveMath,
            ),
        ],
      ),
    ));
  }
}