# Corrige - Exam_IA_GM_FA_2425

## 1. Jeux

### 1. Construction de l'arbre

Il y a 8 feuilles, donc on construit un arbre binaire complet avec :

- racine : Max ;
- niveau 2 : Min ;
- niveau 3 : Max ;
- feuilles : valeurs `2, 3, 5, 9, 0, 1, 7, 5`.

### 2. Signification des feuilles

Les valeurs des feuilles representent l'utilite ou l'evaluation d'une position du point de vue de Max. Une grande valeur est favorable a Max, une petite valeur est favorable a Min. Elles peuvent venir d'un score final ou d'une fonction d'evaluation heuristique.

### 3. Parcours utilise par Minimax

Minimax utilise un parcours en profondeur de l'arbre : on descend jusqu'aux feuilles, puis on remonte les valeurs.

### 4. Application de Minimax

Niveau Max juste au-dessus des feuilles :

$$
\max(2,3)=3,\quad \max(5,9)=9,\quad \max(0,1)=1,\quad \max(7,5)=7
$$

Niveau Min :

$$
\min(3,9)=3,\quad \min(1,7)=1
$$

Racine Max :

$$
\max(3,1)=3
$$

La valeur de la racine est donc **3**. Cela signifie que si les deux joueurs jouent optimalement, Max peut garantir la valeur `3`.

### 5. Principe de l'elagage alpha-beta

Alpha-beta calcule la meme valeur que Minimax, mais evite d'explorer les branches qui ne peuvent plus changer la decision finale.

- `alpha` : meilleure valeur deja garantie pour Max.
- `beta` : meilleure valeur deja garantie pour Min.
- Initialisation : `alpha = -inf`, `beta = +inf`.
- Si `alpha >= beta`, on coupe la branche courante.

### 6. Application alpha-beta

Parcours de gauche a droite.

1. Sous-arbre gauche :
   - premier noeud Max : `max(2,3)=3` ;
   - le noeud Min gauche a donc `beta=3` ;
   - deuxieme noeud Max : on lit d'abord `5`.
   - comme `5 >= beta`, on coupe la feuille `9`.
   - le sous-arbre gauche vaut `3`.

2. Retour a la racine :
   - `alpha=3`.

3. Sous-arbre droit :
   - premier noeud Max : `max(0,1)=1` ;
   - le noeud Min droit a une valeur `1`.
   - comme `1 <= alpha`, on coupe le dernier noeud Max, donc les feuilles `7` et `5`.

La racine vaut toujours :

$$
\max(3,1)=3
$$

### 7. Mesure de l'amelioration

Minimax classique visite les 8 feuilles.

Avec alpha-beta, on visite seulement :

```text
2, 3, 5, 0, 1
```

soit 5 feuilles. Les feuilles coupees sont :

```text
9, 7, 5
```

On a donc coupe 3 feuilles sur 8.

$$
\text{taux de coupe} = \frac{3}{8} = 37{,}5\%
$$

## 2. Apprentissage par renforcement

La grille a 8 colonnes `A` a `H` et 5 lignes. La case cible est `F3`. Les actions menant a `F3` donnent une recompense `10`, toutes les autres donnent `-1`. L'agent s'arrete lorsqu'il arrive en `F3`.

### 1. Gain a long terme pour la strategie pi1

Depuis `A1` :

```text
A1 -> A2 -> A3 -> A4 -> A5 -> B5 -> C5 -> D5 -> E5 -> F5 -> F4 -> F3
```

$$
G(A1)
= -1-\gamma-\gamma^2-\cdots-\gamma^9+10\gamma^{10}
= -\frac{1-\gamma^{10}}{1-\gamma}+10\gamma^{10}
$$

Depuis `A5` :

```text
A5 -> B5 -> C5 -> D5 -> E5 -> F5 -> F4 -> F3
```

$$
G(A5)
= -1-\gamma-\gamma^2-\cdots-\gamma^5+10\gamma^6
= -\frac{1-\gamma^6}{1-\gamma}+10\gamma^6
$$

Depuis `H1` :

```text
H1 -> H2 -> H3 -> H4 -> H5 -> G5 -> F5 -> F4 -> F3
```

$$
G(H1)
= -1-\gamma-\gamma^2-\cdots-\gamma^6+10\gamma^7
= -\frac{1-\gamma^7}{1-\gamma}+10\gamma^7
$$

Depuis `H5` :

```text
H5 -> G5 -> F5 -> F4 -> F3
```

$$
G(H5)
= -1-\gamma-\gamma^2+10\gamma^3
= -\frac{1-\gamma^3}{1-\gamma}+10\gamma^3
$$

### 2. Pourquoi pi1 n'est pas optimale

La strategie `pi1` impose des detours. Par exemple, depuis `A1`, elle descend jusqu'a la ligne 5 puis remonte vers `F3`. Un chemin plus direct vers `F3` utiliserait moins d'actions, donc moins de recompenses `-1`, et atteindrait plus vite la recompense `10`.

### 3. Strategie optimale pi2

Une strategie optimale consiste a se rapprocher de `F3` par un plus court chemin.

Par exemple :

