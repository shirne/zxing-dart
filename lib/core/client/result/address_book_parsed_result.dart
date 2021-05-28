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
 * Represents a parsed result that encodes contact information, like that in an address book
 * entry.
 *
 * @author Sean Owen
 */
class AddressBookParsedResult extends ParsedResult {
  final List<String>? names;
  final List<String>? nicknames;
  final String? pronunciation;
  final List<String>? phoneNumbers;
  final List<String>? phoneTypes;
  final List<String>? emails;
  final List<String>? emailTypes;
  final String? instantMessenger;
  final String? note;
  final List<String>? addresses;
  final List<String>? addressTypes;
  final String? org;
  final String? birthday;
  final String? title;
  final List<String>? urls;
  final List<String>? geo;

  AddressBookParsedResult.quick(
      List<String>? names,
      List<String>? phoneNumbers,
      List<String>? phoneTypes,
      List<String>? emails,
      List<String>? emailTypes,
      List<String>? addresses,
      List<String>? addressTypes)
      : this(names, null, null, phoneNumbers, phoneTypes, emails, emailTypes,
            null, null, addresses, addressTypes, null, null, null, null, null);

  AddressBookParsedResult(
      this.names,
      this.nicknames,
      this.pronunciation,
      this.phoneNumbers,
      this.phoneTypes,
      this.emails,
      this.emailTypes,
      this.instantMessenger,
      this.note,
      this.addresses,
      this.addressTypes,
      this.org,
      this.birthday,
      this.title,
      this.urls,
      this.geo)
      : super(ParsedResultType.ADDRESSBOOK) {
    if (phoneNumbers != null &&
        phoneTypes != null &&
        phoneNumbers!.length != phoneTypes!.length) {
      throw Exception("Phone numbers and types lengths differ");
    }
    if (emails != null &&
        emailTypes != null &&
        emails!.length != emailTypes!.length) {
      throw Exception("Emails and types lengths differ");
    }
    if (addresses != null &&
        addressTypes != null &&
        addresses!.length != addressTypes!.length) {
      throw Exception("Addresses and types lengths differ");
    }
  }

  List<String>? getNames() {
    return names;
  }

  List<String>? getNicknames() {
    return nicknames;
  }

  /**
   * In Japanese, the name is written in kanji, which can have multiple readings. Therefore a hint
   * is often provided, called furigana, which spells the name phonetically.
   *
   * @return The pronunciation of the getNames() field, often in hiragana or katakana.
   */
  String? getPronunciation() {
    return pronunciation;
  }

  List<String>? getPhoneNumbers() {
    return phoneNumbers;
  }

  /**
   * @return optional descriptions of the type of each phone number. It could be like "HOME", but,
   *  there is no guaranteed or standard format.
   */
  List<String>? getPhoneTypes() {
    return phoneTypes;
  }

  List<String>? getEmails() {
    return emails;
  }

  /**
   * @return optional descriptions of the type of each e-mail. It could be like "WORK", but,
   *  there is no guaranteed or standard format.
   */
  List<String>? getEmailTypes() {
    return emailTypes;
  }

  String? getInstantMessenger() {
    return instantMessenger;
  }

  String? getNote() {
    return note;
  }

  List<String>? getAddresses() {
    return addresses;
  }

  /**
   * @return optional descriptions of the type of each e-mail. It could be like "WORK", but,
   *  there is no guaranteed or standard format.
   */
  List<String>? getAddressTypes() {
    return addressTypes;
  }

  String? getTitle() {
    return title;
  }

  String? getOrg() {
    return org;
  }

  List<String>? getURLs() {
    return urls;
  }

  /**
   * @return birthday formatted as yyyyMMdd (e.g. 19780917)
   */
  String? getBirthday() {
    return birthday;
  }

  /**
   * @return a location as a latitude/longitude pair
   */
  List<String>? getGeo() {
    return geo;
  }

  @override
  String getDisplayResult() {
    StringBuffer result = StringBuffer();
    ParsedResult.maybeAppendList(names, result);
    ParsedResult.maybeAppendList(nicknames, result);
    ParsedResult.maybeAppend(pronunciation, result);
    ParsedResult.maybeAppend(title, result);
    ParsedResult.maybeAppend(org, result);
    ParsedResult.maybeAppendList(addresses, result);
    ParsedResult.maybeAppendList(phoneNumbers, result);
    ParsedResult.maybeAppendList(emails, result);
    ParsedResult.maybeAppend(instantMessenger, result);
    ParsedResult.maybeAppendList(urls, result);
    ParsedResult.maybeAppend(birthday, result);
    ParsedResult.maybeAppendList(geo, result);
    ParsedResult.maybeAppend(note, result);
    return result.toString();
  }
}
