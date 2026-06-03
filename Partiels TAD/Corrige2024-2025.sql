/*
  Correction simplifiee - Examen TAD ING2-GIA 2024-2025

  QCM
  1. a
  2. a, b, d
  3. a, b, d
  4. b
  5. b, c
  6. c
  7. a, c, f
  8. a, c, e

  Questions de cours
  1. Un role regroupe des privileges. On donne les privileges au role, puis le
     role aux utilisateurs. C'est plus simple a administrer.

  2. Un tablespace est une zone logique de stockage Oracle. Une table est un
     objet contenant des lignes et des colonnes. La table est stockee dans un
     tablespace.

  3. Une vue materialisee stocke le resultat d'une requete. Elle est utile quand
     une requete est longue et souvent utilisee. Elle doit etre rafraichie :
     soit automatiquement, soit manuellement.

  4. Fragmentation :
     - horizontale : on separe les lignes ;
     - verticale : on separe les colonnes ;
     - mixte : les deux ;
     - replication : on copie les donnees sur plusieurs sites.

  5. Un cluster est utile quand plusieurs tables sont souvent jointes sur les
     memes colonnes. Les donnees proches sont stockees ensemble.
*/

/* -------------------------------------------------------------------------- */
/* Partie A - PL/SQL                                                          */
/* -------------------------------------------------------------------------- */

/* 1. Generer automatiquement le numero de location. */
CREATE OR REPLACE TRIGGER trg_cle_location
BEFORE INSERT ON Location
FOR EACH ROW
BEGIN
    IF :NEW.no_location IS NULL THEN
        :NEW.no_location := LocID.NEXTVAL;
    END IF;
END;
/

/* 2. Verifier que le client possede un permis. */
CREATE OR REPLACE TRIGGER trg_check_permis
BEFORE INSERT ON Location
FOR EACH ROW
DECLARE
    v_permis Client.permis_conduire%TYPE;
BEGIN
    SELECT permis_conduire
    INTO v_permis
    FROM Client
    WHERE no_client = :NEW.no_client;

    IF v_permis IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Client sans permis.');
    END IF;
END;
/

/* 3. Ajouter un vehicule dans une location en cours. */
CREATE OR REPLACE PROCEDURE ajouter_vehicule_location (
    p_location IN NUMBER,
    p_vehicule IN NUMBER
) IS
    v_statut Location.statut%TYPE;
    v_nb     NUMBER;
BEGIN
    SELECT statut
    INTO v_statut
    FROM Location
    WHERE no_location = p_location;

    IF LOWER(v_statut) <> 'en cours' THEN
        RAISE_APPLICATION_ERROR(-20002, 'La location n''est pas en cours.');
    END IF;

    SELECT COUNT(*)
    INTO v_nb
    FROM Vehicule_Location vl
         JOIN Location l ON l.no_location = vl.no_location
    WHERE vl.no_vehicule = p_vehicule
      AND LOWER(l.statut) = 'en cours';

    IF v_nb > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Vehicule deja loue.');
    END IF;

    INSERT INTO Vehicule_Location(no_location, no_vehicule)
    VALUES (p_location, p_vehicule);
END;
/

/* 4. Afficher le n-ieme et le n+1-ieme client de l'annee. */
CREATE OR REPLACE FUNCTION top_clients_annee (
    p_n IN NUMBER
) RETURN VARCHAR2 IS
    v_result VARCHAR2(1000) := '';
    v_rang   NUMBER := 0;
BEGIN
    FOR c IN (
        SELECT c.no_client,
               c.nom,
               c.prenom,
               COUNT(*) AS nb_locations
        FROM Client c
             JOIN Location l ON l.no_client = c.no_client
        WHERE EXTRACT(YEAR FROM l.date_debut) = EXTRACT(YEAR FROM SYSDATE)
        GROUP BY c.no_client, c.nom, c.prenom
        ORDER BY COUNT(*) DESC
    ) LOOP
        v_rang := v_rang + 1;

        IF v_rang = p_n OR v_rang = p_n + 1 THEN
            v_result := v_result
                || v_rang || ' - '
                || c.no_client || ' '
                || c.nom || ' '
                || c.prenom || ' : '
                || c.nb_locations || CHR(10);
        END IF;

        EXIT WHEN v_rang = p_n + 1;
    END LOOP;

    RETURN v_result;
END;
/

/*
  5. La table Cumul_Depenses_Client contient une information calculee.
     Un trigger permet de la mettre a jour automatiquement quand une facture
     payee est ajoutee.
*/
CREATE OR REPLACE TRIGGER trg_cumul_depenses
AFTER INSERT ON Facture
FOR EACH ROW
DECLARE
    v_client Location.no_client%TYPE;
    v_annee  NUMBER;
BEGIN
    IF :NEW.paye = 'O' THEN
        SELECT no_client, EXTRACT(YEAR FROM date_debut)
        INTO v_client, v_annee
        FROM Location
        WHERE no_location = :NEW.no_location;

        UPDATE Cumul_Depenses_Client
        SET montant_total = montant_total + :NEW.montant
        WHERE no_client = v_client
          AND annee = v_annee;

        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO Cumul_Depenses_Client(no_client, annee, montant_total)
            VALUES (v_client, v_annee, :NEW.montant);
        END IF;
    END IF;
END;
/

/* -------------------------------------------------------------------------- */
/* Partie B - Base de donnees repartie                                        */
/* -------------------------------------------------------------------------- */

/*
  1. Repartition possible.

  Au siege :
    - Client
    - Facture
    - Cumul_Depenses_Client

  Dans chaque agence :
    - Vehicule de l'agence
    - Location de l'agence
    - Vehicule_Location de l'agence
    - une copie minimale des clients : no_client, permis_conduire

  Idee :
    - les donnees communes et sensibles restent au siege ;
    - les donnees utiles au travail quotidien restent dans les agences ;
    - les locations sont separees par agence.
*/

/* Vue globale au siege. */
CREATE OR REPLACE VIEW v_locations_globales AS
SELECT * FROM Location@Agence_Paris
UNION ALL
SELECT * FROM Location@Agence_Marseille
UNION ALL
SELECT * FROM Location@Agence_Lyon;

/* Copie minimale des clients dans une agence. */
CREATE MATERIALIZED VIEW mv_client_min
REFRESH ON DEMAND
AS
SELECT no_client, permis_conduire
FROM Client@Siege;

/*
  2. Si la table Agence est souvent lue depuis plusieurs sites, on peut la copier
     localement avec une vue materialisee.
*/
CREATE MATERIALIZED VIEW mv_agence
REFRESH ON DEMAND
AS
SELECT no_agence, nom, adresse, ville, cp
FROM Agence@Siege;