- si la colonne est avant `F`, aller vers la droite ;
- si la colonne est apres `F`, aller vers la gauche ;
- une fois sur la colonne `F`, descendre ou monter vers la ligne 3 ;
- si l'on est deja en `F3`, s'arreter.

Il peut y avoir plusieurs strategies optimales si plusieurs plus courts chemins existent.

### 4. Algorithme permettant de trouver pi2

On peut utiliser `Value Iteration` ou `Policy Iteration`.

### 5. Principe de Value Iteration

Value Iteration calcule progressivement la valeur optimale des etats :

$$
Q(s,a)=R(s,a)+\gamma\sum_{s'}T(s,a,s')V(s')
$$

$$
V(s)=\max_a Q(s,a)
$$

Une fois les valeurs stabilisees, on choisit dans chaque etat l'action qui maximise `Q(s,a)`. Cela donne une strategie optimale.

## 3. Deep Learning

### 1. Types de couches d'un ConvNet

On utilise typiquement :

- des couches de convolution `Conv2D` ;
- des couches de pooling ;
- une couche `Flatten` ;
- des couches denses `Dense`.

### 2. Couche de sortie

La couche de sortie est une couche `Dense`.

Elle contient `nbClasses` neurones, un par classe. Sa fonction d'activation est `softmax`, car on veut obtenir une distribution de probabilites sur les classes.

### 3. Hyperparametres et formules de parametres

Convolution :

- hyperparametres : nombre de filtres, taille du noyau, stride, padding, activation ;
- parametres :

$$
N_{\text{param}}
= N_{\text{filtres}}
\left(W_{\text{noyau}}H_{\text{noyau}}C_{\text{entree}}+1\right)
$$

Pooling :

- hyperparametres : taille de la fenetre, stride, fonction de pooling ;
- parametres : `0`.

Flatten :

- parametres : `0`.

Dense :

- hyperparametres : nombre de neurones, activation ;
- parametres :

$$
N_{\text{param}}=N_{\text{sortie}}(N_{\text{entree}}+1)
$$

### 4. Calcul des parametres

Les parametres sont les poids et les biais du reseau. Ils sont initialises puis ajustes pendant l'apprentissage. Le reseau produit une prediction, la fonction de perte mesure l'erreur, puis la retropropagation calcule les gradients. L'optimiseur met alors a jour les parametres pour reduire la perte.

### 5. Fonction de perte

La fonction de perte mesure l'ecart entre les predictions et les vraies etiquettes. Elle guide donc l'apprentissage.

Pour une classification multi-classes, on utilise l'entropie croisee categorielle, car les classes sont exclusives et la sortie utilise `softmax`.

### 6. Taux d'apprentissage

Le taux d'apprentissage controle la taille des mises a jour des poids.

- Trop grand : risque de divergence.
- Trop petit : apprentissage tres lent.

### 7. Epochs et batch size

Une `epoch` correspond a un passage complet sur l'ensemble d'apprentissage.

Le `batch size` est le nombre d'exemples utilises avant une mise a jour des poids.

### 8. Metrique globale

On peut utiliser l'accuracy :

$$
\text{Accuracy}
=
\frac{\text{nombre de predictions correctes}}
{\text{nombre total d'exemples}}
$$

### 9. Evaluation par classe

On peut utiliser :

- precision et rappel par classe ;
- matrice de confusion.

### 10. Probleme de la figure

La figure met en evidence un surapprentissage si l'erreur d'apprentissage diminue tandis que l'erreur de test augmente ou stagne.

Solutions :

- dropout ;
- regularisation ;
- early stopping ;
- data augmentation ;
- reduire le nombre d'epochs.

## 4. Optimisation - Recuit simule

### 1. Metaheuristique

Une metaheuristique est une methode generale d'optimisation permettant de chercher de bonnes solutions dans un grand espace de recherche, sans garantir necessairement l'optimum exact.

Le recuit simule est une metaheuristique inspiree du refroidissement des metaux. Il accepte parfois des solutions moins bonnes pour eviter de rester bloque dans un minimum local.

### 2. Vocabulaire du recuit simule

- Energie : fonction cout a minimiser.
- Temperature : parametre controlant l'acceptation des mauvaises solutions.
- Refroidissement : diminution progressive de la temperature.
- Perturbation / voisinage : modification locale d'une solution pour obtenir une solution voisine.

### 3. Exploration et exploitation

L'exploration permet de visiter des zones variees de l'espace de recherche. L'exploitation permet d'ameliorer localement une bonne solution. Le recuit simule combine les deux : beaucoup d'exploration au debut, puis de plus en plus d'exploitation lorsque la temperature diminue.

### 4. Critere de Metropolis

Le critere de Metropolis sert a accepter parfois une solution moins bonne.

Si la difference de cout est :

$$
\Delta E = E_{\text{nouveau}} - E_{\text{courant}} > 0
$$

alors la solution est acceptee avec la probabilite :

$$
P = e^{-\Delta E/T}
$$

### 5. Temperature initiale et minimale

Une temperature initiale trop elevee accepte trop de mauvaises solutions ; trop faible, elle bloque l'exploration. Une temperature minimale trop elevee peut empecher la convergence ; trop faible, elle peut allonger inutilement le calcul.
