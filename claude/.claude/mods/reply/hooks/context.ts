import type { Elements, UiPressArgument } from 'claude-code'

/**
 * What every part needs to draw: the surface's elements, the room right of the bullet column, and a press handler
 * copying `text` then toasting `toast` (mods may not pass `$` around, so register.tsx builds it).
 */
export type Ctx = {
  ui: Pick<Elements['terminal'], 'Box' | 'Text' | 'Button' | 'Markdown' | 'Code'>
  available: number
  copy: (text: string, toast: string) => (press: UiPressArgument) => Promise<void>
}

// Powerline round caps, for pills
export const LEFT_CAP = ''
export const RIGHT_CAP = ''
// Background of the author's terminal theme (ghostty, hsablonniere-dark)
export const TERMINAL_BG = '#000000'
export const MARGIN = 2
