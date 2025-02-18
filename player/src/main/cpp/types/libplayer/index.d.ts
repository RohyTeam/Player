export declare class SubtitleRenderer {
  Subtitle_Init(buffer: ArrayBuffer): void;
  Subtitle_AddFont(name: string, font: ArrayBuffer): void;
  Subtitle_Render(time: number, width: number, height: number): void;
  Subtitle_Release(): void;
}