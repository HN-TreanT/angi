import type { Place, PlaceDraft } from './places'

const API = '/api'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API}${path}`, {
    headers: { 'Content-Type': 'application/json', ...(init?.headers ?? {}) },
    ...init,
  })
  if (!response.ok) {
    const text = await response.text()
    throw new Error(text || `API ${response.status}`)
  }
  if (response.status === 204) return undefined as T
  return response.json() as Promise<T>
}

export function fetchPlaces() {
  return request<Place[]>('/places')
}

export function createPlaceApi(draft: PlaceDraft) {
  return request<Place>('/places', { method: 'POST', body: JSON.stringify(draft) })
}

export function updatePlaceApi(id: string, draft: PlaceDraft) {
  return request<Place>(`/places/${id}`, { method: 'PUT', body: JSON.stringify(draft) })
}

export function deletePlaceApi(id: string) {
  return request<void>(`/places/${id}`, { method: 'DELETE' })
}

export function healthCheck() {
  return request<{ ok: boolean }>('/health')
}
