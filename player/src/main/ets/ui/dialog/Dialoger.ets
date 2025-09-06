import { Sys } from '../../context/SystemContext'

export class Dialoger {
  public static alert(context: UIContext, title: ResourceStr | undefined, message: ResourceStr | undefined,
    onClose: () => void = () => {
    }) {
    context.showAlertDialog({
      title: title,
      message: message,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      gridCount: 4,
      showInSubWindow: Sys.isPC(),
      isModal: !Sys.isPC(),
      offset: { dx: 0, dy: -20 },
      buttonDirection: DialogButtonDirection.HORIZONTAL,
      confirm: {
        value: $r("sys.string.general_confirm"),
        action: () => {
        }
      },
      cancel: () => {
      },
      onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
        if (dismissDialogAction.reason == DismissReason.PRESS_BACK ||
          dismissDialogAction.reason == DismissReason.TOUCH_OUTSIDE) {
          dismissDialogAction.dismiss()
        }
        if (onClose) {
          onClose()
        }
      }
    })
  }
}