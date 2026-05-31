# Fiche de revision C++ - Partiel

Objectif : savoir lire, expliquer et ecrire du C++ oriente objet simple. Les points les plus rentables pour le partiel sont : constructeurs/destructeurs, copie profonde, surcharge d'operateurs, polymorphisme, fichiers, exceptions, templates et STL.

## 1. Introduction au C++

### A retenir
- C++ = C + programmation orientee objet + programmation generique.
- Programme souvent separe en :
  - `.h` / `.hpp` : declarations, interface de classe, prototypes.
  - `.cpp` : implementations des methodes.
- `#include <iostream>` pour `cin`, `cout`, `cerr`.
- `#include <string>` pour `std::string`.
- `namespace` evite les conflits de noms : `std::cout`, ou `using namespace std;`.
- Initialisation moderne : `int x{3};` evite certaines conversions dangereuses.
- Reference `int& r = x;` : alias de `x`, utile pour modifier un parametre ou eviter une copie.
- `const` protege contre les modifications involontaires.

### Syntaxe utile
```cpp
#include <iostream>
#include <string>
using namespace std;

void incrementer(int& x) {
    x++;
}

void afficher(const string& s) {
    cout << s << endl;
}
```

### Pieges
- Une reference doit etre initialisee tout de suite.
- `const int* p` : pointeur vers entier constant.
- `int* const p` : pointeur constant vers entier modifiable.
- Eviter `using namespace std;` dans les headers.

### Comprendre `const`

`const` veut dire "je promets de ne pas modifier". C'est utile pour rendre le code plus sur, plus lisible, et pour permettre au compilateur de detecter des erreurs.

#### Variable constante
```cpp
const int max = 10;
// max = 12; // interdit
```

#### `const` avant le type de retour
```cpp
const int getNumerateur() const {
    return numerateur;
}
```

Le premier `const`, avant `int`, concerne la valeur retournee. Pour un type simple retourne par valeur comme `int`, il est peu utile, car on retourne deja une copie.

On ecrit donc plutot :
```cpp
int getNumerateur() const {
    return numerateur;
}
```

Le `const` avant le type devient surtout utile quand on retourne une reference ou un pointeur :
```cpp
const string& getNom() const {
    return nom;
}
```

Ici, on donne acces au vrai `nom`, mais en lecture seule.

#### Passage par reference constante
On l'utilise tres souvent pour eviter une copie sans autoriser la modification.
```cpp
void afficher(const string& nom) {
    cout << nom << endl;
}
```

Ici :
- `string& nom` evite une copie, mais la fonction pourrait modifier `nom`.
- `const string& nom` evite une copie et interdit la modification.
- Pour les gros objets, c'est le passage le plus classique.

#### Methode constante
Une methode marquee `const` promet de ne pas modifier l'objet courant.
```cpp
class Fraction {
private:
    int numerateur;
    int denominateur;

public:
    int getNumerateur() const {
        return numerateur;
    }
};
```

Le `const` apres les parentheses concerne `this` : dans cette methode, `this` devient un pointeur vers objet constant. Donc les attributs ne peuvent pas etre modifies.

```cpp
void afficherFraction(const Fraction& f) {
    cout << f.getNumerateur(); // possible seulement si getNumerateur() est const
}
```

Regle simple : les getters et les methodes d'affichage/calcul doivent souvent etre `const`.

#### Pointeurs et `const`
Lire de droite a gauche aide beaucoup.

```cpp
const int* p1 = &x;  // l'entier pointe est constant via p1
int const* p2 = &x;  // meme chose que p1
int* const p3 = &x;  // le pointeur est constant, pas l'entier pointe
const int* const p4 = &x; // pointeur constant vers entier constant
```

Exemples :
```cpp
int x = 3;
int y = 4;

const int* p1 = &x;
// *p1 = 5; // interdit
p1 = &y;    // autorise

int* const p2 = &x;
*p2 = 5;    // autorise
// p2 = &y; // interdit
```

#### Retour constant
On peut retourner une reference constante pour donner un acces en lecture seule.
```cpp
const string& getNom() const {
    return nom;
}
```

Attention : ne jamais retourner une reference vers une variable locale.

