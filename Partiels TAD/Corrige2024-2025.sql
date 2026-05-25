/*
  Corrige - Examen TAD ING2-GIA 2024-2025

  QCM
  1. a
  2. a, b, d
  3. a, b, d
  4. b
  5. b, c
  6. c
  7. a, c, f
     Les index bitmap sont a eviter sur une table fortement modifiee.
     Sans detail sur les requetes, les B-tree sont les choix les plus raisonnables.
  8. a, c, e

  Questions de reflexion
  1. Les roles simplifient l'administration des privileges : on accorde les droits
     a un role, puis le role aux utilisateurs. Cela limite les erreurs, facilite
     les audits et permet de modifier les droits d'un groupe en une seule action.

  2. Un tablespace est une zone logique de stockage Oracle composee de fichiers de
     donnees. Une table est un objet relationnel contenant des lignes et colonnes.
     Une table est stockee dans un tablespace.

  3. Une vue materialisee est plus performante qu'une vue simple lorsque le resultat
     d'une requete couteuse est consulte souvent et change moins souvent qu'il n'est
     lu. En environnement transactionnel, on choisit le rafraichissement selon le
     besoin : ON COMMIT pour des donnees toujours a jour mais avec un cout sur les
     transactions, ou ON DEMAND pour rafraichir a des moments controles.

  4. Les principales strategies de fragmentation sont :
     - horizontale : les lignes sont reparties selon un critere, par exemple l'agence ;
     - verticale : les colonnes sont reparties selon leur usage ou leur sensibilite ;
     - mixte : combinaison des deux ;
     - replication : copie totale ou partielle de donnees souvent consultees.

  5. Un cluster peut etre mis en place lorsque des tables sont souvent jointes sur
     les memes cles, ou lorsque l'on veut regrouper physiquement des donnees ayant
     des acces communs afin de reduire les lectures disque.
*/

/* -------------------------------------------------------------------------- */
/* Partie A - PL/SQL                                                          */
/* -------------------------------------------------------------------------- */

/* 1. Trigger de generation de la cle de Location. */
CREATE OR REPLACE TRIGGER trg_location_bi
BEFORE INSERT ON Location
FOR EACH ROW
WHEN (NEW.no_location IS NULL)
BEGIN
    :NEW.no_location := LocID.NEXTVAL;
END;
/

/* 2. Verification du permis avant creation d'une location. */
CREATE OR REPLACE TRIGGER trg_location_check_permis
BEFORE INSERT OR UPDATE OF no_client ON Location
FOR EACH ROW
DECLARE
    v_permis Client.permis_conduire%TYPE;
BEGIN
    SELECT permis_conduire
    INTO v_permis
    FROM Client
    WHERE no_client = :NEW.no_client;

    IF v_permis IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Le client ne possede pas de permis de conduire valide.'
        );
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Client inexistant.');
END;
/

/* 3. Procedure d'ajout d'un vehicule a une location existante. */
CREATE OR REPLACE PROCEDURE ajouter_vehicule_location (
    p_no_location IN Location.no_location%TYPE,
    p_no_vehicule IN Vehicule.no_vehicule%TYPE
) IS
    v_statut      Location.statut%TYPE;
    v_dummy       NUMBER;
    v_deja_loue   NUMBER;
BEGIN
    SELECT statut
    INTO v_statut
    FROM Location
    WHERE no_location = p_no_location;

    IF LOWER(v_statut) <> 'en cours' THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'La location doit etre en cours pour ajouter un vehicule.'
        );
    END IF;

    SELECT 1
    INTO v_dummy
    FROM Vehicule
    WHERE no_vehicule = p_no_vehicule;

    SELECT COUNT(*)
    INTO v_deja_loue
    FROM Vehicule_Location vl
         JOIN Location l ON l.no_location = vl.no_location
    WHERE vl.no_vehicule = p_no_vehicule
      AND LOWER(l.statut) = 'en cours';

    IF v_deja_loue > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Le vehicule est deja affecte a une location en cours.'
        );
    END IF;

    INSERT INTO Vehicule_Location (no_location, no_vehicule)
    VALUES (p_no_location, p_no_vehicule);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'La location ou le vehicule n''existe pas.'
        );
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(
            -20006,
            'Ce vehicule est deja affecte a cette location.'
        );
END;
/

/* 4. Fonction affichant les n-ieme et n+1-ieme clients de l'annee courante. */
CREATE OR REPLACE FUNCTION top_clients_annee (
    p_n IN PLS_INTEGER
) RETURN VARCHAR2 IS
    CURSOR cur_clients IS
        SELECT c.no_client,
               c.nom,
               c.prenom,
               COUNT(vl.no_vehicule) AS nb
        FROM Client c
             JOIN Location l ON l.no_client = c.no_client
             JOIN Vehicule_Location vl ON vl.no_location = l.no_location
        WHERE l.date_debut >= TRUNC(SYSDATE,'YYYY')
          AND l.date_debut < ADD_MONTHS(TRUNC(SYSDATE,'YYYY'),12)
        GROUP BY c.no_client, c.nom, c.prenom
        ORDER BY COUNT(vl.no_vehicule) DESC, c.no_client;

    TYPE t_clients IS TABLE OF cur_clients%ROWTYPE;
    v_clients t_clients;
    v_result  VARCHAR2(4000) := '';
