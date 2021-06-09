/*
 * Copyright 2007 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'parsed_result.dart';
import 'parsed_result_type.dart';
import 'result_parser.dart';
import 'uriresult_parser.dart';

/// A simple result type encapsulating a URI that has no further interpretation.
///
/// @author Sean Owen
class URIParsedResult extends ParsedResult {
  final String _uri;
  final String? _title;

  URIParsedResult(String uri, this._title) : _uri = _massageURI(uri),super(ParsedResultType.URI);

  String getURI() {
    return _uri;
  }

  String? getTitle() {
    return _title;
  }

  /// @return true if the URI contains suspicious patterns that may suggest it intends to
  ///  mislead the user about its true nature
  /// @deprecated see {@link URIResultParser#isPossiblyMaliciousURI(String)}
  @deprecated
  bool isPossiblyMaliciousURI() {
    return URIResultParser.isPossiblyMaliciousURI(_uri);
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppend(_title, result);
    ParsedResult.maybeAppend(_uri, result);
    return result.toString();
  }

  /// Transforms a string that represents a URI into something more proper, by adding or canonicalizing
  /// the protocol.
  static String _massageURI(String uri) {
    uri = uri.trim();
    int protocolEnd = uri.indexOf(':');
    if (protocolEnd < 0 || _isColonFollowedByPortNumber(uri, protocolEnd)) {
      // No protocol, or found a colon, but it looks like it is after the host, so the protocol is still missing,
      // so assume http
      uri = "http://" + uri;
    }
    return uri;
  }

  static bool _isColonFollowedByPortNumber(String uri, int protocolEnd) {
    int start = protocolEnd + 1;
    int nextSlash = uri.indexOf('/', start);
    if (nextSlash < 0) {
      nextSlash = uri.length;
    }
    return ResultParser.isSubstringOfDigits(uri, start, nextSlash - start);
  }
}
