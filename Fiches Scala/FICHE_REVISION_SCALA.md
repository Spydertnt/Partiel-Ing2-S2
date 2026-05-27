# Fiche de revision Scala - Programmation fonctionnelle

## Objectif du partiel

Le partiel semble viser surtout :

- la syntaxe Scala de base ;
- les fonctions en parametre ;
- les fonctions pures ;
- les fonctions d'ordre superieur ;
- `map`, `filter`, `foldLeft`, `foldRight` ;
- la recursion ;
- les collections ;
- les complexites temporelles et spatiales ;
- la difference entre style imperatif et style fonctionnel.

---

## 1. Bases de Scala

### Declaration de valeurs

```scala
val x = 10
```

`val` signifie valeur non reassigneable.

```scala
x = 12 // interdit
```

A retenir :

- utiliser `val` par defaut ;
- c'est le style recommande en programmation fonctionnelle ;
- une valeur immuable rend le code plus simple a raisonner.

### Declaration de variables

```scala
var x = 10
x = 12
```

`var` signifie variable reassigneable.

A retenir :

- eviter `var` en programmation fonctionnelle ;
- `var` introduit de la mutation ;
- mutation = code plus difficile a tester et a paralleliser.

### Types de base

```scala
val a: Int = 5
val b: Double = 3.14
val c: Boolean = true
val d: String = "scala"
val e: Char = 'x'
```

Scala peut souvent inferer les types :

```scala
val a = 5        // Int
val d = "scala" // String
```

Mais en partiel, il vaut mieux ecrire les types dans les signatures de fonctions.

---

## 2. Fonctions

### Fonction simple

```scala
def carre(x: Int): Int = {
  x * x
}
```

Equivalent court :

```scala
def carre(x: Int): Int = x * x
```

Structure :

```scala
def nom(parametre: Type): TypeRetour = expression
```

### Fonction avec plusieurs parametres

```scala
def somme(a: Int, b: Int): Int = a + b
```

### Fonction sans parametre

```scala
def hello(): String = "Bonjour"
```

### Retour implicite

En Scala, la derniere expression est retournee.

```scala
def max(a: Int, b: Int): Int = {
  if (a > b) a
  else b
}
```

Pas besoin d'ecrire `return`.

A retenir :

- `return` est rarement utilise en Scala ;
- on prefere retourner la derniere expression.

---

## 3. Conditions

### if / else

```scala
def abs(x: Int): Int = {
  if (x < 0) -x
  else x
}
```

En Scala, `if` est une expression : il produit une valeur.

```scala
val resultat = if (x >= 10) "grand" else "petit"
```

Attention :

```scala
def f(n: Int): Int = {
  if (n < 0) 0
  val x = n + 1
  x
}
```

Ici, le `if` ne stoppe pas la fonction. La fonction continue apres le `if`.

Version correcte :

```scala
def f(n: Int): Int = {
  if (n < 0) 0
  else {
    val x = n + 1
    x
  }
}
```

---

## 4. Fonctions anonymes et lambdas

Une fonction anonyme est une fonction sans nom.

```scala
val double = (x: Int) => x * 2
```

Type :

```scala
Int => Int
```

Exemples :

```scala
val increment = (x: Int) => x + 1
val somme = (x: Int, y: Int) => x + y
val estPair = (x: Int) => x % 2 == 0
```

Types :

```scala
val increment: Int => Int = (x: Int) => x + 1
val somme: (Int, Int) => Int = (x: Int, y: Int) => x + y
val estPair: Int => Boolean = (x: Int) => x % 2 == 0
```

---

## 5. Fonctions d'ordre superieur

Une fonction d'ordre superieur est une fonction qui :

- prend une fonction en parametre ;
- ou retourne une fonction.

### Fonction qui prend une fonction en parametre

```scala
def appliquer(f: Int => Int, x: Int): Int = {
  f(x)
}
```

Exemple :

```scala
val double = (x: Int) => x * 2

appliquer(double, 5) // 10
```

### Fonction qui applique deux fois

