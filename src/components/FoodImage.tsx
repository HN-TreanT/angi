import { Utensils } from 'lucide-react'
import type { Food } from '../lib/foods'

export function FoodImage({ food }: { food: Food }) {
  if (food.photo) {
    return (
      <div
        role="img"
        aria-label={food.name}
        className="food-image photo"
        style={{ backgroundImage: `url(${food.photo})` }}
      />
    )
  }
  if (food.image < 0) {
    return (
      <div className="food-image custom-food-art" role="img" aria-label={food.name}>
        <Utensils size={48} />
      </div>
    )
  }
  const common = food.image >= 120
  const lunch = food.image >= 72 && !common
  const expanded = food.image >= 36
  const index = common ? (food.image - 120) % 12 : lunch ? (food.image - 72) % 12 : expanded ? (food.image - 36) % 12 : food.image % 4
  const atlas = common
    ? `food-common-${Math.floor((food.image - 120) / 12)}`
    : lunch
      ? `food-lunch-${Math.floor((food.image - 72) / 12)}`
      : expanded
        ? `food-expanded-${Math.floor((food.image - 36) / 12)}`
        : `food-hd-${Math.floor(food.image / 4)}`
  const yStops = common ? [0, 50, 100] : [0, 46, 92]
  return (
    <div
      role="img"
      aria-label={food.name}
      className="food-image"
      style={{
        clipPath: common ? 'inset(0 0 4% 0)' : lunch ? 'inset(0 0 7% 0)' : undefined,
        backgroundImage: `url(/${atlas}.webp)`,
        backgroundSize: expanded ? '400% 300%' : '200% 200%',
        backgroundPosition: expanded
          ? `${(index % 4 / 3) * 100}% ${yStops[Math.floor(index / 4)]}%`
          : `${(index % 2) * 100}% ${Math.floor(index / 2) * 100}%`,
      }}
    />
  )
}

export function MysteryArt() {
  return (
    <div className="mystery-art" role="img" aria-label="Món bí ẩn">
      <div className="mystery-rays" />
      <svg className="mystery-emblem" viewBox="0 0 240 150" aria-hidden="true">
        <path className="gold-orbit" d="M120 5 174 27 193 75 174 123 120 145 66 123 47 75 66 27Z" />
        <path fill="#b27a16" d="m120 10 16 38 44-18-18 38 55 7-55 14 18 34-44-16-16 33-16-33-44 16 18-34-55-14 55-7-18-38 44 18Z" />
        <path fill="#ffe59a" d="m120 18 13 41 38-21-23 35 49 2-49 10 23 31-38-18-13 34-13-34-38 18 23-31-49-10 49-2-23-35 38 21Z" />
        <path fill="#372414" stroke="#eac366" strokeWidth="2" d="m120 34 35 20 0 42-35 20-35-20V54Z" />
        <path fill="#fff3ba" d="M104 61c0-22 36-24 36-2 0 10-12 13-13 20v4h-13v-6c0-9 12-12 12-18 0-8-11-7-11 2zm10 28h13v13h-13z" />
      </svg>
      <div className="mystery-sheen" />
    </div>
  )
}
