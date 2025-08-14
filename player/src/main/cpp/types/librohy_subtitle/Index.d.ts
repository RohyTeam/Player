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
  release: () => void;

}