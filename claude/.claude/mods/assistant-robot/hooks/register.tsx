import type { Register } from 'claude-code'

const BULLET = '●'
const LEFT_CAP = ''
const RIGHT_CAP = ''
const PILL_COLORS: Record<string, string> = { Q: '#5fd7d7', N: '#d7d75f', H: '#af87ff' }
const LABEL_COLORS = { option: '#ff875f', step: '#87d7af', sub: '#d7af87' }
const PILL_TEXT = '#000000'
const MARKED = /^(\s*(?:[-*]\s+)?)(?:_([QNH]\d+)_|-([QNH]\d+)-)(?=\s)/
const ITEM = /^(\s*)((?:[-*]\s+)?)([QNH]\d+|[A-C]|\d+[a-z]|\d+)(\.?)\s+(.*)$/
const TABLE_SEPARATOR = /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$/
const HEADER_BG = '#3b4048'
const ROW_BG = ['#12171d', '#161b22']
const GUTTER = 3
const IS_TABLE_STYLING_ENABLED = true
const MARGIN = 2
const MAX_CELL_LINES = 4

type Chunk =
  | { kind: 'text'; text: string; hasGap: boolean }
  | { kind: 'item'; indent: number; bullet: string; label: string; rest: string; hasGap: boolean }
  | { kind: 'table'; header: string[]; rows: string[][]; hasGap: boolean }

const isTableRow = (line: string) => line.trim().startsWith('|')

const splitRow = (line: string) =>
  line
    .trim()
    .replace(/^\|/, '')
    .replace(/\|$/, '')
    .split(/(?<!\\)\|/)
    .map(cell => cell.trim().replace(/\\\|/g, '|'))

const cleanCell = (cell: string) =>
  cell
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/\*\*([^*]+)\*\*/g, '$1')
    .replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '$1')
    .replace(/`([^`]*)`/g, '$1')
    .replace(/<br\s*\/?>/gi, ' ')

const longestWord = (cell: string) => Math.max(1, ...cell.split(/\s+/).map(word => word.length))

function columnWidths(header: string[], rows: string[][], available: number): number[] | null {
  const all = [header, ...rows]
  const natural = header.map((_, c) => Math.max(...all.map(row => row[c]?.length ?? 0)))
  const floor = header.map((_, c) =>
    Math.min(natural[c] ?? 1, Math.max(...all.map(row => longestWord(row[c] ?? '')))),
  )
  const widths = [...natural]
  const budget = available - MARGIN * 2 - GUTTER * header.length

  if (floor.reduce((a, b) => a + b, 0) > budget) {
    return null
  }

  while (widths.reduce((a, b) => a + b, 0) > budget) {
    let target = -1
    for (let c = 0; c < widths.length; c++) {
      if ((widths[c] ?? 0) > (floor[c] ?? 0) && (target === -1 || (widths[c] ?? 0) > (widths[target] ?? 0))) {
        target = c
      }
    }
    if (target === -1) {
      target = widths.indexOf(Math.max(...widths))
      if ((widths[target] ?? 0) <= 4) {
        break
      }
    }
    widths[target] = (widths[target] ?? 0) - 1
  }

  const isTooTall = all.some(row =>
    row.some((cell, c) => Math.ceil(cell.length / Math.max(1, widths[c] ?? 1)) > MAX_CELL_LINES),
  )

  return isTooTall ? null : widths.map(w => w + GUTTER)
}

function split(text: string): Chunk[] {
  const chunks: Chunk[] = []
  let buffer: string[] = []
  let isFenced = false
  let hasGap = false

  const flush = () => {
    let end = buffer.length
    while (end > 0 && buffer[end - 1]?.trim() === '') {
      end -= 1
    }
    let start = 0
    while (start < end && buffer[start]?.trim() === '') {
      start += 1
    }
    const body = buffer.slice(start, end)
    if (body.length > 0) {
      chunks.push({ kind: 'text', text: body.join('\n'), hasGap: hasGap || start > 0 })
    }
    hasGap = end < buffer.length
    buffer = []
  }

  const lines = text.split('\n')

  for (let i = 0; i < lines.length; i++) {
    const line = (lines[i] ?? '').replace(MARKED, (_, lead: string, a?: string, b?: string) => `${lead}${a ?? b}.`)

    if (line.trimStart().startsWith('```')) {
      isFenced = !isFenced
    }

    const isTable = IS_TABLE_STYLING_ENABLED && !isFenced && isTableRow(line) && TABLE_SEPARATOR.test(lines[i + 1] ?? '')
    if (isTable) {
      flush()
      const header = splitRow(line).map(cleanCell)
      const rows: string[][] = []
      i += 2
      while (i < lines.length && isTableRow(lines[i] ?? '')) {
        const cells = splitRow(lines[i] ?? '').map(cleanCell)
        while (cells.length < header.length) {
          cells.push('')
        }
        rows.push(cells.slice(0, header.length))
        i += 1
      }
      i -= 1
      chunks.push({ kind: 'table', header, rows, hasGap })
      hasGap = false
      continue
    }

    const match = isFenced ? null : ITEM.exec(line)
    const token = match?.[3] ?? ''
    const hasDot = (match?.[4] ?? '') === '.'
    const isValid = match !== null && (hasDot || /^\d+[a-z]$/.test(token))
    if (match && isValid) {
      flush()
      chunks.push({
        kind: 'item',
        indent: (match[1] ?? '').length,
        bullet: match[2] ?? '',
        label: token + (match[4] ?? ''),
        rest: match[5] ?? '',
        hasGap,
      })
      hasGap = false
    } else {
      buffer.push(line)
    }
  }
  flush()

  return chunks
}