```scala
def appliquerDeuxFois(f: Int => Int, x: Int): Int = {
  f(f(x))
}
```

Exemple :

```scala
val plusUn = (x: Int) => x + 1

appliquerDeuxFois(plusUn, 10) // 12
```

---

## 6. Composition de fonctions

Composer deux fonctions signifie appliquer l'une apres l'autre.

Si :

```scala
f: Int => Int
g: (Int, Int) => Int
```

Alors :

```scala
f(g(x, y))
```

### Exemple type partiel

```scala
def composeFG(f: Int => Int, g: (Int, Int) => Int, x: Int, y: Int): Int = {
  f(g(x, y))
}
```

Exemple d'appel :

```scala
val f = (a: Int) => a * 2
val g = (x: Int, y: Int) => x + y

composeFG(f, g, 3, 4) // f(g(3, 4)) = f(7) = 14
```

Complexite :

```text
Temps : O(Tf + Tg)
Espace : O(Sf + Sg)
```

Si `f` et `g` sont en temps constant :

```text
Temps : O(1)
Espace : O(1)
```

Purete :

```text
composeFG est pure si f et g sont pures.
```

---

## 7. Fonction pure

Une fonction pure respecte deux regles :

1. Pour les memes entrees, elle retourne toujours le meme resultat.
2. Elle n'a pas d'effet de bord.

### Exemple pur

```scala
def carre(x: Int): Int = x * x
```

Meme entree :

```scala
carre(4) // toujours 16
```

### Exemple non pur

```scala
var compteur = 0

def incrementer(): Int = {
  compteur = compteur + 1
  compteur
}
```

Pourquoi non pur ?

- modifie une variable externe ;
- depend de l'etat du programme ;
- deux appels successifs ne donnent pas forcement la meme chose.

### Effets de bord classiques

```scala
println("test")
readLine()
array(i) = 10
var x = x + 1
ecrire dans un fichier
lire une base de donnees
faire une requete reseau
utiliser une valeur aleatoire
utiliser l'heure actuelle
```

### Interet des fonctions pures

Les fonctions pures sont importantes car elles sont :

- plus faciles a tester ;
- plus faciles a comprendre ;
- plus faciles a paralleliser ;
- plus fiables dans des systemes distribues ;
- interessantes pour Spark car une meme transformation peut etre relancee sur plusieurs machines sans surprise.

Phrase type pour Spark :

```text
Dans Spark, les fonctions pures sont utiles car les calculs sont distribues, rejoues et parallelises. Si une fonction ne depend que de ses entrees et ne modifie pas d'etat externe, Spark peut l'executer sur plusieurs noeuds sans effets de bord imprevisibles.
```

---

## 8. Collections principales

### List

```scala
val xs = List(1, 2, 3)
```

`List` est immuable.

Operations :

```scala
xs.head // 1
xs.tail // List(2, 3)
xs.isEmpty // false
```

Ajouter en tete :

```scala
val ys = 0 :: xs // List(0, 1, 2, 3)
```

Concatener :

```scala
List(1, 2) ++ List(3, 4) // List(1, 2, 3, 4)
```

Complexites utiles :

```text
head : O(1)
tail : O(1)
ajout en tete avec :: : O(1)
acces a l'indice i : O(n)
concatener deux listes : O(n) avec n taille de la premiere liste
```

### Array

```scala
val tab = Array(1, 2, 3)
```

Acces :

```scala
tab(0) // 1
```

Modification :

```scala
tab(0) = 10
```

Attention :

```text
Array est mutable.
```

Complexites :

```text
acces par indice : O(1)
modification par indice : O(1)
parcours complet : O(n)
```

### Tuple

```scala
val couple = (1, "scala")
```

Acces :

```scala
couple._1 // 1
couple._2 // "scala"
```

Utile avec `foldLeft` :

```scala
val etat = (precedent, courant)
```

---

## 9. map, filter, reduce, fold

Ces fonctions sont centrales en programmation fonctionnelle.

### map

`map` transforme chaque element.

```scala
List(1, 2, 3).map(x => x * 2)
// List(2, 4, 6)
```

