#### SUIVI DES FONCTIONNALITÉS - ComfyUI Portable Launcher
#### Date de dernière mise à jour : 2025-09-02

Ce document offre une vue d'ensemble des fonctionnalités implémentées et prévues pour le projet.

---

### 1. Noyau et Portabilité

- [x] **Gestionnaire d'outils autonome** : Télécharge et installe automatiquement Portable Git et Miniforge.
- [x] **Environnement Python isolé** : Crée et gère un environnement Conda dédié pour éviter les conflits.
- [x] **Structure de projet portable** : Tous les fichiers (outils, environnement, ComfyUI) sont contenus dans le répertoire du lanceur.

### 2. Détection Matérielle et Installation Adaptative

- [x] **Détection multi-composants** : Identifie le CPU, la RAM et le GPU au démarrage.
- [x] **Détection GPU précise (NVIDIA)** : Utilise `nvidia-smi` pour récupérer le nom, la VRAM et la **Compute Capability**.
- [x] **Fallback pour GPU non-NVIDIA** : Utilise `wmic` comme solution de secours.
- [x] **Installation conditionnelle de `SageAttention`** : L'installation est déclenchée uniquement pour les GPU NVIDIA avec une Compute Capability de 8.0 ou supérieure.

### 3. Gestion du Cycle de Vie et Interface Utilisateur

- [x] **Menu principal interactif** : Propose des options claires à l'utilisateur.
- [x] **Lancement de ComfyUI** : Démarre l'application avec des arguments personnalisables via `parameters.txt`.
- [x] **Mise à jour de ComfyUI** : Met à jour le dépôt de ComfyUI via Git.
- [x] **Réparation de l'environnement** : Permet de supprimer et de réinstaller proprement l'environnement Conda.
- [x] **Terminal interactif** : Ouvre une console avec l'environnement Conda déjà activé pour le débogage ou la gestion manuelle.
- [x] **Option pour quitter** : Permet de fermer le script proprement depuis le menu.

---