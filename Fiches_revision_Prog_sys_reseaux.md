# Fiches de revision - Programmation systeme et reseaux

## 1. Fichiers, descripteurs et entrees/sorties bas niveau

### Idees cles

- Un descripteur de fichier est un entier manipule par le noyau.
- Par convention :
  - `0` : entree standard (`stdin`)
  - `1` : sortie standard (`stdout`)
  - `2` : sortie erreur (`stderr`)
- Les appels systeme principaux sont `open`, `read`, `write`, `close`, `lseek`, `dup`, `dup2`.
- Contrairement a `printf`/`scanf`, `read` et `write` ne passent pas par les buffers de la bibliotheque C.

### Appels a connaitre

```c
int fd = open("fichier.txt", O_RDONLY);
int fd2 = open("out.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);

ssize_t n = read(fd, buffer, sizeof(buffer));
ssize_t w = write(fd2, buffer, n);

off_t pos = lseek(fd, 0, SEEK_SET);
close(fd);
```

### Drapeaux utiles pour `open`

- `O_RDONLY` : lecture seule.
- `O_WRONLY` : ecriture seule.
- `O_RDWR` : lecture/ecriture.
- `O_CREAT` : cree le fichier s'il n'existe pas.
- `O_TRUNC` : vide le fichier au moment de l'ouverture.
- `O_APPEND` : ecrit toujours a la fin.

### Redirection avec `dup2`

`dup2(fd, 1)` remplace la sortie standard par `fd`.

```c
int fd = open("sortie.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
dup2(fd, STDOUT_FILENO);
close(fd);
printf("Ce texte part dans sortie.txt\n");
```

### Pieges classiques

- Toujours tester les retours : `open` renvoie `-1` en cas d'erreur.
- `read` renvoie le nombre d'octets lus, pas forcement la taille demandee.
- `read` renvoie `0` en fin de fichier.
- Ne pas oublier le mode `0644` quand on utilise `O_CREAT`.
- `write(fd, buffer, strlen(buffer))` convient pour une chaine, mais pas pour un bloc binaire.

---

## 2. Processus : `fork`, `wait`, `exec`

### Idees cles

- Un processus est un programme en execution avec son espace memoire.
- `fork()` duplique le processus courant.
- Apres un `fork`, le pere et le fils continuent tous les deux apres l'appel.
- Les variables sont copiees, mais les modifications faites par le fils ne changent pas celles du pere.

### Retour de `fork`

```c
pid_t pid = fork();

if (pid < 0) {
    perror("fork");
    exit(EXIT_FAILURE);
}
if (pid == 0) {
    // Code du fils
} else {
    // Code du pere, pid contient le PID du fils
}
```

### Attendre un fils

```c
int status;
pid_t ended = wait(&status);

if (WIFEXITED(status)) {
    printf("Code retour : %d\n", WEXITSTATUS(status));
}
```

`wait(NULL)` attend n'importe quel fils.  
`waitpid(pid, &status, 0)` attend un fils precis.

### `exec` : remplacer le programme courant

La famille `exec` ne cree pas de processus. Elle remplace le code du processus courant.

```c
execlp("ls", "ls", "-l", NULL);
perror("execlp"); // execute uniquement si exec echoue
exit(EXIT_FAILURE);
```

### Variantes de `exec`

- `execl` : arguments listes, chemin exact.
- `execlp` : arguments listes, recherche dans le `PATH`.
- `execv` : arguments dans un tableau, chemin exact.
- `execvp` : arguments dans un tableau, recherche dans le `PATH`.

Exemple avec `execvp` :

```c
char *args[] = {"ps", "aux", NULL};
execvp(args[0], args);
perror("execvp");
exit(EXIT_FAILURE);
```

### Pieges classiques

- Mettre `NULL` a la fin des arguments de `exec`.
- Apres un `exec` reussi, le code suivant n'est jamais execute.
- Sans `wait`, un fils termine peut devenir zombie.
- Si plusieurs `fork` sont dans une boucle, le nombre de processus peut exploser.

---

## 3. Signaux

### Idees cles

- Un signal est une notification asynchrone envoyee a un processus.
- Exemples :
  - `SIGINT` : interruption clavier, souvent `Ctrl+C`.
  - `SIGTERM` : demande de terminaison.
  - `SIGKILL` : terminaison forcee, impossible a intercepter.
  - `SIGCHLD` : envoye au pere quand un fils change d'etat.
  - `SIGHUP` : deconnexion du terminal ou rechargement selon les programmes.