#### Mini-regles partiel
- Parametre objet non modifie : `const Type&`.
- Methode qui ne modifie pas l'objet : ajouter `const` apres les parentheses.
- Getter : presque toujours `const`.
- Operateur `==`, `+`, `*`, affichage : souvent avec parametres `const`.
- `const` avant `*` protege la valeur pointee ; `const` apres `*` protege le pointeur.

## 2. Classes, constructeurs, destructeurs, allocation dynamique

### Classe
```cpp
class Fraction {
private:
    int numerateur;
    int denominateur;

public:
    Fraction();
    Fraction(int n, int d);
    ~Fraction();
};
```

### Constructeur
- Meme nom que la classe.
- Aucun type de retour.
- Initialise l'objet.
- Preferer la liste d'initialisation.

```cpp
Fraction::Fraction() : numerateur{0}, denominateur{1} {}
Fraction::Fraction(int n, int d) : numerateur{n}, denominateur{d} {}
```

### Destructeur
- Nom : `~NomClasse()`.
- Appele automatiquement en fin de vie de l'objet.
- Sert surtout a liberer les ressources dynamiques.
- Il n'a ni parametre ni type de retour, donc pas de surcharge.

```cpp
Fraction::~Fraction() {}
```

### Classe canonique
Dans beaucoup de cours, une classe canonique contient explicitement :
```cpp
class Point {
public:
    Point();                         // constructeur par defaut
    Point(const Point& autre);        // constructeur de recopie
    Point& operator=(const Point& autre); // affectation
    ~Point();                        // destructeur
};
```

Si on ecrit un constructeur avec parametres, par exemple :
```cpp
Point(short x, short y);
```
le compilateur ne genere plus automatiquement le constructeur sans argument `Point()`.

Pour une classe qui gere une ressource dynamique, il faut penser a la regle des trois : destructeur, constructeur de copie, operateur d'affectation.

### Pile vs tas
```cpp
Fraction f(1, 2);              // pile, destruction automatique
Fraction* pf = new Fraction(1, 2); // tas
delete pf;                     // obligatoire

Fraction* tab = new Fraction[10];
delete[] tab;
```

### Copie profonde : point majeur
Si une classe possede un pointeur vers une zone dynamique, la copie par defaut copie l'adresse, pas le contenu. Il faut souvent definir :
- constructeur de copie ;
- operateur d'affectation ;
- destructeur.

```cpp
class Vector {
private:
    double* elem;
    unsigned int sz;

public:
    Vector(unsigned int s) : elem{new double[s]}, sz{s} {}

    Vector(const Vector& a) : elem{new double[a.sz]}, sz{a.sz} {
        for (unsigned int i = 0; i < sz; ++i) elem[i] = a.elem[i];
    }

    Vector& operator=(const Vector& a) {
        if (this != &a) {
            delete[] elem;
            sz = a.sz;
            elem = new double[sz];
            for (unsigned int i = 0; i < sz; ++i) elem[i] = a.elem[i];
        }
        return *this;
    }

    ~Vector() {
        delete[] elem;
    }
};
```

#### Explication de `elem{new double[s]}`

```cpp
Vector(unsigned int s) : elem{new double[s]}, sz{s} {}
```

La partie apres `:` s'appelle la liste d'initialisation. Elle initialise directement les attributs avant d'entrer dans le corps du constructeur `{}`.

Ici :

```cpp
: elem{new double[s]}, sz{s}
```

veut dire :

- `elem{new double[s]}` : `elem` recoit l'adresse d'un tableau dynamique de `s` elements de type `double` ;
- `sz{s}` : l'attribut `sz` recoit la valeur du parametre `s`.

Exemple :

```cpp
Vector v(4);
```

cree un tableau dynamique de 4 `double` :

```text
elem -> [ double ][ double ][ double ][ double ]
```

Le corps `{}` est vide parce que l'initialisation est deja faite avant. On pourrait ecrire :

```cpp
Vector(unsigned int s) {
    elem = new double[s];
    sz = s;
}
```

mais la liste d'initialisation est plus propre, et parfois obligatoire pour les attributs `const`, les references, ou les objets sans constructeur par defaut.

