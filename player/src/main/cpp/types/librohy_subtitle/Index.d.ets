export class RohyAssSubtitleRenderer {

  constructor();

  init: (buffer: ArrayBuffer) => void;
  addMemoryFont: (name: string, buffer: ArrayBuffer) => void;
  render: (time: number, width: number, height: number) => Array<object>; // Array<AssSubtitleImage>
  release: () => void;

}

export class RohyPgsSubtitleRenderer {

  constructor();

  init: (path: string) => void;
  render: (time: number) => Array<object> | undefined; // Array<PgsSubtitleImage> | undefined
  getMaxDuration: () => number;
  listAllSubtitles: (basePath: string) => Array<object> // Array<PgsSubtitle>
  release: () => void;

}

@Sendable
export class SendableRohyPgsSubtitleRenderer {

  constructor();

  sendableInit(path: string): Array<object>; // Array<PgsSubtitleRange>
  sendableRender(time: number): Array<object> | undefined; // Array<PgsSubtitleImage> | undefined
  sendableRenderByIndex(index: number): Array<object> | undefined; // Array<PgsSubtitleImage> | undefined
  sendableGetMaxDuration(): number;
  sendableRelease(): void;

}