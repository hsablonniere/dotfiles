import type { RenderChildren } from 'claude-code'

import { MARGIN, TERMINAL_BG, type Ctx } from './context'
import { copyPill } from './copy-pill'

// After backtuick's code blocks: onedark deep colors, language tab top right
const CODE_BG = '#151b23'
const CODE_LABEL = '#0d1117'
const CODE_LABEL_BG = '#efbd5d'
// nf-ple-upper_right_triangle: the slanted left edge of the language tab
const TAB_EDGE = ''
const CODE_PAD_LEFT = 2
const CODE_PAD_RIGHT = 1
// Room left after the longest line, so a narrow block does not look cramped
const CODE_SLACK = 9
const COPY_LABEL = 'copy'
const FENCE = /^\s*```\s*([\w+#.-]*)/
const CLOSING_FENCE = /^\s*```\s*$/

export type CodeChunk = { kind: 'code'; lang: string; source: string; hasGap: boolean }

/** The closed code block opening at `lines[start]`, and the index of its closing fence; null otherwise. */
export function parseCode(lines: string[], start: number, hasGap: boolean): { chunk: CodeChunk; end: number } | null {
  const fence = FENCE.exec(lines[start] ?? '')
  if (!fence) {
    return null
  }
  const end = lines.findIndex((line, j) => j > start && CLOSING_FENCE.test(line))
  if (end === -1) {
    return null
  }

  return { chunk: { kind: 'code', lang: fence[1] ?? '', source: lines.slice(start + 1, end).join('\n'), hasGap }, end }
}

export function drawCode(ctx: Ctx, chunk: CodeChunk, index: number) {
  const { Box, Text, Code } = ctx.ui
  const label = chunk.lang === '' ? '' : `  ${chunk.lang}  `
  const scope = `copy-code:${index}:${chunk.source.length}`
  // As narrow as the longest line, or the tab and the pill, and never wider than the room
  const longest = Math.max(0, ...chunk.source.split('\n').map(line => [...line.replace(/\t/g, '  ')].length))
  const tabs = Math.max(label === '' ? 0 : label.length + 2, COPY_LABEL.length + 2 + MARGIN)
  const width = Math.min(ctx.available, Math.max(longest + CODE_PAD_LEFT + CODE_PAD_RIGHT + CODE_SLACK, tabs))
  const blank = (content: RenderChildren) => (
    <Box flexDirection="row" width={width} flexShrink={0} backgroundColor={CODE_BG} justifyContent="flex-end">
      {content}
    </Box>
  )

  return (
    <Box flexDirection="column" marginTop={chunk.hasGap ? 1 : 0} width={width} flexShrink={0}>
      {blank(
        label === '' ? (
          <Text backgroundColor={CODE_BG}> </Text>
        ) : (
          <Text>
            <Text color={CODE_LABEL_BG} backgroundColor={CODE_BG}>
              {TAB_EDGE}
            </Text>
            <Text color={CODE_LABEL} backgroundColor={CODE_LABEL_BG} bold>
              {label}
            </Text>
          </Text>
        ),
      )}
      <Box width={width} flexShrink={0} backgroundColor={CODE_BG} paddingLeft={CODE_PAD_LEFT} paddingRight={CODE_PAD_RIGHT}>
        <Code source={chunk.source} language={chunk.lang === '' ? undefined : chunk.lang} />
      </Box>
      {blank(<Text backgroundColor={CODE_BG}> </Text>)}
      <Box flexDirection="row" width={width} flexShrink={0} justifyContent="flex-end" marginTop={1}>
        {copyPill(ctx, scope, COPY_LABEL, chunk.source, 'Code copied', TERMINAL_BG)}
      </Box>
    </Box>
  )
}
