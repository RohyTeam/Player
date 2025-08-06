import { BackgroundBlurModifier } from "./BackgroundBlurModifier";

export class Modifiers {

  public static backgroundBlur(): BackgroundBlurModifier {
    return new BackgroundBlurModifier()
  }

}