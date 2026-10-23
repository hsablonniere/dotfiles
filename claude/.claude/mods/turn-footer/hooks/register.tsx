import type { Register } from 'claude-code'

type Info = { time: string; tools: number }
type Turn = { tools: number; isActive: boolean; completedAt: number; updatedAt: number }

const STALE_MS = 60 * 60 * 1000
const GRACE_MS = 5000
const MAX_INFOS = 100

const formatDuration = (ms: number) => {
  const total = Math.round(ms / 1000)
  const minutes = Math.floor(total / 60)

  return minutes > 0 ? `${minutes}m ${total % 60}s` : `${total}s`
}

const formatTime = (ms: number) => {
  const date = new Date(ms)
  const pad = (n: number) => String(n).padStart(2, '0')

  return `${pad(date.getHours())}:${pad(date.getMinutes())}`
}

type Store = {
  store: {
    get: (key: string) => Promise<unknown>
    set: (key: string, value: unknown) => Promise<void>
  }
  clock: { now: () => Promise<number> }
}

async function readTurn($: Store): Promise<Turn> {
  return (
    ((await $.store.get('turn')) as Turn | undefined) ?? {
      tools: 0,
      isActive: false,
      completedAt: 0,
      updatedAt: 0,
    }
  )
}

async function writeTurn($: Store, patch: Partial<Turn>) {
  const turn = await readTurn($)
  await $.store.set('turn', { ...turn, ...patch, updatedAt: await $.clock.now() })
}

export const register: Register = on => {
  const cache = new Map<number, Info>()

  on('turn.start', async ($, e, next) => {
    await writeTurn($, { tools: 0, isActive: true, completedAt: 0 })

    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    const turn = await readTurn($)
    await writeTurn($, { tools: turn.tools + 1 })

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    await writeTurn($, { isActive: false, completedAt: await $.clock.now() })

    return next(e)
  })

  on('ui.render', { component: 'TurnDuration' }, async ($, e, next) => {
    if (e.props.waitingFor || e.props.isExpanded) {
      return next(e)
    }

    const { Box, Text } = $.ui.resolve(e)
    const key = e.props.durationMs
    const infos = ((await $.store.get('infos')) as Record<string, Info> | undefined) ?? {}
    let info = infos[String(key)] ?? cache.get(key)

    if (!info) {
      const now = await $.clock.now()
      const turn = await readTurn($)
      const isLive =
        now - turn.updatedAt < STALE_MS && (turn.isActive || now - turn.completedAt < GRACE_MS)
      if (isLive) {
        info = { time: formatTime(now), tools: turn.tools }
        cache.set(key, info)
        const kept = Object.entries({ ...infos, [String(key)]: info }).slice(-MAX_INFOS)
        try {
          await $.store.set('infos', Object.fromEntries(kept))
        } catch {
          // the cache still serves this session
        }
      }
    }

    const parts = [formatDuration(key)]
    if (info) {
      parts.push(info.time)
      if (info.tools > 0) {
        parts.push(`${info.tools} tool${info.tools === 1 ? '' : 's'} used`)
      }
    }

    return (
      <Box flexDirection="row" marginTop={1}>
        <Box width={2} flexShrink={0}>
          <Text dimColor></Text>
        </Box>
        <Text dimColor>{parts.join(' · ')}</Text>
      </Box>
    )
  })
}