### Installer un gestionnaire simple

```c
void handler(int sig) {
    write(STDOUT_FILENO, "Signal recu\n", 12);
}

signal(SIGINT, handler);
```

### Methode plus propre : `sigaction`

```c
struct sigaction sa;
sa.sa_handler = handler;
sigemptyset(&sa.sa_mask);
sa.sa_flags = 0;

sigaction(SIGINT, &sa, NULL);
```

### Eviter les zombies avec `SIGCHLD`

```c
void handler_chld(int sig) {
    while (waitpid(-1, NULL, WNOHANG) > 0) {
    }
}
```

### Pieges classiques

- Un handler de signal doit faire peu de choses.
- Eviter `printf` dans un handler : preferer `write`.
- `SIGKILL` et `SIGSTOP` ne peuvent pas etre captures.
- Si plusieurs fils terminent presque en meme temps, utiliser une boucle avec `waitpid(..., WNOHANG)`.

---

## 4. Tubes anonymes : `pipe`

### Idees cles

- Un tube anonyme sert a communiquer entre processus apparentes, typiquement pere/fils.
- `pipe(fd)` donne deux descripteurs :
  - `fd[0]` : lecture.
  - `fd[1]` : ecriture.
- Les donnees ecrites dans `fd[1]` sont lues dans `fd[0]`.

### Modele pere/fils

```c
int fd[2];
pipe(fd);

pid_t pid = fork();

if (pid == 0) {
    close(fd[1]);
    char buffer[100];
    int n = read(fd[0], buffer, sizeof(buffer));
    write(STDOUT_FILENO, buffer, n);
    close(fd[0]);
    exit(0);
} else {
    close(fd[0]);
    write(fd[1], "Bonjour\n", 8);
    close(fd[1]);
    wait(NULL);
}
```

### Redirection vers une commande

Pour faire l'equivalent de `cat fichier | wc -l`, on combine `pipe`, `fork`, `dup2` et `exec`.

```c
int p[2];
pipe(p);

if (fork() == 0) {
    dup2(p[1], STDOUT_FILENO);
    close(p[0]);
    close(p[1]);
    execlp("cat", "cat", "fichier.txt", NULL);
    exit(1);
}

if (fork() == 0) {
    dup2(p[0], STDIN_FILENO);
    close(p[0]);
    close(p[1]);
    execlp("wc", "wc", "-l", NULL);
    exit(1);
}

close(p[0]);
close(p[1]);
wait(NULL);
wait(NULL);
```

### Pieges classiques

- Fermer les extremites inutiles, sinon un lecteur peut attendre indefiniment.
- Un tube est un flux d'octets, pas une suite de messages structures.
- `read` peut lire moins que ce qui a ete ecrit.

---

## 5. Tubes nommes : FIFO

### Idees cles

- Une FIFO est un tube nomme visible dans le systeme de fichiers.
- Elle permet de communiquer entre processus non apparentes.
- Creation avec `mkfifo`.

```c
mkfifo("mafifo", 0644);
int fd = open("mafifo", O_WRONLY);
write(fd, "hello", 5);
close(fd);
```

Cote lecteur :

```c
int fd = open("mafifo", O_RDONLY);
char buf[100];
int n = read(fd, buf, sizeof(buf));
write(STDOUT_FILENO, buf, n);
close(fd);
```

### Pieges classiques

- `open` en lecture seule peut bloquer tant qu'il n'y a pas d'ecrivain.
- `open` en ecriture seule peut bloquer tant qu'il n'y a pas de lecteur.
- Supprimer la FIFO avec `unlink` quand elle n'est plus utile.

---

## 6. Threads POSIX

### Idees cles

- Un thread est un fil d'execution dans le meme processus.
- Les threads partagent la memoire globale du processus.
- Chaque thread a sa propre pile.
- Les threads sont plus legers que les processus, mais les donnees partagees creent des risques de concurrence.

### Creation et attente

```c
#include <pthread.h>

void *routine(void *arg) {
    int id = *(int *)arg;
    printf("Thread %d\n", id);
    return NULL;
}

pthread_t th;
int id = 1;
pthread_create(&th, NULL, routine, &id);
pthread_join(th, NULL);
```

Compilation :

```bash
gcc fichier.c -o prog -pthread
```

### Mutex

Un mutex protege une section critique.

```c
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
int compteur = 0;

pthread_mutex_lock(&mutex);
compteur++;
pthread_mutex_unlock(&mutex);
```

