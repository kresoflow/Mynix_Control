import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/core/network/websocket_service.dart';
import '../repository/menu_repository.dart';

// --- Events ---
abstract class MenuEvent extends Equatable {
  const MenuEvent();
  @override
  List<Object?> get props => [];
}

class LoadMenu extends MenuEvent {}

class CreateMenuItem extends MenuEvent {
  final String name;
  final double price;
  final String category;
  final int sortOrder;
  final Map<String, dynamic>? attributes;
  final String? barcode;

  const CreateMenuItem({
    required this.name,
    required this.price,
    required this.category,
    this.sortOrder = 0,
    this.attributes,
    this.barcode,
  });

  @override
  List<Object?> get props => [name, price, category, sortOrder, barcode];
}

class DeleteMenuItem extends MenuEvent {
  final int id;

  const DeleteMenuItem(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateMenuItem extends MenuEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateMenuItem(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class UpdateRetailProduct extends MenuEvent {
  final int id;
  final Map<String, dynamic> data;

  const UpdateRetailProduct(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class CreateRetailProduct extends MenuEvent {
  final String name;
  final int? categoryId;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final Map<String, dynamic>? attributes;
  final double initialStock;
  final double minStockAlert;
  final int sortOrder;
  final String? barcode;
  final int? parentId;

  const CreateRetailProduct({
    required this.name,
    this.categoryId,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    this.attributes,
    this.initialStock = 0.0,
    this.minStockAlert = 0.0,
    this.sortOrder = 0,
    this.barcode,
    this.parentId,
  });

  @override
  List<Object?> get props => [name, categoryId, unit, purchasePrice, sellingPrice, attributes, initialStock, minStockAlert, sortOrder, barcode, parentId];
}

class CreateRetailProductGroup extends MenuEvent {
  final String name;
  final int? categoryId;
  final String? flavor;
  final List<Map<String, dynamic>> variations;

  const CreateRetailProductGroup({
    required this.name,
    this.categoryId,
    this.flavor,
    required this.variations,
  });

  @override
  List<Object?> get props => [name, categoryId, flavor, variations];
}

// --- States ---
abstract class MenuState extends Equatable {
  const MenuState();
  @override
  List<Object?> get props => [];
}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuItem> items;
  const MenuLoaded({required this.items});
  
  @override
  List<Object?> get props => [items];
}

class MenuError extends MenuState {
  final String message;
  const MenuError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

// --- Bloc ---
class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository menuRepository;
  StreamSubscription? _wsSubscription;

  MenuBloc(this.menuRepository) : super(MenuLoading()) {
    on<LoadMenu>(_onLoadMenu);
    on<CreateMenuItem>(_onCreateMenuItem);
    on<DeleteMenuItem>(_onDeleteMenuItem);
    on<CreateRetailProduct>(_onCreateRetailProduct);
    on<CreateRetailProductGroup>(_onCreateRetailProductGroup);
    on<UpdateMenuItem>(_onUpdateMenuItem);
    on<UpdateRetailProduct>(_onUpdateRetailProduct);

    _wsSubscription = webSocketService.messages.listen((data) {
      if (data['event'] == 'inventory_updated') {
        add(LoadMenu());
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadMenu(LoadMenu event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final items = await menuRepository.getMenuItems();
      emit(MenuLoaded(items: items));
    } catch (e) {
      emit(MenuError(message: e.toString()));
    }
  }

  Future<void> _onCreateMenuItem(CreateMenuItem event, Emitter<MenuState> emit) async {
    try {
      await menuRepository.createMenuItem(
        name: event.name,
        price: event.price,
        category: event.category,
        sortOrder: event.sortOrder,
        attributes: event.attributes,
        barcode: event.barcode,
      );
      // Reload menu after creation
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(message: e.toString()));
      add(LoadMenu());
    }
  }

  Future<void> _onCreateRetailProduct(CreateRetailProduct event, Emitter<MenuState> emit) async {
    try {
      await menuRepository.createRetailProduct(
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
      );
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(message: e.toString().replaceFirst('Exception: ', '')));
      add(LoadMenu());
    }
  }

  Future<void> _onCreateRetailProductGroup(CreateRetailProductGroup event, Emitter<MenuState> emit) async {
    try {
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
          unit: v['unit'] as String? ?? 'pcs',
          purchasePrice: (v['purchasePrice'] as num?)?.toDouble() ?? 0.0,
          sellingPrice: (v['price'] as num?)?.toDouble() ?? 0.0,
          initialStock: (v['stock'] as num?)?.toDouble() ?? 0.0,
          barcode: v['barcode'] as String?,
          parentId: parentId,
        );
      }
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(message: e.toString().replaceFirst('Exception: ', '')));
      add(LoadMenu());
    }
  }

  Future<void> _onDeleteMenuItem(DeleteMenuItem event, Emitter<MenuState> emit) async {
    try {
      await menuRepository.deleteMenuItem(event.id);
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(message: e.toString().replaceFirst('Exception: ', '')));
      add(LoadMenu());
    }
  }

  Future<void> _onUpdateMenuItem(UpdateMenuItem event, Emitter<MenuState> emit) async {
    try {
      await menuRepository.updateMenuItem(event.id, event.data);
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(message: e.toString().replaceFirst('Exception: ', '')));
      add(LoadMenu());
    }
  }

  Future<void> _onUpdateRetailProduct(UpdateRetailProduct event, Emitter<MenuState> emit) async {
    try {
      await menuRepository.updateRetailProduct(event.id, event.data);
      add(LoadMenu());
    } catch (e) {
      emit(MenuError(message: e.toString().replaceFirst('Exception: ', '')));
      add(LoadMenu());
    }
  }
}
