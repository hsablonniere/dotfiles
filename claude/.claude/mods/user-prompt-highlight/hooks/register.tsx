import type { Register } from 'claude-code'

const GREEN = '#87d787'
const BACKGROUND = '#0d2315'
const TOP_EDGE = '▄'.repeat(500)
const BOTTOM_EDGE = '▀'.repeat(500)

export const register: Register = on => {
  on('ui.render', { component: 'UserMessage' }, ($, e, next) => {
    if (e.props.origin.kind !== 'composer') {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)

    return (
      <Box flexDirection="column" marginTop={2}>
        <Box height={1} overflow="hidden">
          <Text color={BACKGROUND}>
            {TOP_EDGE}
          </Text>
        </Box>
        <Box flexDirection="row" paddingLeft={2} backgroundColor={BACKGROUND}>
          <Box flexGrow={1} flexShrink={1}>
            <Text color={GREEN} backgroundColor={BACKGROUND}>
              {e.props.text}
            </Text>
          </Box>
        </Box>
        <Box height={1} overflow="hidden">
          <Text color={BACKGROUND}>
            {BOTTOM_EDGE}
          </Text>
        </Box>
      </Box>
    )
  })
}
