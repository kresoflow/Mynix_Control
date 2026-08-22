import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mynix_frontend/core/network/api_client.dart';
import 'package:mynix_frontend/core/router/app_router.dart';
import 'package:mynix_frontend/core/theme/app_theme.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_bloc.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_event.dart';
import 'package:mynix_frontend/features/auth/bloc/auth_state.dart';
import 'package:mynix_frontend/features/auth/repository/auth_repository.dart';
import 'package:mynix_frontend/features/pos/repository/menu_repository.dart';
import 'package:mynix_frontend/features/pos/repository/order_repository.dart';
import 'package:mynix_frontend/core/theme/theme_bloc.dart';
import 'package:mynix_frontend/features/pos/models/menu_item.dart';
import 'package:mynix_frontend/features/pos/models/cart_item.dart';
import 'package:mynix_frontend/features/pos/bloc/menu_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/cart_bloc.dart';
import 'package:mynix_frontend/features/pos/repository/shift_repository.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/shift_event.dart';
import 'package:mynix_frontend/features/kitchen/repository/kitchen_repository.dart';
import 'package:mynix_frontend/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:mynix_frontend/features/inventory/repository/inventory_repository.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/ingredient_event.dart';
import 'package:mynix_frontend/core/network/websocket_service.dart';

import 'package:mynix_frontend/features/inventory/bloc/recipe_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_bloc.dart';
import 'package:mynix_frontend/features/inventory/bloc/document_event.dart';
import 'package:mynix_frontend/features/inventory/bloc/category_bloc.dart';
import 'package:mynix_frontend/features/settings/bloc/settings_bloc.dart';
import 'package:mynix_frontend/features/orders/repository/orders_repository.dart';
import 'package:mynix_frontend/features/orders/bloc/orders_bloc.dart';
import 'package:mynix_frontend/features/pos/bloc/pos_settings_cubit.dart';
import 'package:mynix_frontend/features/crm/repository/crm_repository.dart';
import 'package:mynix_frontend/features/crm/bloc/crm_bloc.dart';
import 'package:mynix_frontend/features/settings/repository/settings_repository.dart';
import 'package:mynix_frontend/features/pos/services/pos_outbox_service.dart';
import 'package:mynix_frontend/features/pos/services/pos_sync_service.dart';
import 'package:mynix_frontend/features/pos/services/lan/local_pos_server.dart';
import 'package:mynix_frontend/features/settings/services/lan_settings_service.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Added for URL strategy
import 'package:device_preview/device_preview.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:mynix_frontend/core/utils/app_bloc_observer.dart';

/// 📱 ФЛАГ ЭМУЛЯТОРА: Переключите в `true` для тестирования мобильных экранов (iPhone/iPad/Android)
const bool kEnableDevicePreview = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  Bloc.observer = AppBlocObserver();

  // Initialize Hive & Offline Outbox
  await Hive.initFlutter();
  Hive.registerAdapter(MenuItemAdapter());
  Hive.registerAdapter(CartItemAdapter());

  await PosOutboxService.init();
  await LanSettingsService.init();

  final appWidget = DevicePreview(
    enabled: kEnableDevicePreview,
    builder: (context) => const RetailOSApp(),
  );

  if (kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://95ba1567f2be41c4645bc1942ff77bd5@o4511875643015168.ingest.de.sentry.io/4511875668050000';
        options.environment = 'production';
        options.tracesSampleRate = 0.2;
        options.attachScreenshot = true;
      },
      appRunner: () => runApp(appWidget),
    );
  } else {
    runApp(appWidget);
  }
}


class RetailOSApp extends StatefulWidget {
  const RetailOSApp({super.key});

  @override
  State<RetailOSApp> createState() => _RetailOSAppState();
}

