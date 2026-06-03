/*
  Corrige - Examen TAD CY TECH ING2 GIA / DU CPI 2023-2024
*/

/* -------------------------------------------------------------------------- */
/* Exercice 1 - Base de donnees repartie : bibliotheques                      */
/* -------------------------------------------------------------------------- */

/*
  1. Decoupage propose sur deux sites : Cergy et Pau.

  Fragments horizontaux locaux :
    - EMPLOYE_CERGY : employes affectes a Cergy ;
    - EMPLOYE_PAU : employes affectes a Pau ;
    - ETUDIANT_CERGY : etudiants inscrits a Cergy ;
    - ETUDIANT_PAU : etudiants inscrits a Pau ;
    - OUVRAGES_CERGY : ouvrages geres par Cergy ;
    - OUVRAGES_PAU : ouvrages geres par Pau.

  Tables dependantes :
    - AUTEURS est fragmente selon le site de l'ouvrage ;
    - PRETS est fragmente selon le site de l'ouvrage emprunte, car un ouvrage
      est rendu dans la bibliotheque d'emprunt.

  Justification :
    - chaque universite gere ses etudiants ;
    - chaque bibliotheque gere son personnel et ses ouvrages ;
    - les prets restent proches du stock local ;
    - nb_emprunts est global pour un etudiant : il faut donc acceder au fragment
      ETUDIANT du site d'inscription lors d'un pret distant.
*/

/* 2. Vues locales de fragmentation. */
CREATE OR REPLACE VIEW Employe_Cergy AS
SELECT *
FROM Employe
WHERE affectation = 'Cergy';

CREATE OR REPLACE VIEW Employe_Pau AS
SELECT *
FROM Employe
WHERE affectation = 'Pau';

CREATE OR REPLACE VIEW Etudiant_Cergy AS
SELECT *
FROM Etudiant
WHERE universite = 'Cergy';

CREATE OR REPLACE VIEW Etudiant_Pau AS
SELECT *
FROM Etudiant
WHERE universite = 'Pau';

CREATE OR REPLACE VIEW Ouvrages_Cergy AS
SELECT *
FROM Ouvrages
WHERE site = 'Cergy';

CREATE OR REPLACE VIEW Ouvrages_Pau AS
SELECT *
FROM Ouvrages
WHERE site = 'Pau';

CREATE OR REPLACE VIEW Auteurs_Cergy AS
SELECT a.*
FROM Auteurs a
     JOIN Ouvrages o ON o.id_ouv = a.id_ouv
WHERE o.site = 'Cergy';

CREATE OR REPLACE VIEW Auteurs_Pau AS
SELECT a.*
FROM Auteurs a
     JOIN Ouvrages o ON o.id_ouv = a.id_ouv
WHERE o.site = 'Pau';

CREATE OR REPLACE VIEW Prets_Cergy AS
SELECT p.*
FROM Prets p
     JOIN Ouvrages o ON o.id_ouv = p.id_ouv
WHERE o.site = 'Cergy';

CREATE OR REPLACE VIEW Prets_Pau AS
SELECT p.*
FROM Prets p
     JOIN Ouvrages o ON o.id_ouv = p.id_ouv
WHERE o.site = 'Pau';

/* 3. Reconstruction globale pour la direction. */
CREATE OR REPLACE VIEW Employe_Global AS
SELECT * FROM Employe_Cergy@BD_Cergy
UNION ALL
SELECT * FROM Employe_Pau@BD_Pau;

CREATE OR REPLACE VIEW Etudiant_Global AS
SELECT * FROM Etudiant_Cergy@BD_Cergy
UNION ALL
SELECT * FROM Etudiant_Pau@BD_Pau;

CREATE OR REPLACE VIEW Ouvrages_Global AS
SELECT * FROM Ouvrages_Cergy@BD_Cergy
UNION ALL
SELECT * FROM Ouvrages_Pau@BD_Pau;

CREATE OR REPLACE VIEW Auteurs_Global AS
SELECT * FROM Auteurs_Cergy@BD_Cergy
UNION ALL
SELECT * FROM Auteurs_Pau@BD_Pau;

CREATE OR REPLACE VIEW Prets_Global AS
SELECT * FROM Prets_Cergy@BD_Cergy
UNION ALL
SELECT * FROM Prets_Pau@BD_Pau;

/* -------------------------------------------------------------------------- */
/* Exercice 2 - PL/SQL : conducteurs, permis, vehicules                       */
/* -------------------------------------------------------------------------- */

/*
  Hypothese de passage du MCD vers le relationnel :
    Conducteur(no_conducteur, civilite, nom, prenom)
    Permis(no_permis, type)
    Titulaire(no_conducteur, no_permis)
    Vehicule(no_vehicule, immatriculation, ...)
    Necessiter(no_vehicule, no_permis)
    Louer(no_conducteur, no_vehicule, debut, fin)
*/

