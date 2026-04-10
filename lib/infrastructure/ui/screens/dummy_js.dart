// Este archivo solo sirve para que el compilador de Android
// no falle al encontrar referencias a dart:js en la Web.
class JsContext {
  void callMethod(String method, List args) {}
}

final context = JsContext();
