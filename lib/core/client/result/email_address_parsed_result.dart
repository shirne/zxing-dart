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

/**
 * Represents a parsed result that encodes an email message including recipients, subject
 * and body text.
 *
 * @author Sean Owen
 */
class EmailAddressParsedResult extends ParsedResult {
  final List<String>? tos;
  final List<String>? ccs;
  final List<String>? bccs;
  final String? subject;
  final String? body;

  EmailAddressParsedResult(
      dynamic tos, [this.ccs, this.bccs, this.subject, this.body])
      : this.tos = tos is String ? [tos] : tos as List<String>,
        super(ParsedResultType.EMAIL_ADDRESS);

  /**
   * @return first elements of {@link #getTos()} or {@code null} if none
   * @deprecated use {@link #getTos()}
   */
  @deprecated
  String? getEmailAddress() {
    return tos == null || tos!.length == 0 ? null : tos![0];
  }

  List<String>? getTos() {
    return tos;
  }

  List<String>? getCCs() {
    return ccs;
  }

  List<String>? getBCCs() {
    return bccs;
  }

  String? getSubject() {
    return subject;
  }

  String? getBody() {
    return body;
  }

  /**
   * @return "mailto:"
   * @deprecated without replacement
   */
  @deprecated
  String getMailtoURI() {
    return "mailto:";
  }

  @override
  String getDisplayResult() {
    StringBuffer result = new StringBuffer(30);
    ParsedResult.maybeAppendList(tos, result);
    ParsedResult.maybeAppendList(ccs, result);
    ParsedResult.maybeAppendList(bccs, result);
    ParsedResult.maybeAppend(subject, result);
    ParsedResult.maybeAppend(body, result);
    return result.toString();
  }
}
