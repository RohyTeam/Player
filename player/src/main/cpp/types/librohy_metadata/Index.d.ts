interface ExportInfo {
  index: number
  dest: string
}

export const RohyMetedata_getMetadata: (path: string, headers?: Record<string, string>) => object | undefined;
export const RohyMetadata_extractTracks: (path: string, tracks: ExportInfo[], headers?: Record<string, string>) => void;