Attention : `new double[s]` ne met pas forcement les valeurs a `0.0`. Pour initialiser toutes les cases a `0.0`, on ecrit :

```cpp
elem{new double[s]{}}
```

### Pieges
- `Fraction f;` appelle le constructeur par defaut.
- `Fraction f();` declare une fonction, ce n'est pas un objet.
- `delete` avec `new`, `delete[]` avec `new[]`.
- Dans `operator=`, penser a `return *this;`.
- Tester l'auto-affectation : `if (this != &a)`.

## 3. Surcharge des operateurs

### Idee
La surcharge permet d'ecrire :
```cpp
Fraction c = a * b;
if (a == b) {}
cout << a;
```
au lieu de fonctions moins lisibles.

### Operateur membre
Utilise quand l'operande gauche est l'objet courant.
```cpp
class Fraction {
public:
    Fraction operator*(const Fraction& autre) const {
        return Fraction(numerateur * autre.numerateur,
                        denominateur * autre.denominateur);
    }
};
```

### Operateur non membre
Utile pour permettre les conversions des deux cotes, par exemple `2 * f`.
```cpp
Fraction operator*(const Fraction& a, const Fraction& b) {
    return Fraction(a.getNumerateur() * b.getNumerateur(),
                    a.getDenominateur() * b.getDenominateur());
}
```

### Fonction amie `friend`
Une fonction non membre peut acceder au prive si elle est declaree amie.
```cpp
class Fraction {
    friend ostream& operator<<(ostream& out, const Fraction& f);
};

ostream& operator<<(ostream& out, const Fraction& f) {
    out << f.numerateur << "/" << f.denominateur;
    return out;
}
```

Une fonction amie n'est pas une methode membre. Elle est declaree dans la classe avec `friend`, puis souvent definie en dehors de la classe. Elle ne s'appelle pas avec `f.operator<<()`, mais comme une fonction ou un operateur normal.

`ostream` signifie `output stream`, donc flux de sortie. `cout` est un `ostream`, mais un fichier `ofstream` est aussi un flux de sortie. C'est pour ca qu'on ecrit dans `out` au lieu d'ecrire directement dans `cout`.

Dans un `operator<<`, on evite generalement de mettre `endl`. L'operateur doit seulement dire comment afficher l'objet ; c'est l'utilisateur qui choisit ensuite :
```cpp
cout << f;         // sans retour ligne
cout << f << endl; // avec retour ligne
cout << f << " ";  // avec espace
```

`endl` fait deux choses : retour a la ligne et vidage immediat du flux. Pour un simple retour ligne, `\n` suffit souvent.

### A savoir coder
```cpp
bool operator==(const Complexe& a, const Complexe& b) {
    return a.getReel() == b.getReel()
        && a.getImag() == b.getImag();
}
```

### Pieges
- `f1 * 2` peut marcher avec une methode membre si `2` est convertible en `Fraction`.
- `2 * f1` ne marche pas avec une methode membre de `Fraction`, car l'operande gauche est `int`.
- `operator<<` doit retourner `ostream&` pour permettre `cout << a << b`.
- Mettre `const` sur les methodes qui ne modifient pas l'objet.

## 4. Heritage et polymorphisme

### Heritage
Relation "est un".
```cpp
class Personne {
private:
    string nom;
public:
    Personne(string n) : nom{n} {}
    string getNom() const { return nom; }
};

class Etudiant : public Personne {
private:
    string id;
public:
    Etudiant(string nom, string id) : Personne{nom}, id{id} {}
};
```

#### Heritage `public`, `protected`, `private`
```cpp
class Fille : public Mere {};
class Fille : protected Mere {};
class Fille : private Mere {};
```

- `public` : relation "est un". Un `Etudiant` est une `Personne`. C'est l'heritage classique pour le polymorphisme.
- `protected` : les membres publics de la mere deviennent `protected` dans la fille. L'heritage reste utilisable dans la classe fille et ses futures classes filles, mais pas depuis l'exterieur.
- `private` : les membres publics/protected de la mere deviennent `private` dans la fille. La classe fille utilise la classe mere en interne, mais ne l'expose pas.

