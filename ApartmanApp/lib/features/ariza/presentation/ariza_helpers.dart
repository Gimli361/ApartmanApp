import 'package:flutter/material.dart';
import '../domain/ariza_model.dart';

Color durumColor(ArizaDurum durum) => switch (durum) {
      ArizaDurum.beklemede => Colors.orange,
      ArizaDurum.inceleniyor => Colors.blue,
      ArizaDurum.tamamlandi => Colors.green,
      ArizaDurum.reddedildi => Colors.red,
    };

Color oncelikColor(ArizaOncelik oncelik) => switch (oncelik) {
      ArizaOncelik.dusuk => Colors.grey,
      ArizaOncelik.orta => Colors.blue,
      ArizaOncelik.yuksek => Colors.orange,
      ArizaOncelik.kritik => Colors.red,
    };

IconData durumIcon(ArizaDurum durum) => switch (durum) {
      ArizaDurum.beklemede => Icons.schedule,
      ArizaDurum.inceleniyor => Icons.search,
      ArizaDurum.tamamlandi => Icons.check_circle,
      ArizaDurum.reddedildi => Icons.cancel,
    };
