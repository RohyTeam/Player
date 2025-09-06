export interface ChapterMetadata {

  title: string | undefined
  start: number
  end: number

}

@Sendable
export class SendableChapterMetadata {
  title: string | undefined
  start: number
  end: number

  public constructor(
    title: string | undefined,
    start: number,
    end: number,
  ) {
    this.title = title
    this.start = start
    this.end = end
  }
}

export function sendableChapterMetadataToNormal(chapter: SendableChapterMetadata): ChapterMetadata {
  return {
    title: chapter.title,
    start: chapter.start,
    end: chapter.end,
  }
}