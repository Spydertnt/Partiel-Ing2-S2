# Corrige - ExamIA_GSIFI2425

Sujet : `ExamIA_GSIFI2425.pdf`

## 1. Questions de cours et de reflexion

### 1. Apprentissage par renforcement et autres types d'apprentissage

L'apprentissage par renforcement correspond bien a de l'apprentissage automatique : un agent apprend a ameliorer son comportement a partir de ses interactions avec un environnement. Il n'est pas programme explicitement pour chaque situation ; il apprend par essais et erreurs.

Difference avec l'apprentissage supervise :

- en apprentissage supervise, on dispose d'exemples etiquetes ;
- en apprentissage par renforcement, l'agent ne connait pas directement la bonne action ;
- il recoit seulement une recompense ou une punition apres ses actions.

Difference avec l'apprentissage non supervise :

- l'apprentissage non supervise cherche des structures dans des donnees non etiquetees ;
- l'apprentissage par renforcement est guide par un signal de recompense fourni par l'environnement.

### 2. Dichotomie exploration / exploitation

L'exploitation consiste a choisir l'action qui semble actuellement la meilleure, c'est-a-dire celle qui maximise le gain attendu.

L'exploration consiste a essayer d'autres actions pour decouvrir de meilleures possibilites.

Dans le Q-learning, ce compromis est souvent gere par une strategie `epsilon-greedy` :

- avec probabilite `epsilon`, l'agent choisit une action au hasard : exploration ;
- avec probabilite `1 - epsilon`, il choisit l'action ayant la plus grande valeur `Q(s, a)` : exploitation.

Dans le recuit simule, ce compromis est controle par la temperature `T`. Quand `T` est elevee, l'algorithme accepte plus facilement des solutions moins bonnes, ce qui favorise l'exploration. Quand `T` diminue, l'algorithme devient plus selectif et exploite davantage les bonnes solutions deja trouvees.

## 2. Deep Learning

### 1. Caracteristiques des images

Le code indique :

```python
input_shape=(32, 32, 3)
```

Les images ont donc une taille de `32 x 32` pixels et possedent `3` canaux. Ce sont donc des images couleur, de type RGB.

### 2. Nombre de classes

La derniere couche est :

```python
layers.Dense(5, activation='softmax')
```

Le probleme comporte donc **5 classes**.

### 3. Couche de convolution

#### a. Role

Une couche de convolution applique des filtres, aussi appeles noyaux ou templates, pour extraire des caracteristiques locales dans l'image : contours, formes, textures, motifs.

#### b. Taille

La couche est :

```python
layers.Conv2D(32, (3, 3), activation='relu', input_shape=(32, 32, 3))
```

Elle contient `32` filtres de taille `3 x 3`.

Comme aucun padding n'est precise, Keras utilise par defaut `padding='valid'`. La taille spatiale devient donc :

```text
32 - 3 + 1 = 30
```

La sortie de cette couche a donc la forme :

```text
(30, 30, 32)
```

#### c. Nombre de parametres

Formule :

```text
nombre de filtres * (largeur * hauteur * canaux d'entree + 1 biais)
```

Application :

```text
32 * (3 * 3 * 3 + 1)
= 32 * 28
= 896 parametres
```

### 4. Couche de pooling

Le pooling sert a simplifier/resumer les cartes de caracteristiques obtenues apres convolution. Avec un max-pooling, on garde la valeur maximale dans chaque zone.

Ici :

```python
layers.MaxPooling2D(pool_size=(2, 2))
```

La couche precedente a une taille `(30, 30, 32)`. Le pooling `2 x 2` divise les dimensions spatiales par 2 :

```text
(30, 30, 32) -> (15, 15, 32)
```

### 5. Couches Dropout

Le dropout desactive aleatoirement une fraction des neurones pendant l'entrainement. Cela evite que le reseau depende trop de certains neurones et aide a limiter le surapprentissage.

Le dropout ne change pas la taille de la sortie et n'a aucun parametre appris.

Pour `Dropout(0.3)` :

```text
taille d'entree : (15, 15, 32)
taille de sortie : (15, 15, 32)
parametres : 0
```

Pour `Dropout(0.5)` :

```text
taille d'entree : (128)
taille de sortie : (128)
parametres : 0
```

### 6. Signification de `loss=keras.losses.categorical_crossentropy`

Cette instruction choisit la fonction de perte du modele : l'entropie croisee categorielle.

Elle est adaptee a une classification multi-classes avec des etiquettes encodees en one-hot et une sortie `softmax`. Elle mesure l'ecart entre la distribution attendue et la distribution predite par le reseau.

### 7. Ajustement des parametres du reseau

Les images passent d'abord dans le reseau pour produire des predictions. La fonction de perte calcule ensuite l'erreur entre predictions et vraies etiquettes. La retropropagation du gradient calcule l'influence de chaque poids et biais sur cette erreur. L'optimiseur, ici `adam`, modifie alors les parametres dans le sens qui reduit la perte. Ce processus est repete pendant plusieurs epochs.

### 8. Evaluation du reseau

#### a. Metrique globale

