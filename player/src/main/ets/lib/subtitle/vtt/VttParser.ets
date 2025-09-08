export interface AnchorPosition {
  x: number
  y: number
}

export interface CueSettings {
  vertical?: 'rl' | 'lr';
  line?: number | string;
  position?: number;
  size?: number;
  align?: 'start' | 'center' | 'end';
  region?: string;
}

export interface Cue {
  identifier?: string;
  start: number;
  end: number;
  text: string;
  settings?: CueSettings;
  voice?: string;
  classes?: string[];
  nextLineIndex: number;
}

export interface Region {
  id: string;
  width?: number;
  lines?: number;
  regionAnchor?: AnchorPosition
  viewportAnchor?: AnchorPosition
  scroll?: 'up';
}

export interface WebVTT {
  cues: Cue[];
  regions: Map<string, Region>;
  styles: string;
}

export function parseVtt(content: string): WebVTT {
  return new WebVTTParser().parse(content)
}

interface ParsedTextContent {
  voice?: string;
  classes: string[];
  cleanText: string
}

class WebVTTParser {
  private static readonly TIME_REGEX = /^(\d{2,}):(\d{2}):(\d{2})\.(\d{3})/;
  private regions: Map<string, Region> = new Map();
  private styles: string = '';

  parse(content: string): WebVTT {
    const lines = content.split(/\r\n|\n/);
    const cues: Cue[] = [];

    if (!lines[0].startsWith('WEBVTT')) {
      throw new Error('Invalid WebVTT file: missing WEBVTT signature');
    }

    let i = 1;
    while (i < lines.length && (lines[i].trim() === '' || lines[i].startsWith('NOTE'))) {
      i++;
    }

    while (i < lines.length) {
      const line = lines[i].trim();

      if (line === '') {
        i++;
        continue;
      }

      if (line.startsWith('REGION')) {
        const region = this.parseRegion(lines, i);
        this.regions.set(region.id, region);
        i = this.skipBlock(lines, i);
        continue;
      }

      if (line.startsWith('STYLE')) {
        this.styles = this.parseStyle(lines, i);
        i = this.skipBlock(lines, i);
        continue;
      }

      if (line.match("NOTE .+")) { // inline NOTE
        i++;
        continue;
      } else if (line.startsWith('NOTE')) {
        i = this.skipBlock(lines, i);
        continue;
      }

      const cue = this.parseCue(lines, i);
      if (cue) {
        cues.push(cue);
        i = cue.nextLineIndex || lines.length;
      } else {
        i++;
      }
    }

    return {
      cues,
      regions: this.regions,
      styles: this.styles
    };
  }

  private parseRegion(lines: string[], startIndex: number): Region {
    const region: Region = { id: '' };
    let i = startIndex + 1;

    while (i < lines.length) {
      const line = lines[i].trim();
      if (line === '') break;

      const parts = line.split(':');
      if (parts.length < 2) {
        i++;
        continue;
      }

      const key = parts[0].trim();
      const value = parts.slice(1).join(':').trim();

      switch (key) {
        case 'id':
          region.id = value;
          break;
        case 'width':
          region.width = parseFloat(value);
          break;
        case 'lines':
          region.lines = parseInt(value, 10);
          break;
        case 'regionanchor':
          const rSplit = value.split(',').map(v => parseFloat(v));
          let rx = rSplit[0]
          let ry = rSplit[1]
          if (!isNaN(rx) && !isNaN(ry)) {
            region.regionAnchor = { x: rx, y: ry };
          }
          break;
        case 'viewportanchor':
          const vSplit = value.split(',').map(v => parseFloat(v));
          let vx = vSplit[0]
          let vy = vSplit[1]
          if (!isNaN(vx) && !isNaN(vy)) {
            region.viewportAnchor = { x: vx, y: vy };
          }
          break;
        case 'scroll':
          if (value === 'up') {
            region.scroll = 'up';
          }
          break;
      }

      i++;
    }

    return region;
  }

