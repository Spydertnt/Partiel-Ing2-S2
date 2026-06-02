# Correction - Programmation Systeme et Reseau

Sujet corrige : `Examen de ProgSystemeEtReseau 2023_sessionNormale2.pdf`  
Session : Normale 2022-2023

---

## Exercice 1 - Questions de cours

### 1. Ignorer un signal avec un handler

Pour ignorer un signal, on peut installer le comportement `SIG_IGN`.

```c
#include <signal.h>

int main() {
    signal(SIGINT, SIG_IGN);

    while (1) {
    }

    return 0;
}
```

Ici, `SIGINT` correspond souvent a `Ctrl+C`. Le programme l'ignore.

Avec un handler personnel, on peut aussi ne rien faire :

```c
void handler(int sig) {
    (void)sig;
}

signal(SIGINT, handler);
```

---

### 2. Utilite de `dup` et `dup2`

`dup` et `dup2` dupliquent un descripteur de fichier.

`dup(fd)` renvoie le plus petit descripteur libre.

```c
int fd2 = dup(fd);
```

`dup2(fd, nouveau_fd)` force la copie vers un descripteur precis.

```c
dup2(fd, STDOUT_FILENO);
```

Difference :

- `dup` choisit automatiquement le nouveau numero ;
- `dup2` permet de choisir le numero, par exemple `0`, `1` ou `2`.

Utilite classique : rediriger l'entree ou la sortie standard.

---

### 3. Bloquer l'acces au clavier

Le clavier correspond a l'entree standard, c'est-a-dire le descripteur `0`.

Une methode simple consiste a fermer l'entree standard :

```c
#include <unistd.h>
#include <stdio.h>

int main() {
    char buffer[100];

    close(STDIN_FILENO);

    printf("Clavier bloque\n");
    scanf("%99s", buffer); /* echoue car stdin est ferme */

    return 0;
}
```

On peut aussi rediriger l'entree standard vers `/dev/null` :

```c
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd = open("/dev/null", O_RDONLY);
    dup2(fd, STDIN_FILENO);
    close(fd);

    return 0;
}
```

---

### 4. Difference entre processus et thread

Un processus possede son propre espace memoire. Deux processus sont isoles.

Un thread appartient a un processus et partage la memoire avec les autres threads du meme processus.

Phrase courte :

> Un processus est independant avec sa propre memoire, alors qu'un thread est plus leger et partage la memoire de son processus.

---

### 5. Utilite des semaphores

Les semaphores servent a synchroniser des processus ou des threads et a proteger les ressources partagees.

Exemple :

- une ressource unique : semaphore initialise a `1` ;
- plusieurs ressources disponibles : semaphore initialise a `N`.

Primitives :

```c
sem_init(&sem, 0, valeur);
sem_wait(&sem);
sem_post(&sem);
sem_destroy(&sem);
```

---

## Exercice 2 - Cabines d'essayage avec signaux

Variables globales supposees :

```c
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

int nbCabinesDisponibles;
pid_t pidEntree;
```

### 1. Handler de `SIGUSR1` dans le processus Gestion

Quand Gestion recoit `SIGUSR1`, cela signifie qu'un client veut entrer.

- si une cabine est disponible : on decremente le nombre de cabines et on repond `SIGUSR2` ;
- sinon : on repond `SIGUSR1`.

```c
void handler_gestion_sigusr1(int sig) {
    (void)sig;

    if (nbCabinesDisponibles > 0) {
        nbCabinesDisponibles--;
        printf("Entree autorisee\n");
        kill(pidEntree, SIGUSR2);
    } else {
        printf("Entree interdite\n");
        kill(pidEntree, SIGUSR1);
    }
}
```

Remarque : dans un vrai programme, `printf` dans un handler est a eviter, mais dans un examen on l'accepte souvent pour montrer le comportement.

Pour une version plus propre, on utiliserait `write`.

---

### Handler de `SIGUSR2` dans Gestion pour une sortie

Quand un client quitte une cabine, le processus Sortie envoie `SIGUSR2` au pere.

