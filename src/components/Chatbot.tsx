import { useEffect, useRef, useState, type FormEvent } from 'react'
import { Send, X } from 'lucide-react'
import { sendChat, type ChatTurn } from '../lib/api'

type Bubble = ChatTurn & { id: number }

export function Chatbot({ playerName }: { playerName: string }) {
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const [messages, setMessages] = useState<Bubble[]>(() => [
    {
      id: 0,
      role: 'model',
      text: playerName
        ? `Chào ${playerName}! Tớ là Doraemon đây. Muốn ăn gì cứ hỏi tớ nka.`
        : 'Chào bạn! Tớ là Doraemon đây. Muốn ăn gì cứ hỏi tớ nka.',
    },
  ])
  const scroller = useRef<HTMLDivElement>(null)
  const input = useRef<HTMLTextAreaElement>(null)

  useEffect(() => {
    scroller.current?.scrollTo({ top: scroller.current.scrollHeight, behavior: 'smooth' })
  }, [messages, pending, open])

  useEffect(() => {
    if (open) input.current?.focus()
  }, [open])

  async function submit(event: FormEvent) {
    event.preventDefault()
    const text = draft.trim()
    if (!text || pending) return
    const history = [...messages, { id: Date.now(), role: 'user' as const, text }]
    setMessages(history)
    setDraft('')
    setPending(true)
    setError('')
    try {
      const reply = await sendChat(
        history.filter((item) => item.id !== 0).map(({ role, text: body }) => ({ role, text: body })),
        playerName,
      )
      setMessages((current) => [...current, { id: Date.now() + 1, role: 'model', text: reply.text }])
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Không nhắn được Doraemon')
    } finally {
      setPending(false)
    }
  }

  return (
    <div className={`chatbot ${open ? 'is-open' : ''}`}>
      {open && (
        <section className="chat-panel" aria-label="Chat với Doraemon">
          <header className="chat-head">
            <span className="chat-avatar" aria-hidden="true">
              <img src="/doraemon1-removebg-preview.png" alt="" />
            </span>
            <div>
              <strong>Doraemon</strong>
              <p>Hỏi món ăn trưa nha</p>
            </div>
            <button type="button" className="chat-close" onClick={() => setOpen(false)} aria-label="Đóng chat">
              <X size={18} />
            </button>
          </header>
          <div className="chat-log" ref={scroller}>
            {messages.map((message) => (
              <p key={message.id} className={`chat-bubble ${message.role}`}>
                {message.text}
              </p>
            ))}
            {pending && <p className="chat-bubble model is-typing">Đang nghĩ...</p>}
            {error && <p className="chat-error">{error}</p>}
          </div>
          <form className="chat-form" onSubmit={submit}>
            <textarea
              ref={input}
              rows={1}
              value={draft}
              disabled={pending}
              placeholder="Hỏi Doraemon..."
              aria-label="Tin nhắn"
              onChange={(e) => setDraft(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault()
                  e.currentTarget.form?.requestSubmit()
                }
              }}
            />
            <button type="submit" disabled={pending || !draft.trim()} aria-label="Gửi">
              <Send size={18} />
            </button>
          </form>
        </section>
      )}
      <button
        type="button"
        className="chat-launcher"
        aria-label={open ? 'Đóng chat Doraemon' : 'Mở chat Doraemon'}
        onClick={() => setOpen((value) => !value)}
      >
        <img src="/doraemon1-removebg-preview.png" alt="" />
      </button>
    </div>
  )
}
