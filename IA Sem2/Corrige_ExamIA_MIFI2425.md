# Corrige - ExamIA_MIFI2425

## 1. Jeux - Expectiminimax

### 1. Completer l'arbre

Les noeuds Min prennent le minimum de leurs feuilles :

$$
\min(4,1)=1,\quad \min(5,8)=5,\quad \min(1,3)=1,\quad \min(2,1)=1
$$

Les noeuds Chance prennent la moyenne ponderee de leurs fils.

Noeud Chance gauche :

$$
0{,}9 \times 1 + 0{,}1 \times 5 = 1{,}4
$$

Noeud Chance droit :

$$
0{,}3 \times 1 + 0{,}7 \times 1 = 1
$$

La racine est un noeud Max :

$$
\max(1{,}4,1)=1{,}4
$$

### 2. Meilleur coup de Max

Max choisit le fils gauche, car sa valeur expectiminimax est `1,4`, contre `1` pour le fils droit.

### 3. Signification de la valeur de la racine

Dans Minimax classique, la valeur de la racine est le gain garanti par Max si les deux joueurs jouent optimalement.

Dans Expectiminimax, la valeur de la racine est l'esperance de gain pour Max, en tenant compte a la fois des choix optimaux des joueurs et des probabilites des evenements aleatoires.

### 4. Representation d'un noeud Chance

Pour le lancer d'une piece :

```text
Chance
├── Pile : 1/2
└── Face : 1/2
```

Pour deux lancers de de sans tenir compte de l'ordre, les evenements sont les couples `{i,j}` avec `1 <= i <= j <= 6`.

- Si `i = j`, la probabilite est `1/36`.
- Si `i != j`, la probabilite est `2/36`, car `{i,j}` peut sortir dans deux ordres.

Il y a donc `21` branches : 6 doubles et 15 couples differents.

## 2. Optimisation - Recuit simule et clustering

### 1. Representation d'une solution

On peut representer une solution par un vecteur `X` de taille `n`, ou `n` est le nombre de points.

$$
X[i] \in \{1,\dots,k\}
$$

`X[i]` indique le cluster affecte au point `i`.

Exemple :

```text
X = [1, 2, 1, 3, 2]
```

signifie que les points 1 et 3 sont dans le cluster 1, les points 2 et 5 dans le cluster 2, et le point 4 dans le cluster 3.

### 2. Taille de l'espace de recherche

Chaque point peut etre affecte a l'un des `k` clusters. Pour `n` points :

$$
|\Omega| = k^n
$$

Cet espace devient tres grand lorsque `n` augmente. Le recuit simule est donc utile, car il explore l'espace sans tester toutes les solutions.

### 3. Voisinage et energie

Une relation de voisinage simple consiste a changer le cluster d'un seul point.

Exemple :

```text
[1, 2, 1, 3] -> [1, 2, 2, 3]
```

L'energie doit favoriser des clusters compacts et separes. On peut par exemple minimiser :

$$
E(X)
= \sum_{c=1}^{k} \sum_{x_i \in C_c} d(x_i,\mu_c)^2
$$

ou `mu_c` est le centre du cluster `C_c`. Cette energie penalise les points eloignes du centre de leur cluster.

On peut aussi ajouter un terme qui favorise l'eloignement entre centres de clusters.

## 3. Apprentissage par renforcement

La grille a 4 colonnes et 4 lignes. La case verte est l'objectif : ligne 1, colonne 2. Les cases rouges sont des obstacles : `(2,2)`, `(2,3)` et `(3,3)`.

### 1. Modelisation

On peut modeliser le probleme comme un processus de decision markovien.

- Etats `S` : les cases non obstacles de la grille.
- Etat terminal : la case verte.
- Actions `A` : haut, bas, gauche, droite.
- Transitions `T(s,a,s')` : deterministes si l'action est possible ; si l'action sort de la grille ou touche un obstacle, l'agent reste sur place.
- Recompenses : par exemple `+1` pour atteindre l'objectif, `0` pour les autres deplacements, ou une petite penalite negative pour favoriser les chemins courts.
- Facteur d'actualisation : `gamma`.

### 2. Definition d'une strategie

Une strategie, ou politique, associe une action a chaque etat :

$$
\pi : S \to A
$$

Exemple : pour une case situee a gauche de l'objectif, la strategie peut choisir l'action `droite`.

### 3. Utilite de Value Iteration

Value Iteration sert a calculer la fonction de valeur optimale `V*`, puis a en deduire une strategie optimale.

L'algorithme applique l'equation :

$$
Q(s,a)=R(s,a)+\gamma\sum_{s'}T(s,a,s')V(s')
$$

puis :

$$
V(s)=\max_a Q(s,a)
$$

### 4. Deux premieres iterations

Le resultat numerique depend des recompenses choisies dans la modelisation. Avec le choix simple suivant :

- `V_0(s)=0` pour tous les etats ;
- recompense `+1` lorsqu'une action atteint la case verte ;
- recompense `0` ailleurs ;
- obstacles non accessibles.

Iteration 1 :

$$
V_1(s)=\max_a R(s,a)
$$

Les cases pouvant atteindre directement l'objectif en un coup prennent la valeur `1`. Les autres restent a `0`.

Iteration 2 :

$$
V_2(s)=\max_a \left(R(s,a)+\gamma V_1(s')\right)
$$

Les cases qui peuvent atteindre en un coup une case de valeur `1` prennent la valeur `\gamma`, sauf si elles peuvent atteindre directement l'objectif, auquel cas elles gardent la valeur `1`.

## 4. Deep Learning

Le jeu Fashion MNIST contient `60 000` images de taille `28 x 28` en niveaux de gris, avec `10` classes.

Architecture du code :

```text
Conv2D(32, 3x3, relu)
Conv2D(64, 3x3, relu)
Conv2D(128, 3x3, relu)
MaxPooling2D(2x2)
Dropout(0.25)
Flatten
Dense(128, relu)
Dropout(0.5)
Dense(num_classes, softmax)
```

### 1. Avantages d'un ConvNet

Un ConvNet prend en compte la structure spatiale de l'image. Les filtres detectent des motifs locaux, comme des contours ou des formes, et les memes filtres sont reutilises sur toute l'image. Cela reduit le nombre de parametres par rapport a un reseau entierement connecte et rend le modele plus adapte aux images.

### 2. Interet de Softmax

`softmax` transforme les scores de sortie en probabilites sur les classes. Elle est adaptee a une classification multi-classes exclusive.

### 3. Description des couches

- `Conv2D` : extrait des caracteristiques locales avec des filtres.
- `MaxPooling2D` : resume les cartes de caracteristiques et reduit leur taille.
- `Dropout` : desactive aleatoirement une proportion de neurones pendant l'entrainement pour limiter le surapprentissage.
- `Flatten` : transforme les cartes 2D en un vecteur.
- `Dense` : couche totalement connectee qui combine les caracteristiques.
- `Dense softmax` : produit les probabilites finales des classes.

### 4. Couches sans parametres

Les couches sans parametres sont :

- `MaxPooling2D` : hyperparametre principal `pool_size=(2,2)`.
- `Dropout(0.25)` et `Dropout(0.5)` : hyperparametre `rate`.
- `Flatten` : pas de parametre appris, pas d'hyperparametre important.

### 5. `batch_size` et `epochs`

`batch_size` est le nombre d'exemples traites avant une mise a jour des poids.

`epochs` est le nombre de passages complets sur l'ensemble d'apprentissage.
