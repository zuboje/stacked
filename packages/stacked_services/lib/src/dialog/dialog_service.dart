import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stacked_services/src/dialog/platform_dialog.dart';
import 'package:stacked_services/src/models/overlay_request.dart';
import 'package:stacked_services/src/models/overlay_response.dart';

typedef DialogBuilder = Widget Function(
    BuildContext, DialogRequest, void Function(DialogResponse));

enum DialogPlatform {
  Cupertino,
  Material,
  Custom,
}

/// A DialogService that uses the Get package to show dialogs from the business logic
class DialogService {
  Map<dynamic, DialogBuilder>? _dialogBuilders;

  void registerCustomDialogBuilders(Map<dynamic, DialogBuilder> builders) {
    _dialogBuilders = builders;
  }

  Map<dynamic, DialogBuilder> _customDialogBuilders =
      Map<dynamic, DialogBuilder>();

  @Deprecated(
      'Prefer to use the StackedServices.navigatorKey instead of using this key. This will be removed in the next major version update for stacked.')
  get navigatorKey {
    return Get.key;
  }

  /// Registers a custom dialog builder. The builder function has been updated to include the function to call
  /// when you want to close the dialog. This improves readability and ease of use. When you want to close a dialog
  /// and return the result all you do is call the completer function passed in. i.e
  ///
  /// [registerCustomDialogBuilder](variant: MyDialog.Large, builder: (context, request, completer) => Button(onPressed: () => completer([DialogResponse]())))
  ///
  /// The normal completeDialog function will also still work when called on the service
  @Deprecated(
    'Prefer to use the registerCustomDialogBuilders() method. This method will be removed on the next major release. 0.7.0',
  )
  void registerCustomDialogBuilder({
    required dynamic variant,
    required Widget Function(
            BuildContext, DialogRequest, Function(DialogResponse))
        builder,
  }) {
    _customDialogBuilders[variant] = builder;
  }

  /// Check if dialog is open
  bool? get isDialogOpen => Get.isDialogOpen;

  /// Shows a dialog to the user
  ///
  /// It will show a platform specific dialog by default. This can be changed by setting [dialogPlatform]
  Future<DialogResponse?> showDialog({
    String? title,
    String? description,
    String? cancelTitle,
    Color? cancelTitleColor,
    String buttonTitle = 'Ok',
    Color? buttonTitleColor,
    bool barrierDismissible = false,

    /// Indicates which [DialogPlatform] to show.
    ///
    /// When not set a Platform specific dialog will be shown
    DialogPlatform? dialogPlatform,
  }) {
    if (dialogPlatform != null) {
      return _showDialog(
        title: title,
        description: description,
        cancelTitle: cancelTitle,
        buttonTitle: buttonTitle,
        dialogPlatform: dialogPlatform,
        barrierDismissible: barrierDismissible,
      );
    } else {
      var _dialogType = GetPlatform.isAndroid
          ? DialogPlatform.Material
          : DialogPlatform.Cupertino;
      return _showDialog(
        title: title,
        description: description,
        cancelTitle: cancelTitle,
        cancelTitleColor: cancelTitleColor,
        buttonTitle: buttonTitle,
        buttonTitleColor: buttonTitleColor,
        dialogPlatform: _dialogType,
        barrierDismissible: barrierDismissible,
      );
    }
  }

  Future<DialogResponse?> _showDialog({
    String? title,
    String? description,
    String? cancelTitle,
    Color? cancelTitleColor,
    String? buttonTitle,
    Color? buttonTitleColor,
    DialogPlatform dialogPlatform = DialogPlatform.Material,
    bool barrierDismissible = false,
  }) {
    var isConfirmationDialog = cancelTitle != null;
    return Get.dialog<DialogResponse>(
      PlatformDialog(
        dialogPlatform: dialogPlatform,
        title: title,
        content: description,
        actions: <Widget>[
          if (isConfirmationDialog)
            PlatformButton(
              dialogPlatform: dialogPlatform,
              text: cancelTitle!,
              cancelBtnColor: cancelTitleColor,
              isCancelButton: true,
              onPressed: () {
                completeDialog(
                  DialogResponse(
                    confirmed: false,
                  ),
                );
              },
            ),
          PlatformButton(
            dialogPlatform: dialogPlatform,
            text: buttonTitle!,
            confirmationBtnColor: buttonTitleColor,
            onPressed: () {
              completeDialog(
                DialogResponse(
                  confirmed: true,
                ),
              );
            },
          ),
        ],
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  // Creates a popup with the given widget, a scale animation, and faded background.
  Future<DialogResponse?> showCustomDialog({
    dynamic variant,
    String? title,
    String? description,
    bool hasImage = false,
    String? imageUrl,
    bool showIconInMainButton = false,
    String? mainButtonTitle,
    bool showIconInSecondaryButton = false,
    String? secondaryButtonTitle,
    bool showIconInAdditionalButton = false,
    String? additionalButtonTitle,
    bool takesInput = false,
    Color barrierColor = Colors.black54,
    bool barrierDismissible = false,
    String barrierLabel = '',
    dynamic customData,
  }) {
    assert(
      _dialogBuilders != null,
      'You have to call registerCustomDialogBuilder to use this function. Look at the custom dialog UI section in the stacked_services readme.',
    );

    final customDialogUI = _dialogBuilders![variant];

    assert(
      customDialogUI != null,
      'You have to call registerCustomDialogBuilder to use this function. Look at the custom dialog UI section in the stacked_services readme.',
    );

    return Get.generalDialog<DialogResponse>(
      barrierColor: barrierColor,
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      useRootNavigator: true,
      pageBuilder: (BuildContext buildContext, _, __) => SafeArea(
        child: Builder(
          builder: (BuildContext context) => customDialogUI!(
            context,
            DialogRequest(
              title: title,
              description: description,
              hasImage: hasImage,
              imageUrl: imageUrl,
              showIconInMainButton: showIconInMainButton,
              mainButtonTitle: mainButtonTitle,
              showIconInSecondaryButton: showIconInSecondaryButton,
              secondaryButtonTitle: secondaryButtonTitle,
              showIconInAdditionalButton: showIconInAdditionalButton,
              additionalButtonTitle: additionalButtonTitle,
              takesInput: takesInput,
              customData: customData,
              variant: variant,
            ),
            completeDialog,
          ),
        ),
      ),
      // TODO: Add configurable transition builders to set  from the outside as well
      // transitionBuilder: (context, animation, _, child) {
      //   return ScaleTransition(
      //     scale: CurvedAnimation(
      //       parent: animation,
      //       curve: Curves.decelerate,
      //     ),
      //     child: child,
      //   );
      // },
    );
  }

  /// Shows a confirmation dialog with title and description
  Future<DialogResponse?> showConfirmationDialog({
    String? title,
    String? description,
    String cancelTitle = 'Cancel',
    String confirmationTitle = 'Ok',
    bool barrierDismissible = false,

    /// Indicates which [DialogPlatform] to show.
    ///
    /// When not set a Platform specific dialog will be shown
    DialogPlatform? dialogPlatform,
  }) =>
      showDialog(
        title: title,
        description: description,
        buttonTitle: confirmationTitle,
        cancelTitle: cancelTitle,
        dialogPlatform: dialogPlatform,
        barrierDismissible: barrierDismissible,
      );

  /// Completes the dialog and passes the [response] to the caller
  void completeDialog(DialogResponse response) {
    Get.back(result: response);
  }
}
