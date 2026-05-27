# Correction - Programmation Systeme et Reseau

Sujet corrige : `Examen de ProgSystemeEtReseau_Session_Normale.pdf`  
Session : Normale 2024-2025

---

## Exercice 1 - Questions de cours

### 1. Role de `exec()` en C

La famille des fonctions `exec` remplace le programme courant par un autre programme.

Points importants :

- le processus garde le meme PID ;
- le code, les donnees et la pile sont remplaces ;
- si `exec` reussit, elle ne revient pas ;
- si `exec` echoue, elle renvoie `-1`.

Exemple classique :

```c
execlp("ls", "ls", "-l", NULL);
perror("execlp"); /* execute seulement si execlp echoue */
```

---

### 2. Processus ou threads pour des taches paralleles

Avantages des processus :

- meilleure isolation memoire : un processus qui plante ne corrompt pas directement les autres ;
- plus adapte pour executer des programmes differents avec `fork` puis `exec`.

Inconvenients des processus :

- creation et changement de contexte plus couteux que pour les threads ;
- communication plus lourde : pipes, sockets, memoire partagee, etc.

Avantages des threads :

- plus legers a creer ;
- partage direct des variables globales et de la memoire du processus.

Inconvenients des threads :

- risque de concurrence sur les variables partagees ;
- une erreur memoire dans un thread peut faire planter tout le processus.

---

### 3. Processus zombie

Un processus zombie est un processus fils termine, mais dont le pere n'a pas encore recupere le code de retour avec `wait` ou `waitpid`.

Le zombie ne s'execute plus, mais il garde une entree dans la table des processus pour que le pere puisse lire son statut de fin.

Pour l'eviter :

```c
wait(NULL);
waitpid(pid, NULL, 0);
```

Dans un serveur multi-clients, on peut aussi traiter `SIGCHLD` :

```c
while (waitpid(-1, NULL, WNOHANG) > 0) {
}
```

---

### 4. Role des signaux

Les signaux servent a notifier un processus qu'un evenement est arrive.

Exemples :

- `SIGINT` : interruption clavier, souvent `Ctrl+C` ;
- `SIGQUIT` : interruption avec quit, souvent `Ctrl+\` ;
- `SIGCHLD` : un processus fils s'est termine ;
- `SIGALRM` : fin d'une minuterie.

Un programme peut garder le comportement par defaut, ignorer le signal ou installer un handler.

---

### 5. Comportement par defaut de `SIGINT`

Par defaut, `SIGINT` termine le processus.

Il est generalement envoye par `Ctrl+C` dans le terminal.

---

## Exercice 2 - Pipes, processus, threads et semaphores

### Partie 1 - Deux pipes anonymes pere/fils

Objectif :

- le pere envoie une chaine au fils avec un premier pipe ;
- le fils transforme la chaine en majuscules ;
- le fils renvoie la chaine au pere avec un deuxieme pipe ;
- le pere affiche le resultat.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/wait.h>

int main() {
    int p_to_f[2];
    int f_to_p[2];
    pid_t pid;
    char message[256];
    char buffer[256];
    int n;
    int i;

    if (pipe(p_to_f) == -1) {
        perror("pipe pere vers fils");
        exit(EXIT_FAILURE);
    }

    if (pipe(f_to_p) == -1) {
        perror("pipe fils vers pere");
        exit(EXIT_FAILURE);
    }

    pid = fork();
    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {
        /* Fils : lit dans p_to_f[0] et ecrit dans f_to_p[1]. */
        close(p_to_f[1]);
        close(f_to_p[0]);

        n = read(p_to_f[0], buffer, sizeof(buffer) - 1);
        if (n > 0) {
            buffer[n] = '\0';

            for (i = 0; buffer[i] != '\0'; i++) {
                buffer[i] = toupper((unsigned char)buffer[i]);
            }

            write(f_to_p[1], buffer, strlen(buffer) + 1);
        }

        close(p_to_f[0]);
        close(f_to_p[1]);
        exit(EXIT_SUCCESS);
    }

    /* Pere : ecrit dans p_to_f[1] et lit dans f_to_p[0]. */
    close(p_to_f[0]);
    close(f_to_p[1]);

    printf("Donner une chaine : ");
    scanf("%255s", message);

    write(p_to_f[1], message, strlen(message) + 1);

    n = read(f_to_p[0], buffer, sizeof(buffer) - 1);
    if (n > 0) {
        buffer[n] = '\0';
        printf("Chaine modifiee : %s\n", buffer);
    }

    close(p_to_f[1]);
    close(f_to_p[0]);

    wait(NULL);
    return 0;
}
```