### Pieges classiques

- Ne pas passer l'adresse d'une variable de boucle partagee a plusieurs threads sans precaution.
- Toujours liberer un mutex verrouille.
- Une variable globale modifiee par plusieurs threads doit etre protegee.
- `pthread_join` evite que le programme se termine avant les threads.

---

## 7. Semaphores

### Idees cles

- Un semaphore est un compteur protege par le noyau ou la bibliotheque.
- `sem_wait` decremente. Si la valeur est 0, le thread/processus bloque.
- `sem_post` incremente et reveille eventuellement un attenteur.
- Utile pour synchroniser, limiter l'acces a une ressource ou implementer producteur/consommateur.

### Semaphore POSIX non nomme

```c
#include <semaphore.h>

sem_t sem;
sem_init(&sem, 0, 1); // 1 = mutex logique

sem_wait(&sem);
// section critique
sem_post(&sem);

sem_destroy(&sem);
```

### Producteur / consommateur

Pour un buffer de taille `N`, on utilise souvent :

- `mutex` : protege l'acces au buffer.
- `vide` : nombre de places libres, initialise a `N`.
- `plein` : nombre de cases remplies, initialise a `0`.

Producteur :

```c
sem_wait(&vide);
sem_wait(&mutex);
// deposer un element
sem_post(&mutex);
sem_post(&plein);
```

Consommateur :

```c
sem_wait(&plein);
sem_wait(&mutex);
// retirer un element
sem_post(&mutex);
sem_post(&vide);
```

### Pieges classiques

- L'ordre des `sem_wait` est important pour eviter les interblocages.
- Ne pas confondre exclusion mutuelle et synchronisation.
- Un semaphore initialise a `1` peut jouer le role d'un mutex.

---

## 8. Memoire partagee

### Idees cles

- La memoire partagee permet a plusieurs processus d'acceder a une meme zone memoire.
- Elle est plus rapide que les tubes pour de gros volumes, mais demande une synchronisation.
- Sans semaphore ou mutex inter-processus, les acces concurrents peuvent corrompre les donnees.

### Approche POSIX typique

```c
int fd = shm_open("/zone", O_CREAT | O_RDWR, 0644);
ftruncate(fd, sizeof(int));

int *ptr = mmap(NULL, sizeof(int), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
*ptr = 42;

munmap(ptr, sizeof(int));
close(fd);
shm_unlink("/zone");
```

### Pieges classiques

- `shm_open` cree un objet nomme, pas un fichier classique.
- Il faut dimensionner avec `ftruncate`.
- Il faut detacher avec `munmap`.
- Il faut supprimer l'objet avec `shm_unlink` quand il n'est plus utile.

---

## 9. Sockets UDP

### Idees cles

- UDP est sans connexion.
- Pas de garantie de livraison, d'ordre ni d'unicite.
- Tres utile pour des echanges simples, rapides, ou quand l'application gere elle-meme les pertes.
- Un serveur UDP utilise souvent `socket`, `bind`, `recvfrom`, `sendto`.

### Serveur UDP minimal

```c
int s = socket(AF_INET, SOCK_DGRAM, 0);

struct sockaddr_in addr;
memset(&addr, 0, sizeof(addr));
addr.sin_family = AF_INET;
addr.sin_addr.s_addr = INADDR_ANY;
addr.sin_port = htons(5000);

bind(s, (struct sockaddr *)&addr, sizeof(addr));

char buf[1024];
struct sockaddr_in client;
socklen_t len = sizeof(client);

int n = recvfrom(s, buf, sizeof(buf), 0,
                 (struct sockaddr *)&client, &len);

sendto(s, buf, n, 0, (struct sockaddr *)&client, len);
close(s);
```

### Client UDP minimal

```c
int s = socket(AF_INET, SOCK_DGRAM, 0);

struct sockaddr_in srv;
memset(&srv, 0, sizeof(srv));
srv.sin_family = AF_INET;
srv.sin_port = htons(5000);
inet_pton(AF_INET, "127.0.0.1", &srv.sin_addr);

sendto(s, "hello", 5, 0, (struct sockaddr *)&srv, sizeof(srv));
close(s);
```

### Pieges classiques

- Toujours convertir le port avec `htons`.
- Utiliser `inet_pton` pour convertir une adresse IP texte en binaire.
- UDP conserve la notion de datagramme : un `recvfrom` recupere un message.

---

## 10. Sockets TCP

