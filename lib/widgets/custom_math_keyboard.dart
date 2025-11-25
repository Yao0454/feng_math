import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';
// ignore: implementation_imports
import 'package:math_keyboard/src/foundation/node.dart';

class CustomMathKeyboard extends StatefulWidget {
  final MathFieldEditingController controller;
  final VoidCallback onSubmit;

  const CustomMathKeyboard({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  State<CustomMathKeyboard> createState() => _CustomMathKeyboardState();
}

class _CustomMathKeyboardState extends State<CustomMathKeyboard> {
  final List<String> _tabLabels = ['基础', '代数', '三角', '微积分', '高级'];
  int _currentTab = 0;

  String _texDSymbol(int order) {
    if (order == 1) return r'\mathrm{d}';
    return '\\mathrm{d}^{${order.toString()}}';
  }

  String _texDOf(String variable, int order) {
    if (order == 1) return '\\mathrm{d}$variable';
    return '\\mathrm{d}${variable}^{${order.toString()}}';
  }

  String _texPartialSymbol(int order) {
    if (order == 1) return r'\partial';
    return '\\partial^{${order.toString()}}';
  }

  String _texPartialOf(String variable, int order) {
    if (order == 1) return '\\partial ${variable}';
    return '\\partial ${variable}^{${order.toString()}}';
  }

  void _insertFunctionWithBraces(String command) {
    widget.controller.addLeaf(command);
    widget.controller.addLeaf('{');
    widget.controller.addLeaf('}');
    widget.controller.goBack();
  }

  void _insertText(String text) => widget.controller.addLeaf(text);

  void _insertFunction(String functionName, List<TeXArg> args) =>
      widget.controller.addFunction(functionName, args);

  void _insertSquare() {
    widget.controller.addFunction('^', [TeXArg.braces]);
    widget.controller.addLeaf('2');
    widget.controller.goNext();
  }

  void _insertPowerTemplate() {
    widget.controller.addFunction('^', [TeXArg.braces]);
  }

  void _insertSqrt() {
    widget.controller.addLeaf(r'\sqrt');
    widget.controller.addLeaf('{');
    widget.controller.addLeaf('}');
    widget.controller.goBack();
  }

  void _insertFractionBlank() {
    final controller = widget.controller;
    final node = controller.currentNode;
    node.removeCursor();

    final cursorPos = node.courserPosition;
    final tail = node.children.sublist(cursorPos);
    node.children.removeRange(cursorPos, node.children.length);

    final frac = TeXFunction(r'\frac', node, [TeXArg.braces, TeXArg.braces]);
    node.addTeX(frac);
    node.children.addAll(tail);

    controller.currentNode = frac.argNodes.first;
    controller.currentNode.courserPosition = 0;
    controller.currentNode.setCursor();
    controller.addLeaf(' ');
    controller.goBack(deleteMode: true);
  }

  void _insertAbsolute() {
    widget.controller.addLeaf(r'\left|');
    widget.controller.addLeaf(r'\right|');
    widget.controller.goBack();
  }

  void _insertIntegralFor(String variable, {String symbol = r'\int'}) {
    widget.controller.addLeaf(symbol);
    widget.controller.addLeaf('{');
    widget.controller.addLeaf('}');
    widget.controller.addLeaf(r'\,');
    widget.controller.addLeaf('d');
    widget.controller.addLeaf(variable);
    widget.controller.goBack();
    widget.controller.goBack();
    widget.controller.goBack();
    widget.controller.goBack();
  }

  void _insertDefiniteIntegral(String variable) {
    widget.controller.addLeaf(r'\int_{a}^{b}');
    widget.controller.addLeaf('{');
    widget.controller.addLeaf('}');
    widget.controller.addLeaf(r'\,');
    widget.controller.addLeaf('d');
    widget.controller.addLeaf(variable);
    widget.controller.goBack();
    widget.controller.goBack();
    widget.controller.goBack();
    widget.controller.goBack();
  }

  void _insertSummation() {
    widget.controller.addLeaf(r'\sum');
    widget.controller.addFunction('_', [TeXArg.braces]);
    widget.controller.goNext();
    widget.controller.addFunction('^', [TeXArg.braces]);
    widget.controller.goNext();
  }

  void _insertProduct() {
    widget.controller.addLeaf(r'\prod');
    widget.controller.addFunction('_', [TeXArg.braces]);
    widget.controller.goNext();
    widget.controller.addFunction('^', [TeXArg.braces]);
    widget.controller.goNext();
  }

  void _insertLimit() {
    widget.controller.addLeaf(r'\lim');
    widget.controller.addFunction('_', [TeXArg.braces]);
    widget.controller.addLeaf(r'\to');
    widget.controller.goBack();
  }

  void _insertDerivativeOperator({String variable = 'x', int order = 1}) {
    widget.controller.addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);
    widget.controller.addLeaf(_texDSymbol(order));
    widget.controller.goNext();
    widget.controller.addLeaf(_texDOf(variable, order));
    widget.controller.goNext();
  }

  void _insertFunctionDerivative({String dependent = 'y', String variable = 'x', int order = 1}) {
    widget.controller.addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);
    widget.controller.addLeaf(order == 1
        ? '\\mathrm{d}$dependent'
        : '\\mathrm{d}^{${order.toString()}}$dependent');
    widget.controller.goNext();
    widget.controller.addLeaf(_texDOf(variable, order));
    widget.controller.goNext();
  }