Tableau mental :
```text
Heritage public    : public -> public,    protected -> protected
Heritage protected : public -> protected, protected -> protected
Heritage private   : public -> private,   protected -> private
```

Dans tous les cas, les attributs `private` de la classe mere restent inaccessibles directement dans la classe fille. Il faut des getters ou passer les attributs en `protected`.

### Ordre constructeur/destructeur
- Construction : base puis derivee.
- Destruction : derivee puis base.

### Redefinition vs surcharge
- Meme signature dans la classe fille : redefinition.
- Signature differente : surcharge ou masquage de nom.
- `override` force le compilateur a verifier qu'on redefinit vraiment.

### Polymorphisme
Le polymorphisme permet d'utiliser un objet derive via un pointeur ou une reference de base, tout en appelant la bonne methode.

```cpp
class Figure {
public:
    virtual void affiche() const = 0;
    virtual ~Figure() {}
};

class Cercle : public Figure {
public:
    void affiche() const override {
        cout << "Cercle" << endl;
    }
};

void dessiner(const Figure& f) {
    f.affiche(); // appelle Cercle::affiche si f reference un Cercle
}
```

### Comprendre `virtual`

Sans `virtual`, le choix de la fonction appelee depend du type de la variable ou du pointeur au moment de la compilation. C'est la liaison statique.

```cpp
class Base {
public:
    void afficher() const {
        cout << "Base" << endl;
    }
};

class Derivee : public Base {
public:
    void afficher() const {
        cout << "Derivee" << endl;
    }
};

Base* p = new Derivee();
p->afficher(); // affiche "Base" si afficher n'est pas virtual
delete p;
```

Avec `virtual`, le choix depend du vrai type de l'objet pendant l'execution. C'est la liaison dynamique.

```cpp
class Base {
public:
    virtual void afficher() const {
        cout << "Base" << endl;
    }

    virtual ~Base() {}
};

class Derivee : public Base {
public:
    void afficher() const override {
        cout << "Derivee" << endl;
    }
};

Base* p = new Derivee();
p->afficher(); // affiche "Derivee"
delete p;      // appelle bien ~Derivee puis ~Base si destructeur virtuel
```

#### `override`
`override` ne rend pas une fonction virtuelle. Il sert a demander au compilateur : "verifie que je redefinis bien une methode virtuelle de la classe mere".

```cpp
class Base {
public:
    virtual void f(int) const;
};

class Derivee : public Base {
public:
    void f(double) const override; // erreur : signature differente
};
```

Sans `override`, ce genre d'erreur peut passer inapercu : on croit redefinir, mais on cree une nouvelle methode.

#### `= 0` : virtuelle pure
```cpp
class Figure {
public:
    virtual double aire() const = 0;
};
```

`= 0` signifie : la classe impose cette fonction aux classes filles. La classe devient abstraite, donc non instanciable.

```cpp
// Figure f; // interdit
```

Une classe derivee doit implementer toutes les methodes virtuelles pures pour pouvoir etre instanciee.

Une fonction est virtuelle pure seulement si elle contient `= 0` :
```cpp
virtual void afficher() const = 0;
```

On ne met pas d'accolades directement avec `= 0` dans la classe :
```cpp
virtual void afficher() const = 0; // oui
// virtual void afficher() const = 0 {} // non
```

Le `const` avant `= 0` signifie que la methode ne modifie pas l'objet. Le `= 0` signifie que la methode est obligatoire dans les classes filles.

#### Destructeur virtuel
Si une classe est faite pour etre manipulee par pointeur/reference de base, son destructeur doit etre virtuel.

```cpp
class Figure {
public:
    virtual double aire() const = 0;
    virtual ~Figure() {}
};
```

Pourquoi ? Si on fait :
```cpp
Figure* f = new Cercle();
delete f;
```

Sans destructeur virtuel dans `Figure`, le destructeur de `Cercle` risque de ne pas etre appele correctement. Probleme classique : fuite memoire ou liberation incomplete.

#### `final`
`final` ferme une possibilite.

```cpp
class Base {
public:
    virtual void f() final;
};

class Derniere final {
};
```