### Idees cles

- TCP est connecte, fiable et ordonne.
- Un serveur TCP suit le schema : `socket`, `bind`, `listen`, `accept`, `read/write`, `close`.
- Un client TCP suit le schema : `socket`, `connect`, `read/write`, `close`.

### Serveur TCP minimal

```c
int s = socket(AF_INET, SOCK_STREAM, 0);

int opt = 1;
setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

struct sockaddr_in addr;
memset(&addr, 0, sizeof(addr));
addr.sin_family = AF_INET;
addr.sin_addr.s_addr = INADDR_ANY;
addr.sin_port = htons(5000);

bind(s, (struct sockaddr *)&addr, sizeof(addr));
listen(s, 10);

int client = accept(s, NULL, NULL);
write(client, "hello\n", 6);

close(client);
close(s);
```

### Client TCP minimal

```c
int s = socket(AF_INET, SOCK_STREAM, 0);

struct sockaddr_in srv;
memset(&srv, 0, sizeof(srv));
srv.sin_family = AF_INET;
srv.sin_port = htons(5000);
inet_pton(AF_INET, "127.0.0.1", &srv.sin_addr);

connect(s, (struct sockaddr *)&srv, sizeof(srv));
write(s, "hello", 5);
close(s);
```

### Pieges classiques

- `listen` n'accepte pas une connexion : il met la socket en mode ecoute.
- `accept` cree une nouvelle socket pour communiquer avec un client.
- Le serveur garde la socket d'ecoute ouverte pour accepter d'autres clients.
- TCP est un flux : un `read` ne correspond pas forcement a un `write`.

---

## 11. Multiplexage : `select`

### Idees cles

- `select` permet d'attendre plusieurs descripteurs en meme temps.
- Utile pour un serveur qui gere plusieurs clients sans creer un thread/processus par client.
- On surveille des ensembles de descripteurs avec `fd_set`.

### Modele general

```c
fd_set readfds;
FD_ZERO(&readfds);
FD_SET(sock_ecoute, &readfds);
FD_SET(client_fd, &readfds);

int maxfd = sock_ecoute > client_fd ? sock_ecoute : client_fd;

int r = select(maxfd + 1, &readfds, NULL, NULL, NULL);

if (FD_ISSET(sock_ecoute, &readfds)) {
    int c = accept(sock_ecoute, NULL, NULL);
}

if (FD_ISSET(client_fd, &readfds)) {
    char buf[1024];
    int n = read(client_fd, buf, sizeof(buf));
}
```

### Pieges classiques

- `select` modifie les ensembles : il faut les reconstruire avant chaque appel.
- Le premier argument est `max_fd + 1`.
- Si `read` renvoie `0` sur une socket TCP, le client a ferme la connexion.

---

## 12. Comparaisons a savoir faire

### Processus vs thread

| Point | Processus | Thread |
| --- | --- | --- |
| Memoire | Separee | Partagee |
| Creation | Plus couteuse | Plus legere |
| Communication | IPC necessaire | Variables partagees |
| Isolation | Forte | Faible |
| Risque principal | Zombies, IPC | Race conditions |

### Tube vs FIFO

| Point | Tube anonyme | FIFO |
| --- | --- | --- |
| Nom dans le systeme de fichiers | Non | Oui |
| Processus apparentes | Oui, typiquement | Pas necessaire |
| Creation | `pipe` | `mkfifo` |
| Acces | Descripteurs herites | `open` par nom |

### UDP vs TCP

| Point | UDP | TCP |
| --- | --- | --- |
| Connexion | Non | Oui |
| Fiabilite | Non garantie | Garantie |
| Ordre | Non garanti | Garanti |
| Donnees | Datagrammes | Flux |
| Appels typiques | `sendto`, `recvfrom` | `connect`, `accept`, `read`, `write` |

### Mutex vs semaphore

| Point | Mutex | Semaphore |
| --- | --- | --- |
| Role principal | Exclusion mutuelle | Synchronisation/compteur |
| Valeur | Verrouille/deverrouille | Entier |
| Proprietaire | Souvent le thread qui verrouille | Pas forcement |
| Exemple | Proteger un compteur | Producteur/consommateur |

---

## 13. Methodes pour les exercices d'examen

### Quand on te demande de creer un fils

1. Appeler `fork`.
2. Tester `pid < 0`.
3. Ecrire le code du fils dans `pid == 0`.
4. Ecrire le code du pere dans `pid > 0`.
5. Ajouter `wait` si le pere doit attendre.