Points importants :

- un pipe est unidirectionnel ;
- `fd[0]` sert a lire, `fd[1]` sert a ecrire ;
- comme il faut communiquer dans les deux sens, on utilise deux pipes ;
- chaque processus ferme les extremites qu'il n'utilise pas.

---

### Partie 2 - Trains A vers B et B vers A

On veut autoriser plusieurs trains dans le meme sens, mais jamais deux sens opposes en meme temps.

Principe :

- `voie` protege la voie contre le sens oppose ;
- `mutexAB` protege le compteur des trains A vers B ;
- `mutexBA` protege le compteur des trains B vers A ;
- le premier train d'un sens prend la voie ;
- le dernier train d'un sens libere la voie.

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#define NB_TRAINS 6

sem_t voie;
sem_t mutexAB;
sem_t mutexBA;

int nbAB = 0;
int nbBA = 0;

void *train_A_vers_B(void *arg) {
    int id = *(int *)arg;

    printf("Train AB %d demande l'acces par A\n", id);

    sem_wait(&mutexAB);
    nbAB++;
    if (nbAB == 1) {
        /* Premier train A->B : il bloque le sens oppose. */
        sem_wait(&voie);
    }
    sem_post(&mutexAB);

    printf("Train AB %d circule de A vers B\n", id);
    sleep(1);
    printf("Train AB %d sort par B\n", id);

    sem_wait(&mutexAB);
    nbAB--;
    if (nbAB == 0) {
        /* Dernier train A->B : il libere la voie. */
        sem_post(&voie);
    }
    sem_post(&mutexAB);

    return NULL;
}

void *train_B_vers_A(void *arg) {
    int id = *(int *)arg;

    printf("Train BA %d demande l'acces par B\n", id);

    sem_wait(&mutexBA);
    nbBA++;
    if (nbBA == 1) {
        /* Premier train B->A : il bloque le sens oppose. */
        sem_wait(&voie);
    }
    sem_post(&mutexBA);

    printf("Train BA %d circule de B vers A\n", id);
    sleep(1);
    printf("Train BA %d sort par A\n", id);

    sem_wait(&mutexBA);
    nbBA--;
    if (nbBA == 0) {
        /* Dernier train B->A : il libere la voie. */
        sem_post(&voie);
    }
    sem_post(&mutexBA);

    return NULL;
}

int main() {
    pthread_t th[NB_TRAINS];
    int ids[NB_TRAINS];
    int i;

    sem_init(&voie, 0, 1);
    sem_init(&mutexAB, 0, 1);
    sem_init(&mutexBA, 0, 1);

    for (i = 0; i < NB_TRAINS; i++) {
        ids[i] = i + 1;
        if (i % 2 == 0) {
            pthread_create(&th[i], NULL, train_A_vers_B, &ids[i]);
        } else {
            pthread_create(&th[i], NULL, train_B_vers_A, &ids[i]);
        }
    }

    for (i = 0; i < NB_TRAINS; i++) {
        pthread_join(th[i], NULL);
    }

    sem_destroy(&voie);
    sem_destroy(&mutexAB);
    sem_destroy(&mutexBA);

    return 0;
}
```

Remarque : cette solution gere l'exclusion entre les deux sens. Elle ne garantit pas forcement l'absence de famine si des trains d'un sens arrivent sans arret.

---

## Exercice 3 - Signaux

### 1. Interrompre un calcul avec `CTRL+C`

On installe un handler sur `SIGINT`. Le handler ne fait que poser un drapeau. Le `main` teste ensuite ce drapeau et demande a l'utilisateur s'il veut continuer ou arreter.

```c
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

