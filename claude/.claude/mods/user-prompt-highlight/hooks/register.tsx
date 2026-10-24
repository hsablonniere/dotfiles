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

const PADDING_X = 1
const EDGE = 1
const IMAGE_TAG = /\[Image #(\d+)\]/g
const MENTION = /(^|\s)@([\w./~-]*[\w/~-])/g
const SKILL = /(^|\s)\/([a-z][a-z0-9:-]*)(?=$|\s|[.,;:!?)])/g
const PILL = new RegExp(`(${CAP_LEFT}[^${CAP_LEFT}${CAP_RIGHT}]+${CAP_RIGHT})`)
const SAFETY = 2

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
    const { Box, Text } = $.ui.resolve(e)
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

    const innerWidth = textWidth + PADDING_X * 2
    const bubbleWidth = innerWidth + EDGE * 2

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
              <Text key={i} color={TEXT_COLOR} wrap="truncate">
                {line.split(PILL).map((part, j) => {
                  if (!part.startsWith(CAP_LEFT)) {
                    return part
                  }
                  const pill = part[1] === '@' ? MENTION_PILL : part[1] === '/' ? SKILL_PILL : IMAGE_PILL
                  return (
                    <Text key={j}>
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
        </Box>
      </Box>
    )
  })
}