- Sur une methode virtuelle : interdit aux classes filles de la redefinir.
- Sur une classe : interdit d'en heriter.

#### Resume express
- `virtual` : active le choix dynamique de la methode.
- `override` : verifie une vraie redefinition.
- `= 0` : methode virtuelle pure, classe abstraite.
- `virtual ~Base()` : indispensable si destruction via pointeur de base.
- `final` : interdit la redefinition ou l'heritage.

### Classe abstraite
- Une methode virtuelle pure se declare avec `= 0`.
- Une classe avec au moins une methode virtuelle pure est abstraite.
- On ne peut pas instancier une classe abstraite.
- Une classe derivee doit implementer les methodes pures pour devenir concrete.

### Types de methodes
- Methode non virtuelle : implementation obligatoire heritee telle quelle.
- Methode virtuelle : implementation par defaut redefinissable.
- Methode virtuelle pure : interface obligatoire, implementation imposee aux classes concretes.

### Appel avec `.` ou `->`
```cpp
objet.afficher();      // objet normal ou reference
pointeur->afficher();  // pointeur
```

La fleche est un raccourci :
```cpp
p->afficher();
```
veut dire :
```cpp
(*p).afficher();
```

### Pieges
- Pour detruire via un pointeur de base, le destructeur de la base doit etre `virtual`.
- Le polymorphisme fonctionne avec pointeurs/references, pas avec copie par valeur.
- `final` sur une methode interdit sa redefinition ; sur une classe interdit l'heritage.

## 5. Entrees-sorties et fichiers

### Flux standards
- `cin` : entree standard.
- `cout` : sortie standard.
- `cerr` : sortie erreur.
- `<<` ecrit dans un flux.
- `>>` lit depuis un flux.

### Surcharge des flux
```cpp
ostream& operator<<(ostream& out, const Fraction& f) {
    out << f.numerateur << "/" << f.denominateur;
    return out;
}

istream& operator>>(istream& in, Fraction& f) {
    char slash;
    if (!(in >> f.numerateur >> slash >> f.denominateur) || slash != '/') {
        in.setstate(ios::failbit);
    }
    return in;
}
```

### Fichiers
```cpp
#include <fstream>

ofstream out("data.txt", ios::out);
out << "texte" << endl;
out.close();

ifstream in("data.txt");
string ligne;
while (getline(in, ligne)) {
    cout << ligne << endl;
}
in.close();
```

### Modes utiles
- `ios::in` : lecture.
- `ios::out` : ecriture.
- `ios::app` : ajout en fin.
- `ios::trunc` : vide le fichier a l'ouverture.
- `ios::binary` : mode binaire.

### Etats du flux
- `good()` : tout va bien.
- `fail()` : erreur logique ou format incorrect.
- `bad()` : erreur grave de lecture/ecriture.
- `eof()` : fin de fichier atteinte.

### Pieges
- Preferer `while (in >> x)` ou `while (getline(in, ligne))` a `while (!in.eof())`.
- Tester l'ouverture : `if (!in) cerr << "Erreur ouverture";`.
- `>>` s'arrete aux espaces ; `getline` lit toute la ligne.

## 6. Exceptions

### Principe
Une exception signale une erreur a l'execution et interrompt le flux normal.

```cpp
try {
    if (b == 0) {
        throw "Division par zero";
    }
    cout << a / b << endl;
}
catch (const char* msg) {
    cerr << msg << endl;
}
```

### Plusieurs catch
```cpp
try {
    throw 10;
}
catch (int e) {
    cout << "Erreur int : " << e << endl;
}
catch (...) {
    cout << "Exception inattendue" << endl;
}
```

### Exception personnalisee
```cpp
#include <exception>
#include <string>

class Erreur : public std::exception {
private:
    std::string phrase;
public:
    Erreur(const std::string& p) : phrase{p} {}

    const char* what() const noexcept override {
        return phrase.c_str();
    }
};
```

Explication :
- `std::string` est le nom complet de `string`, car `string` appartient au namespace `std`.
- `what()` est la methode standard qui retourne le message de l'exception.
- `const char*` est une chaine C classique ; `what()` doit retourner ce type.
- `phrase.c_str()` transforme la `std::string` en `const char*`.
- `noexcept` signifie que la methode promet de ne pas lancer d'exception.
- `override` verifie qu'on redefinit bien `std::exception::what()`.

