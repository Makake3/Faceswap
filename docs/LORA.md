# Garder le même avatar d'une vidéo à l'autre, avec ma tenue et mon décor

But : je tourne une vidéo (je danse, je parle…) et c'est mon avatar IA qui apparaît à ma place, avec son visage, son corps et sa silhouette. **Le décor et les vêtements que je porte restent ceux de la vidéo.**

## Le principe : trois briques

| Brique | Rôle | Ce qu'elle règle |
|---|---|---|
| 1. **LoRA de l'avatar** | Un petit fichier entraîné sur les images de l'avatar, chargé dans le workflow | Le visage et le corps de l'avatar restent identiques d'une vidéo à l'autre |
| 2. **Image de référence par vidéo** | La première image de **ma** vidéo, retouchée pour que l'avatar y soit à ma place, **dans ma tenue et mon décor** | Le workflow recopie la tenue de la référence : c'est ce qui empêche l'ajout ou le changement de vêtements |
| 3. **SCAIL-2** | Anime la référence avec mes mouvements | Les gestes, la danse et le décor de la vidéo d'origine |

La brique 2 est la plus importante pour la tenue. Si on donne au workflow une image de l'avatar dans une autre tenue, il impose cette tenue. Si on lui donne l'avatar déjà habillé comme moi, il la garde.

---

## Brique 1 : entraîner la LoRA

### a) Rassembler les images (20 à 40)

Place-les dans un dossier, par exemple `C:\ComfyUI\avatar_brut`.

| À faire | À éviter |
|---|---|
| Plusieurs angles : face, trois-quarts, profil, dos | Toujours la même pose |
| Plusieurs distances : environ 40 % en pied, 30 % à mi-corps, 30 % de visage | Uniquement des portraits (le corps ne serait pas appris) |
| **Des tenues variées** | Toujours la même tenue : la LoRA l'imposerait dans toutes les vidéos |
| Lumières et fonds variés, mais simples | Du texte, un filigrane, d'autres personnes |
| Des images nettes, 1024 px ou plus | Des images floues ou déformées (mains, yeux) |

Si l'avatar n'existe qu'en quelques images, génère des variantes en local (Qwen Image Edit : même personne, autre pose, autre tenue). Ne garde que celles où l'avatar est **parfaitement reconnaissable**.

### b) Préparer le dataset

Glisse le dossier `avatar_brut` sur **`scripts/preparer-dataset.bat`**. Le script crée `C:\ComfyUI\dataset_avatar` avec :
- les images redimensionnées : `001.png`, `002.png`… ;
- une légende par image : `001.txt`, `002.txt`…

### c) Écrire les légendes (la règle importante)

Chaque `.txt` commence par le mot déclencheur `avtr_ia`. Ensuite :

- **Décris** ce qui doit pouvoir **changer** : la tenue, la pose, le cadrage, le décor, la lumière.
- **Ne décris pas** ce qui doit **rester fixe** : le visage, les cheveux, la morphologie, la couleur de peau. Le mot `avtr_ia` absorbe tout cela.

Exemple :
```
avtr_ia, débardeur blanc côtelé et jean bleu taille haute, debout, plan en pied, de face, fond uni gris clair, lumière douce
```

C'est cette règle qui permet ensuite de garder **mes** vêtements dans les vidéos.

### d) Lancer l'entraînement (AI-Toolkit, en local)

