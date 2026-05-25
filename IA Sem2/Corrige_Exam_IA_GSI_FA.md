# Corrige - Intelligence Artificielle Applications GSI FA

## 1. Apprentissage par renforcement 1

### 1. Propriete de Markov et matrice de transition

Le systeme possede la propriete de Markov car la probabilite de passer a l'etat futur `s(t+1)` depend uniquement de l'etat actuel `s(t)`, et non de l'historique des etats passes. Ici, la regle de deplacement depend seulement de l'indice `i` de l'etat courant `s_i`.

Les etats `s1` et `s6` sont absorbants : une fois arrive dans ces etats, l'agent s'y arrete. Pour les etats intermediaires, l'agent avance vers `s(i+1)` avec une probabilite `p` et recule vers `s(i-1)` avec une probabilite `1-p`.

Avec la convention $P_{ij} = P(s_i \to s_j)$, c'est-a-dire lignes = etat de depart et colonnes = etat d'arrivee, la matrice de transition est :

$$
P =
\begin{pmatrix}
1 & 0 & 0 & 0 & 0 & 0 \\
1-p & 0 & p & 0 & 0 & 0 \\
0 & 1-p & 0 & p & 0 & 0 \\
0 & 0 & 1-p & 0 & p & 0 \\
0 & 0 & 0 & 1-p & 0 & p \\
0 & 0 & 0 & 0 & 0 & 1
\end{pmatrix}
$$

Si le cours utilise l'autre convention, avec les colonnes comme etats de depart, il suffit de prendre la transposee de cette matrice.

### 2. Probabilites de suites d'etats avec p = 0,3

Suite `s2, s3, s4, s5, s6` :

Il y a 4 transitions vers la droite.

$$
P = p^4 = 0{,}3^4 = 0{,}0081
$$

Suite `s3, s4, s3, s2, s1` :

Il y a une transition vers la droite, puis 3 transitions vers la gauche.

$$
P = p(1-p)^3
= 0{,}3 \times 0{,}7^3
= 0{,}3 \times 0{,}343
= 0{,}1029
$$

### 3. Formule de la valeur de chaque etat

La valeur d'un etat correspond a la recompense immediate plus la valeur actualisee des etats futurs, ponderee par leurs probabilites.

Pour les etats transitoires `i in {2, 3, 4, 5}` :

$$
V(s_i)
= r_i + \gamma \left[pV(s_{i+1}) + (1-p)V(s_{i-1})\right]
$$

Pour les etats terminaux :

$$
V(s_1) = r_1
\quad \text{et} \quad
V(s_6) = r_6
$$

## 2. Apprentissage par renforcement 2

### 1. Gain a long terme pour la strategie pi1

La strategie `pi1` fait descendre l'agent jusqu'a la ligne 5, puis le rapproche de la colonne F, et enfin le fait remonter vers la case cible `F3`. Les deplacements intermediaires donnent une recompense `-1`, et l'arrivee en `F3` donne `+10`.

Depuis `A1` :

```text
A1 -> A2 -> A3 -> A4 -> A5 -> B5 -> C5 -> D5 -> E5 -> F5 -> F4 -> F3
```

Il y a 11 transitions : 10 pas a `-1`, puis le dernier pas vers `F3` a `+10`.

$$
G(A1)
= -1 - \gamma - \gamma^2 - \cdots - \gamma^9 + 10\gamma^{10}
= -\frac{1-\gamma^{10}}{1-\gamma} + 10\gamma^{10}
$$

Depuis `A5` :

```text
A5 -> B5 -> C5 -> D5 -> E5 -> F5 -> F4 -> F3
```

$$
G(A5)
= -1 - \gamma - \gamma^2 - \cdots - \gamma^5 + 10\gamma^6
= -\frac{1-\gamma^6}{1-\gamma} + 10\gamma^6
$$

Depuis `H1` :

```text
H1 -> H2 -> H3 -> H4 -> H5 -> G5 -> F5 -> F4 -> F3
```

$$
G(H1)
= -1 - \gamma - \gamma^2 - \cdots - \gamma^6 + 10\gamma^7
= -\frac{1-\gamma^7}{1-\gamma} + 10\gamma^7
$$

Depuis `H5` :

```text
H5 -> G5 -> F5 -> F4 -> F3
```

$$
G(H5)
= -1 - \gamma - \gamma^2 + 10\gamma^3
= -\frac{1-\gamma^3}{1-\gamma} + 10\gamma^3
$$

### 2. Argument intuitif de non-optimalite

La strategie `pi1` impose des detours inutiles. Par exemple, depuis `A1`, l'agent descend jusqu'a la ligne 5 puis remonte ensuite vers `F3`. Il pourrait aller plus directement vers la colonne F puis rejoindre `F3`. Un chemin plus court evite des recompenses negatives `-1` et atteint plus vite la recompense `+10`.

### 3. Modification vers une strategie optimale pi2

Pour rendre la strategie optimale, il faut se rapprocher directement de la cible `F3`, en suivant une logique de distance de Manhattan.

- Si l'agent est a gauche de la colonne F, il doit se deplacer vers la droite quand cela rapproche de `F3`.
- S'il est a droite de la colonne F, il doit se deplacer vers la gauche.
- S'il est au-dessus de la ligne 3, il doit descendre.
- S'il est en dessous de la ligne 3, il doit monter.
- Sur la colonne F, il va directement vers `F3`.

