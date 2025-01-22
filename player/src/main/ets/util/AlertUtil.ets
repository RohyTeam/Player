export function showAlert(
  context: UIContext,
  title: ResourceStr,
  text: ResourceStr,
) {
  context.showAlertDialog(
    {
      title: title,
      message: text,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      showInSubWindow: true,
      isModal: true,
      offset: { dx: 0, dy: -20 },
      buttonDirection: DialogButtonDirection.HORIZONTAL,
      confirm: {
        value: $r("app.string.confirm"),
        action: () => {
        }
      },
      cancel: () => {
      },
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason == DismissReason.PRESS_BACK) {
          dismissDialogAction.dismiss()
        }
        if (dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
          dismissDialogAction.dismiss()
        }
      }
    })
}