  private parseStyle(lines: string[], startIndex: number): string {
    const styleLines: string[] = [];
    let i = startIndex + 1;
    let inStyle = false;

    while (i < lines.length) {
      const line = lines[i].trim();

      if (line === '---') {
        if (inStyle)
          break;
        inStyle = true;
      } else if (inStyle) {
        styleLines.push(line);
      }

      i++;
    }

    return styleLines.join('\n');
  }

  private parseCue(lines: string[], startIndex: number): Cue | null {
    let i = startIndex;
    let identifier: string | undefined;

    if (lines[i] && !lines[i].includes('-->')) {
      identifier = lines[i].trim();
      i++;
    }

    if (i >= lines.length) return null;

    const timeLine = lines[i].trim();
    const timeMatch = timeLine.match(/(\d{2,}):(\d{2}):(\d{2})\.(\d{3})\s*-->\s*(\d{2,}):(\d{2}):(\d{2})\.(\d{3})(.*)/);

    if (!timeMatch) return null;

    const startTime = this.parseTime(
      parseInt(timeMatch[1], 10),
      parseInt(timeMatch[2], 10),
      parseInt(timeMatch[3], 10),
      parseInt(timeMatch[4], 10)
    );

    const endTime = this.parseTime(
      parseInt(timeMatch[5], 10),
      parseInt(timeMatch[6], 10),
      parseInt(timeMatch[7], 10),
      parseInt(timeMatch[8], 10)
    );

    const settingsStr = timeMatch[9] || '';
    const settings = this.parseCueSettings(settingsStr);

    i++;

    const textLines: string[] = [];
    while (i < lines.length && lines[i].trim() !== '') {
      textLines.push(lines[i].trim());
      i++;
    }

    const text = textLines.join('\n');
    const parsedTextContent = this.parseTextContent(text);

    return {
      identifier,
      start: startTime,
      end: endTime,
      text: parsedTextContent.cleanText,
      settings: settings,
      voice: parsedTextContent.voice,
      classes: parsedTextContent.classes,
      nextLineIndex: i
    };
  }

  private parseTime(hours: number, minutes: number, seconds: number, milliseconds: number): number {
    return hours * 3600 + minutes * 60 + seconds + milliseconds / 1000;
  }

  private parseCueSettings(settingsStr: string): CueSettings {
    const settings: CueSettings = {};
    const parts = settingsStr.trim().split(/\s+/);

    for (const part of parts) {
      if (!part.includes(':')) continue;

      let split = part.split(':');
      let key = split[0]
      let value = split[1]

      switch (key) {
        case 'vertical':
          if (value === 'rl' || value === 'lr') {
            settings.vertical = value;
          }
          break;
        case 'line':
          if (value.endsWith('%')) {
            settings.line = value;
          } else {
            settings.line = parseFloat(value);
          }
          break;
        case 'position':
          settings.position = parseFloat(value);
          break;
        case 'size':
          settings.size = parseFloat(value);
          break;
        case 'align':
          if (value === 'start' || value === 'center' || value === 'end') {
            settings.align = value;
          }
          break;
        case 'region':
          settings.region = value;
          break;
      }
    }

    return settings;
  }

  private parseTextContent(text: string): ParsedTextContent {
    let cleanText = text;
    let voice: string | undefined;
    const classes: string[] = [];

    const voiceMatch = text.match(/<v\s+([^>]+)>(.*?)<\/v>/);
    if (voiceMatch) {
      voice = voiceMatch[1];
      cleanText = voiceMatch[2];
    }

    const classMatches = text.matchAll(/<c\.([^>]+)>(.*?)<\/c>/g);
    for (const match of classMatches) {
      classes.push(match[1]);
      cleanText = cleanText.replace(match[0], match[2]);
    }

    cleanText = cleanText.replace(/<[^>]*>/g, '');

    return { voice, classes, cleanText };
  }

  private skipBlock(lines: string[], startIndex: number): number {
    let i = startIndex + 1;
    while (i < lines.length && lines[i].trim() !== '') {
      i++;
    }
    return i;
  }
}