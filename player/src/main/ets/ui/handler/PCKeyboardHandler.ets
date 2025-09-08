import { PlayerController } from '../../player/PlayerController';
import { KeyCode } from '@kit.InputKit';

export class PCKeyboardHandler {
  public static handle(context: UIContext | Context, controller: PlayerController, event: KeyEvent): boolean {
    if (event.keySource != KeySource.Keyboard) {
      return false
    }
    if (event.keyCode === KeyCode.KEYCODE_DPAD_LEFT) {
      controller.goBackward(15 * 1000)
      return true
    } else if (event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT) {
      controller.goForward(15 * 1000)
      return true
    } else if (event.keyCode === KeyCode.KEYCODE_SPACE) {
      controller.playOrPause()
      return true
    }
    return false
  }
}