La metrique utilisee est :

```python
metrics=['accuracy']
```

L'accuracy est le rapport entre le nombre de predictions correctes et le nombre total d'exemples :

```text
accuracy = nombre de predictions correctes / nombre total d'exemples
```

#### b. Metrique par classe

Pour evaluer plus finement chaque classe, on peut utiliser :

- la precision : parmi les exemples predits comme appartenant a une classe, proportion de predictions correctes ;
- le rappel : parmi les vrais exemples d'une classe, proportion correctement retrouves.

## 3. Optimisation - Recuit simule

### 1. Principe et utilite

Le recuit simule est une methode d'optimisation inspiree du refroidissement des metaux. L'algorithme explore l'espace des solutions en acceptant toujours les solutions qui ameliorent le cout, mais aussi parfois des solutions moins bonnes.

Cette acceptation de solutions moins bonnes permet d'echapper aux minima locaux. C'est pourquoi le recuit simule est utile pour les problemes d'optimisation combinatoire.

### 2. Representation d'une solution

Si le graphe contient `n` sommets, on peut representer une solution par un vecteur `X` de taille `n`.

Chaque composante `X[i]` indique la couleur donnee au sommet `i`.

Exemple :

```text
X = [1, 2, 1, 3]
```

Cela signifie :

- sommet 1 : couleur 1 ;
- sommet 2 : couleur 2 ;
- sommet 3 : couleur 1 ;
- sommet 4 : couleur 3.

### 3. Fonction cout a minimiser

On veut utiliser peu de couleurs, tout en evitant que deux sommets adjacents aient la meme couleur.

On peut donc definir :

```text
f(X) = nombre de couleurs utilisees
       + alpha * nombre de conflits
```

ou un conflit est une arete `(u, v)` telle que :

```text
X[u] == X[v]
```

`alpha` est une grande penalite pour favoriser les colorations valides.

### 4. Fonction de perturbation

Pour generer un voisin d'une solution courante :

1. choisir aleatoirement un sommet `i` ;
2. choisir une nouvelle couleur pour ce sommet ;
3. remplacer `X[i]` par cette nouvelle couleur ;
4. obtenir ainsi une solution voisine.

### 5. Probabilite d'accepter une solution moins bonne

Si la nouvelle solution est moins bonne, on pose :

```text
Delta E = f(X_voisin) - f(X_courant) > 0
```

Elle est acceptee avec la probabilite :

```text
P(accepter) = exp(-Delta E / T)
```

Quand `T` est grande, on accepte plus facilement les mauvaises solutions. Quand `T` diminue, on les accepte de moins en moins.

## 4. Traitement du langage naturel

### 1. Grammaire, terminaux et non-terminaux

La grammaire est hors-contexte, car chaque regle a un seul symbole non-terminal a gauche.

Symboles non-terminaux :

```text
S, NP, VP, PP, Det, N, V, P
```

Symboles terminaux :

```text
"le", "un", "la", "une", "chat", "poisson", "loupe", "voit", "mange", "dans", "avec"
```

Remarque : la phrase contient le mot `"jardin"`, mais la grammaire fournie ne contient pas ce mot dans les terminaux. Pour pouvoir analyser la phrase, on suppose qu'il s'agit d'un oubli dans l'enonce et que `"jardin"` peut aussi etre un nom.

### 2. Deux arbres syntaxiques possibles

Phrase :

```text
Le chat voit le poisson avec un jardin.
```

#### Arbre 1 : rattachement du PP au VP

Dans cette interpretation, `avec un jardin` modifie le groupe verbal.

```text
S
├── NP
│   ├── Det -> le
│   └── N   -> chat
└── VP
    ├── VP
    │   ├── V  -> voit
    │   └── NP
    │       ├── Det -> le
    │       └── N   -> poisson
    └── PP
        ├── P  -> avec
        └── NP
            ├── Det -> un
            └── N   -> jardin
```

Derivation principale :

```text
S -> NP VP
NP -> Det N
VP -> VP PP
VP -> V NP
PP -> P NP
```

#### Arbre 2 : rattachement du PP au NP

Dans cette interpretation, `avec un jardin` modifie le groupe nominal `le poisson`.

```text
S
├── NP
│   ├── Det -> le
│   └── N   -> chat
└── VP
    ├── V -> voit
    └── NP
        ├── NP
        │   ├── Det -> le
        │   └── N   -> poisson
        └── PP
            ├── P  -> avec
            └── NP
                ├── Det -> un
                └── N   -> jardin
```

Derivation principale :

```text
S -> NP VP
NP -> Det N
VP -> V NP
NP -> NP PP
PP -> P NP
```

### 3. Origine et nature de l'ambiguite

L'ambiguite vient du rattachement du groupe prepositionnel `avec un jardin`.

Ce groupe peut etre rattache :

- soit au groupe verbal `voit le poisson` ;
- soit au groupe nominal `le poisson`.

Il s'agit donc d'une ambiguite syntaxique, car une meme phrase admet deux arbres syntaxiques differents. La resolution peut ensuite faire intervenir la semantique ou le contexte.
