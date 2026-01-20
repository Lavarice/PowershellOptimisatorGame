# PowershellOptimisatorGame

Script PowerShell permettant de désactiver temporairement certains services Windows 11 gourmands en ressources pour optimiser le jeu, puis de les réactiver ensuite.

## 1. Contenu du dossier

- `Doc-App-PowerShell.ps1` : affiche une **documentation détaillée** en couleur dans la console sur comment créer des apps (scripts) PowerShell.
- `scriptJeux.ps1` : active un **mode jeu** sur Windows 11 en désactivant temporairement certains services Windows puis en les réactivant à la fin.
- `test.ps1` : script de test (contenu libre / à expérimenter).

## 2. Prérequis

- Windows 10 ou 11.
- PowerShell (version Windows intégrée) ou PowerShell 7 recommandé.
- Lancer PowerShell **en tant qu'administrateur** pour tout script qui modifie des services système (comme `scriptJeux.ps1`).

## 3. Documentation : Doc-App-PowerShell.ps1

Ce script affiche une doc pas à pas pour apprendre à créer des apps PowerShell.

### Lancer la documentation

```powershell
cd C:\Users\Revelation\Desktop\PojetPowershell
.\Doc-App-PowerShell.ps1
```

Le script :
- Efface l'écran.
- Affiche une documentation structurée (sections numérotées) avec des couleurs.
- Explique :
  - les prérequis,
  - le premier script "Hello World",
  - les paramètres (`param`),
  - la gestion des erreurs (`try` / `catch`),
  - un exemple d'app de sauvegarde,
  - les fonctions, modules, menus texte, GUI, etc.
- Attend une touche avant de se fermer.

## 4. Mode Jeu : scriptJeux.ps1

Ce script est fait pour **optimiser un peu les performances en jeu** en arrêtant temporairement certains services Windows (Windows Update, télémétrie, Xbox, indexation, etc.), puis en les remettant comme avant.

### ⚠️ Attention

- À utiliser **avec prudence** : tu modifies des services système.
- Toujours lancer PowerShell **en administrateur**.
- Le gain en FPS dépend beaucoup de ta machine et de ton usage. Ce script peut surtout réduire les micro-freezes et les tâches inutiles en arrière-plan.

### Lancer le mode jeu

1. Ouvre PowerShell **en tant qu'administrateur**.
2. Place-toi dans le dossier du projet :

```powershell
cd C:\Users\Revelation\Desktop\PojetPowershell
```

3. Lancer le script :

```powershell
.\scriptJeux.ps1
```

Le script :
- Vérifie que tu es bien en administrateur.
- Liste les services ciblés et leur état (en couleur).
- Te demande confirmation avant de les arrêter (sauf si tu utilises `-SansConfirmation`).
- Arrête les services qui étaient en cours d'exécution.
- Attend que tu aies fini de jouer.
- Réactive uniquement les services qui étaient **actifs au départ**.

### Option : sans confirmation

Tu peux lancer directement le mode jeu sans question :

```powershell
.\scriptJeux.ps1 -SansConfirmation
```

## 5. Conseils pour aller plus loin

- T'inspirer de la doc dans `Doc-App-PowerShell.ps1` pour créer tes propres scripts :
  - scripts de nettoyage,
  - app de sauvegarde de fichiers,
  - petits outils pour ton PC.
- Ajouter d'autres scripts dans ce dossier et les documenter dans ce README.

---

Ce projet est un bon point de départ pour apprendre PowerShell en créant des scripts utiles pour ton PC de jeu.
