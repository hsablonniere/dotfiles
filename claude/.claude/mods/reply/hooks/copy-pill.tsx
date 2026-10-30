import { LEFT_CAP, RIGHT_CAP, type Ctx } from './context'

const COPY_BG = '#3b4048'
const COPY_FG = '#c0c4cc'

// A pill on the `bg` of the row it sits on. The terminal inverts a hovered button, so the caps' hover colors are
// pre-inverted.
export const copyPill = ({ copy, ui: { Button, Text } }: Ctx, scope: string, label: string, text: string, toast: string, bg: string) => (
  <Button
    plain
    key={scope}
    label={label}
    hover={{ scope }}
    onPress={copy(text, toast)}
  >
    <Text color={COPY_BG} backgroundColor={bg} hover={{ scope, color: bg, backgroundColor: COPY_FG }}>
      {LEFT_CAP}
    </Text>
    <Text color={COPY_FG} backgroundColor={COPY_BG}>
      {label}
    </Text>
    <Text color={COPY_BG} backgroundColor={bg} hover={{ scope, color: bg, backgroundColor: COPY_FG }}>
      {RIGHT_CAP}
    </Text>
  </Button>
)
