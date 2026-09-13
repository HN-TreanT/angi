import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import pg from 'pg'

const connectionString = process.env.DATABASE_URL ?? 'postgres://baongocangi:baongocangi@localhost:5433/baongocangi'

export const pool = new pg.Pool({ connectionString })

export async function waitForDb(tries = 30) {
  for (let i = 0; i < tries; i++) {
    try {
      await pool.query('SELECT 1')
      return
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 1000))
    }
  }
  throw new Error('Postgres chưa sẵn sàng')
}

export async function ensureSchema() {
  const file = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'init.sql')
  const sql = fs.readFileSync(file, 'utf8')
  await pool.query(sql)
}