Type mental :

```text
List[A] + fonction A => B donne List[B]
```

Exemples :

```scala
List("a", "bb", "ccc").map(s => s.length)
// List(1, 2, 3)
```

Complexite :

```text
Temps : O(n)
Espace : O(n)
```

### filter

`filter` garde les elements qui verifient une condition.

```scala
List(1, 2, 3, 4).filter(x => x % 2 == 0)
// List(2, 4)
```

Type mental :

```text
List[A] + fonction A => Boolean donne List[A]
```

Complexite :

```text
Temps : O(n)
Espace : O(n) dans le pire cas
```

### reduce

`reduce` combine les elements d'une collection non vide.

```scala
List(1, 2, 3, 4).reduce((a, b) => a + b)
// 10
```

Attention :

```scala
List[Int]().reduce((a, b) => a + b) // erreur
```

Car `reduce` ne sait pas quoi faire sur une liste vide.

### foldLeft

`foldLeft` parcourt de gauche a droite avec un accumulateur initial.

```scala
List(1, 2, 3, 4).foldLeft(0)((acc, x) => acc + x)
// 10
```

Schema :

```scala
collection.foldLeft(valeurInitiale)((accumulateur, element) => nouvelAccumulateur)
```

Exemple produit :

```scala
List(1, 2, 3, 4).foldLeft(1)((acc, x) => acc * x)
// 24
```

Exemple compter les pairs :

```scala
List(1, 2, 3, 4).foldLeft(0) {
  (acc, x) =>
    if (x % 2 == 0) acc + 1
    else acc
}
// 2
```

Complexite :

```text
Temps : O(n)
Espace : O(1) hors resultat, si l'accumulateur est de taille constante
```

### foldRight

`foldRight` parcourt de droite a gauche.

```scala
List(1, 2, 3).foldRight(0)((x, acc) => x + acc)
// 6
```

Schema :

```scala
collection.foldRight(valeurInitiale)((element, accumulateur) => nouvelAccumulateur)
```

Difference importante :

```scala
List(1, 2, 3).foldLeft("")((acc, x) => acc + x)
// "123"

List(1, 2, 3).foldRight("")((x, acc) => acc + x)
// "321"
```

### Quand utiliser quoi ?

```text
map       : transformer chaque element
filter    : garder certains elements
reduce    : combiner une collection non vide
foldLeft  : construire un resultat avec accumulateur
foldRight : utile pour composer depuis la droite ou reconstruire des listes
```

---

## 10. Recursion

La recursion consiste a definir une fonction qui s'appelle elle-meme.

### Factorielle

```scala
def fact(n: Int): Int = {
  if (n <= 1) 1
  else n * fact(n - 1)
}
```

Exemple :

```scala
fact(5) = 5 * 4 * 3 * 2 * 1 = 120
```

Complexite :

```text
Temps : O(n)
Espace : O(n) a cause de la pile d'appels
```

### Recursion terminale

Une recursion est terminale si l'appel recursif est la derniere operation.

```scala
import scala.annotation.tailrec

def fact(n: Int): Int = {
  @tailrec
  def loop(i: Int, acc: Int): Int = {
    if (i <= 1) acc
    else loop(i - 1, acc * i)
  }

  loop(n, 1)
}
```

Avantage :

```text
La recursion terminale peut etre optimisee en boucle par le compilateur.
```

Complexite :

```text
Temps : O(n)
Espace : O(1) si optimisation tail-recursive
```

---

## 11. Pattern matching

Le pattern matching est une forme puissante de `switch`.

```scala
def signe(x: Int): String = x match {
  case 0 => "nul"
  case n if n > 0 => "positif"
  case _ => "negatif"
}
```

`_` signifie "tout le reste".

### Pattern matching sur les listes

```scala
def somme(xs: List[Int]): Int = xs match {
  case Nil => 0
  case head :: tail => head + somme(tail)
}
```

Explication :

```text
Nil          : liste vide
head :: tail : premier element + reste de la liste
```

Version tail-recursive :