```c
void handler_gestion_sigusr2(int sig) {
    (void)sig;

    nbCabinesDisponibles++;
    printf("Une cabine est liberee\n");
}
```

---

### 2. Handler unique de `SIGUSR1` et `SIGUSR2` dans Entree

Dans le processus Entree :

- `SIGUSR2` signifie entree autorisee ;
- `SIGUSR1` signifie entree interdite.

```c
void handler_entree(int sig) {
    if (sig == SIGUSR2) {
        printf("Entree autorisee\n");
    } else if (sig == SIGUSR1) {
        printf("Entree interdite\n");
    }
}
```

Installation :

```c
signal(SIGUSR1, handler_entree);
signal(SIGUSR2, handler_entree);
```

---

### 3. Autres moyens de communication sans signaux

On peut proposer plusieurs IPC.

#### Tubes anonymes

```text
Processus Entree  --->  pipe  --->  Processus Gestion
```

Utiles entre processus apparentes, par exemple pere/fils.

#### Tubes nommes FIFO

```text
Processus A  --->  FIFO nommee  --->  Processus B
```

Utiles meme si les processus ne sont pas parents.

#### Files de messages

```text
Processus A  --->  [file de messages]  --->  Processus B
```

Chaque message garde un type et un contenu.

#### Memoire partagee

```text
Processus A  <--- zone memoire commune --->  Processus B
```

Rapide, mais necessite souvent des semaphores pour eviter les acces concurrents.

#### Sockets

```text
Client  <--- TCP/UDP --->  Serveur
```

Utiles pour communiquer sur la meme machine ou sur un reseau.

---

## Exercice 3 - Jeu du plus grand / plus petit avec deux processus

On peut choisir une solution avec deux pipes anonymes :

- un pipe joueur vers ordinateur ;
- un pipe ordinateur vers joueur.

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <time.h>

int main() {
    int j2o[2];
    int o2j[2];
    pid_t pid;

    pipe(j2o);
    pipe(o2j);

    pid = fork();

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {
        int proposition;
        int reponse = 1;

        close(j2o[0]);
        close(o2j[1]);

        while (reponse != 0) {
            printf("Entrer un nombre : ");
            scanf("%d", &proposition);

            write(j2o[1], &proposition, sizeof(int));
            read(o2j[0], &reponse, sizeof(int));

            if (reponse > 0) {
                printf("Le nombre mystere est plus grand\n");
            } else if (reponse < 0) {
                printf("Le nombre mystere est plus petit\n");
            } else {
                printf("Trouve !\n");
            }
        }

        close(j2o[1]);
        close(o2j[0]);
        exit(EXIT_SUCCESS);
    } else {
        int mystere;
        int proposition;
        int reponse;

        close(j2o[1]);
        close(o2j[0]);

        srand(time(NULL));
        mystere = rand() % 100 + 1;

        do {
            read(j2o[0], &proposition, sizeof(int));

            if (proposition < mystere) {
                reponse = 1;
            } else if (proposition > mystere) {
                reponse = -1;
            } else {
                reponse = 0;
            }

            write(o2j[1], &reponse, sizeof(int));
        } while (reponse != 0);

        close(j2o[0]);
        close(o2j[1]);
        wait(NULL);
    }

    return 0;
}
```

Explication :

- le fils represente le joueur ;
- le pere represente l'ordinateur ;
- le joueur envoie une proposition ;
- l'ordinateur repond `1`, `-1` ou `0`.

---

## Exercice 4 - TCP et UDP

### Partie 1 - Client TCP complete

```c
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/socket.h>

char* id = 0;
short sport = 0;
int sock = 0;

