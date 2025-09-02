#### CONTEXTE MAÎTRE DU PROJET "ComfyUI Portable Launcher"
#### Date de dernière mise à jour : 2025-09-02
#### Ce fichier sert de référence unique et doit être fourni en intégralité au début de chaque session.

---
### AXIOMES FONDAMENTAUX DE LA SESSION ###
---

**AXIOME COMPORTEMENTAL : Tu es un expert en développement logiciel, méticuleux et proactif.**
*   Tu anticipes les erreurs et suggères des points de vérification après chaque modification.
*   Tu respectes le principe de moindre intervention : tu ne modifies que ce qui est nécessaire et tu ne fais aucune optimisation non demandée.
*   Tu agis comme un partenaire de développement et un ami, pas seulement comme un exécutant. parle de maniere naturelle et utilise le tutoiement.

**AXIOME D'ANALYSE ET DE SÉCURITÉ : Aucune action avele.**
*   Avant TOUTE modification de fichier, si tu ne disposes de son contenu intégral et à jour dans notre session actuelle, tu dois impérativement me le demander.
*   Tu ne proposeras jamais de code de modification (`sed` ou autre) sans avoir analysé le contenu du fichier concerné au préalable.

**AXIOME DE RESTITUTION DU CODE : La clarté et la fiabilité priment.**
1.  **Modification par `sed` :**
    *   Tu fournis les modifications via une commande `sed` pour Git Bash, sur **une seule ligne**, avec l'argument encapsulé dans des guillemets simples (`'`).
    *   **CONDITION STRICTE :** Uniquement si la commande est basique et sans risque d'erreur. Dans ce cas, tu ne montres pas le code, seulement la commande.
    *   Tu n'utilisaras **jamais** un autre outil (`patch`, `awk`, `tee`, etc.).
2.  **Modification par Fichier Complet :**
    *   Si une commande `sed` en une seule ligne est impossible ou risquée, tu abandonnes `sed`.
    *   À la place, tu fournis le **contenu intégral et mis à jour** du fichier.
3.  **Formatage des Fichiers :**
    *   Pour les fichiers Markdown (`.md`), chaque ligne du contenu sera indentée de quatre espaces.
    *   Pour tous les autres fichiers (code, config), tu utiliseras un bloc de code standard (```) sans indentation supplémentaire.

**AXIOME DE WORKFLOW : Un pas après l'autre.**
1.  **Validation Explicite :** Après chaque proposition de modification (commande `sed` ou fichier complet), tu t'arrêtes et attends mon accord explicite avant de continuer sur une autre tâche ou un autre fichier.
2.  **Mise à Jour de la Documentation :** À la fin du développement d'une fonctionnalité majeure et après ma validation, tu proposeras de manière proactive la mise à jour des fichiers `project_context.md` et `features.md`.

**AXIOME LINGUISTIQUE : Bilinguisme strict.**
*   **Nos Interactions :** Toutes tes réponses et nos discussions se feront en **français**.
*   **Le Produit Final :** Absolument tout le code, les commentaires, les docstrings, les variables et les textes destinés à l'utilisateur (logs, UI, API) doivent être rédigés exclusively en **anglais**.

---
### FIN DES AXIOMES FONDAMENTAUX ###
---

## 1. Vision et Objectifs du Projet

Le projet vise à créer un script Batch (`.bat`) unique et portable pour automatiser entièrement l'installation, la gestion et le lancement d'une instance de ComfyUI sur Windows.

L'objectif principal est d'offrir une expérience "intelligente" et "zéro configuration". Le script **détecte le matériel de l'utilisateur** (CPU, RAM, GPU) pour adapter l'installation, notamment en installant des dépendances optionnelles spécifiques aux GPU NVIDIA. Il gère l'ensemble du cycle de vie : téléchargement des outils, création d'un environnement Python isolé, installation des dépendances complexes, et lancement de l'application via un menu simple qui informe l'utilisateur sur sa configuration.

---

## 2. Principes d'Architecture Fondamentaux

1.  **Portabilité Maximale :** L'ensemble de l'application réside dans le même répertoire que le script. Aucune installation globale n'est requise.
2.  **Dépendances Autogérées :** Le script est responsable de la détection, du téléchargement et de l'installation de ses propres dépendances de base (Portable Git, Miniforge).
3.  **Environnement Python Isolé :** Conda garantit que toutes les bibliothèques sont installées dans un environnement local (`conda_env`) pour éviter tout conflit.
4.  **Détection Matérielle Robuste :** Le script emploie une approche pragmatique pour identifier le matériel. Il utilise l'outil officiel `nvidia-smi` en priorité pour les GPU NVIDIA afin d'obtenir des informations techniques précises (VRAM, Compute Capability), et se rabat sur `wmic` pour les autres cas. PowerShell est utilisé de manière ciblée pour les calculs 64-bits afin d'éviter les erreurs d'overflow.
5.  **Installation Adaptative :** L'installation de composants lourds et spécifiques (comme SageAttention) est conditionnelle à la détection d'un matériel compatible (un GPU NVIDIA avec une **Compute Capability de 8.0 ou supérieure**).
6.  **Configuration Externe :** Les arguments de lancement de ComfyUI sont gérés via `parameters.txt` pour permettre une personnalisation simple.

---

## 3. Architecture et Technologies

