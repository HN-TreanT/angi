import cors from 'cors'
import express from 'express'
import { loadLocalEnv, replyWithGemini } from './chat.ts'
import { ensureSchema, pool, waitForDb } from './db.ts'

loadLocalEnv()

type PlaceRow = {
  id: string
  dish_name: string
  restaurant: string
  address: string
  province_id: string
  district_id: string
  stars: number
  eat_again: boolean
  price: number
  notes: string
  image: number | null
  photo: string | null
  created_at: Date
}

type PlaceDraft = {
  dishName: string
  restaurant: string
  address: string
  provinceId: string
  districtId: string
  stars: number
  eatAgain: boolean
  price: number
  notes?: string
  image?: number | null
  photo?: string | null
}

function toPlace(row: PlaceRow) {
  return {
    id: row.id,
    dishName: row.dish_name,
    restaurant: row.restaurant,
    address: row.address,
    provinceId: row.province_id,
    districtId: row.district_id,
    stars: row.stars,
    eatAgain: row.eat_again,
    price: row.price,
    notes: row.notes,
    createdAt: new Date(row.created_at).getTime(),
    image: row.image ?? undefined,
    photo: row.photo ?? undefined,
  }
}

function parsePhoto(value: unknown) {
  if (value == null || value === '') return null
  const photo = String(value)
  if (!photo.startsWith('data:image/')) {
    throw Object.assign(new Error('Ảnh không hợp lệ'), { status: 400 })
  }
  if (photo.length > 1_200_000) {
    throw Object.assign(new Error('Ảnh quá nặng, hãy chọn ảnh nhỏ hơn'), { status: 400 })
  }
  return photo
}

function parseDraft(body: PlaceDraft) {
  const dishName = String(body.dishName ?? '').trim()
  const restaurant = String(body.restaurant ?? '').trim()
  const address = String(body.address ?? '').trim()
  const provinceId = String(body.provinceId ?? '').trim()
  const districtId = String(body.districtId ?? '').trim()
  const stars = Number(body.stars)
  const price = Number(body.price ?? 50)
  if (!dishName || !restaurant || !address || !provinceId || !districtId) {
    throw Object.assign(new Error('Thiếu món, quán, địa chỉ hoặc tỉnh/quận'), { status: 400 })
  }
  if (!Number.isInteger(stars) || stars < 1 || stars > 5) {
    throw Object.assign(new Error('Số sao phải từ 1 đến 5'), { status: 400 })
  }
  if (!Number.isFinite(price) || price < 15 || price > 400) {
    throw Object.assign(new Error('Giá phải từ 15 đến 400 nghìn đồng'), { status: 400 })
  }
  return {
    dishName,
    restaurant,
    address,
    provinceId,
    districtId,
    stars,
    eatAgain: body.eatAgain !== false,
    price: Math.round(price),
    notes: String(body.notes ?? ''),
    image: body.image == null || body.image < 0 ? null : Math.round(Number(body.image)),
    photo: parsePhoto(body.photo),
  }
}

const app = express()
app.use(cors({ origin: true }))
app.use(express.json({ limit: '2mb' }))

app.get('/api/health', (_req, res) => {
  res.json({ ok: true })
})

app.get('/api/places', async (req, res, next) => {
  try {
    const provinceId = String(req.query.provinceId ?? '')
    const districtId = String(req.query.districtId ?? '')
    const values: string[] = []
    const where: string[] = []
    if (provinceId) {
      values.push(provinceId)
      where.push(`province_id = $${values.length}`)
    }
    if (districtId) {
      values.push(districtId)
      where.push(`district_id = $${values.length}`)
    }
    const sql = `SELECT * FROM places ${where.length ? `WHERE ${where.join(' AND ')}` : ''} ORDER BY created_at DESC`
    const { rows } = await pool.query<PlaceRow>(sql, values)
    res.json(rows.map(toPlace))
  } catch (error) {
    next(error)
  }
})

app.post('/api/places', async (req, res, next) => {
  try {
    const draft = parseDraft(req.body as PlaceDraft)
    const { rows } = await pool.query<PlaceRow>(
      `INSERT INTO places (dish_name, restaurant, address, province_id, district_id, stars, eat_again, price, notes, image, photo)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [draft.dishName, draft.restaurant, draft.address, draft.provinceId, draft.districtId, draft.stars, draft.eatAgain, draft.price, draft.notes, draft.image, draft.photo],
    )
    res.status(201).json(toPlace(rows[0]))
  } catch (error) {
    next(error)
  }
})

app.put('/api/places/:id', async (req, res, next) => {
  try {
    const draft = parseDraft(req.body as PlaceDraft)
    const { rows } = await pool.query<PlaceRow>(
      `UPDATE places
       SET dish_name=$1, restaurant=$2, address=$3, province_id=$4, district_id=$5, stars=$6, eat_again=$7, price=$8, notes=$9, image=$10, photo=$11
       WHERE id=$12
       RETURNING *`,
      [draft.dishName, draft.restaurant, draft.address, draft.provinceId, draft.districtId, draft.stars, draft.eatAgain, draft.price, draft.notes, draft.image, draft.photo, String(req.params.id)],
    )
    if (!rows[0]) {
      res.status(404).json({ error: 'Không tìm thấy quán' })
      return
    }
    res.json(toPlace(rows[0]))
  } catch (error) {
    next(error)
  }
})

app.delete('/api/places/:id', async (req, res, next) => {
  try {
    const { rowCount } = await pool.query('DELETE FROM places WHERE id = $1', [String(req.params.id)])
    if (!rowCount) {
      res.status(404).json({ error: 'Không tìm thấy quán' })
      return
    }
    res.status(204).end()
  } catch (error) {
    next(error)
  }
})

app.post('/api/chat', async (req, res, next) => {
  try {
    const result = await replyWithGemini(req.body)
    res.json(result)
  } catch (error) {
    next(error)
  }
})

app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const status = typeof error === 'object' && error && 'status' in error ? Number(error.status) : 500
  const message = error instanceof Error ? error.message : 'Lỗi máy chủ'
  res.status(status || 500).json({ error: message })
})

const port = Number(process.env.PORT ?? 3001)

await waitForDb()
await ensureSchema()
await pool.query('ALTER TABLE places ADD COLUMN IF NOT EXISTS photo TEXT')
app.listen(port, '0.0.0.0', () => {
  console.log(`baongocangi api http://localhost:${port}`)
})
