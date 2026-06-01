# Correction DS 2020 - Ordonnanceur C++

## Sujet resume

On veut simuler un ordonnanceur de processus.

Le programme contient 4 classes :

- `Objet`
- `Processus`
- `Ordonnanceur`
- `Comparaison`

Les classes `Processus` et `Ordonnanceur` derivent de `Objet`.

La classe `Objet` contient une methode virtuelle pure :

```cpp
virtual void afficher() const = 0;
```

Cela permet d'imposer a toutes les classes filles de definir leur propre affichage.

---

## 1. Classe `Objet`

### Fichier `Objet.h`

```cpp
#ifndef OBJET_H
#define OBJET_H

class Objet {
public:
    virtual void afficher() const = 0;
    virtual ~Objet() {}
};

#endif
```

### Explication

`Objet` est une classe abstraite, car elle contient une methode virtuelle pure :

```cpp
virtual void afficher() const = 0;
```

On ne peut donc pas faire :

```cpp
Objet o; // interdit
```

Le role de cette classe est de donner une interface commune aux classes filles.

Le destructeur est virtuel :

```cpp
virtual ~Objet() {}
```

C'est important si on manipule des objets derives avec des pointeurs de type `Objet*`.

---

## 2. Classe `Processus`

Un processus possede :

- un identifiant `id` ;
- une duree de traitement `duree` ;
- une priorite `priority`, comprise entre 1 et 10.

### Fichier `Processus.h`

```cpp
#ifndef PROCESSUS_H
#define PROCESSUS_H

#include "Objet.h"
#include <iostream>
#include <stdexcept>

class Processus : public Objet {
private:
    int id;
    int duree;
    int priority;

public:
    Processus(int i, int d, int p) : id{i}, duree{d}, priority{p} {
        if (duree <= 0) {
            throw std::invalid_argument("Duree invalide");
        }

        if (priority < 1 || priority > 10) {
            throw std::invalid_argument("Priorite invalide");
        }
    }

    int getPriority() const {
        return priority;
    }

    int getDuree() const {
        return duree;
    }

    bool termine() const {
        return duree <= 0;
    }

    void traiter(int quantum) {
        duree -= quantum;

        if (priority > 1) {
            priority--;
        }
    }

    void afficher() const override {
        std::cout << "Processus " << id
                  << " | duree = " << duree
                  << " | priorite = " << priority
                  << std::endl;
    }
};

#endif
```

### Explication

Le constructeur initialise les attributs avec une liste d'initialisation :

```cpp
Processus(int i, int d, int p) : id{i}, duree{d}, priority{p}
```

Il securise ensuite les valeurs :

```cpp
if (duree <= 0) {
    throw std::invalid_argument("Duree invalide");
}
```

et :

```cpp
if (priority < 1 || priority > 10) {
    throw std::invalid_argument("Priorite invalide");
}
```

La methode :

```cpp
void traiter(int quantum)
```

simule un tour de traitement. Elle diminue :

- la duree du processus ;
- la priorite du processus, jusqu'a un minimum de 1.

```cpp
if (priority > 1) {
    priority--;
}
```

La methode :

```cpp
bool termine() const
```

sert a savoir si le processus doit etre supprime de la file.

---

## 3. Classe `Comparaison`

La `priority_queue` a besoin de savoir comment comparer deux processus.

### Fichier `Comparaison.h`

```cpp
#ifndef COMPARAISON_H
#define COMPARAISON_H

#include "Processus.h"

class Comparaison {
public:
    bool operator()(const Processus& p1, const Processus& p2) const {
        return p1.getPriority() < p2.getPriority();
    }
};

#endif
```

### Explication

Cette classe est un foncteur, car elle surcharge :

```cpp
operator()
```

Elle permet d'utiliser un objet comme une fonction.

Cette ligne :

```cpp
return p1.getPriority() < p2.getPriority();
```

signifie que le processus avec la plus grande priorite doit passer devant.

Avec cette comparaison, si on ajoute :

