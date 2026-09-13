type SpinSfx = {
  unlock: () => void;
  setEnabled: (on: boolean) => void;
  startSpin: () => void;
  tickSlot: (slot: number, progress: number) => void;
  win: () => void;
  stop: () => void;
};

function clip(src: string, loop = false) {
  const audio = new Audio(src);
  audio.preload = "auto";
  audio.loop = loop;
  audio.setAttribute("playsinline", "true");
  return audio;
}

async function play(audio: HTMLAudioElement) {
  try {
    audio.currentTime = 0;
    await audio.play();
  } catch {
    /* browser blocked until a later gesture */
  }
}

export function createSpinSfx(): SpinSfx {
  const spin = clip("/sounds/quay.mp3", true);
  const win = clip("/sounds/sms.mp3");
  spin.volume = 0.55;
  win.volume = 0.7;
  let enabled = true;

  function halt(audio: HTMLAudioElement) {
    audio.pause();
    audio.currentTime = 0;
    audio.playbackRate = 1;
  }

  return {
    unlock() {
      void spin.load();
      void win.load();
    },
    setEnabled(on) {
      enabled = on;
      if (!on) {
        halt(spin);
        halt(win);
      }
    },
    startSpin() {
      halt(win);
      if (!enabled) return;
      spin.loop = true;
      spin.playbackRate = 1.12;
      void play(spin);
    },
    tickSlot(_slot, progress) {
      if (!enabled) return;
      spin.playbackRate = Math.max(0.72, 1.15 - progress * 0.5);
    },
    win() {
      halt(spin);
      if (!enabled) return;
      void play(win);
    },
    stop() {
      halt(spin);
      halt(win);
    },
  };
}
