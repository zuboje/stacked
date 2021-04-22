import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/dialog/dialog_route.dart';

String? _extractRouteName(Route? route) {
  if (route?.settings.name != null) {
    return route!.settings.name;
  }

  if (route is GetPageRoute) {
    return route.routeName;
  }

  if (route is GetDialogRoute) {
    return route.name;
  }

  if (route is GetModalBottomSheetRoute) {
    return route.name;
  }

  return null;
}

class _RouteData {
  final bool isGetPageRoute;
  final bool isSnackbar;
  final bool isBottomSheet;
  final bool isDialog;
  final String? name;

  _RouteData({
    required this.name,
    required this.isGetPageRoute,
    required this.isSnackbar,
    required this.isBottomSheet,
    required this.isDialog,
  });

  factory _RouteData.ofRoute(Route? route) {
    return _RouteData(
      name: _extractRouteName(route),
      isGetPageRoute: route is GetPageRoute,
      isSnackbar: route is SnackRoute,
      isDialog: route is GetDialogRoute,
      isBottomSheet: route is GetModalBottomSheetRoute,
    );
  }
}

class StackObserver extends NavigatorObserver {
  StackObserver({Routing? routeSend}) : _routeSend = routeSend ?? Get.routing;

  final Routing? _routeSend;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    final newRoute = _RouteData.ofRoute(route);

    Get.reference = newRoute.name;
    _routeSend?.update((value) {
      if (route is PageRoute) {
        value.current = newRoute.name ?? '';
      }

      value.args = route.settings.arguments;
      value.route = route;
      value.isBack = false;
      value.removed = '';
      value.previous = _extractRouteName(previousRoute) ?? '';
      value.isSnackbar = newRoute.isSnackbar ? true : value.isSnackbar ?? false;
      value.isBottomSheet =
          newRoute.isBottomSheet ? true : value.isBottomSheet ?? false;
      value.isDialog = newRoute.isDialog ? true : value.isDialog ?? false;
    });
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final newRoute = _RouteData.ofRoute(previousRoute);

    Get.reference = newRoute.name;
    _routeSend?.update((value) {
      if (previousRoute is PageRoute) {
        value.current = _extractRouteName(previousRoute) ?? '';
      }

      value.args = route.settings.arguments;
      value.route = previousRoute;
      value.isBack = true;
      value.removed = '';
      value.previous = newRoute.name ?? '';
      value.isSnackbar = newRoute.isSnackbar;
      value.isBottomSheet = newRoute.isBottomSheet;
      value.isDialog = newRoute.isDialog;
    });
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final newName = _extractRouteName(newRoute);
    final oldName = _extractRouteName(oldRoute);
    final currentRoute = _RouteData.ofRoute(oldRoute);

    Get.reference = newName;
    _routeSend?.update((value) {
      if (newRoute is PageRoute) {
        value.current = newName ?? '';
      }

      value.args = newRoute?.settings.arguments;
      value.route = newRoute;
      value.isBack = false;
      value.removed = '';
      value.previous = '$oldName';
      value.isSnackbar = currentRoute.isSnackbar ? false : value.isSnackbar;
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
      value.isDialog = currentRoute.isDialog ? false : value.isDialog;
    });
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    final routeName = _extractRouteName(route);
    final currentRoute = _RouteData.ofRoute(route);

    _routeSend?.update((value) {
      value.route = previousRoute;
      value.isBack = false;
      value.removed = routeName ?? '';
      value.previous = routeName ?? '';
      value.isSnackbar = currentRoute.isSnackbar ? false : value.isSnackbar;
      value.isBottomSheet =
          currentRoute.isBottomSheet ? false : value.isBottomSheet;
      value.isDialog = currentRoute.isDialog ? false : value.isDialog;
    });
  }
}
