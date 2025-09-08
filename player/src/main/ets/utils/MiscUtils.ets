import { systemShare } from '@kit.ShareKit';
import { common } from '@kit.AbilityKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

export function shareUrl(uiContext: UIContext, url: string) {
  let shareData: systemShare.SharedData = new systemShare.SharedData({
    utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
    content: url,
    title: url
  });

  let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
  let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
  controller.show(context, {
    selectionMode: systemShare.SelectionMode.SINGLE,
    previewMode: systemShare.SharePreviewMode.DEFAULT,
  }).then(() => {
    console.info('ShareController show success.');
  }).catch((error: BusinessError) => {
    console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
  });
}