/* 1. Fonction d'insertion d'un conducteur avec un permis. */
CREATE OR REPLACE FUNCTION creer_conducteur (
    p_no_conducteur IN Conducteur.no_conducteur%TYPE,
    p_civilite      IN Conducteur.civilite%TYPE,
    p_nom           IN Conducteur.nom%TYPE,
    p_prenom        IN Conducteur.prenom%TYPE,
    p_no_permis     IN Permis.no_permis%TYPE,
    p_type_permis   IN Permis.type%TYPE
) RETURN NUMBER IS
    v_nb NUMBER;
BEGIN
    IF p_nom IS NULL OR p_prenom IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nom et prenom obligatoires.');
    END IF;

    IF p_type_permis NOT IN ('A', 'B', 'C', 'D') THEN
        RAISE_APPLICATION_ERROR(-20002, 'Type de permis invalide.');
    END IF;

    INSERT INTO Conducteur(no_conducteur, civilite, nom, prenom)
    VALUES (p_no_conducteur, p_civilite, p_nom, p_prenom);

    SELECT COUNT(*)
    INTO v_nb
    FROM Permis
    WHERE no_permis = p_no_permis;

    IF v_nb = 0 THEN
        INSERT INTO Permis(no_permis, type)
        VALUES (p_no_permis, p_type_permis);
    END IF;

    INSERT INTO Titulaire(no_conducteur, no_permis)
    VALUES (p_no_conducteur, p_no_permis);

    RETURN p_no_conducteur;
END;
/

/* 2. Verifier qu'un vehicule est libre au moment de sa location. */
CREATE OR REPLACE TRIGGER trg_vehicule_libre
BEFORE INSERT OR UPDATE OF no_vehicule, debut, fin ON Louer
FOR EACH ROW
DECLARE
    v_nb NUMBER;
BEGIN
    IF :NEW.fin < :NEW.debut THEN
        RAISE_APPLICATION_ERROR(-20003, 'Date de fin avant date de debut.');
    END IF;

    SELECT COUNT(*)
    INTO v_nb
    FROM Louer l
    WHERE l.no_vehicule = :NEW.no_vehicule
      AND l.debut <= :NEW.fin
      AND :NEW.debut <= l.fin
      AND NOT (
          UPDATING
          AND l.no_conducteur = :OLD.no_conducteur
          AND l.no_vehicule = :OLD.no_vehicule
          AND l.debut = :OLD.debut
      );

    IF v_nb > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Vehicule deja loue sur cette periode.');
    END IF;
END;
/

/* 3. Verifier que le conducteur possede un permis requis par le vehicule. */
CREATE OR REPLACE TRIGGER trg_permis_location
BEFORE INSERT OR UPDATE OF no_conducteur, no_vehicule ON Louer
FOR EACH ROW
DECLARE
    v_nb NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_nb
    FROM Titulaire t
         JOIN Necessiter n ON n.no_permis = t.no_permis
    WHERE t.no_conducteur = :NEW.no_conducteur
      AND n.no_vehicule = :NEW.no_vehicule;

    IF v_nb = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Le conducteur ne possede pas le permis requis.'
        );
    END IF;
END;
/

/* -------------------------------------------------------------------------- */
/* Exercice 3 - PL/SQL recursif : tours du monde                              */
/* -------------------------------------------------------------------------- */

/*
  Hypothese : un tour part de p_ville_depart et revient a p_ville_depart.
  Le nombre d'escales est le nombre de villes intermediaires, donc le nombre
  de vols du tour moins 1.
*/
CREATE OR REPLACE PROCEDURE proposer_tours_du_monde (
    p_ville_depart IN Vol.ville_depart%TYPE,
    p_min_escales  IN NUMBER,
    p_max_escales  IN NUMBER
) IS
    PROCEDURE explorer (
        p_ville_courante IN Vol.ville_arrivee%TYPE,
        p_nb_vols        IN NUMBER,
        p_chemin         IN VARCHAR2,
        p_villes_vues    IN VARCHAR2
    ) IS
        v_escales NUMBER;
    BEGIN
        IF p_nb_vols > p_max_escales + 1 THEN
            RETURN;
        END IF;

        FOR v IN (
            SELECT numvol, ville_depart, ville_arrivee
            FROM Vol
            WHERE ville_depart = p_ville_courante
        ) LOOP
            v_escales := p_nb_vols;

            IF v.ville_arrivee = p_ville_depart THEN
                IF v_escales BETWEEN p_min_escales AND p_max_escales THEN
                    DBMS_OUTPUT.PUT_LINE(
                        p_chemin || ' -> vol ' || v.numvol || ' retour '
                        || p_ville_depart
                    );
                END IF;
            ELSIF INSTR(p_villes_vues, '|' || v.ville_arrivee || '|') = 0 THEN
                explorer(
                    v.ville_arrivee,
                    p_nb_vols + 1,
                    p_chemin || ' -> vol ' || v.numvol || ' ' || v.ville_arrivee,
                    p_villes_vues || v.ville_arrivee || '|'
                );
            END IF;
        END LOOP;
    END;
BEGIN
    IF p_min_escales < 0 OR p_max_escales < p_min_escales THEN
        RAISE_APPLICATION_ERROR(-20010, 'Bornes invalides.');
    END IF;

    explorer(
        p_ville_depart,
        1,
        p_ville_depart,
        '|' || p_ville_depart || '|'
    );
END;
/

