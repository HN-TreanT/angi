type Pose = 'idle' | 'win' | 'chest'

const SRC: Record<Pose, string> = {
  idle: '/mascots/mascot-ngoc.png',
  win: '/mascots/mascot-ngoc-win.png',
  chest: '/mascots/cute-chest.png',
}

const ALT: Record<Pose, string> = {
  idle: 'Mèo Ngọc, bạn đồng hành ăn trưa',
  win: 'Mèo Ngọc vui mừng vì món mới',
  chest: 'Hòm báu ăn trưa',
}

export function Mascot({
  pose = 'idle',
  className = '',
}: {
  pose?: Pose
  className?: string
}) {
  return <img className={`mascot mascot-${pose} ${className}`} src={SRC[pose]} alt={ALT[pose]} draggable={false} />
}

export function SkyDecor() {
  return (
    <div className="sky-decor" aria-hidden="true">
      <span className="cloud cloud-a" />
      <span className="cloud cloud-b" />
      <span className="cloud cloud-c" />
      <span className="bubble b1" />
      <span className="bubble b2" />
      <span className="bubble b3" />
      <span className="sparkle p1" />
      <span className="sparkle p2" />
      <span className="sparkle p3" />
      <span className="sparkle p4" />
    </div>
  )
}
