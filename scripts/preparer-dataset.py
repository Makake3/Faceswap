"""Prépare le dataset d'entraînement de la LoRA de l'avatar.

- redimensionne chaque image (côté le plus long = 1024 px par défaut)
- renomme en 001.png, 002.png, ...
- crée un fichier de légende .txt par image, à compléter

Usage (depuis C:\ComfyUI\ComfyUI_windows_portable) :
  .\python_embeded\python.exe preparer-dataset.py <dossier_images> <dossier_sortie> [mot_declencheur]
"""
import sys
from pathlib import Path

from PIL import Image, ImageOps

EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
MAX_SIDE = 1024
TEMPLATE = (
    "{trigger}, [TENUE : décris précisément les vêtements], "
    "[POSE / CADRAGE : ex. debout, plan en pied, de face], "
    "[DÉCOR / LUMIÈRE : ex. fond uni gris, lumière douce]\n"
)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    trigger = sys.argv[3] if len(sys.argv) > 3 else "avtr_ia"
    dst.mkdir(parents=True, exist_ok=True)

    files = sorted(p for p in src.iterdir() if p.suffix.lower() in EXTS)
    if not files:
        print(f"Aucune image trouvée dans {src}")
        sys.exit(1)

    small = 0
    for i, f in enumerate(files, 1):
        im = ImageOps.exif_transpose(Image.open(f)).convert("RGB")
        if max(im.size) < 768:
            small += 1
            print(f"ATTENTION  {f.name} est petite ({im.size[0]}x{im.size[1]}), qualité réduite")
        im.thumbnail((MAX_SIDE, MAX_SIDE), Image.LANCZOS)
        # dimensions multiples de 16 (exigé par la plupart des entraîneurs)
        w, h = (im.size[0] // 16) * 16, (im.size[1] // 16) * 16
        im = ImageOps.fit(im, (w, h), Image.LANCZOS)
        name = f"{i:03d}"
        im.save(dst / f"{name}.png")
        cap = dst / f"{name}.txt"
        if not cap.exists():
            cap.write_text(TEMPLATE.format(trigger=trigger), encoding="utf-8")
        print(f"OK  {f.name}  ->  {name}.png  ({w}x{h})")

    n = len(files)
    print(f"\n{n} images prêtes dans {dst}")
    if n < 15:
        print("Conseil : vise 20 à 40 images pour une LoRA stable.")
    if small:
        print(f"{small} image(s) en basse résolution : remplace-les si possible.")
    print("Étape suivante : ouvre chaque .txt et remplace les [CROCHETS] (voir docs/LORA.md).")


if __name__ == "__main__":
    main()
