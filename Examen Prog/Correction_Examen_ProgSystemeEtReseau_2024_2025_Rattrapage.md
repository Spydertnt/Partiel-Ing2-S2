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

    /* O_TRUNC vide le fichier s'il existe deja, 0660 fixe les droits demandes. */
    fd = open(chemin_du_fichier, O_WRONLY | O_CREAT | O_TRUNC, 0660);
    if (fd == -1) {
        perror("open");
        exit(EXIT_FAILURE);
    }

    /* On lit mot par mot jusqu'a rencontrer le mot sentinelle "stop". */
    while (1) {
        printf("Saisir un mot : ");
        scanf("%255s", buffer);

        if (strcmp(buffer, "stop") == 0) {
            break;
        }

        /* write travaille avec des octets : on donne donc explicitement la taille. */
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

    /* On parcourt uniquement les octets reellement lus, pas tout le tableau. */
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

    /* Le pipe est cree avant les fork pour etre herite par les deux fils.
       fd[0] est l'extremite lecture, fd[1] est l'extremite ecriture. */
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

        /* Premier fils : il ecrit dans le pipe, donc il ferme l'extremite lecture. */
        close(fd[0]);

        f1 = open(argv[1], O_RDONLY);
        if (f1 == -1) {
            perror("open fichier entree");
            exit(EXIT_FAILURE);
        }

        /* Chaque bloc lu dans le fichier est transmis tel quel au pipe. */
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

        /* Deuxieme fils : il lit dans le pipe, donc il ferme l'extremite ecriture. */
        close(fd[1]);

        f2 = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0660);
        if (f2 == -1) {
            perror("open fichier sortie");
            exit(EXIT_FAILURE);
        }

        /* La transformation se fait seulement sur les n octets recus. */
        while ((n = read(fd[0], buffer, sizeof(buffer))) > 0) {
            remplace_Q_to_A(buffer, n);
            write(f2, buffer, n);
        }

        close(f2);
        close(fd[0]);
        exit(EXIT_SUCCESS);
    }

    /* Le pere n'utilise pas le pipe : il ferme les deux extremites. */
    close(fd[0]);
    close(fd[1]);

    /* On attend les deux fils pour eviter des processus zombies. */
    wait(NULL);
    wait(NULL);

    return 0;
}
```

Points importants :

- le pipe doit etre cree avant les `fork` ;
- `pipe(fd)` remplit le tableau `fd` avec deux descripteurs :
  - `fd[0]` sert uniquement a lire dans le tube ;
  - `fd[1]` sert uniquement a ecrire dans le tube ;
- les donnees ecrites avec `write(fd[1], ...)` sont recuperees avec `read(fd[0], ...)` ;
- chaque processus ferme les extremites inutiles du pipe ;
- fermer les extremites inutiles evite les blocages : par exemple, le lecteur detecte la fin du pipe seulement quand toutes les extremites ecriture sont fermees ;
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
        /* Premier fils : affichage de la premiere moitie. */
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
        /* Deuxieme fils : affichage de la seconde moitie. */
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
        /* Ce fils doit finir avant que le second ne commence. */
        for (i = 1; i <= 50; i++) {
            printf("%d ", i);
        }
        exit(EXIT_SUCCESS);
    }

    /* waitpid cible precisement p1 : l'ordre devient deterministe. */
    waitpid(p1, NULL, 0);

    p2 = fork();
    if (p2 == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (p2 == 0) {
        /* Le second affichage ne demarre qu'apres la fin du premier fils. */
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
        /* Le coiffeur dort ici tant qu'aucun client n'attend. */
        sem_wait(&clients);

        /* Section critique : modification de places_libres protegee par mutex. */
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

    /* Un seul client a la fois teste/modifie le nombre de places libres. */
    sem_wait(&mutex);

    if (places_libres > 0) {
        places_libres--;
        printf("Client %d attend dans la salle\n", id);

        /* Le client signale sa presence puis libere l'acces aux autres clients. */
        sem_post(&clients);
        sem_post(&mutex);

        /* Il attend ensuite que le coiffeur soit disponible. */
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

    /* clients et coiffeur commencent a 0 : ils servent a bloquer jusqu'a un signal. */
    sem_init(&clients, 0, 0);
    sem_init(&coiffeur, 0, 0);
    /* mutex commence a 1 : une seule autorisation d'entrer en section critique. */
    sem_init(&mutex, 0, 1);

    /* Thread permanent : il boucle pour servir les clients successifs. */
    pthread_create(&th_coiffeur, NULL, programme_coiffeur, NULL);

    for (i = 0; i < NB_CLIENTS; i++) {
        ids[i] = i + 1;
        /* ids[i] reste valide jusqu'a la fin du programme, contrairement a une variable locale reutilisee. */
        pthread_create(&th_clients[i], NULL, programme_client, &ids[i]);
        sleep(1);
    }

    for (i = 0; i < NB_CLIENTS; i++) {
        /* Le main attend que chaque thread client se termine avant de quitter. */
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

Precisions utiles :

- un semaphore est un compteur d'autorisations ;
- `sem_wait(&sem)` prend une autorisation : si le compteur vaut `0`, le thread bloque ;
- `sem_post(&sem)` rend/ajoute une autorisation et peut reveiller un thread bloque ;
- un semaphore peut depasser `1`, par exemple `clients` peut compter plusieurs clients en attente ;
- ici `mutex` est utilise comme verrou binaire : il est initialise a `1`, donc un seul thread peut passer entre `sem_wait(&mutex)` et `sem_post(&mutex)` ;
- `mutex` ne contient pas `places_libres` : il protege seulement la zone de code ou on lit/modifie `places_libres` ;
- `places_libres` est globale, donc tous les threads du meme processus peuvent la lire et la modifier ;
- un `sem_post(&mutex)` de trop ferait passer le verrou a `2` et casserait l'exclusion mutuelle ;
- `pthread_join(th_clients[i], NULL)` force le `main` a attendre la fin du client `i` avant de terminer le programme.

---

## Exercice 4 - Client/serveur TCP de fichiers

Enonce :

- le client se connecte au serveur ;
- il envoie le nom d'un fichier texte ;
- le serveur cherche ce fichier dans le repertoire `Service` ;
- si le fichier existe, il envoie son contenu ;
- sinon, il envoie un message d'erreur ;
- ensuite on modifie le serveur pour plusieurs clients.

Difference entre les programmes :

- le client TCP initie la connexion avec `connect`, envoie le nom du fichier, puis lit la reponse ;
- le serveur TCP simple attend avec `accept`, traite un seul client, puis se termine ;
- le serveur TCP multi-clients reste en boucle sur `accept` et cree un fils avec `fork` pour chaque client ;
- dans les serveurs, `bind` attache la socket a un port, `listen` met la socket en attente de connexions, et `accept` accepte un client ;
- dans la version multi-clients, le pere garde la socket d'ecoute et les fils traitent chacun une socket client.

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

    /* SOCK_STREAM correspond a TCP. */
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    /* sockaddr_in decrit l'adresse IPv4 du serveur a contacter. */
    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(port);
    inet_aton(argv[1], &serveur.sin_addr);

    if (connect(sock, (struct sockaddr *)&serveur, sizeof(serveur)) == -1) {
        perror("connect");
        exit(EXIT_FAILURE);
    }

    printf("Nom du fichier : ");
    scanf("%255s", nom_fichier);

    /* On envoie aussi le '\0' final pour que le serveur recupere une chaine C. */
    write(sock, nom_fichier, strlen(nom_fichier) + 1);

    /* Le client lit jusqu'a ce que le serveur ferme la connexion. */
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

    /* Socket d'ecoute TCP du serveur. */
    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    /* INADDR_ANY accepte les connexions sur toutes les interfaces de la machine. */
    serveur.sin_family = AF_INET;
    serveur.sin_port = htons(port);
    serveur.sin_addr.s_addr = INADDR_ANY;

    /* bind associe la socket au port choisi. */
    if (bind(sock, (struct sockaddr *)&serveur, sizeof(serveur)) == -1) {
        perror("bind");
        exit(EXIT_FAILURE);
    }

    /* listen transforme la socket en socket passive, prete a accepter. */
    listen(sock, 5);

    /* Version simple : un seul client est accepte. */
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
    /* Le serveur ne cherche que dans le repertoire Service. */
    snprintf(chemin, sizeof(chemin), "Service/%s", nom_fichier);

    fd = open(chemin, O_RDONLY);
    if (fd == -1) {
        char *msg = "le fichier n'existe pas chez le serveur\n";
        write(client, msg, strlen(msg));
    } else {
        /* Envoi du fichier par blocs, ce qui evite de tout charger en memoire. */
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
    /* WNOHANG permet de recolter tous les fils termines sans bloquer le serveur. */
    while (waitpid(-1, NULL, WNOHANG) > 0) {
    }
}

void traiter_client(int client) {
    char nom_fichier[256];
    char chemin[512];
    char buffer[512];
    int n;
    int fd;

    /* Chaque fils lit la requete du client qu'il gere. */
    n = read(client, nom_fichier, sizeof(nom_fichier) - 1);
    if (n <= 0) {
        close(client);
        exit(EXIT_FAILURE);
    }

    nom_fichier[n] = '\0';
    /* Construction du chemin local dans le repertoire de service. */
    snprintf(chemin, sizeof(chemin), "Service/%s", nom_fichier);

    fd = open(chemin, O_RDONLY);
    if (fd == -1) {
        char *msg = "le fichier n'existe pas chez le serveur\n";
        write(client, msg, strlen(msg));
    } else {
        /* Transmission progressive du contenu au client. */
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

    /* Evite que les fils termines restent a l'etat zombie. */
    signal(SIGCHLD, handler_chld);

    /* Socket d'ecoute partagee par le pere, puis heritee par les fils. */
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
        /* Le pere attend en boucle de nouveaux clients. */
        client = accept(sock, NULL, NULL);
        if (client == -1) {
            perror("accept");
            continue;
        }

        /* Un fils par client permet de servir plusieurs clients en parallele. */
        pid = fork();
        if (pid == -1) {
            perror("fork");
            close(client);
            continue;
        }

        if (pid == 0) {
            /* Le fils traite le client ; il n'a pas besoin de la socket d'ecoute. */
            close(sock);
            traiter_client(client);
            exit(EXIT_SUCCESS);
        }

        /* Le pere garde seulement la socket d'ecoute et ferme sa copie du client. */
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

- `fd[0]` : extremite lecture du tube, utilisee avec `read(fd[0], ...)`
- `fd[1]` : extremite ecriture du tube, utilisee avec `write(fd[1], ...)`
- un tube est unidirectionnel : les donnees vont de `fd[1]` vers `fd[0]`
- apres un `fork`, les processus heritent des deux extremites et doivent fermer celles qu'ils n'utilisent pas

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
