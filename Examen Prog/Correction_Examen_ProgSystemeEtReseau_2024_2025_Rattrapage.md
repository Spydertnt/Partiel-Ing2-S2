# Correction - Programmation Systeme et Reseau

Sujet corrige : `Examen de ProgSystemeEtReseau.pdf`  
Session : Rattrapage 2024-2025

---

## Exercice 1 - Fichiers, pipe et processus

### 1. Procedure `Ecrire_fich(chemin_du_fichier)`

On doit creer un fichier avec les droits lecture/ecriture pour le proprietaire et le groupe, puis lire depuis l'entree standard jusqu'au mot `stop`.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

void Ecrire_fich(const char *chemin_du_fichier) {
    int fd;
    char buffer[256];

    fd = open(chemin_du_fichier, O_WRONLY | O_CREAT | O_TRUNC, 0660);
    if (fd == -1) {
        perror("open");
        exit(EXIT_FAILURE);
    }

    while (1) {
        printf("Saisir un mot : ");
        scanf("%255s", buffer);

        if (strcmp(buffer, "stop") == 0) {
            break;
        }

        write(fd, buffer, strlen(buffer));
        write(fd, "\n", 1);
    }

    close(fd);
}
```

Remarque : `0660` donne lecture/ecriture au proprietaire et au groupe.

---

### 2. Procedure `remplace_Q_to_A`

```c
void remplace_Q_to_A(char tab[], int taille) {
    int i;

    for (i = 0; i < taille; i++) {
        if (tab[i] == 'q') {
            tab[i] = 'a';
        }
    }
}
```

Si l'enseignant attend aussi la majuscule :

```c
if (tab[i] == 'q' || tab[i] == 'Q') {
    tab[i] = 'a';
}
```

---

### 3. Programme avec deux fils et un tube anonyme

Enonce :

- le premier fils lit depuis un premier fichier et ecrit dans un pipe ;
- le deuxieme fils lit depuis le pipe, remplace `q` par `a`, puis ecrit dans un deuxieme fichier.

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/wait.h>

void remplace_Q_to_A(char tab[], int taille) {
    int i;
    for (i = 0; i < taille; i++) {
        if (tab[i] == 'q') {
            tab[i] = 'a';
        }
    }
}

int main(int argc, char *argv[]) {
    int fd[2];
    pid_t p1, p2;

    if (argc != 3) {
        fprintf(stderr, "Usage: %s fichier_entree fichier_sortie\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    if (pipe(fd) == -1) {
        perror("pipe");
        exit(EXIT_FAILURE);
    }

    p1 = fork();
    if (p1 == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (p1 == 0) {
        int f1;
        char buffer[256];
        int n;

        close(fd[0]);

        f1 = open(argv[1], O_RDONLY);
        if (f1 == -1) {
            perror("open fichier entree");
            exit(EXIT_FAILURE);
        }

        while ((n = read(f1, buffer, sizeof(buffer))) > 0) {
            write(fd[1], buffer, n);
        }

        close(f1);
        close(fd[1]);
        exit(EXIT_SUCCESS);
    }

    p2 = fork();
    if (p2 == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (p2 == 0) {
        int f2;
        char buffer[256];
        int n;

        close(fd[1]);

        f2 = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0660);
        if (f2 == -1) {
            perror("open fichier sortie");
            exit(EXIT_FAILURE);
        }

        while ((n = read(fd[0], buffer, sizeof(buffer))) > 0) {
            remplace_Q_to_A(buffer, n);
            write(f2, buffer, n);
        }

        close(f2);
        close(fd[0]);
        exit(EXIT_SUCCESS);
    }

    close(fd[0]);
    close(fd[1]);

    wait(NULL);
    wait(NULL);

    return 0;
}
```

Points importants :

- le pipe doit etre cree avant les `fork` ;
- chaque processus ferme les extremites inutiles du pipe ;
- le pere ferme les deux extremites et attend les deux fils.

---

## Exercice 2 - Processus et affichage ordonne

