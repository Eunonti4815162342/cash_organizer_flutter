import '../../domain/models/account_item.dart';
import '../../domain/models/transaction_item.dart';

class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  DateTime? lastSelectedDate;
  AccountItem? lastSelectedAccount;
  TransactionType? lastSelectedType;

  void updateSessionFromTransaction(Map<String, dynamic> transactionData) {
    if (transactionData['date'] != null) {
      lastSelectedDate = DateTime.parse(transactionData['date']);
    }
    // Nota: El objeto AccountItem y TransactionType se recuperarán 
    // en el formulario basándose en los IDs guardados.
  }

  void resetSession() {
    lastSelectedDate = null;
    lastSelectedAccount = null;
    lastSelectedType = null;
  }
}