class _RetailOSAppState extends State<RetailOSApp> {
  late final AuthRepository _authRepository;
  late final MenuRepository _menuRepository;
  late final OrderRepository _orderRepository;
  late final KitchenRepository _kitchenRepository;
  late final ShiftRepository _shiftRepository;
  late final InventoryRepository _inventoryRepository;
  late final CrmRepository _crmRepository;
  late final SettingsRepository _settingsRepository;
  late final AuthBloc _authBloc;
  late final ThemeBloc _themeBloc;
  late final SettingsBloc _settingsBloc;
  late final MenuBloc _menuBloc;
  late final CartBloc _cartBloc;
  late final KitchenBloc _kitchenBloc;
  late final ShiftBloc _shiftBloc;
  late final IngredientBloc _ingredientBloc;
  late final RecipeBloc _recipeBloc;
  late final CategoryBloc _categoryBloc;
  late final DocumentBloc _documentBloc;
  late final OrdersRepository _ordersHistoryRepository;
  late final OrdersBloc _ordersBloc;
  late final CrmBloc _crmBloc;
  late final PosSettingsCubit _posSettingsCubit;
  late final PosSyncService _posSyncService;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(apiClient.dio);
    _menuRepository = MenuRepository(apiClient.dio);
    _orderRepository = OrderRepository(apiClient.dio);
    _kitchenRepository = KitchenRepository();
    _shiftRepository = ShiftRepository(apiClient.dio);
    _inventoryRepository = InventoryRepository(apiClient.dio);
    _crmRepository = CrmRepository(apiClient.dio);
    _settingsRepository = SettingsRepository(apiClient.dio);
    _posSyncService = PosSyncService(apiClient: apiClient)..start();
    _authBloc = AuthBloc(_authRepository)..add(AppStarted());
    _themeBloc = ThemeBloc()..add(LoadSavedTheme());
    _settingsBloc = SettingsBloc();
    _menuBloc = MenuBloc(_menuRepository);
    _cartBloc = CartBloc(_orderRepository);
    _kitchenBloc = KitchenBloc(_kitchenRepository);
    _shiftBloc = ShiftBloc(_shiftRepository);
    _ingredientBloc = IngredientBloc(_inventoryRepository);
    _recipeBloc = RecipeBloc(_inventoryRepository);
    _categoryBloc = CategoryBloc(_inventoryRepository);
    _documentBloc = DocumentBloc(_inventoryRepository);
    _ordersHistoryRepository = OrdersRepository(dio: apiClient.dio);
    _ordersBloc = OrdersBloc(repository: _ordersHistoryRepository);
    _crmBloc = CrmBloc(_crmRepository);
    _posSettingsCubit = PosSettingsCubit();
    _appRouter = AppRouter(_authBloc);

    // Automatically sync tenant feature flags and load shift status on login/startup
    _authBloc.stream.listen((authState) {
      if (authState is AuthAuthenticated) {
        _settingsBloc.add(
          UpdateFeatureFlags(
            useKds: authState.useKds,
            useOrders: authState.useOrders,
          ),
        );
        _shiftBloc.add(CheckCurrentShift());
      }
    });
  }

  @override
  void dispose() {
    _posSyncService.stop();
    LocalPosServer.stop();
    _authBloc.close();
    _themeBloc.close();
    _settingsBloc.close();
    _menuBloc.close();
    _cartBloc.close();
    _kitchenBloc.close();
    _shiftBloc.close();
    _ingredientBloc.close();
    _recipeBloc.close();
    _categoryBloc.close();
    _documentBloc.close();
    _ordersBloc.close();
    _crmBloc.close();
    _posSettingsCubit.close();
    webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: apiClient),
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _menuRepository),
        RepositoryProvider.value(value: _orderRepository),
        RepositoryProvider.value(value: _kitchenRepository),
        RepositoryProvider.value(value: _shiftRepository),
        RepositoryProvider.value(value: _inventoryRepository),
        RepositoryProvider.value(value: _ordersHistoryRepository),
        RepositoryProvider.value(value: _crmRepository),
        RepositoryProvider.value(value: _settingsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _themeBloc),
          BlocProvider.value(value: _settingsBloc),
          BlocProvider.value(value: _menuBloc),
          BlocProvider.value(value: _cartBloc),
          BlocProvider.value(value: _kitchenBloc),
          BlocProvider.value(value: _shiftBloc),
          BlocProvider.value(value: _ingredientBloc),
          BlocProvider.value(value: _recipeBloc),
          BlocProvider.value(value: _categoryBloc),
          BlocProvider.value(value: _documentBloc),
          BlocProvider.value(value: _ordersBloc),
          BlocProvider.value(value: _crmBloc),
          BlocProvider.value(value: _posSettingsCubit),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              webSocketService.connect(state.tenantId);
              context.read<MenuBloc>().add(LoadMenu());
              context.read<ShiftBloc>().add(CheckCurrentShift());
              context.read<IngredientBloc>().add(LoadIngredients());
              context.read<CategoryBloc>().add(LoadCategories());
              context.read<DocumentBloc>().add(const LoadDocuments());
            } else if (state is AuthUnauthenticated) {
              webSocketService.disconnect();
            }
          },
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              return BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return MaterialApp.router(
                    title: 'Kreso Flow',
                    debugShowCheckedModeBanner: false,
                    locale: kEnableDevicePreview ? DevicePreview.locale(context) : null,
                    builder: kEnableDevicePreview ? DevicePreview.appBuilder : null,
                    themeMode: themeState.mode,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    routerConfig: _appRouter.router,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
