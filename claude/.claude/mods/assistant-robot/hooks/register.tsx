import type { Register } from 'claude-code'

const BULLET = '●'
const LEFT_CAP = ''
const RIGHT_CAP = ''
const PILL = 'suggestion'
const PILL_TEXT = '#000000'
const QUESTION = /^(Q\d+)\.\s+(.*)$/

type Chunk =
  | { kind: 'text'; text: string; hasGap: boolean }
  | { kind: 'question'; label: string; rest: string; hasGap: boolean }

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

  for (const line of text.split('\n')) {
    if (line.trimStart().startsWith('```')) {
      isFenced = !isFenced
    }

    const match = isFenced ? null : QUESTION.exec(line)
    if (match) {
      flush()
      chunks.push({ kind: 'question', label: match[1] ?? '', rest: match[2] ?? '', hasGap })
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

    return (
      <Box flexDirection="row" marginTop={e.props.isFirstOfReply ? 0 : 1}>
        <Box width={2} flexShrink={0}>
          <Text>{e.props.isFirstOfReply ? BULLET : ' '}</Text>
        </Box>
        <Box flexDirection="column" flexGrow={1} flexShrink={1}>
          {chunks.map(chunk =>
            chunk.kind === 'text' ? (
              <Box marginTop={chunk.hasGap ? 1 : 0}>
                <Markdown text={chunk.text} />
              </Box>
            ) : (
              <Box flexDirection="row" marginTop={chunk.hasGap ? 1 : 0}>
                <Text color={PILL}>{LEFT_CAP}</Text>
                <Text color={PILL_TEXT} backgroundColor={PILL} bold>
                  {chunk.label}
                </Text>
                <Text color={PILL}>{RIGHT_CAP}</Text>
                <Box marginLeft={1} flexGrow={1} flexShrink={1}>
                  <Markdown text={chunk.rest} />
                </Box>
              </Box>
            ),
          )}
        </Box>
      </Box>
    )
  })
}
