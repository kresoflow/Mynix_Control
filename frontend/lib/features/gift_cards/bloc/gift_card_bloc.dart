// ==============================================================================
// МОДУЛЬ: Подарочные карты (Gift Cards)
// ДОМЕН: lib/features/gift_cards/bloc/gift_card_bloc.dart
// ==============================================================================
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/gift_cards/models/gift_card.dart';
import 'package:kreso_frontend/features/gift_cards/repository/gift_card_repository.dart';

// ─── 1. События BLoC (Events) ─────────────────────────────────────────────────

abstract class GiftCardEvent extends Equatable {
  const GiftCardEvent();
  @override
  List<Object?> get props => [];
}

class LoadGiftCardsEvent extends GiftCardEvent {
  final String? search;
  final bool? isActive;
  final int? customerId;
  const LoadGiftCardsEvent({this.search, this.isActive, this.customerId});
  @override
  List<Object?> get props => [search, isActive, customerId];
}

class IssueGiftCardEvent extends GiftCardEvent {
  final String? code;
  final double initialBalance;
  final DateTime? expiryDate;
  final int? customerId;
  final String? notes;
  const IssueGiftCardEvent({this.code, required this.initialBalance, this.expiryDate, this.customerId, this.notes});
  @override
  List<Object?> get props => [code, initialBalance, expiryDate, customerId, notes];
}

class RedeemGiftCardEvent extends GiftCardEvent {
  final int cardId;
  final double amount;
  final int? orderId;
  final String? notes;
  const RedeemGiftCardEvent({required this.cardId, required this.amount, this.orderId, this.notes});
  @override
  List<Object?> get props => [cardId, amount, orderId, notes];
}

class TopUpGiftCardEvent extends GiftCardEvent {
  final int cardId;
  final double amount;
  final String? notes;
  const TopUpGiftCardEvent({required this.cardId, required this.amount, this.notes});
  @override
  List<Object?> get props => [cardId, amount, notes];
}

class LookupGiftCardEvent extends GiftCardEvent {
  final String code;
  const LookupGiftCardEvent(this.code);
  @override
  List<Object?> get props => [code];
}

class ClearSelectedGiftCardEvent extends GiftCardEvent {}

// ─── 2. Состояние BLoC (State) ────────────────────────────────────────────────

enum GiftCardStateStatus { initial, loading, success, failure, actionLoading, actionSuccess }

class GiftCardState extends Equatable {
  final GiftCardStateStatus status;
  final List<GiftCard> cards;
  final int totalCount;
  final GiftCard? selectedCard;
  final String? errorMessage;
  final String? actionMessage;

  const GiftCardState({
    this.status = GiftCardStateStatus.initial,
    this.cards = const [],
    this.totalCount = 0,
    this.selectedCard,
    this.errorMessage,
    this.actionMessage,
  });

  bool get isLoading => status == GiftCardStateStatus.loading;
  bool get isActionLoading => status == GiftCardStateStatus.actionLoading;

  GiftCardState copyWith({
    GiftCardStateStatus? status,
    List<GiftCard>? cards,
    int? totalCount,
    GiftCard? selectedCard,
    bool clearSelected = false,
    String? errorMessage,
    String? actionMessage,
  }) {
    return GiftCardState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      totalCount: totalCount ?? this.totalCount,
      selectedCard: clearSelected ? null : (selectedCard ?? this.selectedCard),
      errorMessage: errorMessage,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [status, cards, totalCount, selectedCard, errorMessage, actionMessage];
}

// ─── 3. Реализация BLoC (Logic) ───────────────────────────────────────────────

class GiftCardBloc extends Bloc<GiftCardEvent, GiftCardState> {
  final GiftCardRepository _repository;

  GiftCardBloc({required GiftCardRepository repository})
      : _repository = repository,
        super(const GiftCardState()) {
    on<LoadGiftCardsEvent>(_onLoadGiftCards);
    on<IssueGiftCardEvent>(_onIssueGiftCard);
    on<RedeemGiftCardEvent>(_onRedeemGiftCard);
    on<TopUpGiftCardEvent>(_onTopUpGiftCard);
    on<LookupGiftCardEvent>(_onLookupGiftCard);
    on<ClearSelectedGiftCardEvent>((_, emit) => emit(state.copyWith(clearSelected: true)));
  }

  Future<void> _onLoadGiftCards(LoadGiftCardsEvent event, Emitter<GiftCardState> emit) async {
    emit(state.copyWith(status: GiftCardStateStatus.loading));
    try {
      final res = await _repository.getGiftCards(search: event.search, isActive: event.isActive, customerId: event.customerId);
      emit(state.copyWith(status: GiftCardStateStatus.success, cards: res.items, totalCount: res.total));
    } catch (e) {
      emit(state.copyWith(status: GiftCardStateStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onIssueGiftCard(IssueGiftCardEvent event, Emitter<GiftCardState> emit) async {
    emit(state.copyWith(status: GiftCardStateStatus.actionLoading));
    try {
      final card = await _repository.issueGiftCard(
        code: event.code,
        initialBalance: event.initialBalance,
        expiryDate: event.expiryDate,
        customerId: event.customerId,
        notes: event.notes,
      );
      emit(state.copyWith(
        status: GiftCardStateStatus.actionSuccess,
        cards: [card, ...state.cards],
        totalCount: state.totalCount + 1,
        selectedCard: card,
        actionMessage: 'Карта ${card.code} успешно выпущена',
      ),);
    } catch (e) {
      emit(state.copyWith(status: GiftCardStateStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRedeemGiftCard(RedeemGiftCardEvent event, Emitter<GiftCardState> emit) async {
    emit(state.copyWith(status: GiftCardStateStatus.actionLoading));
    try {
      final updated = await _repository.redeemGiftCard(cardId: event.cardId, amount: event.amount, orderId: event.orderId, notes: event.notes);
      emit(state.copyWith(
        status: GiftCardStateStatus.actionSuccess,
        cards: state.cards.map((c) => c.id == updated.id ? updated : c).toList(),
        selectedCard: updated,
        actionMessage: 'С карты успешно списано ${event.amount.toStringAsFixed(2)}',
      ),);
    } catch (e) {
      emit(state.copyWith(status: GiftCardStateStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onTopUpGiftCard(TopUpGiftCardEvent event, Emitter<GiftCardState> emit) async {
    emit(state.copyWith(status: GiftCardStateStatus.actionLoading));
    try {
      final updated = await _repository.topUpGiftCard(cardId: event.cardId, amount: event.amount, notes: event.notes);
      emit(state.copyWith(
        status: GiftCardStateStatus.actionSuccess,
        cards: state.cards.map((c) => c.id == updated.id ? updated : c).toList(),
        selectedCard: updated,
        actionMessage: 'Баланс карты успешно пополнен на ${event.amount.toStringAsFixed(2)}',
      ),);
    } catch (e) {
      emit(state.copyWith(status: GiftCardStateStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLookupGiftCard(LookupGiftCardEvent event, Emitter<GiftCardState> emit) async {
    emit(state.copyWith(status: GiftCardStateStatus.loading));
    try {
      final card = await _repository.lookupGiftCard(event.code);
      if (card == null) {
        emit(state.copyWith(status: GiftCardStateStatus.failure, clearSelected: true, errorMessage: 'Карта с кодом "${event.code}" не найдена'));
      } else {
        emit(state.copyWith(status: GiftCardStateStatus.success, selectedCard: card));
      }
    } catch (e) {
      emit(state.copyWith(status: GiftCardStateStatus.failure, clearSelected: true, errorMessage: e.toString()));
    }
  }
}
