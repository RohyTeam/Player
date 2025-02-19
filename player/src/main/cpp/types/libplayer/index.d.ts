export const Subtitle_Init: (buffer: ArrayBuffer) => void;
export const Subtitle_AddFont: (name: string, buffer: ArrayBuffer) => void;
export const Subtitle_Render: (time: number, width: number, height: number) => Array<object>;
export const Subtitle_Release: () => void;