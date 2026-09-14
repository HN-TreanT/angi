type SpinSfx = {
  unlock: () => void;
  setEnabled: (on: boolean) => void;
  startSpin: () => void;
  tickSlot: (slot: number, progress: number) => void;
  win: () => void;
  stop: () => void;
};

const SPIN_SRC = "/sounds/doraemon_song.mp3";
const WIN_SRC = "/sounds/success.mp3";

type WebkitWindow = Window & {
  webkitAudioContext?: typeof AudioContext;
};

function makeContext() {
  const Ctor =
    window.AudioContext || (window as WebkitWindow).webkitAudioContext;
  if (!Ctor) return null;
  return new Ctor();
}

function htmlClip(src: string, loop: boolean) {
  const audio = new Audio();
  audio.src = src;
  audio.preload = "auto";
  audio.loop = loop;
  audio.crossOrigin = "anonymous";
  audio.setAttribute("playsinline", "true");
  audio.setAttribute("webkit-playsinline", "true");
  audio.volume = 0.8;
  return audio;
}

function safePause(audio: HTMLAudioElement | null) {
  if (!audio) return;
  try {
    audio.pause();
  } catch {
    /* ignore */
  }
  try {
    if (audio.readyState >= 1) audio.currentTime = 0;
  } catch {
    /* iOS throws before metadata */
  }
}

function playNow(audio: HTMLAudioElement) {
  const run = audio.play();
  if (run) void run.catch(() => {});
}

export function createSpinSfx(): SpinSfx {
  let enabled = true;
  let primed = false;
  let ctx: AudioContext | null = null;
  let spinEl: HTMLAudioElement | null = null;
  let winEl: HTMLAudioElement | null = null;

  function elements() {
    if (!spinEl) spinEl = htmlClip(SPIN_SRC, true);
    if (!winEl) winEl = htmlClip(WIN_SRC, false);
    return { spin: spinEl, win: winEl };
  }

  function resumeContext() {
    if (!ctx) ctx = makeContext();
    if (ctx && ctx.state !== "running") void ctx.resume();
  }

  return {
    unlock() {
      resumeContext();
      const { spin, win } = elements();
      if (primed) return;
      primed = true;
      spin.load();
      win.load();
    },
    setEnabled(on) {
      enabled = on;
      if (!on) {
        safePause(spinEl);
        safePause(winEl);
      }
    },
    startSpin() {
      resumeContext();
      const { spin, win } = elements();
      safePause(win);
      if (!enabled) return;
      spin.loop = true;
      playNow(spin);
    },
    tickSlot() {
      /* do not change playbackRate — iOS often goes silent */
    },
    win() {
      resumeContext();
      const { spin, win } = elements();
      safePause(spin);
      if (!enabled) return;
      win.loop = false;
      playNow(win);
    },
    stop() {
      safePause(spinEl);
      safePause(winEl);
    },
  };
}
