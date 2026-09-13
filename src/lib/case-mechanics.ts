export const STEP_PX = 254
export const TILE_PX = 240

export function priceRarity(priceInThousands: number) {
  return priceInThousands <= 40 ? 0 : priceInThousands <= 65 ? 1 : priceInThousands <= 100 ? 2 : priceInThousands <= 130 ? 3 : 4
}

export const RARITY_COLORS = ['#4b69ff', '#8847ff', '#d32ce6', '#eb4b4b', '#e4ae39'] as const
export const RARITY_LABELS = ['Phổ thông', 'Cao cấp', 'Đặc biệt', 'Huyền thoại', 'Thần thoại'] as const

type PricedMeal = { price: number }

const TARGET_LUNCH_PRICE = 50
const LOG_PRICE_SPREAD = 0.35

export function createFoodSelector<T extends PricedMeal>(population: T[], target = TARGET_LUNCH_PRICE) {
  if (!population.length) return null
  const min = Math.min(...population.map((f) => f.price))
  const max = Math.max(...population.map((f) => f.price))
  const clamped = Math.min(max, Math.max(min, target))
  const counts = new Map<number, number>()
  population.forEach((f) => counts.set(f.price, (counts.get(f.price) || 0) + 1))
  const logs = population.map((f) => Math.log(f.price / 50))
  const prior = logs.map((x, i) => -0.5 * (x / LOG_PRICE_SPREAD) ** 2 - Math.log(counts.get(population[i].price)!))
  function weights(tilt: number) {
    const logits = logs.map((x, i) => prior[i] + tilt * x)
    const anchor = Math.max(...logits)
    const raw = logits.map((x) => Math.exp(x - anchor))
    const sum = raw.reduce((s, x) => s + x, 0)
    return raw.map((x) => x / sum)
  }
  const mean = (w: number[]) => population.reduce((s, f, i) => s + f.price * w[i], 0)
  let raw: number[]
  if (clamped === min || clamped === max) {
    const n = counts.get(clamped)!
    raw = population.map((f) => (f.price === clamped ? 1 / n : 0))
  } else {
    let lo = -1
    let hi = 1
    while (mean(weights(lo)) > clamped) lo *= 2
    while (mean(weights(hi)) < clamped) hi *= 2
    for (let i = 0; i < 80; i++) {
      const mid = (lo + hi) / 2
      if (mean(weights(mid)) < clamped) lo = mid
      else hi = mid
    }
    raw = weights((lo + hi) / 2)
  }
  const probabilities = new Map(population.map((f, i) => [f, raw[i]]))
  return {
    expectedPrice: mean(raw),
    choose(items: T[], random = Math.random): T {
      const w = items.map((f) => probabilities.get(f) ?? 0)
      const sum = w.reduce((s, p) => s + p, 0)
      if (sum <= 0) return items[Math.floor(random() * items.length)]
      let remaining = random() * sum
      for (let i = 0; i < items.length; i++) if ((remaining -= w[i]) < 0) return items[i]
      return items[items.length - 1]
    },
  }
}

export function stopFraction(random = Math.random) {
  return (Math.floor(random() * 81) + 10) / 100
}

export function createSpinProfile(random = Math.random) {
  return { durationMs: 7500 + Math.floor(random() * 2001), tiles: 30 + Math.floor(random() * 11), friction: 2.7 + random() * 0.6 }
}

export function spinProgress(progress: number, friction: number) {
  const p = Math.max(0, Math.min(1, progress))
  return 1 - Math.pow(1 - p, friction)
}

export function priceLabel(thousands: number | string) {
  const n = Number(thousands)
  return `${n.toLocaleString('vi-VN')}.000đ`
}