int main(int argc, char** argv) {
    struct sockaddr_in client;
    struct sockaddr_in serveur;
    int ret, len;

    if (argc != 4) {
        fprintf(stderr, "usage: %s id serveur port\n", argv[0]);
        exit(1);
    }

    id = argv[1];
    sport = atoi(argv[3]);

    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        fprintf(stderr, "%s: socket %s\n", argv[0], strerror(errno));
        exit(1);
    }

    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(sport);
    inet_aton(argv[2], &serveur.sin_addr);

    if (connect(sock, (struct sockaddr *)&serveur, sizeof(serveur)) == -1) {
        fprintf(stderr, "%s: connect %s\n", argv[0], strerror(errno));
        exit(1);
    }

    len = sizeof(client);
    getsockname(sock, (struct sockaddr *)&client, (socklen_t *)&len);

    while (1) {
        char buf_read[256], buf_write[256];

        printf("donner le message a envoyer: ");
        scanf("%255s", buf_write);

        ret = write(sock, buf_write, strlen(buf_write) + 1);
        if (ret <= 0) {
            printf("\n%s: erreur dans write (num=%d, mess=%s)\n",
                   argv[0], ret, strerror(errno));
            continue;
        }

        ret = read(sock, buf_read, sizeof(buf_read) - 1);
        if (ret <= 0) {
            printf("\n%s: erreur dans read (num=%d, mess=%s)\n",
                   argv[0], ret, strerror(errno));
            continue;
        }

        buf_read[ret] = '\0';
        printf("le message recu : %s\n", buf_read);
    }

    close(sock);
    return 0;
}
```

---

### Partie 2 - Client UDP complete

Le sujet donne un client qui commence par recevoir, puis envoie une reponse.

```c
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/socket.h>

char* id = 0;
short sport = 0;
int sock = 0;

int main(int argc, char** argv) {
    struct sockaddr_in ClientUDP;
    struct sockaddr_in serveur;
    int nb_message = 0;
    int ret, len;
    socklen_t serveur_len = sizeof(serveur);
    char buf_read[256], buf_write[256];

    if (argc != 4) {
        fprintf(stderr, "usage: %s id host sport\n", argv[0]);
        exit(1);
    }

    id = argv[1];
    sport = atoi(argv[3]);

    if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        fprintf(stderr, "\n%s: socket %s\n", argv[0], strerror(errno));
        exit(1);
    }

    len = sizeof(ClientUDP);
    getsockname(sock, (struct sockaddr *)&ClientUDP, (socklen_t *)&len);

    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(sport);
    inet_aton(argv[2], &serveur.sin_addr);

    while (nb_message < 3) {
        ret = recvfrom(sock, buf_read, sizeof(buf_read) - 1, 0,
                       (struct sockaddr *)&serveur, &serveur_len);
        if (ret <= 0) {
            printf("\n%s: erreur dans recvfrom (num=%d, mess=%s)\n",
                   argv[0], ret, strerror(errno));
            continue;
        }

        buf_read[ret] = '\0';

        printf("\nclient %2s recoit de (%s:%4d) : %s\n",
               id, inet_ntoa(serveur.sin_addr), ntohs(serveur.sin_port), buf_read);

        sprintf(buf_write, "#%2s=%03d", id, nb_message++);

        ret = sendto(sock, buf_write, strlen(buf_write) + 1, 0,
                     (struct sockaddr *)&serveur, sizeof(serveur));
        if (ret <= 0) {
            printf("\n%s: erreur dans sendto (num=%d, mess=%s)\n",
                   argv[0], ret, strerror(errno));
            continue;
        }
    }

    printf("J'ai fini, au revoir\n");
    close(sock);
    return 0;
}
```

Remarque : pour qu'un client UDP puisse recevoir le premier message du serveur, il doit souvent etre connu du serveur ou envoyer un premier message. Dans un vrai programme, on ferait souvent un premier `sendto` avant le premier `recvfrom`.

---

### Partie 2 - Serveur UDP complete

```c
#include <stdio.h>
#include <errno.h>
#include <netinet/in.h>
#include <string.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/socket.h>

char* id = 0;
short port = 0;
int sock = 0;
int nb_reponse = 0;
char buf_read[256], buf_write[256];

