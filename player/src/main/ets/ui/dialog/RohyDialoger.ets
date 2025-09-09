import { common } from "@kit.AbilityKit";
import { ability } from "../../utils/AbilityUtils";

export class RohyDialoger {

  private context: UIContext
  private component?: ComponentContent

  constructor(context: UIContext) {
    this.context = context
  }

  public push(component: ComponentContent) {
    if (this.component)
      this.pop()
    this.context.getPromptAction().openCustomDialog(component)
  }

  public pop() {
    if (this.component)
      this.context.getPromptAction().closeCustomDialog(this.component)
  }

}