### Quand on te demande une redirection

1. Ouvrir le fichier ou creer le tube.
2. Utiliser `dup2`.
3. Fermer les descripteurs inutiles.
4. Appeler `exec` si on lance une commande.

### Quand on te demande une communication pere/fils

1. Creer le `pipe` avant le `fork`.
2. Fermer les extremites inutiles dans chaque processus.
3. Lire/ecrire.
4. Fermer les descripteurs.
5. Le pere attend le fils.

### Quand on te demande un serveur TCP

1. `socket`
2. `setsockopt` avec `SO_REUSEADDR` si besoin
3. `bind`
4. `listen`
5. boucle avec `accept`
6. traiter le client
7. fermer la socket client

### Quand on te demande un serveur UDP

1. `socket`
2. `bind`
3. boucle avec `recvfrom`
4. repondre avec `sendto`

---

## 14. Erreurs d'examen frequentes

- Oublier les `#include` :
  - fichiers : `<fcntl.h>`, `<unistd.h>`, `<sys/stat.h>`
  - processus : `<sys/types.h>`, `<sys/wait.h>`, `<unistd.h>`
  - signaux : `<signal.h>`
  - threads : `<pthread.h>`
  - semaphores : `<semaphore.h>`
  - sockets : `<sys/socket.h>`, `<netinet/in.h>`, `<arpa/inet.h>`
- Oublier `NULL` dans les appels `exec`.
- Confondre `bind` et `connect`.
- Confondre socket d'ecoute TCP et socket client retournee par `accept`.
- Ne pas convertir les ports avec `htons`.
- Ne pas fermer les bons descripteurs dans les pipes.
- Supposer qu'un seul `read` TCP lit tout le message.
- Utiliser une variable partagee entre threads sans mutex/semaphore.
- Oublier `-pthread` a la compilation.

---

## 15. Mini check-list avant de rendre un programme C systeme

- Les retours d'appels systeme critiques sont testes.
- Les fichiers/sockets/descripteurs inutiles sont fermes.
- Les processus fils sont attendus si necessaire.
- Les buffers sont dimensionnes et initialises si besoin.
- Les chaines terminees par `\0` le sont vraiment.
- Les ports reseau passent par `htons`.
- Les adresses IP passent par `inet_pton`.
- Les sections critiques sont protegees.
- Le programme compile sans warnings importants.

Commande conseillee :

```bash
gcc -Wall -Wextra -g fichier.c -o programme -pthread
```

---

## 16. Questions rapides pour s'entrainer

1. Que renvoie `fork` dans le pere ? Dans le fils ?
2. Pourquoi faut-il appeler `wait` ?
3. Quelle difference entre `execlp` et `execv` ?
4. Que fait `dup2(fd, STDOUT_FILENO)` ?
5. Pourquoi fermer `fd[1]` dans un processus qui lit un pipe ?
6. Pourquoi `SIGKILL` ne peut-il pas etre intercepte ?
7. Quelle difference entre TCP et UDP ?
8. Pourquoi `accept` renvoie-t-il une nouvelle socket ?
9. Pourquoi un `read` TCP peut-il lire moins que le message attendu ?
10. Pourquoi un mutex est-il necessaire avec des threads ?
11. Quel est le role des semaphores `vide` et `plein` dans producteur/consommateur ?
12. Pourquoi faut-il reconstruire les `fd_set` avant chaque `select` ?

---

## 17. Reponses courtes

1. `fork` renvoie le PID du fils dans le pere, `0` dans le fils, `-1` en cas d'erreur.
2. `wait` recupere l'etat du fils et evite les zombies.
3. `execlp` prend une liste d'arguments et cherche dans le `PATH`; `execv` prend un tableau et demande un chemin exact.
4. La sortie standard devient le descripteur `fd`.
5. Pour que le lecteur puisse recevoir la fin de fichier quand tous les ecrivains sont fermes.
6. Le noyau impose `SIGKILL`; le processus ne peut pas le traiter.
7. TCP est fiable et connecte; UDP est sans connexion et non garanti.
8. La socket d'ecoute reste disponible; la nouvelle socket sert a discuter avec ce client.
9. TCP est un flux d'octets, pas un protocole de messages.
10. Pour eviter que plusieurs threads modifient la meme donnee en meme temps.
11. `vide` compte les places libres; `plein` compte les elements disponibles.
12. Parce que `select` modifie les ensembles passes en parametre.