volatile sig_atomic_t interruption = 0;

int calculcomplexe(int i) {
    sleep(1);
    return i * i;
}

void handler_sigint(int sig) {
    (void)sig;
    interruption = 1;
}

int main(void) {
    int i;
    int tab[100];
    char choix;

    signal(SIGINT, handler_sigint);

    for (i = 0; i < 100; i++) {
        tab[i] = calculcomplexe(i);

        if (interruption) {
            interruption = 0;

            printf("\nInterruption demandee. Continuer le calcul ? (o/n) ");
            scanf(" %c", &choix);

            if (choix != 'o' && choix != 'O') {
                printf("Calcul arrete definitivement.\n");
                return EXIT_FAILURE;
            }

            printf("Calcul confirme, reprise...\n");
        }
    }

    printf("Calcul termine.\n");
    return EXIT_SUCCESS;
}
```

Points importants :

- `SIGINT` est declenche par `CTRL+C` ;
- le handler modifie une variable globale de type `volatile sig_atomic_t` ;
- le dialogue avec l'utilisateur est fait dans le `main`, pas directement dans le handler.

---

### 2. Programme `ping.c` avec `SIGQUIT`

Le programme affiche `ping !` quand il recoit `SIGQUIT`, puis envoie `SIGQUIT` a un autre processus.

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

pid_t cible;

void handler_sigquit(int sig) {
    (void)sig;
    write(STDOUT_FILENO, "ping !\n", 7);
    kill(cible, SIGQUIT);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s pid_cible\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    cible = (pid_t)atoi(argv[1]);

    signal(SIGQUIT, handler_sigquit);

    printf("Mon PID est %d\n", getpid());
    printf("J'enverrai SIGQUIT au processus %d\n", cible);

    while (1) {
        pause();
    }

    return 0;
}
```

Utilisation typique :

- lancer deux instances du programme ;
- donner a chaque instance le PID de l'autre ;
- envoyer un premier `SIGQUIT` a l'une des deux pour demarrer l'echange.

---

## Exercice 4 - Client/serveur TCP de messages

### 1. Role de `inet_aton` et `getsockname`

`inet_aton` convertit une adresse IPv4 sous forme de chaine en adresse binaire utilisable dans `struct sockaddr_in`.

Exemple :

```c
inet_aton("127.0.0.1", &serveur.sin_addr);
```

`getsockname` permet de connaitre l'adresse locale et le port local associes a une socket.

Exemple :

```c
getsockname(sock, (struct sockaddr *)&client, &len);
```

Dans un client TCP, cela permet notamment de connaitre le port local choisi automatiquement par le systeme apres `connect`.

---

### 2. Client TCP complete

```c
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <unistd.h>

char *id = 0;
short sport = 0;
int sock = 0;

int main(int argc, char **argv) {
    struct sockaddr_in client;
    struct sockaddr_in serveur;
    int ret;
    socklen_t len;

    if (argc != 4) {
        fprintf(stderr, "usage: %s id serveur port\n", argv[0]);
        exit(1);
    }

    id = argv[1];
    sport = atoi(argv[3]);

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
        fprintf(stderr, "%s: socket %s\n", argv[0], strerror(errno));
        exit(1);
    }

    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(sport);
    inet_aton(argv[2], &serveur.sin_addr);

    ret = connect(sock, (struct sockaddr *)&serveur, sizeof(serveur));
    if (ret == -1) {
        fprintf(stderr, "%s: connect %s\n", argv[0], strerror(errno));
        close(sock);
        exit(1);
    }

    len = sizeof(client);
    getsockname(sock, (struct sockaddr *)&client, &len);

    while (1) {
        char buf_read[256];
        char buf_write[256];

        printf("donner le message a envoyer: ");
        scanf("%255s", buf_write);

        printf("le message a envoyer par le client %s : %s\n", id, buf_write);

        ret = write(sock, buf_write, strlen(buf_write) + 1);
        if (ret < (int)strlen(buf_write) + 1) {
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
        printf("le message recu: %s\n", buf_read);
    }

    close(sock);
    printf("j ai fini, au revoir\n");
    return 0;
}
```