```scala
import scala.annotation.tailrec

def somme(xs: List[Int]): Int = {
  @tailrec
  def loop(rest: List[Int], acc: Int): Int = rest match {
    case Nil => acc
    case head :: tail => loop(tail, acc + head)
  }

  loop(xs, 0)
}
```

---

## 12. Option

`Option[A]` represente une valeur qui peut exister ou non.

Deux cas :

```scala
Some(valeur)
None
```

Exemple :

```scala
def inverse(x: Int): Option[Double] = {
  if (x == 0) None
  else Some(1.0 / x)
}
```

Utilisation :

```scala
inverse(2) match {
  case Some(v) => v
  case None => 0.0
}
```

Interet :

```text
Eviter les null et les erreurs de type NullPointerException.
```

---

## 13. Complexite

### Notation O

La notation `O(...)` decrit l'evolution du cout quand la taille de l'entree grandit.

Exemples :

```text
O(1)      : constant
O(log n)  : logarithmique
O(n)      : lineaire
O(n log n): quasi-lineaire
O(n^2)    : quadratique
O(2^n)    : exponentiel
```

### O(1)

```scala
def premier(tab: Array[Int]): Int = tab(0)
```

On accede directement a un element.

```text
Temps : O(1)
Espace : O(1)
```

### O(n)

```scala
def somme(xs: List[Int]): Int = {
  xs.foldLeft(0)((acc, x) => acc + x)
}
```

On parcourt toute la liste.

```text
Temps : O(n)
Espace : O(1)
```

### O(n^2)

```scala
for (i <- 0 until n) {
  for (j <- 0 until n) {
    println(i + j)
  }
}
```

Deux boucles imbriquees de taille `n`.

```text
Temps : O(n^2)
```

### Complexite spatiale

La complexite spatiale mesure la memoire supplementaire utilisee.

Exemple :

```scala
val dp = Array.ofDim[Int](n + 1)
```

Ici :

```text
Espace : O(n)
```

Si on garde seulement deux entiers :

```scala
val a = 1
val b = 1
```

Alors :

```text
Espace : O(1)
```

---

## 14. Exercice type : waysToClimb

### Enonce

On veut compter le nombre de facons de monter `n` marches en faisant des pas de 1 ou 2 marches.

Exemples :

```text
n = 0 : 1 facon
n = 1 : 1 facon
n = 2 : 2 facons
  - 1 + 1
  - 2
n = 3 : 3 facons
  - 1 + 1 + 1
  - 1 + 2
  - 2 + 1
```

Relation :

```text
waysToClimb(n) = waysToClimb(n - 1) + waysToClimb(n - 2)
```

Pourquoi ?

- pour arriver sur la marche `n`, on vient soit de `n - 1` avec un pas de 1 ;
- soit de `n - 2` avec un pas de 2.

### Version imperativo-dynamique

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

Valeurs :

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

Complexite :

```text
Temps : O(n)
Espace : O(n)
```

Purete :

```text
Cette version utilise Array et modifie dp(i), donc elle est imperative.
En programmation fonctionnelle stricte, on ne la considere pas comme pure.
```

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

Complexite :

```text
Temps : O(n)
Espace : O(1)
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

Explication de l'accumulateur :

```text
(prev, curr) represente deux valeurs consecutives.
A chaque tour, on avance :
(prev, curr) devient (curr, prev + curr)
```

---

## 15. Exercice type : appliquer f n fois

### Objectif

On a :

```scala
f: Int => Int
g: (Int, Int) => Int
x: Int
y: Int
n: Int
```

On veut calculer :

```scala
f(f(...f(g(x, y))...))
```

avec `f` appliquee `n` fois.

### Version avec foldRight

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

Exemple :

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

### Version avec foldLeft

```scala
def applyNTimes(f: Int => Int, x: Int, n: Int): Int = {
  (1 to n).foldLeft(x)((acc, _) => f(acc))
}
```

Exemple :

```scala
applyNTimes((x: Int) => x + 1, 10, 3)
// 13
```

---

## 16. Style imperatif vs style fonctionnel

### Style imperatif

```scala
var somme = 0

