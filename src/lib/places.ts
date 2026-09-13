import { matchCatalogFood, type Food } from './foods'
import { priceRarity } from './case-mechanics'
import { districtById, provinceById } from './vietnam'

const STORAGE_KEY = 'baongocangi-places'

export type Place = {
  id: string
  dishName: string
  restaurant: string
  address: string
  provinceId: string
  districtId: string
  stars: number
  eatAgain: boolean
  price: number
  notes: string
  createdAt: number
  image?: number
}

export type PlaceDraft = Omit<Place, 'id' | 'createdAt'>

export function mapsUrl(place: Pick<Place, 'restaurant' | 'address' | 'provinceId' | 'districtId'>) {
  const province = provinceById(place.provinceId)
  const district = districtById(province, place.districtId)
  const query = [place.restaurant, place.address, district?.name, province?.name].filter(Boolean).join(', ')
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}`
}

export function loadPlaces(): Place[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw) as Place[]
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

export function savePlaces(places: Place[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(places))
}

export function placeToFood(place: Place): Food {
  const matched = matchCatalogFood(place.dishName)
  const price = place.price || matched?.price || 50
  const province = provinceById(place.provinceId)
  const district = districtById(province, place.districtId)
  return {
    name: place.dishName,
    sub: [place.restaurant, place.address, district?.name, province?.name].filter(Boolean).join(' • '),
    price,
    rarity: priceRarity(price),
    image: place.image ?? matched?.image ?? -1,
    veg: matched?.veg,
    quip: place.notes || matched?.quip || '',
    customId: `place-${place.id}`,
    placeId: place.id,
    restaurant: place.restaurant,
    address: place.address,
    provinceName: province?.name,
    districtName: district?.name,
    stars: place.stars,
    eatAgain: place.eatAgain,
  }
}

export function createPlace(draft: PlaceDraft): Place {
  const matched = matchCatalogFood(draft.dishName)
  return {
    ...draft,
    id: crypto.randomUUID(),
    createdAt: Date.now(),
    image: draft.image ?? matched?.image,
    stars: Math.min(5, Math.max(1, Math.round(draft.stars))),
  }
}
