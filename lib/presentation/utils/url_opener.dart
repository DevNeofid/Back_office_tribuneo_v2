// Ouverture d'un lien externe : implémentation web, ou sans effet hors web
// (tests sur la VM, où `package:web` n'est pas disponible).
export 'url_opener_stub.dart'
    if (dart.library.js_interop) 'url_opener_web.dart';
