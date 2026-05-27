# Correction du partiel de Programmation fonctionnelle - Scala

Correction basee sur les deux photos du sujet.

---

## Exercice 1 - Fonctions d'ordre superieur

### Question 1

Enonce :

Ecrire une fonction Scala `composeFG` definie par :

```scala
composeFG(f, g, x, y) = f(g(x, y))
```

avec :

```scala
f: Int => Int
g: (Int, Int) => Int
x, y: Int
```

### Correction

```scala
def composeFG(f: Int => Int, g: (Int, Int) => Int, x: Int, y: Int): Int = {
  f(g(x, y))
}
```

Version courte :

```scala
def composeFG(f: Int => Int, g: (Int, Int) => Int, x: Int, y: Int): Int =
  f(g(x, y))
```

### Explication

On commence par appliquer `g` a `x` et `y` :

```scala
g(x, y)
```

Comme `g` retourne un `Int`, on peut ensuite appliquer `f` au resultat :

```scala
f(g(x, y))
```

Exemple :

```scala
val f = (a: Int) => a * 2
val g = (x: Int, y: Int) => x + y

composeFG(f, g, 3, 4)
```

Calcul :

```text
g(3, 4) = 7
f(7) = 14
```

Resultat :

```text
14
```

---

## Question 2

Enonce :

Donner la complexite temporelle et la complexite spatiale de `composeFG`.

### Correction

Si on note :

```text
Tf = complexite temporelle de f
Tg = complexite temporelle de g
Sf = complexite spatiale de f
Sg = complexite spatiale de g
```

Alors :

```text
Complexite temporelle : O(Tg + Tf)
Complexite spatiale : O(Sg + Sf)
```

Si `f` et `g` sont des fonctions simples en temps constant :

```text
Complexite temporelle : O(1)
Complexite spatiale : O(1)
```

### Explication

La fonction fait seulement deux appels :

```scala
g(x, y)
f(...)
```

Elle ne contient :

- ni boucle ;
- ni recursion ;
- ni creation de collection proportionnelle a `n`.

Donc si `f` et `g` sont en `O(1)`, toute la fonction est en `O(1)`.

---

## Question 3

Enonce :

Est-ce que `composeFG` est une fonction pure ? Justifier.

### Correction

```text
composeFG est pure si les fonctions f et g passees en parametre sont elles-memes pures.
```

Justification :

```text
composeFG ne fait qu'appliquer g puis f. Elle ne modifie aucun etat, ne fait pas d'affichage, ne lit pas de fichier et ne produit pas directement d'effet de bord. Cependant, si f ou g a un effet de bord, alors composeFG aura aussi un effet de bord.
```

### Exemple pur

```scala
val f = (x: Int) => x + 1
val g = (x: Int, y: Int) => x + y
```

Ici, `composeFG(f, g, x, y)` est pure.

### Exemple non pur

```scala
val f = (x: Int) => {
  println(x)
  x + 1
}

val g = (x: Int, y: Int) => x + y
```

Ici, `composeFG(f, g, x, y)` n'est pas pure car `f` fait un `println`, donc un effet de bord.

---

## Question 4

Enonce :

Modifier `composeFG` pour appliquer `f` un nombre variable `n >= 2` de fois.

Exemples attendus :

```scala
f(f(f(g(x, y)))) // 3 fois
f(f(g(x, y)))    // 2 fois
```

Il faut utiliser `foldRight` pour combiner les applications et donner un exemple d'appel.

### Correction avec foldRight

```scala
def composeFG(
  f: Int => Int,
  g: (Int, Int) => Int,
  x: Int,
  y: Int,
  n: Int
): Int = {
  require(n >= 2)

  List.fill(n)(f).foldRight(g(x, y)) {
    (fonction, acc) => fonction(acc)
  }
}
```

### Exemple d'appel

```scala
val f = (a: Int) => a + 1
val g = (x: Int, y: Int) => x * y

composeFG(f, g, 2, 3, 3)
```

Calcul :

```text
g(2, 3) = 6
f(f(f(6))) = 9
```

Resultat :

```text
9
```

### Explication

```scala
List.fill(n)(f)
```

cree une liste contenant `n` fois la fonction `f`.

Pour `n = 3` :

```scala
List(f, f, f)
```

Puis :

```scala
foldRight(g(x, y))(...)
```

part de la valeur initiale `g(x, y)` et applique les fonctions.

### Variante acceptable avec foldLeft