Etapes du client :

- `socket` cree une socket TCP ;
- `connect` se connecte au serveur ;
- `write` envoie un message ;
- `read` lit la reponse du serveur.

---

### 3. Serveur TCP multi-clients

Version avec `fork` : le pere accepte les clients, chaque fils traite un client.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>
#include <arpa/inet.h>
#include <netinet/in.h>

void handler_chld(int sig) {
    (void)sig;
    while (waitpid(-1, NULL, WNOHANG) > 0) {
    }
}

void traiter_client(int client) {
    char buffer[256];
    char reponse[300];
    int n;

    while ((n = read(client, buffer, sizeof(buffer) - 1)) > 0) {
        buffer[n] = '\0';
        printf("Message recu : %s\n", buffer);

        snprintf(reponse, sizeof(reponse), "Serveur a recu : %s", buffer);
        write(client, reponse, strlen(reponse) + 1);
    }

    close(client);
}

int main(int argc, char *argv[]) {
    int sock;
    int client;
    int port;
    pid_t pid;
    struct sockaddr_in serveur;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s port\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    port = atoi(argv[1]);

    signal(SIGCHLD, handler_chld);

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(port);
    serveur.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock, (struct sockaddr *)&serveur, sizeof(serveur)) == -1) {
        perror("bind");
        close(sock);
        exit(EXIT_FAILURE);
    }

    if (listen(sock, 5) == -1) {
        perror("listen");
        close(sock);
        exit(EXIT_FAILURE);
    }

    while (1) {
        client = accept(sock, NULL, NULL);
        if (client == -1) {
            perror("accept");
            continue;
        }

        pid = fork();
        if (pid == -1) {
            perror("fork");
            close(client);
            continue;
        }

        if (pid == 0) {
            close(sock);
            traiter_client(client);
            exit(EXIT_SUCCESS);
        }

        close(client);
    }

    close(sock);
    return 0;
}
```

Points importants :

- `bind` associe le serveur a un port ;
- `listen` met la socket en attente de connexions ;
- `accept` accepte une connexion cliente ;
- le pere garde la socket d'ecoute ;
- le fils ferme la socket d'ecoute et traite son client ;
- `SIGCHLD` evite l'accumulation de processus zombies.

---

## Resume des points a retenir

### Pipes

```c
int fd[2];
pipe(fd);
```

- `fd[0]` : lecture ;
- `fd[1]` : ecriture ;
- un pipe est unidirectionnel ;
- deux pipes sont necessaires pour un aller-retour.

### Semaphores

```c
sem_init(&sem, 0, valeur);
sem_wait(&sem);
sem_post(&sem);
sem_destroy(&sem);
```

- `sem_wait` prend une autorisation ou bloque ;
- `sem_post` ajoute une autorisation ;
- initialise a `1`, un semaphore peut servir de mutex ;
- initialise a `0`, il peut servir a attendre un evenement.

### Signaux

```c
signal(SIGINT, handler);
kill(pid, SIGQUIT);
pause();
```

- `signal` installe un handler ;
- `kill` envoie un signal ;
- `pause` bloque jusqu'a reception d'un signal.

### TCP client

```c
socket(...);
connect(...);
write(...);
read(...);
close(...);
```

### TCP serveur

```c
socket(...);
bind(...);
listen(...);
accept(...);
fork();
```

