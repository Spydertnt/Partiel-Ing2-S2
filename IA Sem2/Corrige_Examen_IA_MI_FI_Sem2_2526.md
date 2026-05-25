# Corrige - Examen IA Applications MI-FI Sem2 2025-26

Version adaptee aux formulations vues dans les supports de cours et TD.

## 1. Jeux a deux joueurs

### 1. Construction de l'arbre

L'arbre comporte 5 niveaux : racine au niveau 1 et feuilles au niveau 5. C'est un arbre binaire puisque chaque noeud non terminal possede exactement 2 fils.

- Niveau 1 : 1 noeud Max, la racine.
- Niveau 2 : 2 noeuds Min.
- Niveau 3 : 4 noeuds Max.
- Niveau 4 : 8 noeuds Min.
- Niveau 5 : 16 feuilles.

Feuilles de gauche a droite :

```text
3, -5, -6, 7, 7, 8, 8, -3, -4, 6, 8, -3, 3, 2, -1, 5
```

### 2. Signification des valeurs des feuilles

Ces valeurs representent l'utilite ou l'evaluation heuristique d'une configuration de jeu, du point de vue de Max. Une valeur elevee favorise Max, tandis qu'une valeur basse ou negative favorise Min.

Elles peuvent etre obtenues par une fonction d'evaluation statique appliquee lorsque la profondeur maximale de recherche est atteinte. Cette fonction estime la qualite d'une position sans explorer toute la suite du jeu.

### 3. Application de Minimax

On remonte les valeurs de bas en haut : minimum aux niveaux Min, maximum aux niveaux Max.

Niveau 4, noeuds Min :

```text
min(3, -5) = -5
min(-6, 7) = -6
min(7, 8) = 7
min(8, -3) = -3
min(-4, 6) = -4
min(8, -3) = -3
min(3, 2) = 2
min(-1, 5) = -1
```

Niveau 3, noeuds Max :

```text
max(-5, -6) = -5
max(7, -3) = 7
max(-4, -3) = -3
max(2, -1) = 2
```

Niveau 2, noeuds Min :

```text
min(-5, 7) = -5
min(-3, 2) = -3
```

Racine Max :

```text
max(-5, -3) = -3
```

La valeur minimax de la racine est donc **-3**. Cela signifie que si les deux joueurs jouent optimalement, Max peut garantir au mieux la valeur `-3`.

### 4. Principe et interet de l'elagage alpha-beta

Pendant le parcours de l'arbre, on conserve deux bornes :

- `alpha` : meilleure valeur deja garantie pour Max ;
- `beta` : meilleure valeur deja garantie pour Min.

Si on obtient `alpha >= beta`, la branche courante ne peut plus influencer la decision finale. On peut donc l'elaguer. L'interet est de visiter moins de noeuds que minimax classique, sans changer le resultat final.

### 5. Alpha-beta jusqu'au premier retour a la racine

Parcours de gauche a droite.

1. Racine Max : `alpha = -inf`, `beta = +inf`. On explore le fils gauche.
2. Noeud Min gauche : on explore son premier fils Max.
3. Ce noeud Max explore son premier fils Min : `min(3, -5) = -5`.
4. Retour au noeud Max : sa valeur courante devient `alpha = -5`.
5. On explore son deuxieme fils Min, appele avec `alpha = -5`.
6. Dans ce noeud Min, la premiere feuille vaut `-6`. Comme `-6 <= alpha`, on peut couper la deuxieme feuille `7`.
7. Le premier noeud Max renvoie donc `-5`.
8. Retour au noeud Min gauche : sa valeur courante devient `beta = -5`.
9. On explore son deuxieme fils Max, appele avec `beta = -5`.
10. Dans ce noeud Max, le premier fils Min vaut `7`. Comme `7 >= beta`, on peut couper le reste du sous-arbre.
11. Le noeud Min gauche renvoie `-5` a la racine.

Premier retour a la racine :

```text
valeur du fils gauche = -5
alpha de la racine devient -5
```

On s'arrete ici comme demande. La valeur finale de la racine n'est pas encore calculee a ce stade.

### 6. Mesure de l'amelioration

On peut mesurer l'amelioration en comparant le nombre de noeuds ou de feuilles visites par minimax classique et par alpha-beta. On peut aussi calculer le nombre de noeuds elagues ou le temps d'execution economise.

## 2. Deep Learning I - ConvNet

### 1. Sens et utilite de `to_categorical`

Les instructions :

```python
Y_train = np_utils.to_categorical(y_train, nb_classes)
Y_test = np_utils.to_categorical(y_test, nb_classes)
```

convertissent les etiquettes de classes, qui sont des entiers de `0` a `9`, en vecteurs binaires de type one-hot. Par exemple, la classe `3` devient :

```text
[0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
```

C'est utile pour entrainer un classifieur multi-classes dont la couche de sortie utilise `softmax`.

### 2. Fonctionnement et utilite des couches

Une couche de convolution applique des filtres, aussi appeles noyaux ou templates, qui glissent sur l'image pour detecter des motifs locaux.

Une couche de pooling sert a simplifier/resumer les cartes de caracteristiques obtenues apres convolution. Dans le cas du max-pooling, on garde la valeur maximale dans une zone, par exemple `2 x 2`.

### 3. Hyperparametres et parametres

Hyperparametres, fixes avant l'entrainement :

- taille des filtres : `kernel_size = 5` ;
- nombre de filtres : `32`, puis `64` ;
- taille du pooling : `2 x 2` ;
- fonctions d'activation : sigmoid et softmax ;
- nombre de neurones de la couche dense : `100`.

