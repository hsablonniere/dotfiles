import { LEFT_CAP, RIGHT_CAP, type Ctx } from './context'

const PILL_COLORS: Record<string, string> = { Q: '#5fd7d7', N: '#d7d75f', H: '#af87ff' }
const LABEL_COLORS = { option: '#ff875f', step: '#87d7af', sub: '#d7af87' }
const PILL_TEXT = '#000000'
// `-Q1-` or `_Q1_` at the start of a line: a question, note or hypothesis label
const MARKED = /^(\s*(?:[-*]\s+)?)(?:_([QNH]\d+)_|-([QNH]\d+)-)(?=\s)/
const ITEM = /^(\s*)((?:[-*]\s+)?)([QNH]\d+|[A-C]|\d+[a-z]|\d+)(\.?)\s+(.*)$/

export type ItemChunk = { kind: 'item'; indent: number; bullet: string; label: string; rest: string; hasGap: boolean }

/** Turns the `-Q1-` and `_Q1_` markers into `Q1.`, so they read as labelled items. */
export const normalizeMarkers = (line: string) =>
  line.replace(MARKED, (_, lead: string, a?: string, b?: string) => `${lead}${a ?? b}.`)

/** The labelled item a line starts, if any: `Q1.`, `A.`, `2.`, `1a`. */
export function parseItem(line: string, hasGap: boolean): ItemChunk | null {
  const match = ITEM.exec(line)
  const token = match?.[3] ?? ''
  const hasDot = (match?.[4] ?? '') === '.'
  if (!match || !(hasDot || /^\d+[a-z]$/.test(token))) {
    return null
  }

  return {
    kind: 'item',
    indent: (match[1] ?? '').length,
    bullet: match[2] ?? '',
    label: token + (match[4] ?? ''),
    rest: match[5] ?? '',
    hasGap,
  }
}

export function drawItem({ ui: { Box, Text, Markdown } }: Ctx, chunk: ItemChunk) {
  const pillColor = PILL_COLORS[chunk.label[0] ?? '']
  const isPill = pillColor !== undefined && /^[QNH]\d/.test(chunk.label)
  const labelColor = /^[A-C]/.test(chunk.label)
    ? LABEL_COLORS.option
    : /^\d+[a-z]/.test(chunk.label)
      ? LABEL_COLORS.sub
      : LABEL_COLORS.step

  return (
    <Box flexDirection="row" marginTop={chunk.hasGap ? 1 : 0} marginLeft={chunk.indent}>
      {chunk.bullet === '' ? null : <Text>{chunk.bullet}</Text>}
      {isPill ? (
        <Box flexDirection="row">
          <Text color={pillColor}>{LEFT_CAP}</Text>
          <Text color={PILL_TEXT} backgroundColor={pillColor} bold>
            {chunk.label.replace(/\.$/, '')}
          </Text>
          <Text color={pillColor}>{RIGHT_CAP}</Text>
        </Box>
      ) : (
        <Text color={labelColor} bold>
          {chunk.label}
        </Text>
      )}
      <Box marginLeft={1} flexGrow={1} flexShrink={1}>
        <Markdown text={chunk.rest} />
      </Box>
    </Box>
  )
}
