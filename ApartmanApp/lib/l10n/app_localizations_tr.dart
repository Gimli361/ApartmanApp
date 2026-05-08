// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'ApartmanApp';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get errorTitle => 'Hata';

  @override
  String get successTitle => 'Başarılı';

  @override
  String get actionCancel => 'İptal';

  @override
  String get actionConfirm => 'Onayla';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionDelete => 'Sil';

  @override
  String get loginButton => 'Giriş Yap';

  @override
  String get logoutButton => 'Çıkış Yap';

  @override
  String get fieldEmail => 'E-posta';

  @override
  String get fieldPassword => 'Şifre';

  @override
  String get navArizalar => 'Arızalar';

  @override
  String get navAidatlar => 'Aidatlar';

  @override
  String get navBildirimler => 'Bildirimler';

  @override
  String get navOylamalar => 'Oylamalar';
}
