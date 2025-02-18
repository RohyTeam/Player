export const Subtitle_Init: (buffer: ArrayBuffer) => void;
export const Subtitle_Render: (time: number, width: number, height: number) => Array<ArrayBuffer>;
export const Subtitle_Release: () => void;