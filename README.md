# Faceswap : se remplacer par son avatar IA dans ses propres vidéos (100 % local)

Le but est de remplacer la personne filmée (moi) par mon avatar IA dans mes propres vidéos, sans que rien ne passe par Internet. Format visé : une vidéo de type TikTok où je parle, je claque des doigts, puis je réapparais sous l'apparence de l'avatar, avec la même voix, le même décor et les mêmes gestes.

**Périmètre :** uniquement mes propres vidéos et photos.

## Outils (open source, locaux)

- **ComfyUI portable** (Windows), dans `C:\ComfyUI\ComfyUI_windows_portable\`
- Workflow **« SCAIL-2 int8 : Remplacement de personnage »** (basé sur Wan 2.1 14B) : il garde le décor d'origine. Solution de repli : « Wan Animate 2 Distillé ».
- Plus tard, en option : FaceFusion (affiner le visage), Qwen Image Edit ou Flux Kontext (photos).

Règle : jamais de nœuds « API » (couronne, logo de marque, mention API), car ils envoient les images en ligne.

## Scripts (dossier `scripts/`)

Pour les récupérer sur le PC : sur GitHub, bouton **Code → Download ZIP**, puis décompresser, par exemple dans `C:\ComfyUI\scripts`.

| Script | Rôle |
|---|---|
| `verifier-modeles.bat` | Range les modèles restés dans Téléchargements, puis vérifie que les 7 fichiers sont présents, complets (taille) et dans le bon sous-dossier. Signale les téléchargements inachevés (`.crdownload`). |
| `lancer-comfyui.bat` | Lance ComfyUI sur le port 8189 et ouvre http://127.0.0.1:8189. |
| `qui-occupe-le-port.ps1` | Indique quel programme Python occupe le port 8188 (et environ 7 Go de VRAM), d'où il est lancé au démarrage, et l'état de la VRAM. |

## Modèles requis (26,65 Go)

| Fichier | `ComfyUI\models\` |
|---|---|
| sam3.1_multiplex_fp16.safetensors | checkpoints |
| lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors | loras |
| wan2.1_SCAIL_2_DPO_lora_bf16.safetensors | loras |
| Wan2_1_VAE_bf16.safetensors | vae |
| umt5_xxl_fp8_e4m3fn_scaled.safetensors | text_encoders |
| wan2.1_14B_SCAIL_2_int8_convrot.safetensors | diffusion_models |
| clip_vision_h.safetensors | clip_vision |

## Étapes

1. [ ] Attendre la fin des téléchargements, puis lancer `verifier-modeles.bat` : toutes les lignes doivent être vertes.
2. [ ] Lancer `qui-occupe-le-port.ps1`. Si le programme sur le port 8188 est un ancien ComfyUI inutile, l'arrêter avant les rendus pour libérer environ 7 Go de VRAM.
3. [ ] Lancer `lancer-comfyui.bat`, rouvrir le workflow SCAIL-2 et vérifier que le panneau « Modèles manquants » est vide.
4. [ ] Préparer le test dans `ComfyUI\input` : un clip de 3 à 5 s (une seule personne, corps entier visible, caméra stable) et l'avatar (en pied, de face, fond simple).
5. [ ] Charger la vidéo et l'image, désigner la personne à remplacer, régler une résolution d'environ 832 × 480, puis cliquer sur **Exécuter**.
6. [ ] Si le résultat est bon : passer en 720p, puis faire le montage (coupe sur le claquement de doigts, son d'origine) dans CapCut, Clipchamp ou DaVinci Resolve.
7. [ ] Options : FaceFusion pour le visage, ou entraîner une LoRA de l'avatar (15 à 30 images) si son apparence varie d'une vidéo à l'autre.

## Matériel

HP Omen, Windows 11, RTX 5090 Laptop (24 Go de VRAM), 64 Go de RAM, pilote NVIDIA 616.92, PyTorch 2.14 + cu130.

## Confidentialité

- Garder les vidéos et les résultats dans `C:\ComfyUI`, hors des dossiers synchronisés par OneDrive.
- Ne jamais mettre de vidéos personnelles dans ce dépôt : il est **public**.
