/*
 * Copyright 2008 ZXing authors
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

import '../../result.dart';
import 'abstract_do_co_mo_result_parser.dart';
import 'address_book_parsed_result.dart';
import 'result_parser.dart';

/// Implements the "BIZCARD" address book entry format, though this has been
/// largely reverse-engineered from examples observed in the wild -- still
/// looking for a definitive reference.
///
/// @author Sean Owen
class BizcardResultParser extends AbstractDoCoMoResultParser {

  // Yes, we extend AbstractDoCoMoResultParser since the format is very much
  // like the DoCoMo MECARD format, but this is not technically one of
  // DoCoMo's proposed formats

  @override
  AddressBookParsedResult? parse(Result result) {
    String rawText = ResultParser.getMassagedText(result);
    if (!rawText.startsWith("BIZCARD:")) {
      return null;
    }
    String? firstName = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("N:", rawText, true);
    String? lastName = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("X:", rawText, true);
    String? fullName = _buildName(firstName, lastName);
    String? title = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("T:", rawText, true);
    String? org = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("C:", rawText, true);
    List<String>? addresses = AbstractDoCoMoResultParser.matchDoCoMoPrefixedField("A:", rawText);
    String? phoneNumber1 = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("B:", rawText, true);
    String? phoneNumber2 = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("M:", rawText, true);
    String? phoneNumber3 = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("F:", rawText, true);
    String? email = AbstractDoCoMoResultParser.matchSingleDoCoMoPrefixedField("E:", rawText, true);

    return AddressBookParsedResult(ResultParser.maybeWrap(fullName),
                                       null,
                                       null,
                                       _buildPhoneNumbers(phoneNumber1, phoneNumber2, phoneNumber3),
                                       null,
        ResultParser.maybeWrap(email),
                                       null,
                                       null,
                                       null,
                                       addresses,
                                       null,
                                       org,
                                       null,
                                       title,
                                       null,
                                       null);
  }

  static List<String>? _buildPhoneNumbers(String? number1,
                                            String? number2,
                                            String? number3) {
    List<String> numbers = [];
    if (number1 != null) {
      numbers.add(number1);
    }
    if (number2 != null) {
      numbers.add(number2);
    }
    if (number3 != null) {
      numbers.add(number3);
    }
    int size = numbers.length;
    if (size == 0) {
      return null;
    }
    return numbers.toList();
  }

  static String? _buildName(String? firstName, String? lastName) {
    if (firstName == null) {
      return lastName;
    } else {
      return lastName == null ? firstName : firstName + ' ' + lastName;
    }
  }

}