### 4. Algorithme permettant de trouver pi2

On peut utiliser l'algorithme `Value Iteration` ou l'algorithme `Policy Iteration`.

### 5. Principe de Value Iteration

L'objectif de Value Iteration est de calculer la fonction de valeur optimale, puis d'en deduire une strategie optimale.

L'algorithme met a jour iterativement la valeur de chaque etat avec l'equation d'optimalite de Bellman :

$$
V_{k+1}(s)
= \max_{a}
\left[
R(s,a)
+ \gamma \sum_{s'} T(s,a,s') V_k(s')
\right]
$$

Quand les valeurs ne changent presque plus, on extrait la strategie optimale en choisissant, pour chaque etat, l'action qui maximise cette expression.

## 3. Deep Learning

### 1. Types de couches dans un CNN

Dans un reseau convolutif de classification d'images, on utilise generalement :

- des couches de convolution `Conv2D` ;
- des couches de pooling, par exemple `MaxPooling2D` ;
- une couche d'aplatissement `Flatten` ;
- des couches totalement connectees `Dense`.

### 2. Couche de sortie

La couche de sortie est une couche totalement connectee `Dense`.

Ses hyperparametres sont :

- nombre de neurones : `nbClasses` ;
- fonction d'activation : `softmax`.

Le nombre de neurones doit etre egal au nombre de classes. La fonction `softmax` permet d'obtenir une distribution de probabilites sur les classes.

### 3. Hyperparametres et nombre de parametres par type de couche

Couche de convolution `Conv2D` :

- hyperparametres : nombre de filtres, taille du noyau, stride, padding, fonction d'activation ;
- nombre de parametres :

$$
N_{\text{param}}
= N_{\text{filtres}}
\times
\left(
W_{\text{noyau}} \times H_{\text{noyau}} \times C_{\text{entree}} + 1
\right)
$$

Couche de pooling `MaxPooling2D` :

- hyperparametres : taille de la fenetre de pooling, stride ;
- nombre de parametres : `0`.

Couche `Flatten` :

- hyperparametres : aucun hyperparametre important ;
- nombre de parametres : `0`.

Couche dense `Dense` :

- hyperparametres : nombre de neurones, fonction d'activation ;
- nombre de parametres :

$$
N_{\text{param}}
= N_{\text{sortie}} \times (N_{\text{entree}} + 1)
$$

### 4. Calcul des parametres du reseau

Pendant l'apprentissage, les images sont propagees vers l'avant dans le reseau afin de produire une prediction. Une fonction de perte mesure l'erreur entre la prediction et la vraie etiquette. La retropropagation du gradient calcule l'influence de chaque poids et biais sur cette erreur. Un optimiseur utilise ces gradients pour ajuster progressivement les parametres. Le but est de minimiser la perte.

### 5. Fonction de perte

La fonction de perte mesure l'ecart entre les predictions du modele et les vraies etiquettes. Elle sert donc de critere a minimiser pendant l'apprentissage.

Pour une classification multi-classes, on utilise l'entropie croisee categorielle, car les classes sont mutuellement exclusives et la sortie est generalement donnee par `softmax`.

### 6. Role du taux d'apprentissage

Le taux d'apprentissage, ou `learning rate`, controle la taille des pas effectues par l'optimiseur lors de la mise a jour des parametres.

- S'il est trop grand, l'apprentissage peut devenir instable ou diverger.
- S'il est trop petit, l'apprentissage devient tres lent.

### 7. Role des epochs et du batch size

Une `epoch` correspond a un passage complet de tout l'ensemble d'apprentissage dans le reseau.

Le `batch size` est le nombre d'images traitees avant une mise a jour des parametres.

### 8. Metrique globale de performance

On peut utiliser l'accuracy :

$$
\text{Accuracy}
=
\frac{\text{nombre de predictions correctes}}
{\text{nombre total d'images evaluees}}
$$

Elle mesure la proportion d'images correctement classees.

### 9. Evaluation par classe

Deux manieres d'evaluer la performance par classe :

- calculer la precision et le rappel pour chaque classe ;
- construire une matrice de confusion pour voir quelles classes sont confondues.

### 10. Probleme mis en evidence par la courbe d'erreur

Si l'erreur d'apprentissage continue de diminuer alors que l'erreur de test stagne ou augmente, la courbe met en evidence un surapprentissage.

Solutions possibles :

- ajouter du dropout ;
- utiliser une regularisation L1 ou L2 ;
- utiliser l'early stopping ;
- augmenter les donnees avec de la data augmentation.

## 4. Optimisation - Recuit simule

### 1. Metaheuristique

Une metaheuristique est une methode generale d'optimisation, souvent stochastique, qui peut s'appliquer a differents problemes difficiles sans garantir forcement la solution exacte optimale.

Elle est utile pour trouver de bonnes solutions approchees en un temps raisonnable, notamment pour des problemes combinatoires ou l'espace de recherche est trop grand pour une recherche exhaustive.

Dans le cas du recuit simule, l'interet principal est de pouvoir echapper aux minima locaux en acceptant temporairement des solutions moins bonnes.