```cpp
Processus(1, 10, 3)
Processus(2, 5, 9)
Processus(3, 8, 6)
```

alors :

```cpp
pq.top()
```

donne le processus de priorite 9.

---

## 4. Classe `Ordonnanceur`

L'ordonnanceur contient une file de priorite de processus.

### Fichier `Ordonnanceur.h`

```cpp
#ifndef ORDONNANCEUR_H
#define ORDONNANCEUR_H

#include "Objet.h"
#include "Processus.h"
#include "Comparaison.h"
#include <iostream>
#include <queue>
#include <stdexcept>
#include <unistd.h>
#include <vector>

class Ordonnanceur : public Objet {
private:
    std::priority_queue<Processus, std::vector<Processus>, Comparaison> pq;
    int quantum;

public:
    Ordonnanceur(int q) : quantum{q} {
        if (quantum <= 0) {
            throw std::invalid_argument("Quantum invalide");
        }
    }

    void ajouter(const Processus& p) {
        pq.push(p);
    }

    void executer() {
        while (!pq.empty()) {
            Processus p = pq.top();
            pq.pop();

            std::cout << "Traitement de : ";
            p.afficher();

            p.traiter(quantum);

            if (!p.termine()) {
                pq.push(p);
            } else {
                std::cout << "Processus termine" << std::endl;
            }

            sleep(1);
        }
    }

    void afficher() const override {
        std::cout << "Ordonnanceur : "
                  << pq.size()
                  << " processus en attente"
                  << std::endl;
    }
};

#endif
```

### Explication de la `priority_queue`

```cpp
std::priority_queue<Processus, std::vector<Processus>, Comparaison> pq;
```

Cette ligne declare une file de priorite.

Elle se lit comme ca :

- `Processus` : type des elements stockes ;
- `std::vector<Processus>` : conteneur interne utilise par la file ;
- `Comparaison` : classe qui indique comment comparer deux processus ;
- `pq` : nom de la file.

Si on met :

```cpp
using namespace std;
```

on peut ecrire :

```cpp
priority_queue<Processus, vector<Processus>, Comparaison> pq;
```

Mais dans un fichier `.h`, il est plus propre de garder les `std::`.

### Fonctionnement de `executer()`

```cpp
while (!pq.empty())
```

Tant que la file n'est pas vide, on continue la simulation.

```cpp
Processus p = pq.top();
pq.pop();
```

On recupere le processus le plus prioritaire, puis on le retire de la file.

Attention :

```cpp
pq.pop();
```

ne retourne pas l'element. C'est pour cela qu'on fait d'abord :

```cpp
Processus p = pq.top();
```

Ensuite :

```cpp
p.traiter(quantum);
```

On diminue sa duree et sa priorite.

Puis :

```cpp
if (!p.termine()) {
    pq.push(p);
}
```

Si le processus n'est pas termine, on le remet dans la file.

Sinon, il disparait de l'ordonnanceur.

---

## 5. Programme principal

### Fichier `main.cpp`

```cpp
#include "Ordonnanceur.h"
#include <cstdlib>
#include <exception>
#include <iostream>

int main(int argc, char* argv[]) {
    try {
        if (argc != 2) {
            throw std::invalid_argument("Usage : ./programme nombre_processus");
        }

        int n = std::atoi(argv[1]);

        if (n <= 0) {
            throw std::invalid_argument("Nombre de processus invalide");
        }

        Ordonnanceur ord(2);

        for (int i = 0; i < n; ++i) {
            int duree;
            int priority;

            std::cout << "Processus " << i + 1 << std::endl;

            std::cout << "Duree : ";
            std::cin >> duree;

            std::cout << "Priorite entre 1 et 10 : ";
            std::cin >> priority;

            Processus p(i + 1, duree, priority);
            ord.ajouter(p);
        }

        ord.executer();
    }
    catch (const std::exception& e) {
        std::cerr << "Erreur : " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
```

### Explication

Le nombre de processus est donne en ligne de commande :

```cpp
int main(int argc, char* argv[])
```

