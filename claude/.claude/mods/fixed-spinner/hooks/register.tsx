import type { Register } from 'claude-code'

const LABELS = {
  requesting: 'Waiting',
  thinking: 'Thinking',
  'tool-input': 'Preparing',
  'tool-use': 'Running',
  responding: 'Writing',
} as const

export const register: Register = on => {
  on('ui.render', { component: 'Spinner' }, ($, e, next) => {
    if (e.props.message !== null) {
      return next(e)
    }

    return next({ ...e, props: { ...e.props, word: LABELS[e.props.mode] } })
  })
}