export const register: Register = on => {
  on('ui.render', { component: 'AssistantMessage' }, ($, e, next) => {
    if (e.props.isSummary) {
      return next(e)
    }

    const { Box, Text, Markdown } = $.ui.resolve(e)
    const chunks = split(e.props.text)
    const available = Math.max(20, (e.viewport?.columns ?? 100) - 2)

    const drawCards = (chunk: Extract<Chunk, { kind: 'table' }>) => {
      const labelWidth = Math.max(...chunk.header.map(h => h.length)) + GUTTER
      const rowBg = (i: number) => ROW_BG[i % 2] ?? HEADER_BG
      const last = Math.max(0, chunk.rows.length - 1)

      const edge = (glyph: string, color: string, bg?: string) => (
        <Box width={available} flexShrink={0}>
          <Text color={color} backgroundColor={bg}>
            {glyph.repeat(available)}
          </Text>
        </Box>
      )

      return (
        <Box flexDirection="column" marginTop={chunk.hasGap ? 1 : 0}>
          {edge('▄', rowBg(0))}
          {chunk.rows.map((row, r) => (
            <Box flexDirection="column">
              {r === 0 ? null : edge('▀', rowBg(r - 1), rowBg(r))}
              <Box flexDirection="column" width={available} flexShrink={0} backgroundColor={rowBg(r)} paddingX={MARGIN}>
                {chunk.header.map((label, c) => (
                  <Box flexDirection="row">
                    <Box width={labelWidth} flexShrink={0}>
                      <Text bold backgroundColor={rowBg(r)}>
                        {label}
                      </Text>
                    </Box>
                    <Box flexGrow={1} flexShrink={1}>
                      <Text backgroundColor={rowBg(r)}>{row[c] ?? ''}</Text>
                    </Box>
                  </Box>
                ))}
              </Box>
            </Box>
          ))}
          {edge('▀', rowBg(last))}
        </Box>
      )
    }

    const drawTable = (chunk: Extract<Chunk, { kind: 'table' }>) => {
      const widths = columnWidths(chunk.header, chunk.rows, available)
      if (widths === null) {
        return drawCards(chunk)
      }
      const total = widths.reduce((a, b) => a + b, 0) + MARGIN * 2
      const rowBg = (i: number) => ROW_BG[i % 2] ?? HEADER_BG

      const line = (cells: string[], bg: string, isHead: boolean) => (
        <Box flexDirection="row" width={total} flexShrink={0} backgroundColor={bg} paddingX={MARGIN}>
          {cells.map((cell, c) => (
            <Box width={widths[c] ?? 1} paddingRight={GUTTER}>
              <Text bold={isHead} backgroundColor={bg}>
                {cell}
              </Text>
            </Box>
          ))}
        </Box>
      )

      const edge = (glyph: string, color: string, bg?: string) => (
        <Box width={total} flexShrink={0}>
          <Text color={color} backgroundColor={bg}>
            {glyph.repeat(total)}
          </Text>
        </Box>
      )

      return (
        <Box flexDirection="column" marginTop={chunk.hasGap ? 1 : 0}>
          {edge('▄', HEADER_BG)}
          {line(chunk.header, HEADER_BG, true)}
          {chunk.rows.map((row, r) => (
            <Box flexDirection="column">
              {edge('▀', r === 0 ? HEADER_BG : rowBg(r - 1), rowBg(r))}
              {line(row, rowBg(r), false)}
            </Box>
          ))}
          {edge('▀', chunk.rows.length > 0 ? rowBg(chunk.rows.length - 1) : HEADER_BG)}
        </Box>
      )
    }

    const drawItem = (chunk: Extract<Chunk, { kind: 'item' }>) => {
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

    return (
      <Box flexDirection="row" marginTop={e.props.isFirstOfReply ? 0 : 1}>
        <Box width={2} flexShrink={0}>
          <Text>{e.props.isFirstOfReply ? BULLET : ' '}</Text>
        </Box>
        <Box flexDirection="column" flexGrow={1} flexShrink={1}>
          {chunks.map(chunk =>
            chunk.kind === 'table' ? (
              drawTable(chunk)
            ) : chunk.kind === 'text' ? (
              <Box marginTop={chunk.hasGap ? 1 : 0}>
                <Markdown text={chunk.text} />
              </Box>
            ) : (
              drawItem(chunk)
            ),
          )}
        </Box>
      </Box>
    )
  })
}