Le sujet demandait `foldRight`, donc il vaut mieux donner la version precedente. Mais cette version est aussi correcte fonctionnellement :

```scala
def composeFG(
  f: Int => Int,
  g: (Int, Int) => Int,
  x: Int,
  y: Int,
  n: Int
): Int = {
  require(n >= 2)

  (1 to n).foldLeft(g(x, y)) {
    (acc, _) => f(acc)
  }
}
```

---

## Exercice 2 - waysToClimb

Code donne dans le sujet :

```scala
def waysToClimb(n: Int): Int = {
  if (n < 0) 0
  else if (n == 0) 1

  val dp = Array.ofDim[Int](n + 1)
  dp(0) = 1
  dp(1) = 1

  for (i <- 2 to n) {
    dp(i) = dp(i - 1) + dp(i - 2)
  }

  dp(n)
}
```

### Remarque importante sur le code du sujet

Tel qu'il est ecrit sur la photo, le code contient probablement une erreur Scala :

```scala
if (n < 0) 0
else if (n == 0) 1
```

ne stoppe pas la fonction. Comme il n'y a pas de `return` ni de `else` englobant la suite, le programme continue avec :

```scala
val dp = Array.ofDim[Int](n + 1)
```

Donc pour `n < 0`, cela peut provoquer une erreur, car on tente de creer un tableau de taille negative.

La version correcte est :

```scala
def waysToClimb(n: Int): Int = {
  if (n < 0) 0
  else if (n == 0) 1
  else {
    val dp = Array.ofDim[Int](n + 1)
    dp(0) = 1
    dp(1) = 1

    for (i <- 2 to n) {
      dp(i) = dp(i - 1) + dp(i - 2)
    }

    dp(n)
  }
}
```

Pour la correction des questions, on suppose que c'est cette intention qui est demandee.

---

## Question 1

Enonce :

Que fait la fonction `waysToClimb` ?

### Correction

```text
La fonction waysToClimb calcule le nombre de facons de monter un escalier de n marches en faisant a chaque fois un pas de 1 marche ou de 2 marches.
```

### Explication

Pour atteindre la marche `n`, on peut venir :

- de la marche `n - 1` avec un pas de 1 ;
- de la marche `n - 2` avec un pas de 2.

Donc :

```text
waysToClimb(n) = waysToClimb(n - 1) + waysToClimb(n - 2)
```

C'est une variante de la suite de Fibonacci.

Exemples :

```text
waysToClimb(0) = 1
waysToClimb(1) = 1
waysToClimb(2) = 2
waysToClimb(3) = 3
waysToClimb(4) = 5
```

---

## Question 2

Enonce :

Donner la valeur de `waysToClimb(10)`.

### Correction

Valeurs successives :

```text
waysToClimb(0) = 1
waysToClimb(1) = 1
waysToClimb(2) = 2
waysToClimb(3) = 3
waysToClimb(4) = 5
waysToClimb(5) = 8
waysToClimb(6) = 13
waysToClimb(7) = 21
waysToClimb(8) = 34
waysToClimb(9) = 55
waysToClimb(10) = 89
```

Reponse :

```text
waysToClimb(10) = 89
```

---

## Question 3

Enonce :

Quelle est la complexite temporelle de `waysToClimb` ? Et sa complexite spatiale ?

### Correction

```text
Complexite temporelle : O(n)
Complexite spatiale : O(n)
```

### Explication temporelle

La fonction contient une boucle :

```scala
for (i <- 2 to n)
```

Cette boucle effectue environ `n` iterations.

Chaque iteration fait un nombre constant d'operations :

```scala
dp(i) = dp(i - 1) + dp(i - 2)
```

Donc :

```text
Temps : O(n)
```

### Explication spatiale

La fonction cree un tableau :

```scala
val dp = Array.ofDim[Int](n + 1)
```

Ce tableau contient `n + 1` entiers.

Donc :

```text
Espace : O(n)
```

---

## Question 4

Enonce :

La fonction est-elle pure ? Sinon, proposer une version pure.

### Correction

```text
En programmation fonctionnelle stricte, cette fonction n'est pas pure car elle utilise un tableau mutable Array et modifie ses cases avec dp(i) = ...
```

Le probleme vient de :

```scala
dp(0) = 1
dp(1) = 1
dp(i) = dp(i - 1) + dp(i - 2)
```

Ces instructions modifient le contenu du tableau.

### Version pure avec recursion terminale

