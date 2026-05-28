# Correction expliquee - Sujet C++ Point / PointCol / PointForme

## Idee generale de l'exercice

On part de deux classes deja connues :

- `Point` : contient les coordonnees `x` et `y`.
- `PointCol` : est un `Point` avec une couleur en plus.

On ajoute :

- `PointForme` : est un `Point` avec une forme en plus, par exemple `'.'`, `'*'`, `'o'`.
- `PointFormeCol` : est a la fois un `PointForme` et un `PointCol`, donc un point avec une forme et une couleur.

Comme `PointFormeCol` herite a la fois de `PointCol` et de `PointForme`, et que ces deux classes heritent de `Point`, on a un heritage en losange.

Pour eviter d'avoir deux sous-objets `Point` dans `PointFormeCol`, on utilise l'heritage virtuel :

```cpp
class PointCol : virtual public Point { ... };
class PointForme : virtual public Point { ... };
```

## 1. Schema des classes

```text
                 +----------------------+
                 |        Point         |
                 +----------------------+
                 | # x : short          |
                 | # y : short          |
                 +----------------------+
                 | + Point()            |
                 | + Point(abs, ord)    |
                 | + decrire()          |
                 | + ~Point()           |
                 +----------+-----------+
                            ^
              virtual public|virtual public
                            |
          +-----------------+-----------------+
          |                                   |
+----------------------+          +----------------------+
|       PointCol       |          |     PointForme       |
+----------------------+          +----------------------+
| # color : unsigned   |          | # forme : char       |
+----------------------+          +----------------------+
| + PointCol(...)      |          | + PointForme(...)    |
| + decrire()          |          | + decrire()          |
+----------+-----------+          +-----------+----------+
           ^                                  ^
           |                                  |
           +---------------+------------------+
                           |
                 +----------------------+
                 |    PointFormeCol    |
                 +----------------------+
                 | herite forme+couleur|
                 +----------------------+
                 | + PointFormeCol(...)|
                 | + decrire()         |
                 +----------------------+
```

## 2. Fichier `pointforme.h`

```cpp
#ifndef POINTFORME_H_
#define POINTFORME_H_

#include "point.h"
#include <iostream>
using namespace std;

class PointForme : virtual public Point {
protected:
    char forme;

public:
    PointForme(short abs = 0, short ord = 0, char f = '.')
        : Point(abs, ord), forme(f) {}

    virtual void decrire() {
        cout << "Je suis un point avec une forme" << endl;
        cout << "Mes coordonnees : " << x << " " << y
             << " et ma forme : " << forme << endl;
    }
};

#endif
```

### Explication

```cpp
class PointForme : virtual public Point
```

signifie que `PointForme` herite de `Point`, mais avec heritage virtuel. C'est important pour eviter le probleme du losange avec `PointFormeCol`.

```cpp
char forme;
```

represente la maniere de dessiner le point : point, etoile, cercle, etc.

```cpp
PointForme(short abs = 0, short ord = 0, char f = '.')
    : Point(abs, ord), forme(f) {}
```

La partie apres `:` initialise directement :

- la partie `Point` avec `abs` et `ord` ;
- l'attribut `forme` avec `f`.

## 3. Fichier `pointformecol.h`

```cpp
#ifndef POINTFORMECOL_H_
#define POINTFORMECOL_H_

#include "pointcol.h"
#include "pointforme.h"
#include <iostream>
using namespace std;

class PointFormeCol : public PointCol, public PointForme {
public:
    PointFormeCol(short abs = 0, short ord = 0,
                  char f = '.', unsigned int cl = 0)
        : Point(abs, ord),
          PointCol(abs, ord, cl),
          PointForme(abs, ord, f) {}

    virtual void decrire() {
        cout << "Je suis un point avec une forme et une couleur" << endl;
        cout << "Mes coordonnees : " << x << " " << y
             << ", ma forme : " << forme
             << " et ma couleur : " << color << endl;
    }
};

#endif
```
### Explication