Si l'utilisateur lance :

```bash
./programme 3
```

alors :

```cpp
argv[1]
```

contient `"3"`.

On transforme cette chaine en entier :

```cpp
int n = std::atoi(argv[1]);
```

Ensuite, on demande a l'utilisateur la duree et la priorite de chaque processus.

Chaque processus est ajoute a l'ordonnanceur :

```cpp
ord.ajouter(p);
```

Puis la simulation commence :

```cpp
ord.executer();
```

---

## 6. Version avec `using namespace std`

Pour un petit programme de partiel, on peut simplifier les noms avec :

```cpp
using namespace std;
```

Par exemple :

```cpp
std::cout
std::vector
std::priority_queue
std::invalid_argument
```

deviennent :

```cpp
cout
vector
priority_queue
invalid_argument
```

Exemple :

```cpp
priority_queue<Processus, vector<Processus>, Comparaison> pq;
```

Mais dans un vrai projet, surtout dans les fichiers `.h`, il vaut mieux eviter `using namespace std;`.

---

## 7. Points de cours a savoir expliquer

### Pourquoi une classe `Objet` ?

La classe `Objet` sert d'interface commune.

Elle impose une methode :

```cpp
afficher()
```

a toutes les classes filles.

### Pourquoi `virtual` ?

`virtual` permet le polymorphisme.

Si on manipule un objet derive avec un pointeur de classe mere, la bonne methode est appelee selon le vrai type de l'objet.

### Pourquoi `= 0` ?

`= 0` signifie que la methode est virtuelle pure.

La classe devient abstraite et les classes filles doivent redefinir la methode.

### Pourquoi `override` ?

`override` demande au compilateur de verifier qu'on redefinit bien une methode virtuelle de la classe mere.

### Pourquoi `const` apres `afficher()` ?

```cpp
void afficher() const
```

signifie que la methode ne modifie pas l'objet.

Comme `afficher()` sert seulement a lire et afficher les attributs, elle doit etre `const`.

### Pourquoi une `priority_queue` ?

Une `priority_queue` permet de recuperer directement l'element le plus prioritaire.

Dans cet exercice, cela permet de traiter en premier le processus avec la plus grande priorite.

### Pourquoi un foncteur `Comparaison` ?

La file de priorite doit savoir comment comparer deux processus.

Le foncteur donne cette regle :

```cpp
bool operator()(const Processus& p1, const Processus& p2) const
```

### Pourquoi les exceptions ?

Les exceptions servent a securiser les entrees :

- duree strictement positive ;
- priorite entre 1 et 10 ;
- nombre de processus valide ;
- quantum strictement positif.

---

## 8. Exemple de simulation

Supposons un quantum de 2.

On cree :

```text
P1 : duree 5, priorite 3
P2 : duree 4, priorite 8
P3 : duree 3, priorite 5
```

La file traite d'abord `P2`, car sa priorite est 8.

Apres traitement :

```text
P2 : duree 2, priorite 7
```

Il n'est pas termine, donc il retourne dans la file.

Ensuite, la file reprend encore le processus le plus prioritaire.

Quand la duree devient inferieure ou egale a 0, le processus est termine et n'est pas remis dans la file.

---

## 9. Erreurs classiques

- Oublier `virtual` dans `afficher()`.
- Oublier `= 0` dans la classe `Objet`.
- Oublier le destructeur virtuel dans la classe de base.
- Confondre `queue` et `priority_queue`.
- Croire que `pop()` retourne l'element.
- Oublier de faire `top()` avant `pop()`.
- Oublier de remettre le processus dans la file s'il n'est pas termine.
- Ne pas verifier que la priorite est entre 1 et 10.
- Mettre `using namespace std;` dans un `.h`.

---

## 10. Commandes de compilation

Exemple :

```bash
g++ main.cpp -Wall -o ordonnanceur
```

Execution :

```bash
./ordonnanceur 3
```

Sous Windows :

```bash
ordonnanceur.exe 3
```

