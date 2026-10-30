import type { Register } from 'claude-code'

import { drawCode, parseCode, type CodeChunk } from './code'
import type { Ctx } from './context'
import { drawItem, normalizeMarkers, parseItem, type ItemChunk } from './lists'
import { drawTable, parseTable, type TableChunk } from './tables'

const BULLET = '●'

type TextChunk = { kind: 'text'; text: string; hasGap: boolean }
type Chunk = TextChunk | ItemChunk | TableChunk | CodeChunk

// Cuts a reply into plain markdown, labelled items, tables and code blocks, each remembering a blank line above it
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
    const line = normalizeMarkers(lines[i] ?? '')

    const block = isFenced ? null : (parseCode(lines, i, hasGap) ?? parseTable(lines, i, hasGap))
    if (block) {
      flush()
      chunks.push(block.chunk)
      hasGap = false
      i = block.end
      continue
    }

    // An unclosed fence, still streaming: left to the markdown renderer
    if (line.trimStart().startsWith('```')) {
      isFenced = !isFenced
    }

    const item = isFenced ? null : parseItem(line, hasGap)
    if (item) {
      flush()
      chunks.push(item)
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

    const ui = $.ui.resolve(e)
    const { Box, Text, Markdown } = ui
    const ctx: Ctx = {
      ui,
      available: Math.max(20, (e.viewport?.columns ?? 100) - 2),
      copy: (text, toast) => async press => {
        const result = await $.ui.copy({ text, surface: press.surface })
        await $.ui.toast(result.isCopied ? toast : `Copy failed: ${result.reason}`)
      },
    }

    return (
      <Box flexDirection="row" marginTop={1}>
        <Box width={2} flexShrink={0}>
          <Text>{e.props.isFirstOfReply ? BULLET : ' '}</Text>
        </Box>
        <Box flexDirection="column" flexGrow={1} flexShrink={1}>
          {split(e.props.text).map((chunk, index) =>
            chunk.kind === 'code' ? (
              drawCode(ctx, chunk, index)
            ) : chunk.kind === 'table' ? (
              drawTable(ctx, chunk, index)
            ) : chunk.kind === 'item' ? (
              drawItem(ctx, chunk)
            ) : (
              <Box marginTop={chunk.hasGap ? 1 : 0}>
                <Markdown text={chunk.text} />
              </Box>
            ),
          )}
        </Box>
      </Box>
    )
  })
}