  void _insertPartialOperator(String variable, {int order = 1}) {
    widget.controller.addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);
    widget.controller.addLeaf(_texPartialSymbol(order));
    widget.controller.goNext();
    widget.controller.addLeaf(_texPartialOf(variable, order));
    widget.controller.goNext();
  }

  void _insertMixedPartial(String first, String second) {
    widget.controller.addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);
    widget.controller.addLeaf(r'\partial^2');
    widget.controller.goNext();
    widget.controller.addLeaf('\\partial ${first} \\partial ${second}');
    widget.controller.goNext();
  }

  void _insertVector(String symbol) {
    widget.controller.addLeaf('\\vec{$symbol}');
  }

  void _insertDot(String symbol, {int order = 1}) {
    widget.controller.addLeaf(order == 1 ? '\\dot{$symbol}' : '\\ddot{$symbol}');
  }

  void _insertPrime(String symbol, {int order = 1}) {
    widget.controller.addLeaf(order == 1 ? "$symbol'" : "$symbol''");
  }

  void _insertMatrixTemplate() {
    widget.controller.addLeaf(r'\begin{bmatrix}a & b \\ c & d\end{bmatrix}');
  }

  void _insertOdeTemplate() {
    widget.controller.addLeaf(r'\frac{dy}{dx} + y = 0');
  }

  void _insertPdeTemplate() {
    widget.controller.addLeaf(r'\frac{\partial u}{\partial t} = k \nabla^2 u');
  }

  void _insertExp(String exponent) {
    widget.controller.addLeaf('e^{$exponent}');
  }

  void _insertComplexExp() {
    widget.controller.addLeaf(r'e^{i\theta}');
  }

  void _insertOperator(String tex) => widget.controller.addLeaf(tex);

  void _backspace() => widget.controller.goBack(deleteMode: true);

  void _clear() => widget.controller.clear();

  void _moveCursorLeft() => widget.controller.goBack();

  void _moveCursorRight() => widget.controller.goNext();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            height: 360,
            child: Column(
              children: [
                _buildTabSelector(),
                const SizedBox(height: 6),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
          _buildControlRow(),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Row(
      children: List.generate(_tabLabels.length, (index) {
        final isSelected = _currentTab == index;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() => _currentTab = index),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isSelected ? Colors.blue : Colors.transparent),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabLabels[index],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildBasicTab();
      case 1:
        return _buildAlgebraTab();
      case 2:
        return _buildTrigTab();
      case 3:
        return _buildCalculusTab();
      case 4:
      default:
        return _buildAdvancedTab();
    }
  }

  Widget _buildTrigTab() {
    return Column(
      children: [
        _buildRow([
          _btn('sin', display: 'sin', customInsert: () => _insertFunctionWithBraces(r'\sin')),
          _btn('cos', display: 'cos', customInsert: () => _insertFunctionWithBraces(r'\cos')),
          _btn('tan', display: 'tan', customInsert: () => _insertFunctionWithBraces(r'\tan')),
          _btn('cot', display: 'cot', customInsert: () => _insertFunctionWithBraces(r'\cot')),
          _btn('sec', display: 'sec', customInsert: () => _insertFunctionWithBraces(r'\sec')),
          _btn('csc', display: 'csc', customInsert: () => _insertFunctionWithBraces(r'\csc')),
        ]),
        _buildRow([
          _btn('arcsin', display: 'sin⁻¹', customInsert: () => _insertFunctionWithBraces(r'\arcsin')),
          _btn('arccos', display: 'cos⁻¹', customInsert: () => _insertFunctionWithBraces(r'\arccos')),
          _btn('arctan', display: 'tan⁻¹', customInsert: () => _insertFunctionWithBraces(r'\arctan')),
          _btn('arccot', display: 'cot⁻¹', customInsert: () => _insertFunctionWithBraces(r'\arccot')),
          _btn('arcsec', display: 'sec⁻¹', customInsert: () => _insertFunctionWithBraces(r'\arcsec')),
          _btn('arccsc', display: 'csc⁻¹', customInsert: () => _insertFunctionWithBraces(r'\arccsc')),
        ]),
        _buildRow([
          _btn('sinh', display: 'sinh', customInsert: () => _insertFunctionWithBraces(r'\sinh')),
          _btn('cosh', display: 'cosh', customInsert: () => _insertFunctionWithBraces(r'\cosh')),
          _btn('tanh', display: 'tanh', customInsert: () => _insertFunctionWithBraces(r'\tanh')),
          _btn('sech', display: 'sech', customInsert: () => _insertFunctionWithBraces(r'\sech')),
          _btn('csch', display: 'csch', customInsert: () => _insertFunctionWithBraces(r'\csch')),
          _btn('coth', display: 'coth', customInsert: () => _insertFunctionWithBraces(r'\coth')),
        ]),
        _buildRow([
          _btn('sin²+cos²=1', display: 'sin²+cos²=1', customInsert: () {
            widget.controller.addLeaf(r'\sin^{2} \theta + \cos^{2} \theta = 1');
          }),
          _btn('1+tan²=sec²', display: '1+tan²=sec²', customInsert: () {
            widget.controller.addLeaf(r'1 + \tan^{2} \theta = \sec^{2} \theta');
          }),
          _btn('1+cot²=csc²', display: '1+cot²=csc²', customInsert: () {
            widget.controller.addLeaf(r'1 + \cot^{2} \theta = \csc^{2} \theta');
          }),
          _btn('sin(α±β)', customInsert: () {
            widget.controller.addLeaf(r'\sin(\alpha \pm \beta) = \sin \alpha \cos \beta \pm \cos \alpha \sin \beta');
          }),
        ]),
        _buildRow([
          _btn('cos(α±β)', customInsert: () {
            widget.controller.addLeaf(r'\cos(\alpha \pm \beta) = \cos \alpha \cos \beta \mp \sin \alpha \sin \beta');
          }),
          _btn('tan(α±β)', customInsert: () {
            widget.controller.addLeaf(r'\tan(\alpha \pm \beta) = \frac{\tan \alpha \pm \tan \beta}{1 \mp \tan \alpha \tan \beta}');
          }),
          _btn('°→rad', display: '°→rad', customInsert: () {
            widget.controller.addLeaf(r'\theta ^{\circ} = \theta \cdot \frac{\pi}{180}');
          }),
          _btn('rad→°', display: 'rad→°', customInsert: () {
            widget.controller.addLeaf(r'\theta_{\text{rad}} = \theta \cdot \frac{180^{\circ}}{\pi}');
          }),
          _btn('θ', customInsert: () => widget.controller.addLeaf(r'\theta')),
          _btn('φ', customInsert: () => widget.controller.addLeaf(r'\phi')),
        ]),
      ],
    );
  }

  Widget _buildBasicTab() {
    return Column(
      children: [
        _buildRow([
          _btn('7'),
          _btn('8'),
          _btn('9'),
          _btn('\\div', display: '÷'),
        ]),
        _buildRow([
          _btn('4'),
          _btn('5'),
          _btn('6'),
          _btn('\\cdot', display: '×'),
        ]),
        _buildRow([
          _btn('1'),
          _btn('2'),
          _btn('3'),
          _btn('-', display: '−'),
        ]),
        _buildRow([
          _btn('0'),
          _btn('.'),
          _btn('=', display: '='),
          _btn('+'),
        ]),
        _buildRow([
          _btn('('),
          _btn(')'),
          _btn('['),
          _btn(']'),
          _btn('{'),
          _btn('}'),
          _btn(','),
        ]),
      ],
    );
  }

  Widget _buildAlgebraTab() {
    return Column(
      children: [
        _buildRow([
          _btn('x'),
          _btn('y'),
          _btn('z'),
          _btn('t'),
          _btn('a'),
          _btn('b'),
        ]),
        _buildRow([
          _btn(r'\\pi', display: 'π'),
          _btn('e', display: 'e'),
          _btn(r'\\theta', display: 'θ'),
          _btn(r'\\phi', display: 'φ'),
          _btn(r'\\infty', display: '∞'),
        ]),
        _buildRow([
          _btn('frac', display: 'a/b', customInsert: _insertFractionBlank),
          _btn('sqrt', display: '√', customInsert: _insertSqrt),
          _btn('square', display: 'x²', customInsert: _insertSquare),
          _btn('^', display: 'xʸ', customInsert: _insertPowerTemplate),
          _btn('|x|', display: '|x|', customInsert: _insertAbsolute),
        ]),
        _buildRow([
          _btn('log', display: 'log', customInsert: () => _insertFunctionWithBraces(r'\log')),
          _btn('ln', display: 'ln', customInsert: () => _insertFunctionWithBraces(r'\ln')),
          _btn('10^x', display: '10ˣ', customInsert: () {
            widget.controller.addLeaf(r'10^{ }');
            widget.controller.goBack();
          }),
          _btn('e^x', display: 'eˣ', customInsert: () => _insertExp('x')),
        ]),
        _buildRow([
          _btn(r'\\vec{v}', display: '→v', customInsert: () => _insertVector('v')),
          _btn(r'\\vec{a}', display: '→a', customInsert: () => _insertVector('a')),
          _btn(r'\\vec{b}', display: '→b', customInsert: () => _insertVector('b')),
          _btn(r'\\approx', display: '≈'),
          _btn(r'\\equiv', display: '≡'),
        ]),
      ],
    );
  }

  Widget _buildCalculusTab() {
    return Column(
      children: [
        _buildRow([
          _btn('∫dx', display: '∫dx', customInsert: () => _insertIntegralFor('x')),
          _btn('∫dy', display: '∫dy', customInsert: () => _insertIntegralFor('y')),
          _btn('∫dz', display: '∫dz', customInsert: () => _insertIntegralFor('z')),
          _btn('∫ab', display: '∫ab', customInsert: () => _insertDefiniteIntegral('x')),
          _btn('∬', display: '∬', customInsert: () => _insertIntegralFor('A', symbol: r'\iint')),
          _btn('∭', display: '∭', customInsert: () => _insertIntegralFor('V', symbol: r'\iiint')),
        ]),
        _buildRow([
          _btn('∮', display: '∮', customInsert: () => _insertIntegralFor('s', symbol: r'\oint')),
          _btn(r'\lim', display: 'lim', customInsert: _insertLimit),
          _btn(r'\sum', display: 'Σ', customInsert: _insertSummation),
          _btn(r'\prod', display: 'Π', customInsert: _insertProduct),
          _btn('dx', customInsert: () => widget.controller.addLeaf(r'\,dx')),
          _btn('dy', customInsert: () => widget.controller.addLeaf(r'\,dy')),
        ]),
        _buildRow([
          _btn('d/dx', customInsert: () => _insertDerivativeOperator()),
          _btn('d²/dx²', customInsert: () => _insertDerivativeOperator(order: 2)),
          _btn('∂/∂x', customInsert: () => _insertPartialOperator('x')),
          _btn('∂/∂y', customInsert: () => _insertPartialOperator('y')),
          _btn('∂²/∂x²', customInsert: () => _insertPartialOperator('x', order: 2)),
        ]),
        _buildRow([
          _btn('∂²/∂xy', customInsert: () => _insertMixedPartial('x', 'y')),
          _btn('∇', display: '∇', customInsert: () => _insertOperator(r'\nabla')),
          _btn('div', display: '∇·', customInsert: () => _insertOperator(r'\nabla\cdot')),
          _btn('curl', display: '∇×', customInsert: () => _insertOperator(r'\nabla\times')),
          _btn('Δ', display: 'Δ', customInsert: () => _insertOperator(r'\Delta')),
        ]),
        _buildRow([
          _btn('∇²', display: '∇²', customInsert: () => _insertOperator(r'\nabla^{2}')),
          _btn('∂f/∂x', customInsert: () {
            widget.controller.addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);
            widget.controller.addLeaf(r'\partial f');
            widget.controller.goNext();
            widget.controller.addLeaf(r'\partial x');
            widget.controller.goNext();
          }),
          _btn('∂f/∂y', customInsert: () {
            widget.controller.addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);
            widget.controller.addLeaf(r'\partial f');
            widget.controller.goNext();
            widget.controller.addLeaf(r'\partial y');
            widget.controller.goNext();
          }),
          _btn('df', customInsert: () => widget.controller.addLeaf(r'\mathrm{d}f')),
          _btn('du', customInsert: () => widget.controller.addLeaf(r'\mathrm{d}u')),
        ]),
      ],
    );
  }

  Widget _buildAdvancedTab() {
    return Column(
      children: [
        _buildRow([
          _btn('dy/dx', customInsert: () => _insertFunctionDerivative()),
          _btn('d²y/dx²', customInsert: () => _insertFunctionDerivative(order: 2)),
          _btn('dy/dt', customInsert: () => _insertFunctionDerivative(variable: 't')),
          _btn('dx/dt', customInsert: () => _insertFunctionDerivative(dependent: 'x', variable: 't')),
          _btn('∂z/∂x', customInsert: () {
            widget.controller.addFunction(r'\frac', [TeXArg.braces, TeXArg.braces]);
            widget.controller.addLeaf(r'\partial z');
            widget.controller.goNext();
            widget.controller.addLeaf(r'\partial x');
            widget.controller.goNext();
          }),
        ]),
        _buildRow([
          _btn("y'", display: "y'", customInsert: () => _insertPrime('y')),
          _btn("y''", display: "y''", customInsert: () => _insertPrime('y', order: 2)),
          _btn('ẏ', display: 'ẏ', customInsert: () => _insertDot('y')),
          _btn('ÿ', display: 'ÿ', customInsert: () => _insertDot('y', order: 2)),
          _btn("f'(x)", customInsert: () => widget.controller.addLeaf("f'(x)")),
        ]),
        _buildRow([
          _btn('ODE', customInsert: _insertOdeTemplate),
          _btn('PDE', customInsert: _insertPdeTemplate),
          _btn('Laplace', customInsert: () => widget.controller.addLeaf(r'\mathcal{L}\{y(t)\}')),
          _btn('Fourier', customInsert: () => widget.controller.addLeaf(r'\mathcal{F}\{f(t)\}')),
          _btn('e^{iθ}', customInsert: _insertComplexExp),
        ]),
        _buildRow([
          _btn('→i', customInsert: () => _insertVector('i')),
          _btn('→j', customInsert: () => _insertVector('j')),
          _btn('→k', customInsert: () => _insertVector('k')),
          _btn('Matrix', customInsert: _insertMatrixTemplate),
          _btn('det', customInsert: () => widget.controller.addLeaf(r'\det')),
        ]),
        _buildRow([
          _btn('sgn', customInsert: () => widget.controller.addLeaf(r'\operatorname{sgn}')),
          _btn('Heaviside', customInsert: () => widget.controller.addLeaf(r'\Theta(x)')),
          _btn('δ', display: 'δ', customInsert: () => widget.controller.addLeaf(r'\delta(x)')),
          _btn('∇²u', customInsert: () => widget.controller.addLeaf(r'\nabla^{2} u')),
          _btn('exp', customInsert: () {
            widget.controller.addLeaf(r'e^{ }');
            widget.controller.goBack();
          }),
        ]),
      ],
    );
  }

  Widget _buildControlRow() {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _controlButton(label: '←', onTap: _moveCursorLeft),
          const SizedBox(width: 6),
          _controlButton(label: '→', onTap: _moveCursorRight),
          const SizedBox(width: 6),
          _controlButton(label: 'DEL', onTap: _backspace, isDestructive: true),
          const SizedBox(width: 6),
          _controlButton(label: 'AC', onTap: _clear, isDestructive: true),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '求解',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> buttons) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons.asMap().entries.map((entry) {
            final index = entry.key;
            final button = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 3,
                  right: index == buttons.length - 1 ? 0 : 3,
                ),
                child: button,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _controlButton({
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: 64,
      child: Material(
        color: isDestructive ? Colors.red[100] : Colors.white,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          canRequestFocus: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDestructive ? Colors.red[700] : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(
    String insertValue, {
    String? display,
    bool isAction = false,
    VoidCallback? onTap,
    bool isFunction = false,
    List<TeXArg>? args,
    VoidCallback? customInsert,
  }) {
    return Material(
      color: isAction ? Colors.orange[100] : Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap ?? () {
          if (customInsert != null) {
            customInsert();
          } else if (isFunction) {
            _insertFunction(insertValue, args ?? []);
          } else {
            _insertText(insertValue);
          }
        },
        borderRadius: BorderRadius.circular(4),
        canRequestFocus: false,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            display ?? insertValue,
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