A ne pas faire : retourner `c_str()` d'une variable locale, car elle serait detruite a la fin de la fonction.

### Propagation
- Si une fonction ne capture pas l'exception, elle remonte a l'appelant.
- Dans un `catch`, `throw;` relance la meme exception.
- Les destructeurs des objets locaux deja construits sont appeles pendant la remontee.

### Pieges
- Attraper les exceptions objets par reference : `catch (const Erreur& e)`.
- `catch (...)` doit etre en dernier.
- Ne pas utiliser les exceptions pour le deroulement normal du programme.

## 7. Templates et STL

### Fonction template
```cpp
template <typename T>
T minimum(const T& a, const T& b) {
    return (a < b) ? a : b;
}
```

Pour utiliser `minimum<Personne>`, il faut que `operator<` existe pour `Personne`.

### Classe template
```cpp
template <typename T>
class Vector {
private:
    T* elem;
    unsigned int sz;
public:
    Vector(unsigned int s) : elem{new T[s]}, sz{s} {}

    // Explication :
    // - elem est un pointeur de type T*.
    // - new T[s] alloue sur le tas un tableau de s elements de type T.
    // - elem{new T[s]} met dans elem l'adresse du premier element du tableau.
    // - sz{s} copie la taille demandee dans l'attribut sz.
    // - les accolades finales {} sont le corps du constructeur. Il est vide ici.
    ~Vector() { delete[] elem; }

    T& operator[](unsigned int i) { return elem[i]; }
    const T& operator[](unsigned int i) const { return elem[i]; }
};
```

### STL
La STL fournit des conteneurs, iterateurs et algorithmes testes.

Conteneurs :
- `vector<T>` : tableau dynamique, acces rapide par indice.
- `list<T>` : liste chainee, insertions/suppressions faciles.
- `map<Key, Value>` : association cle-valeur.
- `stack<T>` : pile.
- `priority_queue<T>` : file de priorite.

### Iterateurs
```cpp
vector<int> v{1, 2, 3};
for (vector<int>::iterator it = v.begin(); it != v.end(); ++it) {
    cout << *it << endl;
}

for (int x : v) {
    cout << x << endl;
}
```

`vector<int>::iterator` signifie : type d'un iterateur permettant de parcourir un `vector<int>`.

- `v.begin()` pointe sur le premier element.
- `v.end()` pointe juste apres le dernier element.
- `*it` donne l'element courant.
- `++it` avance a l'element suivant.

Avec un conteneur de pointeurs :
```cpp
vector<Point*> points;
for (vector<Point*>::iterator it = points.begin(); it != points.end(); ++it) {
    (*it)->decrire();
}
```

Ici, `*it` donne un `Point*`, donc on utilise `->` pour appeler la methode.

### Algorithmes
```cpp
#include <algorithm>

int n = count(v.begin(), v.end(), 1);
sort(v.begin(), v.end());
```

### Foncteur
Objet qui se comporte comme une fonction grace a `operator()`.
```cpp
class Addition {
public:
    int operator()(int a, int b) const {
        return a + b;
    }
};
```

### Pieges
- Les templates sont generalement definis dans les headers.
- Un algorithme STL travaille souvent avec `[begin, end)`.
- `end()` ne pointe pas sur le dernier element, mais juste apres.

## Focus examen 2024 - Exercice 4

### Points a retenir
- `Point(short abs, short ord) : x(abs), y(ord) {}` utilise une liste d'initialisation.
- `PointCol(short abs, short ord, unsigned int cl) : Point(abs, ord), color(cl) {}` est plus propre que d'affecter `color` dans le corps du constructeur.
- `short` est un entier signe de petite taille, souvent 2 octets. Il peut etre negatif.
- `unsigned int` est un entier non signe : positif ou nul.
- Si `x` et `y` sont `private` dans `Point`, `PointCol` ne peut pas y acceder directement.
- Correction possible : ajouter `getX()` / `getY()` ou mettre `x` et `y` en `protected`.
- `class PointCol : public Point` signifie qu'un `PointCol` est un `Point`.
- `Point* p = new PointCol(...)` est autorise : pointeur de classe mere vers objet de classe fille.
- `PointCol* pc = new Point(...)` est interdit : un `Point` n'est pas forcement un `PointCol`.
- Si `decrire()` est `virtual`, alors `p->decrire()` appelle la methode du vrai type de l'objet.