### 1. Deux fils : l'un affiche 1 a 50, l'autre 51 a 100

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    pid_t p1, p2;
    int i;

    p1 = fork();
    if (p1 == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (p1 == 0) {
        for (i = 1; i <= 50; i++) {
            printf("%d ", i);
        }
        printf("\n");
        exit(EXIT_SUCCESS);
    }

    p2 = fork();
    if (p2 == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (p2 == 0) {
        for (i = 51; i <= 100; i++) {
            printf("%d ", i);
        }
        printf("\n");
        exit(EXIT_SUCCESS);
    }

    wait(NULL);
    wait(NULL);

    return 0;
}
```

Attention : ici l'ordre d'affichage n'est pas garanti. Le deuxieme fils peut afficher avant le premier.

---

### 2. Modifier pour afficher exactement 1, 2, 3, ..., 100

Pour imposer l'ordre, le pere peut attendre la fin du premier fils avant de creer ou laisser afficher le deuxieme.

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main() {
    pid_t p1, p2;
    int i;

    p1 = fork();
    if (p1 == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (p1 == 0) {
        for (i = 1; i <= 50; i++) {
            printf("%d ", i);
        }
        exit(EXIT_SUCCESS);
    }

    waitpid(p1, NULL, 0);

    p2 = fork();
    if (p2 == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (p2 == 0) {
        for (i = 51; i <= 100; i++) {
            printf("%d ", i);
        }
        printf("\n");
        exit(EXIT_SUCCESS);
    }

    waitpid(p2, NULL, 0);

    return 0;
}
```

Phrase d'explication :

> `waitpid(p1, NULL, 0)` oblige le pere a attendre la fin du premier fils avant de lancer ou de continuer avec le deuxieme affichage.

---

## Exercice 3 - Probleme du coiffeur avec threads et semaphores

C'est le probleme classique du coiffeur endormi.

Idee :

- `clients` compte les clients en attente ;
- `coiffeur` reveille un client quand le coiffeur est disponible ;
- `mutex` protege la variable partagee `places_libres`.

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>

#define NBP 5
#define NB_CLIENTS 10

sem_t clients;
sem_t coiffeur;
sem_t mutex;

int places_libres = NBP;

void couper_cheveux() {
    printf("Le coiffeur coupe les cheveux\n");
    sleep(1);
}

void recevoir_coupe(int id) {
    printf("Client %d se fait couper les cheveux\n", id);
    sleep(1);
}

void *programme_coiffeur(void *arg) {
    (void)arg;

    while (1) {
        sem_wait(&clients);

        sem_wait(&mutex);
        places_libres++;
        sem_post(&coiffeur);
        sem_post(&mutex);

        couper_cheveux();
    }

    return NULL;
}

void *programme_client(void *arg) {
    int id = *(int *)arg;

    sem_wait(&mutex);

    if (places_libres > 0) {
        places_libres--;
        printf("Client %d attend dans la salle\n", id);

        sem_post(&clients);
        sem_post(&mutex);

        sem_wait(&coiffeur);
        recevoir_coupe(id);
    } else {
        printf("Client %d quitte : salle pleine\n", id);
        sem_post(&mutex);
    }

    return NULL;
}

int main() {
    pthread_t th_coiffeur;
    pthread_t th_clients[NB_CLIENTS];
    int ids[NB_CLIENTS];
    int i;

    sem_init(&clients, 0, 0);
    sem_init(&coiffeur, 0, 0);
    sem_init(&mutex, 0, 1);

    pthread_create(&th_coiffeur, NULL, programme_coiffeur, NULL);

    for (i = 0; i < NB_CLIENTS; i++) {
        ids[i] = i + 1;
        pthread_create(&th_clients[i], NULL, programme_client, &ids[i]);
        sleep(1);
    }

    for (i = 0; i < NB_CLIENTS; i++) {
        pthread_join(th_clients[i], NULL);
    }

    return 0;
}
```

Explication attendue :

- si aucun client n'est present, le coiffeur bloque sur `sem_wait(&clients)` ;
- quand un client arrive, il fait `sem_post(&clients)` pour reveiller le coiffeur ;
- si la salle d'attente est pleine, le client quitte ;
- `mutex` evite que plusieurs clients modifient `places_libres` en meme temps.

---

## Exercice 4 - Client/serveur TCP de fichiers

Enonce :

- le client se connecte au serveur ;
- il envoie le nom d'un fichier texte ;
- le serveur cherche ce fichier dans le repertoire `Service` ;
- si le fichier existe, il envoie son contenu ;
- sinon, il envoie un message d'erreur ;
- ensuite on modifie le serveur pour plusieurs clients.

---

### 1. Client TCP pour un seul serveur

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>

int main(int argc, char *argv[]) {
    int sock;
    struct sockaddr_in serveur;
    char nom_fichier[256];
    char buffer[512];
    int n;
    int port;

    if (argc != 3) {
        fprintf(stderr, "Usage: %s adresse_serveur port\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    port = atoi(argv[2]);

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(port);
    inet_aton(argv[1], &serveur.sin_addr);

    if (connect(sock, (struct sockaddr *)&serveur, sizeof(serveur)) == -1) {
        perror("connect");
        exit(EXIT_FAILURE);
    }

    printf("Nom du fichier : ");
    scanf("%255s", nom_fichier);

    write(sock, nom_fichier, strlen(nom_fichier) + 1);

    while ((n = read(sock, buffer, sizeof(buffer) - 1)) > 0) {
        buffer[n] = '\0';
        printf("%s", buffer);
    }

    close(sock);
    return 0;
}
```

---

### 2. Serveur TCP pour un seul client

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <netinet/in.h>

int main(int argc, char *argv[]) {
    int sock, client;
    struct sockaddr_in serveur;
    char nom_fichier[256];
    char chemin[512];
    char buffer[512];
    int n;
    int fd;
    int port;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s port\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    port = atoi(argv[1]);

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
        exit(EXIT_FAILURE);
    }

    listen(sock, 5);

    client = accept(sock, NULL, NULL);
    if (client == -1) {
        perror("accept");
        exit(EXIT_FAILURE);
    }

    n = read(client, nom_fichier, sizeof(nom_fichier) - 1);
    if (n <= 0) {
        close(client);
        close(sock);
        exit(EXIT_FAILURE);
    }

    nom_fichier[n] = '\0';
    snprintf(chemin, sizeof(chemin), "Service/%s", nom_fichier);

    fd = open(chemin, O_RDONLY);
    if (fd == -1) {
        char *msg = "le fichier n'existe pas chez le serveur\n";
        write(client, msg, strlen(msg));
    } else {
        while ((n = read(fd, buffer, sizeof(buffer))) > 0) {
            write(client, buffer, n);
        }
        close(fd);
    }

    close(client);
    close(sock);

    return 0;
}
```

---

### 3. Serveur TCP traitant plusieurs clients

Version classique avec `fork()` : a chaque `accept`, le serveur cree un fils pour traiter le client.

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
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
    char nom_fichier[256];
    char chemin[512];
    char buffer[512];
    int n;
    int fd;

    n = read(client, nom_fichier, sizeof(nom_fichier) - 1);
    if (n <= 0) {
        close(client);
        exit(EXIT_FAILURE);
    }

    nom_fichier[n] = '\0';
    snprintf(chemin, sizeof(chemin), "Service/%s", nom_fichier);

    fd = open(chemin, O_RDONLY);
    if (fd == -1) {
        char *msg = "le fichier n'existe pas chez le serveur\n";
        write(client, msg, strlen(msg));
    } else {
        while ((n = read(fd, buffer, sizeof(buffer))) > 0) {
            write(client, buffer, n);
        }
        close(fd);
    }

    close(client);
}

int main(int argc, char *argv[]) {
    int sock, client;
    struct sockaddr_in serveur;
    int port;
    pid_t pid;

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
        exit(EXIT_FAILURE);
    }

    listen(sock, 5);

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

Explication :

- le serveur principal garde la socket d'ecoute ;
- chaque fils traite un client ;
- le pere ferme la socket client apres le `fork` ;
- le fils ferme la socket d'ecoute ;
- `SIGCHLD` evite les processus zombies.

---

## Resume des points a retenir

### Fichiers

```c
open("fichier", O_RDONLY);
open("fichier", O_WRONLY | O_CREAT | O_TRUNC, 0660);
read(fd, buffer, taille);
write(fd, buffer, n);
close(fd);
```

### Pipe

```c
int fd[2];
pipe(fd);
```

- `fd[0]` : lecture
- `fd[1]` : ecriture

### Processus

```c
pid_t pid = fork();
wait(NULL);
waitpid(pid, NULL, 0);
```

### TCP serveur

```c
socket(AF_INET, SOCK_STREAM, 0);
bind(...);
listen(...);
accept(...);
read(...);
write(...);
```

### TCP client

```c
socket(AF_INET, SOCK_STREAM, 0);
connect(...);
write(...);
read(...);
```

### Semaphores

```c
sem_init(&sem, 0, valeur);
sem_wait(&sem);
sem_post(&sem);
sem_destroy(&sem);
```

