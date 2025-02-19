import { requireCJLib } from 'libark_interop_loader.so';
import { WebDAVLib } from './network/webdav';

export function getWebDAVLib(): WebDAVLib {
  return requireCJLib("librohy_player_cangjie_bridge.so") as WebDAVLib;
}