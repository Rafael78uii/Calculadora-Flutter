import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  // Estado principal do tema: false = Escuro (Dark), true = Claro (Light)
  bool _isLightTheme = false;

  @override
  Widget build(BuildContext context) {
    // Definimos as cores exatas para cada modo
    final bgColor = _isLightTheme ? const Color(0xFFF1F3F4) : const Color(0xFF17171C);
    final btnBgColor = _isLightTheme ? const Color(0xFFFFFFFF) : const Color(0xFF2E2F38);
    final topFuncBgColor = _isLightTheme ? const Color(0xFFDCDCE0) : const Color(0xFF4E505F);
    const operatorBgColor = Color(0xFF4B5EFC);
    final textColor = _isLightTheme ? Colors.black : Colors.white;
    final secondaryTextColor = _isLightTheme ? Colors.grey[600]! : Colors.grey[500]!;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculadora',
      home: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: CalculatorMainView(
            isLightTheme: _isLightTheme,
            bgColor: bgColor,
            btnBgColor: btnBgColor,
            topFuncBgColor: topFuncBgColor,
            operatorBgColor: operatorBgColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            onThemeToggle: () {
              setState(() {
                _isLightTheme = !_isLightTheme;
              });
            },
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// VISÃO PRINCIPAL DA CALCULADORA
// -------------------------------------------------------------
class CalculatorMainView extends StatefulWidget {
  final bool isLightTheme;
  final Color bgColor;
  final Color btnBgColor;
  final Color topFuncBgColor;
  final Color operatorBgColor;
  final Color textColor;
  final Color secondaryTextColor;
  final VoidCallback onThemeToggle;

  const CalculatorMainView({
    super.key,
    required this.isLightTheme,
    required this.bgColor,
    required this.btnBgColor,
    required this.topFuncBgColor,
    required this.operatorBgColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onThemeToggle,
  });

  @override
  State<CalculatorMainView> createState() => _CalculatorMainViewState();
}

class _CalculatorMainViewState extends State<CalculatorMainView> {
  String _expression = '';
  String _result = '0';
  double? _firstNum;
  String? _operator;
  bool _shouldResetDisplay = false;

  final List<HistoryItem> _history = [];

  void _onBtnTap(String text) {
    HapticFeedback.lightImpact();
    setState(() {
      if (text == 'C') {
        _expression = '';
        _result = '0';
        _firstNum = null;
        _operator = null;
        _shouldResetDisplay = false;
      } else if (text == '⌫') {
        if (_result.length > 1) {
          _result = _result.substring(0, _result.length - 1);
        } else {
          _result = '0';
        }
      } else if (text == '+/-') {
        if (_result != '0') {
          _result = _result.startsWith('-') ? _result.substring(1) : '-$_result';
        }
      } else if (text == '%') {
        double val = double.tryParse(_result) ?? 0;
        _result = _formatResult(val / 100);
      } else if (['÷', '×', '-', '+'].contains(text)) {
        _firstNum = double.tryParse(_result);
        _operator = text;
        _expression = '$_result $text ';
        _shouldResetDisplay = true;
      } else if (text == '=') {
        if (_firstNum != null && _operator != null) {
          double secondNum = double.tryParse(_result) ?? 0;
          String fullExpr = '$_firstNum $_operator $secondNum';
          double res = 0;
          switch (_operator) {
            case '÷':
              res = secondNum != 0 ? _firstNum! / secondNum : 0;
              break;
            case '×':
              res = _firstNum! * secondNum;
              break;
            case '-':
              res = _firstNum! - secondNum;
              break;
            case '+':
              res = _firstNum! + secondNum;
              break;
          }
          String formattedRes = _formatResult(res);
          _history.insert(0, HistoryItem(expression: fullExpr, result: formattedRes));

          _expression = fullExpr;
          _result = formattedRes;
          _firstNum = null;
          _operator = null;
          _shouldResetDisplay = true;
        }
      } else {
        if (_shouldResetDisplay) {
          _result = text == '.' ? '0.' : text;
          _shouldResetDisplay = false;
        } else {
          if (text == '.' && _result.contains('.')) return;
          _result = (_result == '0' && text != '.') ? text : _result + text;
        }
      }
    });
  }

  String _formatResult(double val) {
    if (val % 1 == 0) return val.toInt().toString();
    return val.toString();
  }

  void _openHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Histórico',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
                      if (_history.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _history.clear();
                            });
                            setModalState(() {});
                          },
                        ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _history.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum cálculo recente',
                              style: TextStyle(
                                color: widget.secondaryTextColor,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              return ListTile(
                                title: Text(
                                  item.expression,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: widget.secondaryTextColor,
                                  ),
                                ),
                                subtitle: Text(
                                  '= ${item.result}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: widget.textColor,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    _result = item.result;
                                    _shouldResetDisplay = true;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Barra Superior: Ícone de Histórico e Chave do Tema Sol/Lua
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.history_rounded,
                  color: widget.textColor,
                  size: 28,
                ),
                onPressed: _openHistoryModal,
              ),
              // Interruptor do Tema Sol/Lua
              ThemeToggleButton(
                isLight: widget.isLightTheme,
                onTap: widget.onThemeToggle,
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Display de Resultados
        Expanded(
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 100) {
                _openHistoryModal();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _expression,
                    style: TextStyle(
                      fontSize: 32,
                      color: widget.secondaryTextColor,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    alignment: Alignment.centerRight,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _result,
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w400,
                        color: widget.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Teclado da Calculadora
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildRow(['C', '+/-', '%', '÷']),
              const SizedBox(height: 14),
              _buildRow(['7', '8', '9', '×']),
              const SizedBox(height: 14),
              _buildRow(['4', '5', '6', '-']),
              const SizedBox(height: 14),
              _buildRow(['1', '2', '3', '+']),
              const SizedBox(height: 14),
              _buildRow(['.', '0', '⌫', '=']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> texts) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: texts.map((text) {
        bool isOperator = ['÷', '×', '-', '+', '='].contains(text);
        bool isTopFunc = ['C', '+/-', '%'].contains(text);

        Color bg = isOperator
            ? widget.operatorBgColor
            : (isTopFunc ? widget.topFuncBgColor : widget.btnBgColor);
        Color txtColor = isOperator ? Colors.white : widget.textColor;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: CalcButton(
                text: text,
                backgroundColor: bg,
                textColor: txtColor,
                onTap: () => _onBtnTap(text),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// -------------------------------------------------------------
// CHAVE DE TEMA (SOL E LUA)
// -------------------------------------------------------------
class ThemeToggleButton extends StatelessWidget {
  final bool isLight;
  final VoidCallback onTap;

  const ThemeToggleButton({
    super.key,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 76,
        height: 38,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFDCDCE0) : const Color(0xFF2E2F38),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ícone do Sol (Visível / Ativo quando isLight = true)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wb_sunny_rounded,
                size: 18,
                color: isLight ? const Color(0xFF4B5EFC) : Colors.grey[600],
              ),
            ),
            // Ícone da Lua (Visível / Ativo quando isLight = false)
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: !isLight ? const Color(0xFF4E505F) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nightlight_round,
                size: 18,
                color: !isLight ? Colors.white : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// BOTÃO DA CALCULADORA COM EFEITO DE ENCOLHIMENTO
// -------------------------------------------------------------
class CalcButton extends StatefulWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const CalcButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 26,
                color: widget.textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryItem {
  final String expression;
  final String result;
  HistoryItem({required this.expression, required this.result});
}