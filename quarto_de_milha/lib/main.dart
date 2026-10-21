import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  // URLs sem `#` no web: `/acesso` e `/baias` funcionam como endereço direto.
  // O Worker já serve o index.html para qualquer rota (not_found_handling:
  // single-page-application) e o app resolve o caminho.
  if (kIsWeb) usePathUrlStrategy();
  runApp(const QuartoDeMilhaApp());
}
