import { Utensils } from 'lucide-react'
import type { Food } from '../lib/foods'

type AtlasCell = { file: string; cols: number; rows: number; index: number }

export function atlasFor(image: number): AtlasCell | null {
  if (image < 0) return null
  if (image >= 120) {
    const i = image - 120
    return { file: `food-common-${Math.floor(i / 12)}`, cols: 4, rows: 3, index: i % 12 }
  }
  if (image >= 72) {
    const i = image - 72
    return { file: `food-lunch-${Math.floor(i / 12)}`, cols: 4, rows: 3, index: i % 12 }
  }
  if (image >= 36) {
    const i = image - 36
    return { file: `food-expanded-${Math.floor(i / 12)}`, cols: 4, rows: 3, index: i % 12 }
  }
  return { file: `food-hd-${Math.floor(image / 4)}`, cols: 2, rows: 2, index: image % 4 }
}

export function FoodImage({ food }: { food: Food }) {
  if (food.photo) {
    return (
      <div
        role="img"
        aria-label={food.name}
        className="food-image photo"
      >
        <img src={food.photo} alt="" />
      </div>
    )
  }
  const cell = atlasFor(food.image)
  if (!cell) {
    return (
      <div className="food-image custom-food-art" role="img" aria-label={food.name}>
        <Utensils size={48} />
      </div>
    )
  }
  const col = cell.index % cell.cols
  const row = Math.floor(cell.index / cell.cols)
  return (
    <div role="img" aria-label={food.name} className="food-image">
      <img
        alt=""
        className="food-atlas"
        src={`/${cell.file}.webp`}
        style={{
          width: `${cell.cols * 100}%`,
          height: `${cell.rows * 100}%`,
          left: `${-col * 100}%`,
          top: `${-row * 100}%`,
        }}
      />
    </div>
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
