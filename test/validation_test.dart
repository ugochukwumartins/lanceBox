// Checks accepted and rejected input values. Null means valid; a message means invalid.
// Tests follow setup → action → expected result. expect(...) checks the result.

import 'package:flutter_test/flutter_test.dart';
import 'package:lancebox/shared/validation.dart';
import 'package:lancebox/features/invoices/invoice.dart';

void main() {
  // Cover valid short/maximum-length numbers and invalid input without losing leading zeros.
  test('bank number accepts only 1–10 digits and preserves leading zeros', () {
    expect(bankNumberError('0123456789'), isNull);
    expect(bankNumberError('123'), isNull);
    for (final value in ['', '01234567890', '123a', '-123', '12.3']) {
      expect(bankNumberError(value), isNotNull);
    }
  });
  // Separate bank-name restrictions from ordinary customer/business-name rules.
  test('bank names reject numbers but allow normal name punctuation', () {
    for (final value in [
      'Lance Bank',
      'Société Générale',
      'First Bank (NG)',
      'A & B Bank',
    ]) {
      expect(bankNameError(value), isNull);
    }
    for (final value in ['', 'Bank 123', 'Bank ١', '@@@', 'Bank@']) {
      expect(bankNameError(value), isNotNull);
    }
    expect(nameError('Studio 24'), isNull);
    expect(nameError("O’Connor"), isNull);
  });
  // Check identifier punctuation, required text and maximum field lengths.
  test('text and invoice identifiers have bounded valid content', () {
    expect(invoiceNumberError('INV-2026/001'), isNull);
    expect(invoiceNumberError('INV @ 1'), isNotNull);
    expect(titleError(' '), isNotNull);
    expect(titleError('x' * 151), isNotNull);
    expect(descriptionError('Design 2'), isNull);
    expect(termsError('x' * 501), isNotNull);
  });
  test(
    'email and passwords reject invalid inputs and mismatched confirmation',
    () {
      expect(emailError('test@example.com'), isNull);
      expect(emailError('invalid@'), isNotNull);
      expect(passwordError('        '), isNotNull);
      expect(passwordError('short'), isNotNull);
      // A password needs a real symbol; spaces and Unicode letters do not qualify.
      expect(passwordError('password123'), isNotNull);
      expect(passwordError('password 123'), isNotNull);
      expect(passwordError('épassword123'), isNotNull);
      for (final symbol in ['!', '@', '#', r'$', '€']) {
        expect(passwordError('password123$symbol'), isNull);
      }
      expect(passwordError('x' * 129), isNotNull);
      expect(confirmationError('password123!', 'password123!'), isNull);
      expect(confirmationError('password124!', 'password123!'), isNotNull);
    },
  );
  // Reject unsupported numeric formats while preserving valid decimals and zero charges.
  test('numbers reject exponents, nonfinite values and excess precision', () {
    for (final value in ['1e3', 'NaN', 'Infinity', '1.234', '1.2.3', '-1']) {
      expect(nonNegativeNumber(value), isNotNull);
    }
    expect(nonNegativeNumber('0.00'), isNull);
    expect(positiveNumber('0'), isNotNull);
    expect(positiveNumber('1.25'), isNull);
  });
}
