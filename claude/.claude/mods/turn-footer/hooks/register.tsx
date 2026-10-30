import type { Register } from 'claude-code'

type Info = { time: string; tools: number }
type Turn = { tools: number; isActive: boolean; completedAt: number; updatedAt: number }

const STALE_MS = 60 * 60 * 1000
const GRACE_MS = 5000
const MAX_INFOS = 100
const ANSWER_TOLERANCE_MS = 1000
const PILL_BG = '#3b4048'
const PILL_FG = '#c0c4cc'
const TERMINAL_BG = '#000000'
const LEFT_CAP = '\ue0b6'
const RIGHT_CAP = '\ue0b4'

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

// turn.complete and the footer may round the duration differently
async function findAnswer($: Store, durationMs: number): Promise<string | undefined> {
  const answers = ((await $.store.get('answers')) as Record<string, string> | undefined) ?? {}
  const closest = Object.keys(answers)
    .map(Number)
    .filter(ms => Math.abs(ms - durationMs) <= ANSWER_TOLERANCE_MS)
    .sort((a, b) => Math.abs(a - durationMs) - Math.abs(b - durationMs))[0]

  return closest === undefined ? undefined : answers[String(closest)]
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
    if (e.agentId !== undefined) {
      return next(e)
    }
    await writeTurn($, { isActive: false, completedAt: await $.clock.now() })
    if (e.answer !== '') {
      const answers = ((await $.store.get('answers')) as Record<string, string> | undefined) ?? {}
      const kept = Object.entries({ ...answers, [String(e.durationMs)]: e.answer }).slice(-MAX_INFOS)
      try {
        await $.store.set('answers', Object.fromEntries(kept))
      } catch {
        // copy is best effort
      }
    }

    return next(e)
  })

  on('ui.render', { component: 'TurnDuration' }, async ($, e, next) => {
    if (e.props.waitingFor || e.props.isExpanded) {
      return next(e)
    }

    const { Box, Text, Button } = $.ui.resolve(e)
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

    const scope = `copy:${key}`

    return (
      <Box flexDirection="row" marginTop={1}>
        <Box width={2} flexShrink={0}>
          <Text dimColor></Text>
        </Box>
        <Text dimColor>{parts.join(' · ')}</Text>
        {info ? (
          <Box flexDirection="row">
            <Text dimColor>{' · '}</Text>
            <Button
              plain
              key={scope}
              label="copy"
              hover={{ scope }}
              onPress={async press => {
                const answer = await findAnswer($, key)
                if (answer === undefined) {
                  await $.ui.toast('No reply to copy')
                  return
                }
                const result = await $.ui.copy({ text: answer, surface: press.surface })
                await $.ui.toast(result.isCopied ? 'Reply copied' : `Copy failed: ${result.reason}`)
              }}
            >
              {/* the terminal inverts a hovered button, so the caps' hover colors are pre-inverted */}
              <Text color={PILL_BG} hover={{ scope, color: TERMINAL_BG, backgroundColor: PILL_FG }}>
                {LEFT_CAP}
              </Text>
              <Text color={PILL_FG} backgroundColor={PILL_BG}>
                copy
              </Text>
              <Text color={PILL_BG} hover={{ scope, color: TERMINAL_BG, backgroundColor: PILL_FG }}>
                {RIGHT_CAP}
              </Text>
            </Button>
          </Box>
        ) : null}
      </Box>
    )
  })
}
