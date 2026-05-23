
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
