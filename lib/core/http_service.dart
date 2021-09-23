import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:isolated_worker/isolated_worker.dart';
import 'package:isolated_worker/js_isolated_worker.dart';

/// our js files/scripts
const List<String> _jsScripts = <String>['fetch_function.js'];

/// our `get` function on the `fetch_function.js` file
const String _jsGetFunctionName = 'get';

class HttpService {
  bool _areScriptsImported = false;

  /// A method for getting response from [url]
  ///
  /// using [IsolatedWorker] when running on Dart VM, but
  /// using [JsIsolatedWorker] when running on Dart JS (web).
  ///
  /// Returns a [LinkedHashMap] containing:
  ///   - statusCode [int], reasonPhrase [String], and jsonResponse [LinkedHashMap] -> when success
  ///   - err -> when error
  ///
  /// This should return [LinkedHashMap] since JavaScript object literals are not
  /// recognized by Dart as [Map], but as `LinkedMap`
  Future<LinkedHashMap<dynamic, dynamic>> get(String url) async {
    if (kIsWeb) {
      if (!_areScriptsImported) {
        await JsIsolatedWorker().importScripts(_jsScripts);
        _areScriptsImported = true;
      }
      return await JsIsolatedWorker().run(
        functionName: _jsGetFunctionName,
        arguments: url,
      ) as LinkedHashMap<dynamic, dynamic>;
    }
    return IsolatedWorker().run(_ioGet, url);
  }
}

// io == Dart VM, hence _ioGet
/// A top-level function for getting response from
/// [url] via [IsolatedWorker]
///
/// A top-level function is `required` to run it properly
/// via [IsolatedWorker]
Future<LinkedHashMap<dynamic, dynamic>> _ioGet(String url) async {
  try {
    final http.Response response = await http.get(Uri.parse(url));
    final dynamic jsonResponse = jsonDecode(response.body);
    final LinkedHashMap<String, dynamic> result = LinkedHashMap<String, dynamic>();
    
    result['statusCode'] = response.statusCode;
    result['reasonPhrase'] = response.reasonPhrase;
    result['jsonResponse'] = jsonResponse;
    return result;
  } catch (error) {
    final LinkedHashMap<String, dynamic> err = LinkedHashMap<String, dynamic>();
    err['err'] = error;
    return err;
  }
}
