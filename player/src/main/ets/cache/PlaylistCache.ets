import { isPlaylistVideo, PlaylistFolder, PlaylistVideo } from '../playlist/PlaylistStructure';
import { fileShare } from '@kit.CoreFileKit';
import { VideoMetadataManager } from '../metadata/VideoMetadataManager';

export class PlaylistCache {
  public static imported: Record<string, number> = {}

  public static async deleteVideos(items: (PlaylistVideo | PlaylistFolder)[]) {
    for (let item of items) {
      if (isPlaylistVideo(item)) {
        let video = item as PlaylistVideo
        if (!PlaylistCache.imported[video.identity]) {
          continue
        }
        PlaylistCache.imported[video.identity] -= 1
        if (PlaylistCache.imported[video.identity] <= 0) {
          await fileShare.revokePermission([{
            uri: video.url,
            operationMode: fileShare.OperationMode.READ_MODE
          }])
          VideoMetadataManager.delete(video.identity)
        }
      } else {
        PlaylistCache.deleteVideos((item as PlaylistFolder).items)
      }
    }
  }
}