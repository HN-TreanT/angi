const MAX_PHOTO_CHARS = 1_100_000

function mimeFromName(name: string) {
  const n = name.toLowerCase()
  if (n.endsWith('.png')) return 'image/png'
  if (n.endsWith('.webp')) return 'image/webp'
  if (n.endsWith('.gif')) return 'image/gif'
  if (n.endsWith('.heic') || n.endsWith('.heif')) return 'image/heic'
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg'
  return ''
}

function encodeJpeg(canvas: HTMLCanvasElement, quality: number) {
  let q = quality
  let data = canvas.toDataURL('image/jpeg', q)
  while (data.length > MAX_PHOTO_CHARS && q > 0.4) {
    q -= 0.12
    data = canvas.toDataURL('image/jpeg', q)
  }
  if (data.length > MAX_PHOTO_CHARS) {
    throw new Error('Ảnh quá nặng, hãy chọn ảnh nhỏ hơn')
  }
  return data
}

export function compressPhoto(file: File, maxEdge = 720, quality = 0.74): Promise<string> {
  const type = file.type || mimeFromName(file.name)
  if (type && !type.startsWith('image/')) return Promise.reject(new Error('Chỉ nhận file ảnh'))
  return new Promise((resolve, reject) => {
    const img = new Image()
    const url = URL.createObjectURL(file)
    img.onload = () => {
      const scale = Math.min(1, maxEdge / Math.max(img.width, img.height))
      const canvas = document.createElement('canvas')
      canvas.width = Math.max(1, Math.round(img.width * scale))
      canvas.height = Math.max(1, Math.round(img.height * scale))
      const ctx = canvas.getContext('2d')
      if (!ctx) {
        URL.revokeObjectURL(url)
        reject(new Error('Không nén được ảnh'))
        return
      }
      ctx.fillStyle = '#ffffff'
      ctx.fillRect(0, 0, canvas.width, canvas.height)
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
      URL.revokeObjectURL(url)
      try {
        resolve(encodeJpeg(canvas, quality))
      } catch (error) {
        reject(error)
      }
    }
    img.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error(type.includes('heic') || type.includes('heif')
        ? 'Ảnh HEIC không đọc được trên trình duyệt này, hãy chọn JPEG/PNG'
        : 'Không đọc được ảnh'))
    }
    img.src = url
  })
}
