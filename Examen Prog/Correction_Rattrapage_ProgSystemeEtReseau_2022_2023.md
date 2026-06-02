# Correction - Programmation Systeme et Reseau

Sujet corrige : `Rattrapagede ProgSystemeEtReseau 2023_sessionNormale.pdf`  
Session : Rattrapage 2022-2023

---

## Questions de cours

### 1. Difference entre `wait` et `waitpid`

`wait()` bloque le processus pere jusqu'a la terminaison de n'importe lequel de ses fils.

```c
wait(&status);
```

`waitpid()` permet d'attendre un fils precis, grace a son PID. Elle peut aussi utiliser des options comme `WNOHANG`.

```c
waitpid(pid, &status, 0);
```

Phrase d'examen :

> `wait` attend un fils quelconque, tandis que `waitpid` permet d'attendre un fils particulier.

---

### 2. Trois mecanismes de communication entre processus

Exemples possibles :

- tubes anonymes : `pipe` ;
- tubes nommes : FIFO ;
- files de messages ;
- memoire partagee ;
- signaux ;
- sockets.

Reponse courte :

> Trois mecanismes IPC sont les tubes, les files de messages et la memoire partagee.

---

### 3. Semaphore et primitives associees

Un semaphore est un compteur protege qui permet de synchroniser des processus ou des threads.

Il sert a controler l'acces a une ressource partagee :

- si le semaphore est positif, un processus peut passer ;
- `sem_wait` decremente le semaphore ;
- si le semaphore vaut 0, `sem_wait` bloque ;
- `sem_post` incremente le semaphore et peut reveiller un processus bloque.

Primitives POSIX :

```c
sem_init(&sem, 0, valeur_initiale);
sem_wait(&sem);
sem_post(&sem);
sem_destroy(&sem);
```

Notation classique :

- `P()` correspond a `sem_wait()` ;
- `V()` correspond a `sem_post()`.

---

### 4. Difference entre processus et thread

Un processus possede son propre espace memoire. Deux processus sont isoles et doivent utiliser un mecanisme IPC pour communiquer.

Un thread appartient a un processus. Les threads d'un meme processus partagent la meme memoire, les variables globales et les fichiers ouverts.

Phrase d'examen :

> Un processus est une execution independante avec sa propre memoire, alors qu'un thread est une execution legere partageant la memoire de son processus.

---

## Exercice 1 - `fork`, `wait`, `waitpid`

### 1. Programme `fork1.c` avec `wait`

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    pid_t pid;

    pid = fork();

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {
        printf("Fils : PID = %d, PPID = %d\n", getpid(), getppid());
        exit(EXIT_SUCCESS);
    } else {
        printf("Pere : PID = %d, PPID = %d, PID fils = %d\n",
               getpid(), getppid(), pid);

        wait(NULL);
        printf("Le fils est termine\n");
    }

    return 0;
}
```

---

### 2. Programme `fork2.c` avec `waitpid`

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    pid_t pid;

    pid = fork();

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {
        printf("Fils : PID = %d, PPID = %d\n", getpid(), getppid());
        exit(EXIT_SUCCESS);
    } else {
        printf("Pere : PID = %d, PPID = %d, PID fils = %d\n",
               getpid(), getppid(), pid);

        waitpid(pid, NULL, 0);
        printf("Le fils precise est termine\n");
    }

    return 0;
}
```

---

### 3. Recuperer le code de retour du fils

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    pid_t pid;
    int status;

    pid = fork();

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {
        printf("Fils : PID = %d, PPID = %d\n", getpid(), getppid());
        exit(5);
    } else {
        printf("Pere : PID = %d, PPID = %d, PID fils = %d\n",
               getpid(), getppid(), pid);

        waitpid(pid, &status, 0);

        if (WIFEXITED(status)) {
            printf("Code retour du fils : %d\n", WEXITSTATUS(status));
        }
    }

    return 0;
}
```

---

## Exercice 2 - Threads

Enonce :

- le nombre de threads est passe en parametre ;
- chaque thread affiche un message ;
- le thread principal attend tous les threads.

```c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

void *routine(void *arg) {
    int id = *(int *)arg;

    printf("Thread %d : hello world !\n", id);

    return NULL;
}

int main(int argc, char *argv[]) {
    int n;
    int i;
    pthread_t *threads;
    int *ids;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s nombre_threads\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    n = atoi(argv[1]);

    threads = malloc(n * sizeof(pthread_t));
    ids = malloc(n * sizeof(int));

    if (threads == NULL || ids == NULL) {
        perror("malloc");
        exit(EXIT_FAILURE);
    }

    for (i = 0; i < n; i++) {
        ids[i] = i + 1;
        pthread_create(&threads[i], NULL, routine, &ids[i]);
    }

    for (i = 0; i < n; i++) {
        pthread_join(threads[i], NULL);
    }

    free(threads);
    free(ids);

    return 0;
}
```

Compilation :

```bash
gcc threads.c -o threads -pthread
```

---

## Exercice 3 - TCP client/serveur

### 1. Client TCP complete

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

### 2. Serveur TCP correspondant

Version simple, un client a la fois :

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>

int main(int argc, char *argv[]) {
    int sock, client;
    struct sockaddr_in serveur;
    short port;
    char buf[256];
    int ret;

    if (argc != 3) {
        fprintf(stderr, "usage: %s id port\n", argv[0]);
        exit(1);
    }

    port = atoi(argv[2]);

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
        perror("socket");
        exit(1);
    }

    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(port);
    serveur.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock, (struct sockaddr *)&serveur, sizeof(serveur)) == -1) {
        perror("bind");
        exit(1);
    }

    listen(sock, 5);

    client = accept(sock, NULL, NULL);
    if (client == -1) {
        perror("accept");
        exit(1);
    }

    while (1) {
        ret = read(client, buf, sizeof(buf) - 1);
        if (ret <= 0) {
            break;
        }

        buf[ret] = '\0';
        printf("message recu : %s\n", buf);

        write(client, buf, strlen(buf) + 1);
    }

    close(client);
    close(sock);

    return 0;
}
```

---

## Resume a retenir

### `fork`

```c
pid_t pid = fork();
if (pid == 0) {
    /* fils */
} else {
    /* pere */
}
```

### `wait` et `waitpid`

```c
wait(NULL);
waitpid(pid, &status, 0);
```

### Threads

```c
pthread_create(&th, NULL, routine, arg);
pthread_join(th, NULL);
```

### TCP

Client :

```c
socket(AF_INET, SOCK_STREAM, 0);
connect(sock, (struct sockaddr *)&serveur, sizeof(serveur));
read(sock, buf, sizeof(buf));
write(sock, buf, strlen(buf) + 1);
```

Serveur :

```c
socket(AF_INET, SOCK_STREAM, 0);
bind(sock, (struct sockaddr *)&serveur, sizeof(serveur));
listen(sock, 5);
accept(sock, NULL, NULL);
```

