import { MARGIN, TERMINAL_BG, type Ctx } from './context'
import { copyPill } from './copy-pill'

const TABLE_SEPARATOR = /^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$/
const HEADER_BG = '#3b4048'
const ROW_BG = ['#12171d', '#161b22']
const GUTTER = 3
const MAX_CELL_LINES = 4

export type TableChunk = { kind: 'table'; header: string[]; rows: string[][]; source: string; hasGap: boolean }

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

const csvCell = (cell: string) => (/[",\n]/.test(cell) ? `"${cell.replace(/"/g, '""')}"` : cell)
const toCsv = (header: string[], rows: string[][]) =>
  [header, ...rows].map(row => row.map(csvCell).join(',')).join('\n')

const rowBg = (i: number) => ROW_BG[i % 2] ?? HEADER_BG

/** The table starting at `lines[start]`, and the index of its last line; null when no table starts there. */
export function parseTable(lines: string[], start: number, hasGap: boolean): { chunk: TableChunk; end: number } | null {
  const first = lines[start] ?? ''
  if (!isTableRow(first) || !TABLE_SEPARATOR.test(lines[start + 1] ?? '')) {
    return null
  }

  const header = splitRow(first).map(cleanCell)
  const rows: string[][] = []
  let i = start + 2
  while (i < lines.length && isTableRow(lines[i] ?? '')) {
    const cells = splitRow(lines[i] ?? '').map(cleanCell)
    while (cells.length < header.length) {
      cells.push('')
    }
    rows.push(cells.slice(0, header.length))
    i += 1
  }
  const end = i - 1

  return { chunk: { kind: 'table', header, rows, source: lines.slice(start, end + 1).join('\n'), hasGap }, end }
}

const longestWord = (cell: string) => Math.max(1, ...cell.split(/\s+/).map(word => word.length))

// Column widths that fit `available`, shrinking the widest columns first; null when the table only reads as cards
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

const edge = ({ ui: { Box, Text } }: Ctx, width: number, glyph: string, color: string, bg?: string) => (
  <Box width={width} flexShrink={0}>
    <Text color={color} backgroundColor={bg}>
      {glyph.repeat(width)}
    </Text>
  </Box>
)

// The table's bottom edge, then the copy pills right below it, flush right
function footer(ctx: Ctx, chunk: TableChunk, index: number, width: number, above: string) {
  const { Box, Text } = ctx.ui

  return (
    <Box flexDirection="column" width={width} flexShrink={0}>
      {edge(ctx, width, '▀', above)}
      <Box flexDirection="row" width={width} flexShrink={0} justifyContent="flex-end">
        {copyPill(ctx, `copy-table:${index}:md`, '.md', chunk.source, 'Table copied as Markdown', TERMINAL_BG)}
        <Text> </Text>
        {copyPill(ctx, `copy-table:${index}:csv`, '.csv', toCsv(chunk.header, chunk.rows), 'Table copied as CSV', TERMINAL_BG)}
      </Box>
    </Box>
  )
}

// One card per row, the header as labels, for tables too wide for a grid
function drawCards(ctx: Ctx, chunk: TableChunk, index: number) {
  const { Box, Text } = ctx.ui
  const width = ctx.available
  const labelWidth = Math.max(...chunk.header.map(h => h.length)) + GUTTER
  const last = Math.max(0, chunk.rows.length - 1)

  return (
    <Box flexDirection="column" marginTop={chunk.hasGap ? 1 : 0}>
      {edge(ctx, width, '▄', rowBg(0))}
      {chunk.rows.map((row, r) => (
        <Box flexDirection="column">
          {r === 0 ? null : edge(ctx, width, '▀', rowBg(r - 1), rowBg(r))}
          <Box flexDirection="column" width={width} flexShrink={0} backgroundColor={rowBg(r)} paddingX={MARGIN}>
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
      {footer(ctx, chunk, index, width, rowBg(last))}
    </Box>
  )
}

export function drawTable(ctx: Ctx, chunk: TableChunk, index: number) {
  const widths = columnWidths(chunk.header, chunk.rows, ctx.available)
  if (widths === null) {
    return drawCards(ctx, chunk, index)
  }

  const { Box, Text } = ctx.ui
  const total = widths.reduce((a, b) => a + b, 0) + MARGIN * 2

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

  return (
    <Box flexDirection="column" marginTop={chunk.hasGap ? 1 : 0}>
      {edge(ctx, total, '▄', HEADER_BG)}
      {line(chunk.header, HEADER_BG, true)}
      {chunk.rows.map((row, r) => (
        <Box flexDirection="column">
          {edge(ctx, total, '▀', r === 0 ? HEADER_BG : rowBg(r - 1), rowBg(r))}
          {line(row, rowBg(r), false)}
        </Box>
      ))}
      {footer(ctx, chunk, index, total, chunk.rows.length > 0 ? rowBg(chunk.rows.length - 1) : HEADER_BG)}
    </Box>
  )
}