BEGIN
    IF p_n IS NULL OR p_n < 1 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Le rang demande doit etre superieur a 0.');
    END IF;

    /*
      BULK COLLECT permet de charger plusieurs lignes du curseur en une seule fois
      dans une collection PL/SQL. Ici, LIMIT p_n + 1 suffit car on veut seulement
      pouvoir afficher le rang p_n et le rang p_n + 1.
    */
    OPEN cur_clients;
    FETCH cur_clients BULK COLLECT INTO v_clients LIMIT p_n + 1;
    CLOSE cur_clients;

    FOR i IN p_n .. p_n + 1 LOOP
        IF i <= v_clients.COUNT THEN
            v_result := v_result
                || i || ' - '
                || v_clients(i).no_client || ' - '
                || v_clients(i).nom || ' ' || v_clients(i).prenom || ' : '
                || v_clients(i).nb || ' vehicule(s)' || CHR(10);
        END IF;
    END LOOP;

    RETURN NVL(v_result, 'Aucun client trouve.');
END top_clients_annee;
/

/*
  5. Cumul_Depenses_Client doit etre maintenue par trigger car elle contient une
     donnee derivee : le total annuel depense par client. Sans trigger, cette table
     risque de ne plus etre coherente avec les locations/factures.

     Hypothese : le cumul est mis a jour lorsqu'une facture payee est inseree ou
     lorsqu'une facture devient payee. Le client et l'annee sont deduits de la
     location associee.
*/
CREATE OR REPLACE TRIGGER trg_facture_cumul_depenses
AFTER INSERT OR UPDATE OF montant, paye ON Facture
FOR EACH ROW
DECLARE
    v_no_client Location.no_client%TYPE;
    v_annee     NUMBER(4);
    v_delta     Facture.montant%TYPE := 0;
BEGIN
    SELECT no_client, EXTRACT(YEAR FROM date_debut)
    INTO v_no_client, v_annee
    FROM Location
    WHERE no_location = :NEW.no_location;

    IF INSERTING THEN
        IF :NEW.paye = 'O' THEN
            v_delta := :NEW.montant;
        END IF;
    ELSIF UPDATING THEN
        /*
          NVL(expr, valeur) remplace NULL par une valeur par defaut.
          Ici, si paye est NULL, on le considere comme 'N' pour dire non paye.
        */
        IF NVL(:OLD.paye, 'N') <> 'O' AND :NEW.paye = 'O' THEN
            v_delta := :NEW.montant;
        ELSIF :OLD.paye = 'O' AND :NEW.paye = 'O' THEN
            v_delta := :NEW.montant - :OLD.montant;
        ELSIF :OLD.paye = 'O' AND NVL(:NEW.paye, 'N') <> 'O' THEN
            v_delta := -:OLD.montant;
        END IF;
    END IF;

    IF v_delta <> 0 THEN
        UPDATE Cumul_Depenses_Client
        SET montant_total = montant_total + v_delta
        WHERE no_client = v_no_client
          AND annee = v_annee;

        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO Cumul_Depenses_Client (no_client, annee, montant_total)
            VALUES (v_no_client, v_annee, v_delta);
        END IF;
    END IF;
END;
/

/* -------------------------------------------------------------------------- */
/* Partie B - Base de donnees repartie                                        */
/* -------------------------------------------------------------------------- */

/*
  1. Proposition de repartition.

  Base centrale Siege :
    - Client(no_client, nom, prenom, date_naissance, permis_conduire)
    - Facture(no_facture, date_facture, montant, paye, no_location)
    - eventuellement Cumul_Depenses_Client pour le reporting global

  Base Agence_Paris :
    - Agence, ou une copie materialisee de Agence
    - Vehicule limite aux vehicules de Paris
    - Location limitee aux locations de Paris
    - Vehicule_Location pour les locations de Paris
    - une vue materialisee minimale des clients :
      Client_Min(no_client, permis_conduire), rafraichie depuis le siege

  Meme principe pour Agence_Marseille et Agence_Lyon.

  Justification :
    - repartition verticale : les donnees personnelles clients et factures restent
      au siege ; les agences gardent les donnees operationnelles necessaires ;
    - repartition horizontale : Location est fragmente par no_agence ;
    - les agences peuvent appeler le siege via liens de base pour les clients et
      factures, et le siege peut consulter l'historique global via des vues UNION.
*/

/* Exemple cote siege : historique global des locations. */
CREATE OR REPLACE VIEW v_locations_globales AS
SELECT *
FROM Location@Agence_Paris
UNION ALL
SELECT *
FROM Location@Agence_Marseille
UNION ALL
SELECT *
FROM Location@Agence_Lyon;

/* Exemple cote agence : copie minimale utile des clients. */
CREATE MATERIALIZED VIEW mv_client_min
REFRESH ON DEMAND
AS
SELECT no_client, permis_conduire
FROM Client@Siege;

/*
  2. Optimisation de l'acces a Agence depuis les autres bases.

  Si la table Agence est stockee dans la base de Paris et qu'elle est lue souvent
  par les autres agences, il faut la repliquer dans les autres bases, par exemple
  avec une vue materialisee locale rafraichie regulierement.
*/
CREATE MATERIALIZED VIEW mv_agence
REFRESH ON DEMAND
AS
SELECT no_agence, nom, adresse, ville, cp
FROM Agence@Agence_Paris;
