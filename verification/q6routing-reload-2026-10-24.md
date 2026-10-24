# q6routing / ADSP state — why a full reboot is required

Date: 2026-10-24
Device: Redmi K30 Pro Zoom (`lmi`), card `lmi`, kernel `6.19.0-rc8-sm8250`
Related: [`runtime-2026-10-24-audio-mic-ime.md`](runtime-2026-10-24-audio-mic-ime.md),
`docs/06-runtime.md`

## Symptom

With the UCM route looking correct, `pactl` listed `alsa_input.platform-sound.HiFi__Mic1__source`
and `parecord` returned 0, but the samples were silence/constant noise. Kernel log repeated:

```text
qcom-q6adm ... cmd = 0x10325 return error = 0x2
q6routing ... DSP returned error[2]          # ADM_CMD_MATRIX_MAP_ROUTINGS_V5
q6asm-dai ... CMD 10bcd timeout              # ASM_STREAM_CMD_CLOSE
```

`0x10325` is the ADM matrix-map command used to connect the PCM front-end to the TX
backend (`TX_CODEC_DMA_TX_3`). Failure means the DSP never established the capture path, so
the ALSA mixer state is irrelevant.

## What did not fix it

- Reloading UCM (`alsaucm -c lmi reset/set`), toggling the ADC switches, changing ADC1/2/3/4.
- Unbinding and rebinding the sound card:

  ```sh
  echo 17300000.remoteproc:glink-edge:apr:service@7:dais > /sys/bus/platform/drivers/q6asm-dai/unbind
  # ... rebind
  ```

  After a card rebind the WCD938x ADC controls disappeared from `amixer` and the ADM errors
  remained. The codec/DSP state is not reset by rebinding the ASoC card.

## What fixed it

A full reboot (`reboot`, then boot recovery). After the reboot:

- `qcom-q6adm` / `q6routing` matrix-map errors are gone.
- `dmesg | grep -cE 'q6adm|q6routing|q6asm'` is 0 right after boot, before any manual
  route experiments.
- The same UCM Mic1 route captures real audio (loopback 1 kHz, peak ~8 k).
- Two stale `q6asm CMD 10bcd timeout` lines can remain from earlier mid-session experiments
  in the same boot; new captures do not add more.

## Why it happens (working theory)

The capture path is DPCM: `q6asm` PCM → `q6adm` matrix → `q6routing` → `TX_CODEC_DMA_TX_3` →
SoundWire TX macro → WCD938x ADC. If a stream is torn down out of order (UCM reset while a
capture is open, card unbind, or a failed `_enadev`), ADM keeps a half-mapped port and every
later map request fails with `0x2`. Only a cold ADSP boot clears it. The initial UCM attempts
that used the wrong control names (`ADC1_MIXER` instead of `ADC1_MIXER Switch`) failed
mid-sequence and left the port in this state, which is how the original “mic captures silence”
report was produced.

## Practical rules

1. Fix UCM, then **reboot** before judging capture quality.
2. Do not use `card unbind/bind` as a route-reset shortcut; it loses codec controls.
3. Stop any `parecord`/PulseAudio stream before `alsaucm reset`.
4. Check `dmesg | grep -E 'q6adm|q6routing'` first; if `0x2` appears, reboot instead of
   chasing mixer controls.

## Re-check commands

```sh
# after reboot, before any capture
dmesg | grep -E 'q6adm|q6routing|q6asm'      # expect no ADM matrix errors

export XDG_RUNTIME_DIR=/run/user/10000
pactl list short sources | grep Mic1

parecord --device=alsa_input.platform-sound.HiFi__Mic1__source \
    --format=s16le --rate=48000 --channels=2 --file-format=raw /tmp/mic.raw
# peak/rms: decode s16le and inspect; quiet room should be non-zero and not clipped
dmesg | grep -E 'q6adm|q6routing'            # expect still empty
```