```scala
import scala.annotation.tailrec

def waysToClimbPure(n: Int): Int = {
  @tailrec
  def loop(i: Int, prev: Int, curr: Int): Int = {
    if (i == n) curr
    else loop(i + 1, curr, prev + curr)
  }

  if (n < 0) 0
  else if (n == 0) 1
  else loop(1, 1, 1)
}
```

### Explication

On ne modifie pas de tableau.

On garde seulement deux valeurs :

```text
prev = valeur precedente
curr = valeur courante
```

A chaque appel recursif :

```text
(prev, curr) devient (curr, prev + curr)
```

Complexite :

```text
Temps : O(n)
Espace : O(1), si la recursion terminale est optimisee
```

### Version pure avec foldLeft

```scala
def waysToClimbPure(n: Int): Int = {
  if (n < 0) 0
  else if (n == 0) 1
  else {
    val (_, result) = (2 to n).foldLeft((1, 1)) {
      case ((prev, curr), _) => (curr, prev + curr)
    }

    result
  }
}
```

Cette version est tres adaptee a un partiel de programmation fonctionnelle car elle remplace la boucle et le tableau mutable par un accumulateur immutable.

---

## Question 5

Enonce :

Quel est l'interet des fonctions pures pour un serveur comme Spark ?

### Correction

```text
Les fonctions pures sont interessantes pour Spark car Spark execute les calculs de maniere distribuee et parallele. Une fonction pure ne depend que de ses entrees et ne produit pas d'effet de bord. Elle peut donc etre executee plusieurs fois, sur plusieurs machines, ou relancee apres un echec sans modifier un etat externe ni produire de resultat imprevisible.
```

### Points importants a citer

- parallelisation plus simple ;
- resultats reproductibles ;
- pas d'etat partage modifie ;
- meilleure tolerance aux pannes ;
- facilite les tests ;
- facilite l'optimisation des calculs.

### Reponse courte possible en copie

```text
Dans Spark, les fonctions pures permettent des traitements paralleles et reproductibles, car elles ne dependent que de leurs entrees et ne modifient pas d'etat externe.
```

---

## Recapitulatif des reponses rapides

### Exercice 1

```scala
def composeFG(f: Int => Int, g: (Int, Int) => Int, x: Int, y: Int): Int =
  f(g(x, y))
```

Complexite :

```text
O(Tf + Tg), donc O(1) si f et g sont O(1).
Espace : O(Sf + Sg), donc O(1) si f et g utilisent une memoire constante.
```

Purete :

```text
Pure si f et g sont pures.
```

Application de `f` `n` fois :

```scala
def composeFG(
  f: Int => Int,
  g: (Int, Int) => Int,
  x: Int,
  y: Int,
  n: Int
): Int = {
  require(n >= 2)

  List.fill(n)(f).foldRight(g(x, y)) {
    (fonction, acc) => fonction(acc)
  }
}
```

### Exercice 2

Ce que fait `waysToClimb` :

```text
Elle calcule le nombre de facons de monter n marches avec des pas de 1 ou 2 marches.
```

Valeur :

```text
waysToClimb(10) = 89
```

Complexite :

```text
Temps : O(n)
Espace : O(n)
```

Purete :

```text
Pas pure en style fonctionnel strict car elle modifie un Array.
```

Version pure :

```scala
def waysToClimbPure(n: Int): Int = {
  if (n < 0) 0
  else if (n == 0) 1
  else {
    val (_, result) = (2 to n).foldLeft((1, 1)) {
      case ((prev, curr), _) => (curr, prev + curr)
    }

    result
  }
}
```

Interet Spark :

```text
Les fonctions pures sont reproductibles, parallelisables et sans effet de bord, ce qui convient aux traitements distribues de Spark.
```

---

## Phrases pretes a recracher

### Fonction pure

```text
Une fonction pure retourne toujours le meme resultat pour les memes arguments et ne produit aucun effet de bord.
```

### Effet de bord

```text
Un effet de bord est une modification d'etat ou une interaction avec l'exterieur, comme modifier une variable, afficher avec println, lire un fichier ou modifier un tableau.
```

### Complexite temporelle

```text
La complexite temporelle mesure le nombre d'operations en fonction de la taille de l'entree.
```

### Complexite spatiale

```text
La complexite spatiale mesure la memoire supplementaire utilisee par l'algorithme.
```

### Programmation fonctionnelle

```text
La programmation fonctionnelle privilegie les fonctions pures, l'immutabilite, les expressions et les transformations de donnees plutot que la mutation d'etat.
```

