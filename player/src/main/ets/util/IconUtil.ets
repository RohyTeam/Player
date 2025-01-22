import { LayeredDrawableDescriptor } from "@kit.ArkUI";
import { hdsDrawable } from "@kit.UIDesignKit";

export function getIcon(resource: Resource): PixelMap {
  return hdsDrawable.getHdsLayeredIcon(
    "org.rohy.player",
    (getContext().resourceManager.getDrawableDescriptor(resource.id)) as LayeredDrawableDescriptor,
    288
  )
}