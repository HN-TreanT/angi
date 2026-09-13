import raw from '../data/vietnam.json'

export type District = { id: string; name: string }
export type Province = { id: string; name: string; districts: District[] }

export const provinces = raw as Province[]

const HANOI_ID = '01'

export const sortedProvinces = [...provinces].sort((a, b) => {
  if (a.id === HANOI_ID) return -1
  if (b.id === HANOI_ID) return 1
  return a.name.localeCompare(b.name, 'vi')
})

export function provinceById(id: string) {
  return provinces.find((p) => p.id === id)
}

export function districtById(province: Province | undefined, id: string) {
  return province?.districts.find((d) => d.id === id)
}

export function shortPlaceName(name: string) {
  return name.replace(/^(Thành phố |Tỉnh |Quận |Huyện |Thị xã |Thành phố )/i, '')
}

export function foldVi(value: string) {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'd')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim()
}

export function matchesPlaceText(place: { address: string; restaurant: string; dishName: string }, needle: string) {
  const parts = foldVi(needle).split(' ').filter(Boolean)
  if (!parts.length) return true
  const haystack = foldVi(`${place.address} ${place.restaurant} ${place.dishName}`)
  return parts.every((part) => haystack.includes(part))
}
