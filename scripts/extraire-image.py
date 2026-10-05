"""Extrait une image d'une vidéo (la première par défaut), en PNG pleine qualité.

Sert à créer la référence « avatar dans ma tenue et mon décor » pour le workflow.

Usage :
  .\python_embeded\python.exe extraire-image.py <video> [seconde]
"""
import sys
from pathlib import Path

import av


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    video = Path(sys.argv[1])
    t = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0

    with av.open(str(video)) as c:
        s = c.streams.video[0]
        if t > 0:
            c.seek(int(t / s.time_base), stream=s, any_frame=False, backward=True)
        for frame in c.decode(s):
            if frame.time is None or frame.time >= t - 1e-3:
                img = frame.to_image()
                break
        else:
            print("Aucune image trouvée à ce moment de la vidéo.")
            sys.exit(1)
        # la rotation des vidéos de téléphone est stockée à part
        rot = getattr(frame, "rotation", 0) or 0
        if rot:
            img = img.rotate(rot, expand=True)

    out = video.with_name(f"{video.stem}_image_{t:g}s.png")
    img.save(out)
    print(f"OK  {out}  ({img.size[0]}x{img.size[1]})")


if __name__ == "__main__":
    main()
