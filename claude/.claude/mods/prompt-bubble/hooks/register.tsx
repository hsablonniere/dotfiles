import type { Register } from 'claude-code'

const BORDER_COLOR = '#6c6c6c'
const TEXT_COLOR = '#b2b2b2'
const IMAGE_PILL = { color: '#d787d7', background: '#2e1a2e' }
const MENTION_PILL = { color: '#87afff', background: '#0d1a33' }
const SKILL_PILL = { color: '#ffaf5f', background: '#33210d' }
const NBSP = '\u00a0'
const CAP_LEFT = '\ue0b6'
const CAP_RIGHT = '\ue0b4'
const MIN_LEFT_GAP = 10
const COPY_BG = '#3b4048'
const COPY_FG = '#c0c4cc'
const TERMINAL_BG = '#000000'
const COPY_LABEL = 'copy'
// the copy pill under the bubble is never wider than it
const COPY_MIN_INNER = COPY_LABEL.length

const PADDING_X = 1
const EDGE = 1
const IMAGE_TAG = /\[Image #(\d+)\]/g
const MENTION = /(^|\s)@([\w./~-]*[\w/~-])/g
const SKILL = /(^|\s)\/([a-z][a-z0-9:-]*)(?=$|\s|[.,;:!?)])/g
const PILL = new RegExp(`(${CAP_LEFT}[^${CAP_LEFT}${CAP_RIGHT}]+${CAP_RIGHT})`)
const SAFETY = 2

const hash = (text: string) => {
  let h = 0
  for (let i = 0; i < text.length; i++) {
    h = (h * 31 + text.charCodeAt(i)) | 0
  }
  return (h >>> 0).toString(36)
}

const wrapLine = (line: string, max: number): string[] => {
  const out: string[] = []
  let current = ''
  for (const word of line.split(' ')) {
    let rest = word
    if (current !== '' && [...current].length + 1 + [...rest].length <= max) {
      current += ' ' + rest
      continue
    }
    if (current !== '') {
      out.push(current)
      current = ''
    }
    while ([...rest].length > max) {
      out.push([...rest].slice(0, max).join(''))
      rest = [...rest].slice(max).join('')
    }
    current = rest
  }
  out.push(current)
  return out
}

export const register: Register = on => {
  on('ui.render', { component: 'UserMessage' }, ($, e, next) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    if (e.props.origin.kind !== 'composer') {
      return next(e)
    }

    const text = e.props.text
      .replace(IMAGE_TAG, `${CAP_LEFT}Image${NBSP}#$1${CAP_RIGHT}`)
      .replace(MENTION, `$1${CAP_LEFT}@$2${CAP_RIGHT}`)
      .replace(SKILL, `$1${CAP_LEFT}/$2${CAP_RIGHT}`)
      .replace(/[ \t\r]+\n/g, '\n')
      .replace(/^[\s​﻿]+|[\s​﻿]+$/g, '')

    const columns = e.viewport?.columns ?? 80
    const max = Math.max(10, columns - MIN_LEFT_GAP - EDGE * 2 - PADDING_X * 2 - SAFETY)
    const lines = text.split('\n').flatMap(line => (line === '' ? [NBSP] : wrapLine(line, max)))
    while (lines.length > 1 && lines[lines.length - 1]?.trim() === '') {
      lines.pop()
    }
    const textWidth = Math.max(...lines.map(line => [...line].length))

    const innerWidth = Math.max(textWidth + PADDING_X * 2, COPY_MIN_INNER)
    const bubbleWidth = innerWidth + EDGE * 2

    const scope = `copy-prompt:${hash(e.props.text)}`
    const column = (char: string) => lines.map(() => char).join('\n')

    return (
      <Box flexDirection="row" justifyContent="flex-end" marginTop={2} marginLeft={MIN_LEFT_GAP}>
        <Box flexDirection="column" width={bubbleWidth} flexShrink={0}>
          <Text color={BORDER_COLOR} wrap="truncate">{'╭' + '─'.repeat(innerWidth) + '╮'}</Text>
          <Box flexDirection="row">
            <Box width={EDGE} flexShrink={0}>
              <Text color={BORDER_COLOR}>{column('│')}</Text>
            </Box>
            <Box flexDirection="column" width={innerWidth} paddingX={PADDING_X} flexShrink={0}>
            {lines.map((line, i) => (
              <Text key={String(i)} color={TEXT_COLOR} wrap="truncate">
                {line.split(PILL).map((part, j) => {
                  if (!part.startsWith(CAP_LEFT)) {
                    return part
                  }
                  const pill = part[1] === '@' ? MENTION_PILL : part[1] === '/' ? SKILL_PILL : IMAGE_PILL
                  return (
                    <Text key={String(j)}>
                      <Text color={pill.background}>{CAP_LEFT}</Text>
                      <Text color={pill.color} backgroundColor={pill.background}>{part.slice(1, -1)}</Text>
                      <Text color={pill.background}>{CAP_RIGHT}</Text>
                    </Text>
                  )
                })}
              </Text>
            ))}
            </Box>
            <Box width={EDGE} flexShrink={0}>
              <Text color={BORDER_COLOR}>{column('│')}</Text>
            </Box>
          </Box>
          <Text color={BORDER_COLOR} wrap="truncate">{'╰' + '─'.repeat(innerWidth) + '┘'}</Text>
          <Box flexDirection="row" justifyContent="flex-end">
            <Button
              plain
              key={scope}
              label={COPY_LABEL}
              hover={{ scope }}
              onPress={async press => {
                const result = await $.ui.copy({ text: e.props.text, surface: press.surface })
                await $.ui.toast(result.isCopied ? 'Prompt copied' : `Copy failed: ${result.reason}`)
              }}
            >
              {/* the terminal inverts a hovered button, so the caps' hover colors are pre-inverted */}
              <Text color={COPY_BG} hover={{ scope, color: TERMINAL_BG, backgroundColor: COPY_FG }}>
                {CAP_LEFT}
              </Text>
              <Text color={COPY_FG} backgroundColor={COPY_BG}>
                {COPY_LABEL}
              </Text>
              <Text color={COPY_BG} hover={{ scope, color: TERMINAL_BG, backgroundColor: COPY_FG }}>
                {CAP_RIGHT}
              </Text>
            </Button>
          </Box>
        </Box>
      </Box>
    )
  })
}