### Classe canonique dans l'exercice
Pour la question 3, on peut repondre que `Point` n'est pas canonique car il manque explicitement :
```cpp
Point();
Point(const Point& autre);
Point& operator=(const Point& autre);
```
Le constructeur sans argument manque aussi, car le constructeur avec parametres empeche sa generation automatique.

### Sortie apres suppression de la ligne fausse
```cpp
Point *p1 = new Point(3,5);
p1->decrire();

PointCol *pc1 = new PointCol(8,6,2);
pc1->decrire();

Point *p2 = new PointCol(8,6,5);
p2->decrire();
```

Sortie :
```text
je suis un point
mes coordonnees : 3 5
je suis un point colore
mes coordonnees : 8 6 et ma couleur : 2
je suis un point colore
mes coordonnees : 8 6 et ma couleur : 5
```

Remarque propre : comme `Point` est utilisee comme classe de base polymorphe, son destructeur devrait etre virtuel :
```cpp
virtual ~Point() {}
```
## Questions type partiel

1. Expliquer la difference entre constructeur de copie et operateur d'affectation.
2. Corriger une classe avec `new[]` mais sans destructeur.
3. Ecrire `operator<<` pour afficher une classe.
4. Dire pourquoi `2 * fraction` ne compile pas avec un `operator*` membre.
5. Expliquer pourquoi le destructeur d'une classe de base polymorphe doit etre virtuel.
6. Ecrire une classe abstraite `Figure` avec `aire()`.
7. Lire un fichier ligne par ligne et gerer l'erreur d'ouverture.
8. Ecrire un `try/catch` pour division par zero.
9. Ecrire une fonction template `max`.
10. Utiliser `vector`, `map`, `sort` ou `count`.

## Mini-exercices pour t'entrainer

### Exercice 1 - Classe dynamique
Ecrire une classe `Tableau` contenant `int* data` et `int taille`.
Elle doit avoir :
- constructeur ;
- destructeur ;
- constructeur de copie ;
- `operator=`.

### Exercice 2 - Surcharge
Pour une classe `Rational`, coder :
- `operator+` ;
- `operator==` ;
- `operator<<`.

### Exercice 3 - Polymorphisme
Creer une classe abstraite `Forme` avec :
```cpp
virtual double aire() const = 0;
virtual void afficher() const = 0;
virtual ~Forme() {}
```
Puis creer `Rectangle` et `Cercle`.

### Exercice 4 - Fichiers
Lire un fichier `contacts.txt` contenant :
```text
nom telephone
```
et remplir un `map<string, string>`.

### Exercice 5 - Templates
Ecrire :
```cpp
template <typename T>
void echanger(T& a, T& b);
```

## Priorite de revision

1. Constructeur, destructeur, copie profonde, `operator=`.
2. Surcharge `==`, `+`, `*`, `<<`, `>>`.
3. Heritage, `virtual`, `override`, classe abstraite.
4. Fichiers et etats de flux.
5. Exceptions.
6. Templates et STL.

## Checklist juste avant le partiel

- Je sais separer une classe en `.h` et `.cpp`.
- Je sais expliquer pile/tas, `new/delete`, `new[]/delete[]`.
- Je sais corriger une fuite memoire simple.
- Je sais coder un constructeur de copie.
- Je sais coder un `operator=`.
- Je sais quand utiliser une fonction amie.
- Je sais pourquoi `operator<<` retourne `ostream&`.
- Je sais expliquer `virtual`, `override`, `= 0`.
- Je sais lire/ecrire un fichier texte.
- Je sais utiliser `try`, `throw`, `catch`.
- Je sais ecrire une fonction template simple.
- Je connais `vector`, `list`, `map`, iterateurs et `algorithm`.