for (x <- List(1, 2, 3)) {
  somme = somme + x
}
```

Caracteristiques :

- utilise `var` ;
- modifie un etat ;
- utilise souvent des boucles.

### Style fonctionnel

```scala
val somme = List(1, 2, 3).foldLeft(0)((acc, x) => acc + x)
```

Caracteristiques :

- utilise `val` ;
- evite la mutation ;
- combine des fonctions ;
- plus declaratif.

---

## 17. Erreurs frequentes en partiel

### Oublier le else

Mauvais :

```scala
def f(n: Int): Int = {
  if (n < 0) 0
  val x = n + 1
  x
}
```

Bon :

```scala
def f(n: Int): Int = {
  if (n < 0) 0
  else {
    val x = n + 1
    x
  }
}
```

### Confondre fonction et appel de fonction

Fonction :

```scala
val f = (x: Int) => x + 1
```

Appel :

```scala
f(3)
```

### Se tromper dans les types

```scala
f: Int => Int
g: (Int, Int) => Int
```

Donc :

```scala
g(x, y) // Int
f(g(x, y)) // Int
```

### Dire qu'une fonction est pure juste parce qu'elle retourne un Int

Le type de retour ne suffit pas.

Exemple non pur :

```scala
def f(x: Int): Int = {
  println(x)
  x + 1
}
```

Elle retourne un `Int`, mais elle fait un affichage, donc elle a un effet de bord.

### Confondre complexite temporelle et spatiale

```scala
for (i <- 0 until n) {
  println(i)
}
```

```text
Temps : O(n)
Espace : O(1)
```

```scala
val tab = Array.ofDim[Int](n)
```

```text
Espace : O(n)
```

---

## 18. Reponses types a apprendre

### Qu'est-ce qu'une fonction pure ?

```text
Une fonction pure est une fonction qui retourne toujours le meme resultat pour les memes arguments et qui ne produit aucun effet de bord.
```

### Qu'est-ce qu'un effet de bord ?

```text
Un effet de bord est une interaction avec l'exterieur ou une modification d'etat observable, par exemple modifier une variable, afficher avec println, lire un fichier ou modifier un tableau.
```

### Qu'est-ce qu'une fonction d'ordre superieur ?

```text
Une fonction d'ordre superieur est une fonction qui prend une fonction en parametre ou qui retourne une fonction.
```

### Interet des fonctions pures pour Spark

```text
Spark execute des traitements en parallele sur plusieurs machines. Les fonctions pures sont interessantes car elles ne dependent que de leurs entrees et n'ont pas d'effet de bord, ce qui rend les calculs reproductibles, parallelisables et plus faciles a relancer en cas d'echec.
```

### Complexite de map

```text
map applique une fonction a chaque element d'une collection de taille n. Sa complexite temporelle est O(n). Sa complexite spatiale est O(n) car elle construit une nouvelle collection.
```

### Complexite de filter

```text
filter teste chaque element d'une collection de taille n. Sa complexite temporelle est O(n). Sa complexite spatiale est O(n) dans le pire cas si tous les elements sont conserves.
```

### Complexite de foldLeft

```text
foldLeft parcourt toute la collection une seule fois. Sa complexite temporelle est O(n). Sa complexite spatiale depend de l'accumulateur, souvent O(1) si l'accumulateur est de taille constante.
```

---

## 19. Mini annales inspirees du sujet

### Question 1

Ecrire une fonction qui compose `f` et `g` :

```scala
def composeFG(f: Int => Int, g: (Int, Int) => Int, x: Int, y: Int): Int = {
  f(g(x, y))
}
```

### Question 2

Donner la complexite de `composeFG`.

Reponse :

```text
La complexite temporelle est O(Tf + Tg). Si f et g sont en O(1), alors la complexite est O(1).
La complexite spatiale est O(Sf + Sg). Si f et g utilisent une memoire constante, alors O(1).
```

### Question 3

Est-ce que `composeFG` est pure ?

Reponse :

```text
composeFG est pure si les fonctions f et g donnees en parametre sont elles-memes pures. Si f ou g produit un effet de bord, alors composeFG n'est pas pure.
```

### Question 4

Modifier `composeFG` pour appliquer `f` `n` fois.

```scala
def composeFG(
  f: Int => Int,
  g: (Int, Int) => Int,
  x: Int,
  y: Int,
  n: Int
): Int = {
  List.fill(n)(f).foldLeft(g(x, y))((acc, fonction) => fonction(acc))
}
```

Exemple :

```scala
val f = (a: Int) => a + 1
val g = (x: Int, y: Int) => x + y

