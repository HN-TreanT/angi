import { useEffect, useMemo, useState, type FormEvent } from 'react'
import { MapPin, Pencil, Plus, Star, Trash2, UtensilsCrossed, RotateCcw } from 'lucide-react'
import { foods } from '../lib/foods'
import { mapsUrl, placeToFood, type Place, type PlaceDraft } from '../lib/places'
import { provinceById, shortPlaceName, sortedProvinces } from '../lib/vietnam'
import { FoodImage } from './FoodImage'

const EMPTY_DRAFT: PlaceDraft = {
  dishName: '',
  restaurant: '',
  address: '',
  provinceId: '01',
  districtId: '001',
  stars: 4,
  eatAgain: true,
  price: 50,
  notes: '',
}

type SortKey = 'area' | 'stars' | 'newest' | 'dish'
type GroupKey = 'district' | 'province' | 'none'

export function PlacesLog({
  places,
  onSave,
  onDelete,
  editing,
  onEdit,
  presetDish,
  onPresetConsumed,
}: {
  places: Place[]
  onSave: (draft: PlaceDraft, id?: string) => void | Promise<void>
  onDelete: (id: string) => void | Promise<void>
  editing: Place | null
  onEdit: (place: Place | null) => void
  presetDish?: string
  onPresetConsumed?: () => void
}) {
  const [formOpen, setFormOpen] = useState(Boolean(presetDish) || Boolean(editing))
  const [draft, setDraft] = useState<PlaceDraft>(() =>
    editing ? toDraft(editing) : { ...EMPTY_DRAFT, dishName: presetDish ?? '' },
  )
  const [provinceFilter, setProvinceFilter] = useState('')
  const [districtFilter, setDistrictFilter] = useState('')
  const [dishFilter, setDishFilter] = useState('')
  const [eatAgainOnly, setEatAgainOnly] = useState(false)
  const [minStars, setMinStars] = useState(0)
  const [sortKey, setSortKey] = useState<SortKey>('area')
  const [groupKey, setGroupKey] = useState<GroupKey>('district')

  useEffect(() => {
    if (presetDish) onPresetConsumed?.()
  }, [presetDish, onPresetConsumed])

  const filterProvince = sortedProvinces.find((p) => p.id === provinceFilter)
  const draftProvince = provinceById(draft.provinceId)

  const filtered = useMemo(() => {
    const needle = dishFilter.trim().toLowerCase()
    return places.filter((place) => {
      if (provinceFilter && place.provinceId !== provinceFilter) return false
      if (districtFilter && place.districtId !== districtFilter) return false
      if (eatAgainOnly && !place.eatAgain) return false
      if (minStars && place.stars < minStars) return false
      if (needle) {
        const province = provinceById(place.provinceId)
        const district = province?.districts.find((d) => d.id === place.districtId)
        const blob = `${place.dishName} ${place.restaurant} ${place.address} ${province?.name ?? ''} ${district?.name ?? ''}`.toLowerCase()
        if (!blob.includes(needle)) return false
      }
      return true
    })
  }, [places, provinceFilter, districtFilter, dishFilter, eatAgainOnly, minStars])

  const sorted = useMemo(() => {
    return [...filtered].sort((a, b) => {
      if (sortKey === 'stars') return b.stars - a.stars || a.dishName.localeCompare(b.dishName, 'vi')
      if (sortKey === 'newest') return b.createdAt - a.createdAt
      if (sortKey === 'dish') return a.dishName.localeCompare(b.dishName, 'vi')
      const pa = provinceById(a.provinceId)?.name ?? ''
      const pb = provinceById(b.provinceId)?.name ?? ''
      if (pa !== pb) return pa.localeCompare(pb, 'vi')
      const da = provinceById(a.provinceId)?.districts.find((d) => d.id === a.districtId)?.name ?? ''
      const db = provinceById(b.provinceId)?.districts.find((d) => d.id === b.districtId)?.name ?? ''
      if (da !== db) return da.localeCompare(db, 'vi')
      return a.dishName.localeCompare(b.dishName, 'vi')
    })
  }, [filtered, sortKey])

  const groups = useMemo(() => {
    if (groupKey === 'none') return [{ key: 'all', title: 'Tất cả quán', items: sorted }]
    const map = new Map<string, Place[]>()
    for (const place of sorted) {
      const province = provinceById(place.provinceId)
      const district = province?.districts.find((d) => d.id === place.districtId)
      const key =
        groupKey === 'province'
          ? province?.name ?? 'Khác'
          : `${shortPlaceName(province?.name ?? 'Khác')} · ${district?.name ?? 'Chưa rõ quận'}`
      const list = map.get(key) ?? []
      list.push(place)
      map.set(key, list)
    }
    return [...map.entries()].map(([title, items]) => ({ key: title, title, items }))
  }, [sorted, groupKey])

  function openNew(dish = '') {
    setDraft({ ...EMPTY_DRAFT, dishName: dish || presetDish || '' })
    onEdit(null)
    setFormOpen(true)
  }

  function openEdit(place: Place) {
    setDraft(toDraft(place))
    onEdit(place)
    setFormOpen(true)
  }

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!draft.dishName.trim() || !draft.restaurant.trim() || !draft.address.trim()) return
    await onSave(draft, editing?.id)
    setFormOpen(false)
    onEdit(null)
    setDraft(EMPTY_DRAFT)
    onPresetConsumed?.()
  }

  return (
    <section className="places-page">
      <div className="section-heading places-heading">
        <div>
          <span className="eyebrow">Nhật ký quán</span>
          <h2>
            Món đã ăn <span>{places.length.toString().padStart(2, '0')}</span>
          </h2>
          <p>Lưu quán Hà Nội và tỉnh khác, kèm địa chỉ, sao và quyết định có ăn lại không.</p>
        </div>
        <button className="open-button compact" onClick={() => openNew()}>
          <Plus size={18} /> Thêm món đã ăn
        </button>
      </div>

      <div className="place-filters">
        <label>
          Tỉnh / thành
          <select
            value={provinceFilter}
            onChange={(e) => {
              setProvinceFilter(e.target.value)
              setDistrictFilter('')
            }}
          >
            <option value="">Tất cả</option>
            {sortedProvinces.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Quận / huyện
          <select value={districtFilter} onChange={(e) => setDistrictFilter(e.target.value)} disabled={!filterProvince}>
            <option value="">Tất cả</option>
            {filterProvince?.districts.map((d) => (
              <option key={d.id} value={d.id}>
                {d.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Tìm món / quán
          <input value={dishFilter} onChange={(e) => setDishFilter(e.target.value)} placeholder="Phở, bún chả, tên quán..." />
        </label>
        <label>
          Sắp xếp
          <select value={sortKey} onChange={(e) => setSortKey(e.target.value as SortKey)}>
            <option value="area">Theo khu vực</option>
            <option value="stars">Sao cao nhất</option>
            <option value="newest">Mới thêm</option>
            <option value="dish">Tên món</option>
          </select>
        </label>
        <label>
          Nhóm theo
          <select value={groupKey} onChange={(e) => setGroupKey(e.target.value as GroupKey)}>
            <option value="district">Quận / huyện</option>
            <option value="province">Tỉnh / thành</option>
            <option value="none">Không nhóm</option>
          </select>
        </label>
        <label className="inline-check">
          <input type="checkbox" checked={eatAgainOnly} onChange={(e) => setEatAgainOnly(e.target.checked)} />
          Chỉ quán đáng ăn lại
        </label>
        <label>
          Tối thiểu
          <select value={minStars} onChange={(e) => setMinStars(Number(e.target.value))}>
            <option value={0}>Mọi mức sao</option>
            <option value={3}>Từ 3 sao</option>
            <option value={4}>Từ 4 sao</option>
            <option value={5}>5 sao</option>
          </select>
        </label>
      </div>

      {!places.length && (
        <div className="empty-places">
          <UtensilsCrossed size={28} />
          <p>Chưa có quán nào. Thêm món đã ăn ở Hà Nội hoặc tỉnh khác để lần sau quay đúng địa chỉ.</p>
        </div>
      )}

      {places.length > 0 && !sorted.length && <p className="empty-places">Không có quán khớp bộ lọc.</p>}

      {groups.map((group) => (
        <div className="place-group" key={group.key}>
          {groupKey !== 'none' && sorted.length > 0 && (
            <h3>
              {group.title} <span>{group.items.length}</span>
            </h3>
          )}
          <div className="place-grid">
            {group.items.map((place) => {
              const food = placeToFood(place)
              return (
                <article className={`place-card ${place.eatAgain ? 'worth-again' : 'skip-again'}`} key={place.id}>
                  <FoodImage food={food} />
                  <div className="place-copy">
                    <strong>{place.dishName}</strong>
                    <span className="place-shop">{place.restaurant}</span>
                    <span className="place-addr">
                      <MapPin size={13} /> {place.address}
                      {food.districtName ? ` · ${food.districtName}` : ''}
                      {food.provinceName ? ` · ${shortPlaceName(food.provinceName)}` : ''}
                    </span>
                    <StarRow value={place.stars} />
                    <em className={place.eatAgain ? 'again-yes' : 'again-no'}>
                      {place.eatAgain ? 'Đáng ăn lại' : 'Không cần ăn lại'}
                    </em>
                    {place.notes && <p className="place-notes">{place.notes}</p>}
                    <div className="place-actions">
                      <a href={mapsUrl(place)} target="_blank" rel="noreferrer">
                        Mở Maps
                      </a>
                      <button type="button" onClick={() => openEdit(place)} aria-label="Sửa">
                        <Pencil size={14} />
                      </button>
                      <button type="button" className="danger" onClick={() => onDelete(place.id)} aria-label="Xóa">
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                </article>
              )
            })}
          </div>
        </div>
      ))}

      {formOpen && (
        <div className="modal-backdrop" onClick={() => { setFormOpen(false); onEdit(null) }}>
          <form className="place-form" onClick={(e) => e.stopPropagation()} onSubmit={submit}>
            <div className="form-head">
              <h3>{editing ? 'Sửa món đã ăn' : 'Thêm món đã ăn'}</h3>
              <p>Đánh sao và quyết định có xứng đáng quay lại quán này không.</p>
            </div>
            <label>
              Món ăn
              <input
                list="dish-catalog"
                required
                value={draft.dishName}
                onChange={(e) => setDraft({ ...draft, dishName: e.target.value })}
                placeholder="Bún chả, phở bò..."
              />
              <datalist id="dish-catalog">
                {foods.map((food) => (
                  <option key={food.image} value={food.name} />
                ))}
              </datalist>
            </label>
            <label>
              Tên quán
              <input
                required
                value={draft.restaurant}
                onChange={(e) => setDraft({ ...draft, restaurant: e.target.value })}
                placeholder="Bún chả Hương Liên"
              />
            </label>
            <label className="full">
              Địa chỉ
              <input
                required
                value={draft.address}
                onChange={(e) => setDraft({ ...draft, address: e.target.value })}
                placeholder="24 Lê Văn Hưu"
              />
            </label>
            <label>
              Tỉnh / thành
              <select
                value={draft.provinceId}
                onChange={(e) => {
                  const next = provinceById(e.target.value)
                  setDraft({ ...draft, provinceId: e.target.value, districtId: next?.districts[0]?.id ?? '' })
                }}
              >
                {sortedProvinces.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Quận / huyện
              <select value={draft.districtId} onChange={(e) => setDraft({ ...draft, districtId: e.target.value })}>
                {draftProvince?.districts.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Giá khoảng (nghìn đồng)
              <input
                type="number"
                min={15}
                max={400}
                value={draft.price}
                onChange={(e) => setDraft({ ...draft, price: Number(e.target.value) })}
              />
            </label>
            <fieldset className="stars-field">
              <legend>Đánh giá món</legend>
              <StarPicker value={draft.stars} onChange={(stars) => setDraft({ ...draft, stars })} />
              <span>{draft.stars}/5 sao</span>
            </fieldset>
            <label className="eat-again-toggle">
              <input type="checkbox" checked={draft.eatAgain} onChange={(e) => setDraft({ ...draft, eatAgain: e.target.checked })} />
              <RotateCcw size={16} />
              {draft.eatAgain ? 'Xứng đáng ăn lại' : 'Không cần ăn lại'}
            </label>
            <label className="full">
              Ghi chú
              <textarea
                rows={3}
                value={draft.notes}
                onChange={(e) => setDraft({ ...draft, notes: e.target.value })}
                placeholder="Nước chấm vừa, hết bàn lúc 12h, gửi xe dễ..."
              />
            </label>
            <div className="form-actions">
              <button type="button" className="ghost" onClick={() => { setFormOpen(false); onEdit(null) }}>
                Hủy
              </button>
              <button type="submit" className="open-button compact">
                {editing ? 'Lưu thay đổi' : 'Lưu quán'}
              </button>
            </div>
          </form>
        </div>
      )}
    </section>
  )
}

function toDraft(place: Place): PlaceDraft {
  return {
    dishName: place.dishName,
    restaurant: place.restaurant,
    address: place.address,
    provinceId: place.provinceId,
    districtId: place.districtId,
    stars: place.stars,
    eatAgain: place.eatAgain,
    price: place.price,
    notes: place.notes,
    image: place.image,
  }
}

function StarRow({ value }: { value: number }) {
  return (
    <span className="star-row" aria-label={`${value} sao`}>
      {Array.from({ length: 5 }, (_, i) => (
        <Star key={i} size={14} fill={i < value ? '#e4ae39' : 'transparent'} color="#e4ae39" />
      ))}
    </span>
  )
}

function StarPicker({ value, onChange }: { value: number; onChange: (value: number) => void }) {
  return (
    <div className="star-picker">
      {Array.from({ length: 5 }, (_, i) => {
        const n = i + 1
        return (
          <button type="button" key={n} onClick={() => onChange(n)} aria-label={`${n} sao`} className={n <= value ? 'on' : ''}>
            <Star size={22} fill={n <= value ? '#e4ae39' : 'transparent'} color="#e4ae39" />
          </button>
        )
      })}
    </div>
  )
}