1. Installe **AI-Toolkit** (d'ostris) via **Pinokio**, en un clic. L'interface s'ouvre dans le navigateur.
2. **Avant de lancer :** ferme ComfyUI et le programme Python qui occupe le port 8188 (`scripts/qui-occupe-le-port.ps1`). L'entraînement a besoin des 24 Go de la carte graphique. Branche le PC sur secteur.
3. Crée un nouveau job :

| Réglage | Valeur de départ |
|---|---|
| Modèle | **Wan 2.1 14B** (la base de SCAIL-2) |
| Dataset | `C:\ComfyUI\dataset_avatar` |
| Mot déclencheur | `avtr_ia` |
| Quantization / Low VRAM | **activés** (float8) |
| Rank (dimension de la LoRA) | 16, ou 32 si le visage manque de précision |
| Learning rate | 0.0001 |
| Steps (étapes d'entraînement) | 2000 à 3000 pour environ 30 images |
| Résolution | 512 et 768 |
| Sauvegarde / échantillons | toutes les 250 étapes |
| Prompts d'échantillon | `avtr_ia, en t-shirt noir, plan en pied, dans une cuisine` et `avtr_ia, gros plan du visage, souriante` |

4. Compte plusieurs heures sur un portable. Compare les images d'échantillon au fil des sauvegardes. **Garde la sauvegarde où l'avatar est reconnaissable ET où la tenue suit le prompt.** La dernière est souvent trop « cuite » : elle impose une tenue ou des détails.

### e) Utiliser la LoRA dans ComfyUI

1. Copie le fichier `.safetensors` choisi dans `ComfyUI\models\loras` (par exemple `avtr_ia_v1.safetensors`).
2. Dans le workflow SCAIL-2, ajoute un nœud **LoraLoaderModelOnly** juste après le chargement du modèle de diffusion, avant les autres LoRA.
3. Commence avec une force de **0.8** : baisse-la si la tenue ou le décor bougent, monte-la si l'avatar n'est pas assez ressemblant.
4. Ajoute `avtr_ia` au début du prompt, suivi de la description de **ma** tenue dans la vidéo.

> Compatibilité : SCAIL-2 est construit sur Wan 2.1 14B. Une LoRA Wan 2.1 14B devrait fonctionner, mais c'est à confirmer au premier essai. Si elle n'a aucun effet ou casse le rendu, il faudra viser exactement la même variante du modèle (I2V) dans AI-Toolkit.

---

## Brique 2 : l'image de référence de chaque vidéo

1. Glisse la vidéo sur **`scripts/extraire-image.bat`**. La première image est enregistrée à côté de la vidéo (`…_image_0s.png`). Pour une autre image : `extraire-image.bat video.mp4 2.5` (à 2,5 s).
2. Retouche cette image en local avec **Qwen Image Edit** (template officiel de ComfyUI, sans nœud API) :
   - image 1 : l'image extraite de ma vidéo ;
   - image 2 : une image de l'avatar ;
   - prompt : `Remplace la personne de l'image 1 par la femme de l'image 2 (visage, cheveux, corps). Garde exactement les vêtements, la pose et le décor de l'image 1.`
3. Vérifie le résultat : **tenue identique, décor identique, avatar reconnaissable.** Sinon, relance avec une autre valeur de seed.
4. Cette image devient l'**image de référence** du workflow SCAIL-2, à la place de l'image de l'avatar seul.

## Brique 3 : le rendu

- **Vidéo** : ma vidéo d'origine. **Référence** : l'image de la brique 2. **LoRA** : `avtr_ia`, force 0.8.
- Masque SAM sur toute ma silhouette : l'avatar remplace le corps, et la tenue est reprise de la référence.
- 480 × 832 pour une vidéo verticale, clip de 3 à 5 s pour les essais, valeur de seed fixe.

---

## Fiche de retour (à remplir après chaque rendu)

Chaque essai est noté sur les mêmes points. On garde ce qui est validé et on ne change **qu'un seul réglage à la fois** sur ce qui ne l'est pas.

| Vidéo | Seed | Force LoRA | Étapes | Visage | Corps | Tenue | Décor | Stabilité | Commentaire |
|---|---|---|---|---|---|---|---|---|---|
| 8 | | | | | | ✅ | | | tenue respectée |
| 1, 2, 5 | | | | ✅ | | | | | correctes |

| Problème | Premier réglage à essayer |
|---|---|
| L'avatar n'est pas ressemblant | Force de la LoRA +0.1 ; vérifier la référence de la brique 2 |
| La tenue change ou des vêtements sont ajoutés | Refaire la référence de la brique 2 ; force de la LoRA −0.1 ; décrire la tenue dans le prompt |
| Le décor bouge | Masque plus serré autour de la silhouette |
| Le corps saute | Plus d'étapes ; clip plus court ; caméra plus stable |
| Visages en double | Format (480 × 832 pour une vidéo verticale) ; masque qui clignote |
