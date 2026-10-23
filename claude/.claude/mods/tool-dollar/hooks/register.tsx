import type { Register } from 'claude-code'

const LABELS: Record<string, [string, string, string]> = {
  Bash: ['Ran', 'shell command', 'shell commands'],
  Read: ['Read', 'file', 'files'],
  Grep: ['Searched', 'pattern', 'patterns'],
  Glob: ['Searched', 'pattern', 'patterns'],
  Edit: ['Edited', 'file', 'files'],
  Write: ['Wrote', 'file', 'files'],
  WebFetch: ['Fetched', 'page', 'pages'],
  WebSearch: ['Searched', 'web query', 'web queries'],
}

export const register: Register = on => {
  on('ui.render', { component: 'ToolGroup' }, ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const counts = new Map<string, number>()
    for (const call of e.props.calls) {
      counts.set(call.tool, (counts.get(call.tool) ?? 0) + 1)
    }

    const parts = [...counts].map(([tool, n]) => {
      const [verb, one, many] = LABELS[tool] ?? ['Used', tool, `${tool} calls`]

      return (
        <Text dimColor>
          {verb} <Text bold>{n}</Text> {n === 1 ? one : many}
        </Text>
      )
    })

    return (
      <Box flexDirection="row" marginY={1}>
        <Box width={2} flexShrink={0}>
          <Text dimColor>$</Text>
        </Box>
        <Box flexDirection="row" gap={1}>
          {parts}
        </Box>
      </Box>
    )
  })
}