```cpp
class PointFormeCol : public PointCol, public PointForme
```

signifie que `PointFormeCol` recupere :

- la couleur de `PointCol` ;
- la forme de `PointForme` ;
- les coordonnees de `Point`.

Le constructeur :

```cpp
: Point(abs, ord),
  PointCol(abs, ord, cl),
  PointForme(abs, ord, f)
```

initialise :

- `Point`, la classe de base commune ;
- `PointCol`, pour la couleur ;
- `PointForme`, pour la forme.

Comme `Point` est heritee virtuellement par `PointCol` et `PointForme`, c'est `PointFormeCol`, la classe la plus derivee, qui initialise vraiment `Point`.

## 4. Correction du `main()`

Pour stocker des objets de types differents dans le meme conteneur, il ne faut pas utiliser :

```cpp
vector<Point> points;
```

car cela ferait de la copie par valeur et on perdrait le polymorphisme.

Il faut utiliser des pointeurs vers la classe de base :

```cpp
vector<Point*> points;
```

### Code

```cpp
#include <iostream>
#include <vector>

#include "point.h"
#include "pointcol.h"
#include "pointforme.h"
#include "pointformecol.h"

using namespace std;

int main() {
    vector<Point*> points;

    points.push_back(new Point(1, 2));
    points.push_back(new PointCol(3, 4, 5));
    points.push_back(new PointForme(6, 7, '*'));
    points.push_back(new PointFormeCol(8, 9, 'o', 10));

    for (vector<Point*>::iterator it = points.begin(); it != points.end(); ++it) {
        (*it)->decrire();
        cout << endl;
    }

    for (vector<Point*>::iterator it = points.begin(); it != points.end(); ++it) {
        delete *it;
    }

    points.clear();

    return 0;
}
```

## 5. Point important : destructeur virtuel

Dans le fichier `point.h`, il vaut mieux ecrire :

```cpp
virtual ~Point() {}
```

au lieu de :

```cpp
~Point() {}
```

Pourquoi ? Parce qu'on detruit des objets derives avec un pointeur de type `Point*` :

```cpp
Point* p = new PointFormeCol(8, 9, 'o', 10);
delete p;
```

Si le destructeur de `Point` n'est pas virtuel, la destruction complete de l'objet derive n'est pas garantie.

## 6. Version attendue des classes deja donnees

Pour que la correction soit propre, on peut garder les classes de depart comme ceci :

```cpp
#ifndef POINT_H_
#define POINT_H_

#include <iostream>
using namespace std;

class Point {
protected:
    short x;
    short y;

public:
    Point() : x(0), y(0) {}
    Point(short abs, short ord) : x(abs), y(ord) {}

    virtual void decrire() {
        cout << "Je suis un point" << endl;
        cout << "Mes coordonnees : " << x << " " << y << endl;
    }

    virtual ~Point() {}
};

#endif
```

```cpp
#ifndef POINTCOL_H_
#define POINTCOL_H_

#include "point.h"
#include <iostream>
using namespace std;

class PointCol : virtual public Point {
protected:
    unsigned int color;

public:
    PointCol(short abs = 0, short ord = 0, unsigned int cl = 0)
        : Point(abs, ord), color(cl) {}

    virtual void decrire() {
        cout << "Je suis un point colore" << endl;
        cout << "Mes coordonnees : " << x << " " << y
             << " et ma couleur : " << color << endl;
    }
};

#endif
```

## 7. Ce qu'il faut savoir expliquer au partiel

- `PointCol` est un `Point` avec une couleur.
- `PointForme` est un `Point` avec une forme.
- `PointFormeCol` est un point avec couleur et forme.
- On utilise `virtual public Point` pour eviter deux copies de `Point` dans `PointFormeCol`.
- On utilise `vector<Point*>` pour stocker des objets de classes derivees differentes.
- `decrire()` doit etre `virtual` pour que le bon affichage soit appele.
- Le destructeur de `Point` doit etre `virtual` si on fait `delete` sur des `Point*`.
