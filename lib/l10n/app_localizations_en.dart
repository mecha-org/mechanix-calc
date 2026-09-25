// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get calculator => 'Calculator';

  @override
  String get maxDigitsErrorMessage => 'Can\'t enter more than 15 digits';

  @override
  String get maxCharactersErrorMessage =>
      'Can\'t enter more than 100 characters';

  @override
  String get maxOperationsErrorMessage =>
      'Can\'t enter more than 20 operations';

  @override
  String get invalidOperationsErrorMessage => 'Error';
}
