import 'package:flutter/foundation.dart';

/// Signal partagé entre le service de push et la cloche de notifications.
///
/// Incrémenté à chaque push reçu app ouverte, pour que la cloche recharge
/// son compteur de non lues. Ce fichier n'importe volontairement rien de
/// Firebase : la cloche et la liste fonctionnent sans lui.
class NotificationEvents {
  NotificationEvents._();

  static final ValueNotifier<int> nouvelleNotification = ValueNotifier<int>(0);
}