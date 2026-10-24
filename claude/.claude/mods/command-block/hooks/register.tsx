import type { Register } from 'claude-code'

const BACKGROUND = '#6c6c6c'
const PADDING_X = 1

// eslint-disable-next-line no-control-regex
const ANSI = /\u001b\[[0-9;?]*[ -/]*[@-~]/g
// eslint-disable-next-line no-control-regex
const CONTROL = /[\u0000-\u0008\u000b-\u001f\u007f]/g

export const register: Register = on => {
  on('ui.render', { component: 'CommandOutput' }, ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const echo = `/${e.props.command}${e.props.args === '' ? '' : ` ${e.props.args}`}`
    const width = [...echo].length + PADDING_X * 2
    const output = e.props.text.replace(ANSI, '').replace(CONTROL, '')

    return (
      <Box flexDirection="column" width="100%">
        <Box flexDirection="row" justifyContent="flex-end" width="100%" marginTop={1}>
          <Box flexDirection="column" width={width} flexShrink={0}>
            <Box height={1} overflow="hidden">
              <Text color={BACKGROUND}>{'▄'.repeat(width)}</Text>
            </Box>
            <Box paddingX={PADDING_X} backgroundColor={BACKGROUND}>
              <Text backgroundColor={BACKGROUND} wrap="truncate">{echo}</Text>
            </Box>
            <Box height={1} overflow="hidden">
              <Text color={BACKGROUND}>{'▀'.repeat(width)}</Text>
            </Box>
          </Box>
        </Box>
        <Box paddingLeft={2}>
          <Text>{output}</Text>
        </Box>
      </Box>
    )
  })
}
