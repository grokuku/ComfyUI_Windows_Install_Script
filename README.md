# ComfyUI Portable Launcher

Un script Batch (`.bat`) simple mais puissant pour automatiser entièrement l'installation, la gestion et le lancement d'une instance **100% portable** de [ComfyUI](https://github.com/comfyanonymous/ComfyUI) sur Windows.

Ce projet est né du besoin d'avoir une solution "clé en main" qui ne nécessite aucune installation manuelle d'outils (comme Python ou Git) et qui n'interfère pas avec le système d'exploitation.

## À quoi ça sert ?

Le but de ce script est de simplifier radicalement l'expérience ComfyUI pour les utilisateurs Windows. Il gère pour vous toutes les étapes techniques et fastidieuses.

En bref, vous téléchargez un seul fichier, vous double-cliquez dessus, et le script s'occupe de tout le reste.

## Caractéristiques principales

*   **Entièrement Portable :** Le script et tous les outils qu'il télécharge (Git, Conda) ainsi que ComfyUI lui-même sont contenus dans un seul dossier. Vous pouvez le placer sur un disque dur externe, le déplacer, ou le supprimer sans laisser de traces sur votre système.
*   **Installation 100% Automatisée :** Le script détecte, télécharge et installe automatiquement :
    *   Portable Git
    *   Miniforge (une version légère de Conda)
    *   ComfyUI (depuis le dépôt officiel)
    *   Le [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
    *   Vos propres custom nodes (ex: ComfyUI-Holaf-Utilities)
*   **Environnement Isolé :** Utilise Conda pour créer un environnement Python dédié. Cela garantit qu'il n'y aura jamais de conflit de dépendances avec d'autres applications Python sur votre machine.
*   **Installation Fiable de PyTorch + CUDA :** Gère la séquence d'installation complexe et fragile de PyTorch avec la bonne version du CUDA Toolkit pour garantir une accélération GPU fonctionnelle dès le premier lancement.
*   **Menu Interactif Simple :** Offre un menu clair pour les actions courantes :
    1.  **Lancer :** Installe si besoin, puis lance l'application.
    2.  **Mettre à jour :** Met à jour le code de ComfyUI, puis réinstalle les dépendances pour assurer la compatibilité.
    3.  **Réparer :** Supprime et reconstruit l'environnement Python de zéro, la solution idéale en cas de problème majeur.
*   **Prise en Charge des Custom Nodes :** Détecte et installe automatiquement les dépendances (`requirements.txt`) de tous les nodes personnalisés que vous ajoutez.
*   **Configuration Simplifiée :** Utilisez le fichier `parameters.txt` pour ajouter vos arguments de lancement favoris (`--preview-method`, etc.) sans avoir à modifier le script.

## Comment l'utiliser ?

1.  Téléchargez le script `ComfyUI-Launcher.bat` depuis ce dépôt.
2.  Placez-le dans un **dossier vide** de votre choix (par exemple `D:\ComfyUI-Portable\`).
3.  Double-cliquez dessus.

La première exécution sera très longue, car le script télécharge et installe plusieurs Gigaoctets de données. Soyez patient ! Les lancements suivants seront quasi-instantanés.

## Crédits

*   **Script :** Créé par Holaf avec l'aide de Gemini.
*   **Outils et Applications :** Un grand merci aux créateurs de [ComfyUI](https://github.com/comfyanonymous/ComfyUI), [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager), [Miniforge (Conda-Forge)](https://github.com/conda-forge/miniforge) et [PortableGit](https://git-for-windows.github.io/).
