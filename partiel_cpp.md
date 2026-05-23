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