int main(int argc, char** argv) {
    int ret;
    struct sockaddr_in serveur;

    if (argc != 3) {
        fprintf(stderr, "usage: %s id port\n", argv[0]);
        exit(1);
    }

    id = argv[1];
    port = atoi(argv[2]);

    if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        fprintf(stderr, "%s: socket %s\n", argv[0], strerror(errno));
        exit(1);
    }

    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(port);
    serveur.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock, (struct sockaddr *)&serveur, sizeof(serveur)) < 0) {
        fprintf(stderr, "%s: bind %s\n", argv[0], strerror(errno));
        exit(1);
    }

    while (1) {
        struct sockaddr_in client;
        socklen_t client_len = sizeof(client);

        ret = recvfrom(sock, buf_read, sizeof(buf_read) - 1, 0,
                       (struct sockaddr *)&client, &client_len);
        if (ret <= 0) {
            printf("%s: recvfrom=%d:%s\n", argv[0], ret, strerror(errno));
            continue;
        }

        buf_read[ret] = '\0';

        printf("serveur %s (%s:%d) recu le message %s\n",
               id, inet_ntoa(client.sin_addr), ntohs(client.sin_port), buf_read);

        sprintf(buf_write, "#%2s reponse%03d#", id, nb_reponse++);

        ret = sendto(sock, buf_write, strlen(buf_write) + 1, 0,
                     (struct sockaddr *)&client, client_len);
        if (ret <= 0) {
            printf("%s: sendto=%d: %s\n", argv[0], ret, strerror(errno));
            continue;
        }

        sleep(6);
    }

    return 0;
}
```

---

### Messages affiches avec `127.0.0.1` et port `7000`

Si le serveur est lance par exemple avec :

```bash
./serveur S1 7000
```

et le client :

```bash
./client C1 127.0.0.1 7000
```

Le serveur affiche des messages du type :

```text
serveur S1 (127.0.0.1:port_client) recu le message #C1=000
serveur S1 (127.0.0.1:port_client) recu le message #C1=001
serveur S1 (127.0.0.1:port_client) recu le message #C1=002
```

Le client affiche des messages du type :

```text
client C1 recoit de (127.0.0.1:7000) : #S1 reponse000#
client C1 recoit de (127.0.0.1:7000) : #S1 reponse001#
client C1 recoit de (127.0.0.1:7000) : #S1 reponse002#
```

Attention : le port cote client est souvent un port ephemere choisi automatiquement par le systeme.

---

### Modifier le client pour terminer quand l'utilisateur tape `FIN`

Version avec saisie utilisateur :

```c
while (1) {
    printf("Message a envoyer : ");
    scanf("%255s", buf_write);

    if (strcmp(buf_write, "FIN") == 0) {
        sendto(sock, buf_write, strlen(buf_write) + 1, 0,
               (struct sockaddr *)&serveur, sizeof(serveur));
        break;
    }

    sendto(sock, buf_write, strlen(buf_write) + 1, 0,
           (struct sockaddr *)&serveur, sizeof(serveur));

    ret = recvfrom(sock, buf_read, sizeof(buf_read) - 1, 0,
                   (struct sockaddr *)&serveur, &serveur_len);
    if (ret > 0) {
        buf_read[ret] = '\0';
        printf("Reponse serveur : %s\n", buf_read);
    }
}

close(sock);
```

---

## Resume a retenir

### TCP

Client TCP :

```c
socket(AF_INET, SOCK_STREAM, 0);
connect(sock, (struct sockaddr *)&serveur, sizeof(serveur));
write(sock, buf, strlen(buf) + 1);
read(sock, buf, sizeof(buf));
```

Serveur TCP :

```c
socket(AF_INET, SOCK_STREAM, 0);
bind(sock, (struct sockaddr *)&serveur, sizeof(serveur));
listen(sock, 5);
accept(sock, NULL, NULL);
```

### UDP

```c
socket(AF_INET, SOCK_DGRAM, 0);
bind(sock, (struct sockaddr *)&serveur, sizeof(serveur));
sendto(sock, buf, strlen(buf) + 1, 0, (struct sockaddr *)&dest, sizeof(dest));
recvfrom(sock, buf, sizeof(buf), 0, (struct sockaddr *)&src, &len);
```

### Signaux

```c
signal(SIGUSR1, handler);
kill(pid, SIGUSR2);
```

### Pipe

```c
int fd[2];
pipe(fd);
```

- `fd[0]` : lecture ;
- `fd[1]` : ecriture.

