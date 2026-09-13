import { useCallback, useEffect, useMemo, useRef, useState, type CSSProperties } from 'react'
import { ArrowUpRight, Leaf, MapPin, Sparkles, Star, Utensils, Volume2, VolumeX } from 'lucide-react'
import { FoodImage, MysteryArt } from './components/FoodImage'
import { PlacesLog } from './components/PlacesLog'
import { foods, type Food } from './lib/foods'
import {
  RARITY_COLORS,
  RARITY_LABELS,
  STEP_PX,
  TILE_PX,
  createFoodSelector,
  createSpinProfile,
  priceLabel,
  spinProgress,
  stopFraction,
} from './lib/case-mechanics'
import { createPlaceApi, deletePlaceApi, fetchPlaces, healthCheck, updatePlaceApi } from './lib/api'
import { createPlace, loadPlaces, mapsUrl, placeToFood, savePlaces, type Place, type PlaceDraft } from './lib/places'
import { provinceById, sortedProvinces, foldVi, matchesPlaceText } from './lib/vietnam'

type Tab = 'spin' | 'places'
type PoolMode = 'catalog' | 'eaten' | 'both'

const BUDGETS = ['35', '50', '75', '100', '150'] as const

export default function App() {
  const [tab, setTab] = useState<Tab>('spin')
  const [places, setPlaces] = useState<Place[]>([])
  const [apiOk, setApiOk] = useState<boolean | null>(null)
  const [apiError, setApiError] = useState('')
  const [budget, setBudget] = useState('50')
  const [veg, setVeg] = useState(false)
  const [poolMode, setPoolMode] = useState<PoolMode>('catalog')
  const [eatAgainOnly, setEatAgainOnly] = useState(true)
  const [spinProvince, setSpinProvince] = useState('')
  const [spinDistrict, setSpinDistrict] = useState('')
  const [spinAddresses, setSpinAddresses] = useState<string[]>([])
  const [spinArea, setSpinArea] = useState('')
  const [spinning, setSpinning] = useState(false)
  const [moving, setMoving] = useState(false)
  const [result, setResult] = useState<Food | null>(null)
  const [revealed, setRevealed] = useState(false)
  const [sound, setSound] = useState(true)
  const [reel, setReel] = useState(() => foods.slice(0, 12).map((food, id) => ({ food, id })))
  const [visibleStart, setVisibleStart] = useState(0)
  const [editing, setEditing] = useState<Place | null>(null)
  const [presetDish, setPresetDish] = useState('')
  const [spins, setSpins] = useState(0)

  const busy = useRef(false)
  const viewport = useRef<HTMLDivElement>(null)
  const track = useRef<HTMLDivElement>(null)
  const position = useRef(-400)
  const frame = useRef(0)

  const attachTrack = useCallback((node: HTMLDivElement | null) => {
    track.current = node
    if (node) node.style.transform = `translate3d(${position.current}px,0,0)`
  }, [])

  const persist = (next: Place[]) => {
    setPlaces(next)
    savePlaces(next)
  }

  useEffect(() => {
    let live = true
    ;(async () => {
      try {
        await healthCheck()
        if (!live) return
        setApiOk(true)
        let remote = await fetchPlaces()
        if (!remote.length) {
          const local = loadPlaces()
          if (local.length) {
            for (const place of local) {
              await createPlaceApi({
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
              })
            }
            savePlaces([])
            remote = await fetchPlaces()
          }
        }
        if (live) setPlaces(remote)
      } catch (error) {
        if (!live) return
        setApiOk(false)
        setApiError(error instanceof Error ? error.message : 'Không kết nối được API')
        setPlaces(loadPlaces())
      }
    })()
    return () => {
      live = false
    }
  }, [])

  const selectedAddressKeys = useMemo(() => new Set(spinAddresses.map(foldVi)), [spinAddresses])
  const addressesPicked = selectedAddressKeys.size > 0
  const spinProvinceData = provinceById(spinProvince)

  const addressOptions = useMemo(() => {
    const seen = new Map<string, { address: string; count: number; dishes: string[] }>()
    for (const place of places) {
      if (eatAgainOnly && !place.eatAgain) continue
      if (spinProvince && place.provinceId !== spinProvince) continue
      if (spinDistrict && place.districtId !== spinDistrict) continue
      if (spinArea.trim() && !matchesPlaceText(place, spinArea)) continue
      const address = place.address.trim()
      if (!address) continue
      const key = foldVi(address)
      const current = seen.get(key)
      if (current) {
        current.count += 1
        if (!current.dishes.includes(place.dishName)) current.dishes.push(place.dishName)
      } else {
        seen.set(key, { address, count: 1, dishes: [place.dishName] })
      }
    }
    return [...seen.values()].sort((a, b) => a.address.localeCompare(b.address, 'vi'))
  }, [places, eatAgainOnly, spinProvince, spinDistrict, spinArea])

  const addressPlaces = useMemo(() => {
    if (!selectedAddressKeys.size) return []
    return places.filter((place) => {
      if (eatAgainOnly && !place.eatAgain) return false
      return selectedAddressKeys.has(foldVi(place.address))
    })
  }, [places, eatAgainOnly, selectedAddressKeys])

  const eatenFoods = useMemo(() => addressPlaces.map(placeToFood), [addressPlaces])

  const population = useMemo(() => {
    if (addressesPicked) return eatenFoods
    if (poolMode === 'eaten') return places.filter((place) => !eatAgainOnly || place.eatAgain).map(placeToFood)
    if (poolMode === 'both') return [...foods, ...places.filter((place) => !eatAgainOnly || place.eatAgain).map(placeToFood)]
    return foods
  }, [addressesPicked, eatenFoods, poolMode, foods, places, eatAgainOnly])

  const selectedAddressLabels = addressOptions.filter((option) => selectedAddressKeys.has(foldVi(option.address)))
  const locationLabel = (selectedAddressLabels.length ? selectedAddressLabels.map((option) => option.address) : spinAddresses).join(', ')

  function toggleSpinAddress(address: string) {
    const key = foldVi(address)
    setSpinAddresses((current) =>
      current.some((item) => foldVi(item) === key) ? current.filter((item) => foldVi(item) !== key) : [...current, address],
    )
  }

  function resetAddressFilters() {
    setSpinDistrict('')
    setSpinAddresses([])
  }

  const eligible = useMemo(() => population.filter((f) => !veg || f.veg), [population, veg])
  const target = Number(budget)
  const selector = useMemo(() => createFoodSelector(eligible, target), [eligible, target])

  useEffect(() => {
    if (spinning || !eligible.length || !selector) return
    setReel((current) =>
      current.map((item) => ({
        ...item,
        food: eligible.find((f) => (f.customId ?? f.image) === (item.food.customId ?? item.food.image)) ?? selector.choose(eligible),
      })),
    )
  }, [eligible, selector, spinning])

  useEffect(() => () => cancelAnimationFrame(frame.current), [])

  function openCase() {
    if (busy.current || !eligible.length || !selector || !track.current || !viewport.current) return
    busy.current = true
    const winner = selector.choose(eligible)
    const step = STEP_PX
    const start = position.current
    const width = viewport.current.clientWidth
    const center = Math.floor((width / 2 - start) / step)
    const profile = createSpinProfile()
    const targetSlot = center + profile.tiles
    const end = width / 2 - TILE_PX * stopFraction() - targetSlot * step
    const rightEdge = Math.ceil((width - start) / step) + 1
    const items = reel.filter((item) => item.id >= center - Math.ceil(width / step) - 2 && item.id <= rightEdge)
    const last = Math.max(...items.map((item) => item.id), 0)
    const recent: Food[] = []
    for (let id = last + 1; id <= targetSlot + 4; id++) {
      const alternatives = eligible.filter((food) => !recent.includes(food))
      const food = id === targetSlot ? winner : selector.choose(alternatives.length ? alternatives : eligible)
      items.push({ id, food })
      recent.push(food)
      if (recent.length > 8) recent.shift()
    }
    setReel(items)
    setSpinning(true)
    setMoving(true)
    setResult(null)
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const duration = reduced ? 180 : profile.durationMs
    const started = performance.now()
    let renderedStart = visibleStart
    const animate = (now: number) => {
      const progress = Math.max(0, Math.min(1, (now - started) / duration))
      const next = start + (end - start) * spinProgress(progress, profile.friction)
      position.current = next
      const firstVisible = Math.max(0, Math.floor(-next / step))
      if (firstVisible - renderedStart >= 4 || firstVisible < renderedStart) {
        renderedStart = Math.max(0, firstVisible - 2)
        setVisibleStart(renderedStart)
      }
      if (track.current) track.current.style.transform = `translate3d(${next}px,0,0)`
      if (progress < 1) {
        frame.current = requestAnimationFrame(animate)
        return
      }
      busy.current = false
      setSpinning(false)
      setMoving(false)
      setResult(winner)
      setRevealed(true)
      setSpins((n) => n + 1)
    }
    frame.current = requestAnimationFrame(animate)
  }

  async function savePlace(draft: PlaceDraft, id?: string) {
    try {
      if (id) {
        const updated = await updatePlaceApi(id, draft)
        setPlaces((current) => current.map((place) => (place.id === id ? updated : place)))
        return
      }
      const created = await createPlaceApi(draft)
      setPlaces((current) => [created, ...current])
      setPresetDish('')
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Không lưu được quán'
      setApiError(message)
      if (id) {
        persist(places.map((place) => (place.id === id ? { ...place, ...draft } : place)))
        return
      }
      persist([createPlace(draft), ...places])
    }
  }

  async function removePlace(id: string) {
    const previous = places
    setPlaces((current) => current.filter((place) => place.id !== id))
    try {
      await deletePlaceApi(id)
    } catch (error) {
      setPlaces(previous)
      setApiError(error instanceof Error ? error.message : 'Không xóa được quán')
    }
  }

  const inventory = useMemo(
    () => [...eligible].sort((a, b) => a.rarity - b.rarity || a.price - b.price || a.name.localeCompare(b.name, 'vi')),
    [eligible],
  )

  return (
    <div className="site-shell">
      <header>
        <a href="#/" className="brand" onClick={() => setTab('spin')}>
          <span className="brand-icon">
            <Utensils size={18} />
          </span>
          {/* baongocangi<span className="brand-dot">.</span> */}
        </a>
        <nav className="tabs">
          <button className={tab === 'spin' ? 'active' : ''} onClick={() => setTab('spin')} disabled={spinning}>
            Mở hòm
          </button>
          <button className={tab === 'places' ? 'active' : ''} onClick={() => setTab('places')} disabled={spinning}>
            Đã ăn <b>{places.length}</b>
          </button>
        </nav>
        <div className="header-actions">
          <button className="sound-button" onClick={() => setSound(!sound)} aria-label={sound ? 'Tắt âm thanh' : 'Bật âm thanh'}>
            {sound ? <Volume2 size={18} /> : <VolumeX size={18} />}
            <span>{sound ? 'Âm thanh bật' : 'Âm thanh tắt'}</span>
          </button>
          <span className={`api-status ${apiOk === false ? 'error' : ''}`}>
            {apiOk === null ? 'Đang nối CSDL...' : apiOk ? 'Postgres sẵn sàng' : 'Lưu tạm trên máy'}
          </span>
        </div>
      </header>

      <main>
        {tab === 'spin' ? (
          <>
            <div className="intro">
              <h1>Mở hòm ăn trưa</h1>
            </div>
            <p className="global-counter">
              Bạn đã mở <strong>{spins.toLocaleString('vi-VN')}</strong> hòm trên máy này
            </p>
            {apiError && <p className="account-message">{apiError}</p>}
            {!eligible.length && (
              <p className="account-message">
                {addressesPicked
                  ? `Chưa có món ở ${locationLabel}. Thêm quán đã ăn với đúng địa chỉ này.`
                  : poolMode === 'eaten'
                    ? 'Chưa có quán đã ăn khớp bộ lọc. Thêm quán hoặc đổi pool.'
                    : 'Không có món phù hợp. Tắt lọc chay hoặc đổi pool.'}
              </p>
            )}
            <section className="address-step" aria-label="Lọc theo địa chỉ khi quay">
              <div className="address-step-head">
                <span>1</span>
                <div>
                  <strong>Chọn địa chỉ để lọc hòm</strong>
                  <p>Tick một hoặc nhiều địa chỉ — hòm chỉ quay món đã lưu ở những chỗ đó.</p>
                </div>
              </div>
              <div className="filters location-filters">
                <div className="budget">
                  <label htmlFor="spin-province">Tỉnh / thành</label>
                  <select
                    id="spin-province"
                    value={spinProvince}
                    disabled={spinning}
                    onChange={(e) => {
                      setSpinProvince(e.target.value)
                      resetAddressFilters()
                    }}
                  >
                    <option value="">Mọi nơi</option>
                    {sortedProvinces.map((province) => (
                      <option key={province.id} value={province.id}>
                        {province.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="budget">
                  <label htmlFor="spin-district">Quận / huyện</label>
                  <select
                    id="spin-district"
                    value={spinDistrict}
                    disabled={spinning || !spinProvinceData}
                    onChange={(e) => {
                      setSpinDistrict(e.target.value)
                      setSpinAddresses([])
                    }}
                  >
                    <option value="">Tất cả quận</option>
                    {spinProvinceData?.districts.map((district) => (
                      <option key={district.id} value={district.id}>
                        {district.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="budget">
                  <label htmlFor="spin-area">Tìm địa chỉ</label>
                  <input
                    id="spin-area"
                    value={spinArea}
                    disabled={spinning}
                    placeholder="Lê Văn Hưu, Trần Bình Trọng..."
                    onChange={(e) => setSpinArea(e.target.value)}
                  />
                </div>
              </div>
              {addressOptions.length ? (
                <>
                  <div className="address-list-actions">
                    <button type="button" disabled={spinning} onClick={() => setSpinAddresses(addressOptions.map((option) => option.address))}>
                      Chọn tất cả ({addressOptions.length})
                    </button>
                    <button type="button" disabled={spinning || !addressesPicked} onClick={() => setSpinAddresses([])}>
                      Bỏ chọn
                    </button>
                  </div>
                  <div className="address-list" role="group" aria-label="Danh sách địa chỉ">
                    {addressOptions.map((option) => {
                      const checked = selectedAddressKeys.has(foldVi(option.address))
                      return (
                        <label key={option.address} className={checked ? 'is-on' : ''}>
                          <input
                            type="checkbox"
                            checked={checked}
                            disabled={spinning}
                            onChange={() => toggleSpinAddress(option.address)}
                          />
                          <span>{option.address}</span>
                          <em>{option.count} món</em>
                        </label>
                      )
                    })}
                  </div>
                </>
              ) : (
                <p className="address-hint">Chưa có địa chỉ quán. Vào tab Đã ăn để thêm quán kèm địa chỉ.</p>
              )}
              {addressesPicked ? (
                <p className="address-ready">
                  Sẽ quay <strong>{eligible.length}</strong> món tại <strong>{locationLabel}</strong>
                  {selectedAddressLabels.length
                    ? ` · ${[...new Set(selectedAddressLabels.flatMap((option) => option.dishes))].join(', ')}`
                    : ''}
                </p>
              ) : (
                <p className="address-hint">Chưa chọn địa chỉ thì hòm quay theo pool bên dưới (catalog / quán đã ăn).</p>
              )}
            </section>
            <section className="case-panel" aria-label="Mở hòm món ăn">
              <div className={`reel-window ${moving ? 'is-spinning' : ''}`} ref={viewport}>
                <div className="selector-line" />
                <div className="reel-track" ref={attachTrack}>
                  {reel
                    .filter(({ id }) => id >= visibleStart && id < visibleStart + 12)
                    .map(({ food, id }) => (
                      <Card key={id} food={food} slot={id} />
                    ))}
                </div>
                <div className="reel-fade left" />
                <div className="reel-fade right" />
              </div>
            </section>
            <div className="control-bar">
              <div className="filters">
                <div className="step-badge">2</div>
                <div className="budget">
                  <label htmlFor="budget">Mức chi thường ngày</label>
                  <select id="budget" value={budget} disabled={spinning} onChange={(e) => setBudget(e.target.value)}>
                    {BUDGETS.map((value) => (
                      <option key={value} value={value}>
                        {priceLabel(value)}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="budget">
                  <label htmlFor="pool">Pool quay</label>
                  <select id="pool" value={addressesPicked ? 'eaten' : poolMode} disabled={spinning || addressesPicked} onChange={(e) => setPoolMode(e.target.value as PoolMode)}>
                    <option value="catalog">Catalog gốc ({foods.length} món)</option>
                    <option value="eaten">Quán đã ăn ({places.length})</option>
                    <option value="both">Cả hai</option>
                  </select>
                </div>
                <label className="veg">
                  <input type="checkbox" checked={veg} disabled={spinning} onChange={(e) => setVeg(e.target.checked)} />
                  <span>
                    <Leaf size={15} /> Ăn chay
                  </span>
                </label>
                {(addressesPicked || poolMode !== 'catalog') && (
                  <label className="veg">
                    <input type="checkbox" checked={eatAgainOnly} disabled={spinning} onChange={(e) => setEatAgainOnly(e.target.checked)} />
                    <span>Chỉ quán đáng ăn lại</span>
                  </label>
                )}
              </div>
              <div className="open-wrap">
                <button className="open-button" disabled={spinning || !eligible.length} onClick={openCase}>
                  <Sparkles size={21} /> {spinning ? 'ĐANG MỞ...' : addressesPicked ? 'MỞ HÒM THEO ĐỊA CHỈ' : result ? 'MỞ LẠI' : 'MỞ HÒM'}
                </button>
              </div>
            </div>
            <section className="inventory">
              <div className="section-heading">
                <div>
                  <span className="eyebrow">Trong hòm</span>
                  <h2>
                    Vật phẩm trong hòm <span>{eligible.length.toString().padStart(2, '0')}</span>
                  </h2>
                </div>
                <div className="rarity-legend">
                  {RARITY_LABELS.map((tier, i) => (
                    <span key={tier}>
                      <i style={{ background: RARITY_COLORS[i] }} />
                      {tier}
                    </span>
                  ))}
                </div>
              </div>
              <div className="inventory-grid">
                {inventory.map((food) => (
                  <Card food={food} small key={food.customId ?? `${food.name}-${food.image}`} />
                ))}
              </div>
            </section>
          </>
        ) : (
          <PlacesLog
            places={places}
            onSave={savePlace}
            onDelete={removePlace}
            editing={editing}
            onEdit={setEditing}
            presetDish={presetDish}
            onPresetConsumed={() => setPresetDish('')}
          />
        )}
        <footer>
          <span>baongocangi. · catalog clone từ truanayangi · quán lưu Postgres</span>
          <span>{eligible.length} món trong pool hiện tại</span>
        </footer>
      </main>

      {revealed && result && (
        <div className="modal-backdrop winner-backdrop" onClick={() => setRevealed(false)}>
          <div className="winner-dialog" onClick={(e) => e.stopPropagation()}>
            <span className="winner-label">VẬT PHẨM MỚI</span>
            <h2 className="winner-title">{result.name}</h2>
            <p className="winner-description">
              Giá tham khảo · {priceLabel(result.price)} / người
              {result.restaurant ? ` · ${result.restaurant}` : ''}
            </p>
            {result.address && (
              <p className="winner-address">
                <MapPin size={14} /> {result.address}
                {result.districtName ? ` · ${result.districtName}` : ''}
                {result.provinceName ? ` · ${result.provinceName}` : ''}
              </p>
            )}
            {typeof result.stars === 'number' && (
              <p className="winner-stars">
                {Array.from({ length: 5 }, (_, i) => (
                  <Star key={i} size={16} fill={i < result.stars! ? '#e4ae39' : 'transparent'} color="#e4ae39" />
                ))}
                <span>{result.eatAgain ? 'Đáng ăn lại' : 'Không cần ăn lại'}</span>
              </p>
            )}
            <div className="winner-art" style={{ '--rarity': RARITY_COLORS[result.rarity] } as CSSProperties}>
              <FoodImage food={result} />
            </div>
            <div className="winner-actions">
              {result.placeId ? (
                <a
                  className="find-button"
                  href={mapsUrl({
                    restaurant: result.restaurant ?? result.name,
                    address: result.address ?? '',
                    provinceId: places.find((p) => p.id === result.placeId)?.provinceId ?? '01',
                    districtId: places.find((p) => p.id === result.placeId)?.districtId ?? '',
                  })}
                  target="_blank"
                  rel="noreferrer"
                >
                  Mở địa chỉ quán <ArrowUpRight size={16} />
                </a>
              ) : (
                <a className="find-button" href={`https://www.google.com/maps/search/${encodeURIComponent(`${result.name} gần đây`)}`} target="_blank" rel="noreferrer">
                  Tìm quán gần đây <ArrowUpRight size={16} />
                </a>
              )}
              {!result.placeId && (
                <button
                  className="save-place-button"
                  onClick={() => {
                    setPresetDish(result.name)
                    setEditing(null)
                    setRevealed(false)
                    setTab('places')
                  }}
                >
                  Lưu quán đã ăn
                </button>
              )}
              <button onClick={() => setRevealed(false)}>Tiếp tục</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function Card({ food, small = false, slot }: { food: Food; small?: boolean; slot?: number }) {
  const mystery = !small && food.rarity === 4
  return (
    <div
      className={`food-card ${small ? 'small' : ''} ${mystery ? 'mystery-card' : ''}`}
      style={{ '--rarity': RARITY_COLORS[food.rarity], ...(slot === undefined ? {} : { position: 'absolute', left: slot * STEP_PX }) } as CSSProperties}
    >
      {mystery ? <MysteryArt /> : <FoodImage food={food} />}
      <div className="card-copy">
        <strong>{mystery ? 'MÓN BÍ ẨN' : food.name}</strong>
        <span>{small ? food.address || priceLabel(food.price) : food.sub}</span>
      </div>
    </div>
  )
}