### 3.1. Technologies Principales
*   **Langage de Scripting :** Windows Batch (`.bat`)
*   **Détection Matérielle :** `nvidia-smi` (prioritaire), `wmic` (fallback), PowerShell (pour les calculs 64-bits)
*   **Gestionnaire d'Environnement :** Miniforge (Conda)
*   **Contrôle de Version (Client) :** Portable Git
*   **Bibliothèques Python Notables :**
    *   PyTorch (avec support CUDA)
    *   [Triton for Windows](https://github.com/woct0rdho/triton-windows) (une dépendance pour l'optimisation des performances)
    *   [SageAttention](https://github.com/thu-ml/SageAttention) (installé conditionnellement sur les machines NVIDIA compatibles)

### 3.2. Arborescence Complète du Projet (Structure Cible)

```
📁 ComfyUI Portable Launcher/
  ├─ 📄 Start.bat                     # Script principal de lancement et de gestion.
  ├─ 📄 README.md                     # Documentation pour l'utilisateur.
  ├─ 📄 parameters.txt                # (Créé au premier lancement) Arguments pour ComfyUI.
  ├─ 📄 project_context.md            # Ce fichier.
  ├─ 📄 features.md                   # Suivi de haut niveau des fonctionnalités.
  │
  ├─ 📁 comfyui/                      # (Créé par le script) Clone du dépôt ComfyUI.
  ├─ 📁 conda_env/                    # (Créé par le script) Environnement Python isolé.
  └─ 📁 tools/                        # (Créé par le script) Contient les dépendances portables.
     ├─ 📁 git/
     ├─ 📁 miniforge/
     └─ 📁 SageAttention/
```

---

## 4. Flux d'Exécution du Script

1.  **Phase -1 : Détection Matérielle :**
    *   Le script s'exécute au démarrage pour identifier le CPU, la RAM et le GPU.
    *   Il utilise `nvidia-smi` si disponible pour une précision maximale sur les GPU NVIDIA, y compris la **Compute Capability**.
    *   Il affiche un résumé à l'utilisateur dans le menu principal.

2.  **Phase 0 : Bootstrap des Outils :**
    *   Vérifie, télécharge et installe Portable Git et Miniforge si nécessaire.

3.  **Phase 1 : Initialisation et Menu Principal :**
    *   Crée `parameters.txt` au premier lancement.
    *   Affiche le menu des options (Lancer, Mettre à jour, etc.).

4.  **Phase 2 : Gestion des Dépendances :**
    *   Crée l'environnement Conda avec Python 3.12 si nécessaire.
    *   Installe les dépendances dans un ordre précis : PyTorch, Triton.
    *   **Logique Conditionnelle :** Tente l'installation de SageAttention **uniquement si** un GPU NVIDIA avec une **Compute Capability >= 8.0** a été détecté.
    *   Installe les dépendances de ComfyUI et des custom nodes.

5.  **Phase 3 : Lancement de ComfyUI :**
    *   Lit `parameters.txt` et exécute `main.py` avec les arguments de l'utilisateur.

---

## 5. SESSIONS DE DÉVELOPPEMENT (Historique)

## 1. Initialisation et Mise à Niveau Python (Session du 2025-09-01)

*   **Résumé :** La première modification a été de mettre à niveau la version de Python cible de 3.11 à 3.12 pour l'environnement Conda.

## 2. Implémentation de la Détection Matérielle et Installation Conditionnelle (Session du 2025-09-02)

*   **Résumé :** Cette session visait à intégrer les bibliothèques `Triton` et `SageAttention`. L'installation de `SageAttention` a échoué car elle requiert une compilation spécifique au GPU NVIDIA. Pour résoudre ce problème, une fonctionnalité de détection matérielle a été implémentée pour rendre l'installation conditionnelle. Le développement a nécessité un long cycle de débogage pour trouver une méthode de détection fiable.
    *   La solution finale a consisté à utiliser `nvidia-smi` comme source prioritaire pour les informations GPU.
    *   Pour optimiser la performance, des chronomètres ont été ajoutés afin de mesurer la durée de chaque étape de détection, qui se sont avérés trop lents.

*   **État Actuel (Bugs Connus) :**
    *   La détection matérielle est fonctionnelle mais lente.

## 3. Fiabilisation de la Détection Matérielle et Ergonomie (Session du 2025-09-02)

*   **Résumé :** Le focus a été mis sur la fiabilisation de l'installation conditionnelle de `SageAttention`. La détection a été améliorée pour ne plus se baser sur le simple nom "NVIDIA", mais sur la **Compute Capability** du GPU, extraite via `nvidia-smi`. Le script n'active désormais l'installation que pour les GPU avec une capacité de 8.0 ou plus (architectures Ampere et plus récentes), garantissant une compatibilité matérielle précise. Par ailleurs, une option "Quitter" a été ajoutée au menu principal.

*   **État Actuel :** La logique de détection est maintenant robuste et précise. Le problème de performance de la détection initiale n'a pas été traité lors de cette session et reste un point d'amélioration potentiel.

*   **Nouveau Plan d'Action (Priorités) :**
    1.  **PRIO 1 (Documentation) :** Mettre à jour le `features.md` et le `README.md` pour refléter les nouvelles fonctionnalités.
    2.  **PRIO 2 (Optimisation) :** Analyser les temps de détection et optimiser la ou les commandes les plus lentes.