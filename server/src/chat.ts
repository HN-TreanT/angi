import { existsSync } from 'node:fs'
import { resolve } from 'node:path'

const FALLBACK_MODELS = ['gemini-3.6-flash', 'gemini-3.5-flash', 'gemini-flash-latest']
const MAX_TURNS = 24
const MAX_TEXT = 1500

export type ChatTurn = { role: 'user' | 'model'; text: string }

type GeminiPart = { text?: string }
type GeminiContent = { role?: string; parts?: GeminiPart[] }
type GeminiResponse = {
  error?: { message?: string }
  candidates?: { content?: GeminiContent }[]
}

export function loadLocalEnv() {
  const file = resolve(process.cwd(), '.env')
  if (!existsSync(file)) return
  try {
    process.loadEnvFile(file)
  } catch {
    /* ignore */
  }
}

function parseTurns(body: unknown): { turns: ChatTurn[]; playerName: string } {
  const payload = body && typeof body === 'object' ? (body as { messages?: unknown; playerName?: unknown }) : {}
  const raw = Array.isArray(payload.messages) ? payload.messages : []
  const turns: ChatTurn[] = []
  for (const item of raw.slice(-MAX_TURNS)) {
    if (!item || typeof item !== 'object') continue
    const role = (item as ChatTurn).role
    const text = String((item as ChatTurn).text ?? '').trim()
    if ((role !== 'user' && role !== 'model') || !text) continue
    turns.push({ role, text: text.slice(0, MAX_TEXT) })
  }
  if (!turns.length || turns.at(-1)?.role !== 'user') {
    throw Object.assign(new Error('Hãy gửi một câu hỏi'), { status: 400 })
  }
  return {
    turns,
    playerName: String(payload.playerName ?? '').trim().slice(0, 32),
  }
}

function extractText(data: GeminiResponse) {
  const parts = data.candidates?.[0]?.content?.parts ?? []
  return parts.map((part) => part.text ?? '').join('').trim()
}

async function generate(model: string, key: string, turns: ChatTurn[], playerName: string) {
  const who = playerName || 'bạn'
  const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': key,
    },
    body: JSON.stringify({
      systemInstruction: {
        parts: [
          {
            text: `Bạn là Doraemon trên web HÔM NAY ĂN GÌ? — hòm quay món ăn trưa kiểu CS:GO.
Người đang chat tên ${who}.
Nói tiếng Việt, ngắn, dễ thương, xưng tớ / gọi ${who}. Thỉnh thoảng nói "nka".
Giúp chọn món, gợi ý theo ngân sách, hướng dẫn tick địa chỉ rồi bấm MỞ HÒM.
Không tiết lộ API, không bịa địa chỉ quán nếu không chắc. Trả lời 1–4 câu, không dùng markdown.`,
          },
        ],
      },
      contents: turns.map((turn) => ({
        role: turn.role,
        parts: [{ text: turn.text }],
      })),
      generationConfig: {
        temperature: 0.85,
        maxOutputTokens: 1024,
      },
    }),
  })
  const data = (await response.json()) as GeminiResponse
  if (!response.ok) {
    const message = data.error?.message || `Gemini ${response.status}`
    throw Object.assign(new Error(message), { status: response.status, gemini: true })
  }
  const text = extractText(data)
  if (!text) throw Object.assign(new Error('Doraemon đang bí ý'), { status: 502 })
  return text
}

export async function replyWithGemini(body: unknown) {
  const key = process.env.GEMINI_API_KEY?.trim()
  if (!key) {
    throw Object.assign(new Error('Chưa cấu hình GEMINI_API_KEY'), { status: 503 })
  }
  const { turns, playerName } = parseTurns(body)
  const preferred = process.env.GEMINI_MODEL?.trim()
  const models = [...new Set([preferred, ...FALLBACK_MODELS].filter(Boolean))] as string[]
  let lastError: Error | undefined
  for (const model of models) {
    try {
      const text = await generate(model, key, turns, playerName)
      return { text, model }
    } catch (error) {
      lastError = error instanceof Error ? error : new Error('Gemini lỗi')
      const status = typeof error === 'object' && error && 'status' in error ? Number(error.status) : 0
      if (status !== 404) throw lastError
    }
  }
  throw lastError ?? Object.assign(new Error('Không gọi được Gemini'), { status: 502 })
}