composeFG(f, g, 2, 3, 3)
// g(2, 3) = 5
// f(f(f(5))) = 8
```

### Question 5

Que fait `waysToClimb` ?

```text
Elle calcule le nombre de facons de monter un escalier de n marches en faisant des pas de 1 ou 2 marches.
```

### Question 6

Valeur de `waysToClimb(10)` :

```text
89
```

### Question 7

Complexite de `waysToClimb` avec tableau `dp` :

```text
Temps : O(n)
Espace : O(n)
```

### Question 8

Version plus fonctionnelle de `waysToClimb` :

```scala
def waysToClimb(n: Int): Int = {
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

---

## 20. Checklist avant le partiel

Savoir faire sans regarder :

- ecrire une fonction Scala avec types ;
- ecrire une lambda ;
- lire un type comme `Int => Int` ;
- lire un type comme `(Int, Int) => Int` ;
- utiliser une fonction en parametre ;
- expliquer une fonction pure ;
- reperer un effet de bord ;
- calculer une complexite simple ;
- utiliser `map` ;
- utiliser `filter` ;
- utiliser `foldLeft` ;
- utiliser `foldRight` ;
- faire une recursion simple ;
- transformer une boucle en `foldLeft` ;
- expliquer `waysToClimb` ;
- reconnaitre Fibonacci ;
- distinguer `Array` mutable et `List` immuable.

---

## 21. Formules mentales rapides

```text
map       = je transforme
filter    = je garde ou je jette
foldLeft  = j'accumule de gauche a droite
foldRight = j'accumule de droite a gauche
pure      = meme entree, meme sortie, pas d'effet de bord
O(n)      = je parcours n elements
O(n^2)    = double boucle imbriquee
O(1)      = cout constant
```

---

## 22. Dernier entrainement express

### Somme d'une liste

```scala
def somme(xs: List[Int]): Int = {
  xs.foldLeft(0)((acc, x) => acc + x)
}
```

### Doubler les elements

```scala
def doubler(xs: List[Int]): List[Int] = {
  xs.map(x => x * 2)
}
```

### Garder les pairs

```scala
def pairs(xs: List[Int]): List[Int] = {
  xs.filter(x => x % 2 == 0)
}
```

### Compter les pairs

```scala
def compterPairs(xs: List[Int]): Int = {
  xs.foldLeft(0) {
    (acc, x) =>
      if (x % 2 == 0) acc + 1
      else acc
  }
}
```

### Maximum d'une liste non vide

```scala
def maximum(xs: List[Int]): Int = {
  xs.reduce((a, b) => if (a > b) a else b)
}
```

### Appliquer une fonction n fois

```scala
def applyNTimes(f: Int => Int, x: Int, n: Int): Int = {
  (1 to n).foldLeft(x)((acc, _) => f(acc))
}
```

---

## 23. Reponse courte parfaite pour la copie

Si tu bloques, ecris proprement :

```text
Cette fonction parcourt les n elements une seule fois, donc sa complexite temporelle est O(n).
Elle cree une structure de taille n, donc sa complexite spatiale est O(n).
```

Ou :

```text
Cette fonction est pure si elle ne depend que de ses parametres et ne modifie aucun etat externe. Elle ne doit pas faire d'affichage, de mutation, de lecture ou d'ecriture externe.
```

Ou :

```text
On utilise foldLeft avec un accumulateur pour remplacer une boucle imperative par une expression fonctionnelle.
```

