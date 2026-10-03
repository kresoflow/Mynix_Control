// ==============================================================================
// МОДУЛЬ: POS / Меню — BLoC управления каталогом, блюдами и ритейл-товарами
// ДОМЕН: lib/features/pos/bloc/menu_bloc.dart
// ==============================================================================

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreso_frontend/features/pos/models/menu_item.dart';
import 'package:kreso_frontend/core/network/websocket_service.dart';
import 'package:kreso_frontend/core/utils/unit_formatter.dart';
import '../repository/menu_repository.dart';
import 'menu_event.dart';
import 'menu_state.dart';

export 'menu_event.dart';
export 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository menuRepository;
  StreamSubscription? _wsSubscription;
  Timer? _wsDebounceTimer;

  MenuBloc(this.menuRepository) : super(MenuLoading()) {
    on<LoadMenu>(_onLoadMenu);
    on<CreateMenuItem>(_onCreateMenuItem);
    on<CreateMenuItemsBulk>(_onCreateMenuItemsBulk);
    on<DeleteMenuItem>(_onDeleteMenuItem);
    on<DeleteMenuItemsBulk>(_onDeleteMenuItemsBulk);
    on<DeleteMenuItemWithPolicy>(_onDeleteMenuItemWithPolicy);
    on<MergeMenuItems>(_onMergeMenuItems);
    on<ExtractVariation>(_onExtractVariation);
    on<UnbundleMenuItem>(_onUnbundleMenuItem);
    on<CreateRetailProduct>(_onCreateRetailProduct);
    on<CreateRetailProductsBulk>(_onCreateRetailProductsBulk);
    on<CreateRetailProductGroup>(_onCreateRetailProductGroup);
    on<UpdateMenuItem>(_onUpdateMenuItem);
    on<UpdateRetailProduct>(_onUpdateRetailProduct);

    _wsSubscription = webSocketService.messages.listen((data) {
      if (data['event'] == 'inventory_updated') {
        _wsDebounceTimer?.cancel();
        _wsDebounceTimer = Timer(const Duration(milliseconds: 350), () {
          add(LoadMenu());
        });
      }
    });
  }

  @override
  Future<void> close() {
    _wsDebounceTimer?.cancel();
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadMenu(LoadMenu event, Emitter<MenuState> emit) async {
    if (state is! MenuLoaded) {
      emit(MenuLoading());
    }
    try {
      final items = await menuRepository.getMenuItems();
      emit(MenuLoaded(items: items));
    } catch (e) {
      if (state is! MenuLoaded) {
        emit(MenuError(message: e.toString()));
      }
    }
  }

  Future<void> _handleMenuAction(Future<void> Function() action, Emitter<MenuState> emit) async {
    final currentItems = state is MenuLoaded ? (state as MenuLoaded).items : <MenuItem>[];
    try {
      await action();
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(message: e.toString().replaceFirst('Exception: ', '')));
      if (currentItems.isNotEmpty) {
        emit(MenuLoaded(items: currentItems));
      } else {
        add(LoadMenu());
      }
    }
  }

  Future<void> _onCreateMenuItem(CreateMenuItem event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.createMenuItem(
        name: event.name,
        price: event.price,
        category: event.category,
        sortOrder: event.sortOrder,
        attributes: event.attributes,
        barcode: event.barcode,
      ), emit,);

  Future<void> _onCreateMenuItemsBulk(CreateMenuItemsBulk event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.createMenuItemsBulk(event.items), emit);

  Future<void> _onCreateRetailProduct(CreateRetailProduct event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.createRetailProduct(
        name: event.name,
        categoryId: event.categoryId,
        unit: event.unit,
        purchasePrice: event.purchasePrice,
        sellingPrice: event.sellingPrice,
        attributes: event.attributes,
        initialStock: event.initialStock,
        sortOrder: event.sortOrder,
        barcode: event.barcode,
        parentId: event.parentId,
      ), emit,);

  Future<void> _onCreateRetailProductsBulk(CreateRetailProductsBulk event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.createRetailProductsBulk(event.items), emit);

  Future<void> _onCreateRetailProductGroup(CreateRetailProductGroup event, Emitter<MenuState> emit) =>
      _handleMenuAction(() async {
        final double basePrice = event.variations.isNotEmpty 
            ? (event.variations.first['price'] as num).toDouble() 
            : 0.0;
            
        final parentId = await menuRepository.createMenuItem(
          name: event.name,
          category: event.categoryId?.toString() ?? '',
          price: basePrice,
          type: 'retail',
          attributes: {
            'icon': 'package',
            if (event.flavor != null && event.flavor!.isNotEmpty) 'flavor': event.flavor,
            'variations': event.variations,
          },
        );

        for (var v in event.variations) {
          await menuRepository.createRetailProduct(
            name: v['name'] as String,
            categoryId: event.categoryId,
            unit: UnitFormatter.toDbKey(v['unit'] as String?, 'pcs'),
            purchasePrice: (v['purchasePrice'] as num?)?.toDouble() ?? 0.0,
            sellingPrice: (v['price'] as num?)?.toDouble() ?? 0.0,
            initialStock: 0.0,
            barcode: v['barcode'] as String?,
            parentId: parentId,
          );
        }
      }, emit,);

  Future<void> _onDeleteMenuItem(DeleteMenuItem event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.deleteMenuItem(event.id, mode: event.mode), emit);

  Future<void> _onDeleteMenuItemsBulk(DeleteMenuItemsBulk event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.deleteMenuItemsBulk(event.ids, mode: event.mode), emit);

  Future<void> _onDeleteMenuItemWithPolicy(DeleteMenuItemWithPolicy event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.deleteMenuItemWithPolicy(itemId: event.id, policy: event.policy), emit);

  Future<void> _onMergeMenuItems(MergeMenuItems event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.mergeMenuItems(
        targetItemId: event.targetItemId,
        sourceItemIds: event.sourceItemIds,
        targetName: event.targetName,
      ), emit,);

  Future<void> _onExtractVariation(ExtractVariation event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.extractVariation(childId: event.childId), emit);

  Future<void> _onUnbundleMenuItem(UnbundleMenuItem event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.unbundleMenuItem(itemId: event.itemId), emit);

  Future<void> _onUpdateMenuItem(UpdateMenuItem event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.updateMenuItem(event.id, event.data), emit);

  Future<void> _onUpdateRetailProduct(UpdateRetailProduct event, Emitter<MenuState> emit) =>
      _handleMenuAction(() => menuRepository.updateRetailProduct(event.id, event.data), emit);
}