Parametres, appris pendant l'entrainement :

- poids, c'est-a-dire coefficients des filtres et des connexions denses ;
- biais associes aux neurones/filtres.

### 4. Determination des parametres

Les parametres, poids et biais, sont initialises puis appris pendant l'entrainement. Les donnees se propagent d'abord vers l'avant pour produire une prediction. L'erreur est ensuite calculee avec une fonction de perte. La retropropagation du gradient permet de calculer comment modifier les parametres, puis un optimiseur les met a jour pour minimiser progressivement cette erreur.

### 5. Nombre de parametres par couche

Attention : le code affiche `X_train.reshape(60000, 784)`, mais `Conv2D` attend normalement une entree image de forme `(28, 28, 1)`. Pour que le ConvNet fonctionne, on suppose donc que l'entree effective est `(28, 28, 1)`.

Formule pour une couche de convolution :

```text
nombre de filtres * (largeur * hauteur * canaux d'entree + 1 biais)
```

| Couche | Calcul | Parametres |
| --- | --- | --- |
| Conv2D_1 | `32 * (5 * 5 * 1 + 1)` | `832` |
| MaxPooling2D_1 | aucune variable apprise | `0` |
| Conv2D_2 | `64 * (5 * 5 * 32 + 1)` | `51 264` |
| MaxPooling2D_2 | aucune variable apprise | `0` |
| Flatten | simple remodelage : `7 * 7 * 64 = 3136` valeurs | `0` |
| Dense_1 | `100 * (3136 + 1)` | `313 700` |
| Dense_2 | `10 * (100 + 1)` | `1 010` |

Total :

```text
832 + 51 264 + 313 700 + 1 010 = 366 806 parametres
```

### 6. Choix de la couche de sortie

MNIST contient 10 classes, les chiffres de `0` a `9`. La couche de sortie contient donc `10` neurones.

La fonction `softmax` est adaptee car elle transforme les scores de sortie en probabilites dont la somme vaut `1`. On choisit ensuite la classe ayant la probabilite la plus forte.

## 3. Deep Learning II - RNN

### 1. Nombre de neurones des couches d'entree et de sortie

Entree : **50 neurones**. Meme si la sequence contient `40` mots, le RNN traite un mot par pas de temps, et chaque mot est represente par un vecteur de taille `50`.

Sortie : **3 neurones**, car il y a trois sentiments possibles : positif, negatif et neutre.

### 2. Fonction d'activation de sortie

On utilise `softmax`, car il s'agit d'une classification multi-classes exclusive. La sortie est un vecteur de probabilites sur les trois sentiments.

### 3. Nombre de parametres avec 64 neurones caches

Pour un RNN simple, la couche cachee combine l'entree courante, de taille `50`, et l'etat cache precedent, de taille `64`.

Couche cachee :

```text
poids entree -> cache : 50 * 64 = 3 200
poids recurrent : 64 * 64 = 4 096
biais : 64
total : 3 200 + 4 096 + 64 = 7 360
```

Couche de sortie :

```text
poids : 64 * 3 = 192
biais : 3
total : 192 + 3 = 195
```

Total :

```text
7 360 + 195 = 7 555 parametres
```

## 4. Apprentissage par renforcement

### 1. Modelisation du probleme

On modelise le probleme comme un processus de decision markovien.

- Etats `S` : les cases de la grille `2 x 3`.
- Etats terminaux : la case verte, objectif, et la case rouge, piege.
- Actions `A` : haut, bas, gauche, droite.
- Transitions `T(s, a, s')` : si le modele est deterministe, une action deplace l'agent vers la case correspondante quand elle existe ; sinon l'agent reste sur place.
- Recompenses `R(s, a)` : par exemple, recompense positive pour atteindre la case verte, recompense negative pour tomber dans la case rouge, et recompense nulle ou legerement negative pour les autres deplacements.
- Objectif : apprendre une strategie qui maximise la recompense cumulee a long terme.

Grille :

```text
[ bleu ] [ bleu ] [ vert ]
[ bleu ] [ rouge] [ bleu ]
```

### 2.a. Sortie de Q-learning

La sortie de Q-learning est une table ou une fonction `Q(s, a)`. Elle donne la qualite estimee de chaque action `a` dans chaque etat `s`, en tenant compte des recompenses futures.

### 2.b. Utilisation de cette sortie

Une fois la table Q apprise, on deduit la strategie optimale en choisissant, pour chaque etat, l'action qui maximise `Q(s, a)` :

```text
pi*(s) = argmax_a Q(s, a)
```

### 2.c. Strategie optimale a la main

En evitant la case rouge et en allant vers la case verte :

```text
[ droite ] [ droite ] [ stop ]
[ haut   ] [ piege  ] [ haut ]
```

Donc :

- depuis la case en haut a gauche : aller a droite ;
- depuis la case en haut au milieu : aller a droite vers l'objectif ;
- depuis la case en bas a gauche : aller en haut ;
- depuis la case en bas a droite : aller en haut vers l'objectif.

### 2.d. Exploration / exploitation

Q-learning utilise souvent une strategie `epsilon-greedy` :

- avec une probabilite `epsilon`, l'agent choisit une action au hasard : exploration ;
- avec une probabilite `1 - epsilon`, l'agent choisit la meilleure action connue selon `Q(s, a)` : exploitation.

L'idee est d'explorer suffisamment au debut, puis d'exploiter davantage les bonnes actions apprises.
