import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Calculadora RPN'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  String display = '0';
  Tipo ultimoTipo = Tipo.enter;
  List<Decimal> cache = [];
  var historicoCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: limparHistorico,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Expanded(
              child: TextField(
                maxLines: 88,
                readOnly: true,
                controller: historicoCtrl,
              ),
            ),
            Text(
              display,
              style: const TextStyle(fontSize: 30.0),
            ),
            Row(
              children: <Widget>[
                btnNumero(7),
                btnNumero(8),
                btnNumero(9),
                btnOperador(Operador.soma, '+'),
              ],
            ),
            Row(
              children: <Widget>[
                btnNumero(4),
                btnNumero(5),
                btnNumero(6),
                btnOperador(Operador.subtr, '-'),
              ],
            ),
            Row(
              children: <Widget>[
                btnNumero(1),
                btnNumero(2),
                btnNumero(3),
                btnOperador(Operador.multip, '*'),
              ],
            ),
            Row(
              children: <Widget>[
                btnNumero(0),
                Botao('.', inserePonto),
                Botao('Enter', enter),
                btnOperador(Operador.divisao, '/'),
              ],
            ),
            Row(
              children: <Widget>[
                Botao('ABS', abs),
                Botao('<', backspace),
                Botao('C', clear),
                Botao('CA', clearAll),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget btnNumero(int numero) {
    return Botao(numero.toString(), () => insereNumero(numero));
  }

  Widget btnOperador(Operador operador, String label) {
    return Botao(label, () => insereOperador(operador));
  }

  void insereDisplay(String s) {
    if (display == '0') {
      defineDisplay(s);
    } else {
      setState(() => display += s);
    }
    
  }

  void defineDisplay(String s) {
    setState(() => display = s);
  }

  void insereNumero(int numero) {
    if (ultimoTipo == Tipo.operador) {
      insereNoCache();
      defineDisplay(numero.toString());
    } else if (ultimoTipo == Tipo.enter) {
      defineDisplay(numero.toString());
    } else if (ultimoTipo == Tipo.numero) {
      insereDisplay(numero.toString());
    }
    ultimoTipo = Tipo.numero;
  }

  void insereOperador(Operador operador) {
    if (cache.isEmpty) {
      return;
    }
    if (operador == Operador.soma) {
      soma();
    } else if(operador == Operador.subtr) {
      subtr();
    } else if(operador == Operador.multip) {
      multip();
    } else if(operador == Operador.divisao) {
      if (display == '0') {
        return;
      }
      divisao();
    }
    ultimoTipo = Tipo.operador;
  }

  void inserePonto() {
    if (ultimoTipo == Tipo.enter || display == '0') {
      defineDisplay('0.');
      ultimoTipo = Tipo.numero;
    } else if (ultimoTipo == Tipo.operador) {
      insereNoCache();
      defineDisplay('0.');
      ultimoTipo = Tipo.numero;
    } else if (ultimoTipo == Tipo.numero && !display.contains('.')) {
      insereDisplay('.');
    }
  }
  
  Decimal getValorDisplay() {
    return Decimal.parse(display);
  }
  
  void enter() {
    insereNoCache();
    ultimoTipo = Tipo.enter;
  }
  
  void backspace() {
    if (display == '0' || RegExp(r'^\-\d$').hasMatch(display)) {
      clear();
    }else if (display.length > 1) {
      defineDisplay(display.substring(0, display.length - 1));
    } else {
      clear();
    }
    ultimoTipo = Tipo.numero;
  }
  
  void clear() {
    defineDisplay('0');
    ultimoTipo = Tipo.numero;
  }
  
  void clearAll() {
    clear();
    clearCache();
    ultimoTipo = Tipo.enter;
  }
  
  void removeCacheItem() {
    setState(() => cache.removeAt(0));
  }
  
  void insereNoCache() {
    setState(() => cache.insert(0, getValorDisplay()));
  }
  
  void clearCache() {
    setState(cache.clear);
  }
  
  void soma() {
    final soma = cache[0] + getValorDisplay();
    insereHistorico('${cache[0]} + ${parenteses(getValorDisplay())} = $soma');
    defineDisplay(soma.toString());
    removeCacheItem();
  }
  
  void subtr() {
    final subtr = cache[0] - (getValorDisplay());
    insereHistorico('${cache[0]} - ${parenteses(getValorDisplay())} = $subtr');
    defineDisplay(subtr.toString());
    removeCacheItem();
  }
  
  void multip() {
    final multip = cache[0] * getValorDisplay();
    insereHistorico('${cache[0]} * ${parenteses(getValorDisplay())} = $multip');
    defineDisplay(multip.toString());
    removeCacheItem();
  }
  
  void divisao() {
    var precisao = 10;
    final divisao = cache[0] / getValorDisplay();
    insereHistorico('${cache[0]} / ${parenteses(getValorDisplay())} = $divisao');
    final divisaoComPresicaoAjustada = divisao
        .toDecimal(scaleOnInfinitePrecision: precisao)
        .toStringAsFixed(precisao);
    final result = Decimal.parse(divisaoComPresicaoAjustada);
    defineDisplay(result.toString());
    removeCacheItem();
  }
  
  void abs() {
    if (display == '0' || display == '0,') {
      return;
    }
    if (display.contains('-')) {
      defineDisplay(display.substring(1));
    } else {
      defineDisplay('-$display');
    }
    ultimoTipo = Tipo.numero;
  }
  
  void insereHistorico(String str) {
    setState(() => historicoCtrl.text = '$str\n${historicoCtrl.text}');
  }
  
  void limparHistorico() {
    setState(() => historicoCtrl.text = '');
  }
  
  String parenteses(Decimal number) {
    if (number < Decimal.zero) {
      return '($number)';
    }
    return number.toString();
  }
}

class Botao extends StatelessWidget {
  final String label;
  final void Function() callback;

  const Botao(this.label, this.callback);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4.0), // Define a margem aqui
        child: ElevatedButton(
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            side: const BorderSide(
              width: 1,
              color: Colors.grey,
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 0.0), // Define o padding aqui
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 20.0),
          ),
        ),
      ),
    );
  }
}

enum Tipo { numero, operador, enter }

enum Operador { soma, subtr, divisao, multip, enter }