import type { Register } from 'claude-code'

const BACKGROUND = '#1c1c1c'
const ERROR_BACKGROUND = '#2a1212'
const TOP_EDGE = '▄'.repeat(500)
const BOTTOM_EDGE = '▀'.repeat(500)

export const register: Register = on => {
  on('ui.render', { component: 'CommandOutput' }, ($, e) => {
    const { Box, Text, Markdown } = $.ui.resolve(e)
    const background = e.props.isErrored ? ERROR_BACKGROUND : BACKGROUND

    return (
      <Box flexDirection="column">
        <Box height={1} overflow="hidden">
          <Text color={background}>{TOP_EDGE}</Text>
        </Box>
        <Box paddingLeft={2} backgroundColor={background}>
          <Markdown text={e.props.text} />
        </Box>
        <Box height={1} overflow="hidden">
          <Text color={background}>{BOTTOM_EDGE}</Text>
        </Box>
      </Box>
    )
  })
}
