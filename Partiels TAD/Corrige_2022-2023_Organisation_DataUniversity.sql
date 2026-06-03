/*
  Corrige - Examen TAD CY Tech ING2-SIE - 12 mai 2023
  Sujet : Organisation et Data University.
*/

/* -------------------------------------------------------------------------- */
/* I. Administration de bases de donnees                                      */
/* -------------------------------------------------------------------------- */

/* 1.a. Creation des utilisateurs. */
CREATE USER dproje IDENTIFIED BY dproje;
CREATE USER green IDENTIFIED BY green;

GRANT CREATE SESSION TO dproje;
GRANT CREATE SESSION TO green;

/* 1.b. Creation des roles. */
CREATE ROLE ChefDivision;
CREATE ROLE ChefProjet;

/* ChefDivision : tous les acces sur toutes les tables du schema organisation. */
GRANT SELECT, INSERT, UPDATE, DELETE ON organisation.DIVISION TO ChefDivision;
GRANT SELECT, INSERT, UPDATE, DELETE ON organisation.PROJET TO ChefDivision;
GRANT SELECT, INSERT, UPDATE, DELETE ON organisation.SERVICE TO ChefDivision;
GRANT SELECT, INSERT, UPDATE, DELETE ON organisation.SALARIE TO ChefDivision;
GRANT SELECT, INSERT, UPDATE, DELETE ON organisation.TRAVAILLESUR TO ChefDivision;

/* ChefProjet : consulter toutes les tables et gerer les salaries d'un projet. */
GRANT SELECT ON organisation.DIVISION TO ChefProjet;
GRANT SELECT ON organisation.PROJET TO ChefProjet;
GRANT SELECT ON organisation.SERVICE TO ChefProjet;
GRANT SELECT ON organisation.SALARIE TO ChefProjet;
GRANT SELECT, INSERT, DELETE ON organisation.TRAVAILLESUR TO ChefProjet;

/* 1.c. Affectation des roles. */
GRANT ChefProjet TO dproje;
GRANT ChefDivision TO green;

/*
  1.d. Questions.

  - Dirk Proje peut-il affecter des salaries de son projet a un service ?
    Non, le role ChefProjet n'a pas le droit UPDATE sur SALARIE.codeserv.
    Il peut seulement ajouter ou supprimer des lignes dans TRAVAILLESUR.

  - Peut-il voir dans une deuxieme session les affectations non validees faites
    dans une premiere session ?
    Non. Oracle isole les transactions : une autre session ne voit les
    modifications qu'apres COMMIT.
*/

/* 2. Vue sal_Drag_MandMs. */
CREATE OR REPLACE VIEW organisation.sal_Drag_MandMs AS
SELECT s.numsal,
       s.nomsal,
       s.adresse,
       s.qualification,
       s.codeserv,
       p.numproj,
       p.nomproj,
       d.codediv,
       d.nomdiv
FROM organisation.SALARIE s
     JOIN organisation.SERVICE serv ON serv.codeserv = s.codeserv
     JOIN organisation.DIVISION d ON d.codediv = serv.codediv
     JOIN organisation.TRAVAILLESUR ts ON ts.numsal = s.numsal
     JOIN organisation.PROJET p ON p.numproj = ts.numproj
WHERE p.nomproj = 'MandMs'
  AND d.nomdiv = 'Dragees'
  AND serv.codeserv = 27;

/* -------------------------------------------------------------------------- */
/* II. PL/SQL                                                                 */
/* -------------------------------------------------------------------------- */

/*
  1. Generation automatique des cles.
     On utilise une sequence et un trigger BEFORE INSERT, ou une colonne
     IDENTITY dans les versions recentes d'Oracle.
*/

CREATE SEQUENCE seq_salarie START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_salarie_pk
BEFORE INSERT ON SALARIE
FOR EACH ROW
BEGIN
    IF :NEW.numsal IS NULL THEN
        :NEW.numsal := seq_salarie.NEXTVAL;
    END IF;
END;
/

/* 2. Fonction NbProjets. */
CREATE OR REPLACE FUNCTION NbProjets (
    p_numsal IN SALARIE.numsal%TYPE
) RETURN NUMBER IS
    v_nb NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_nb
    FROM TRAVAILLESUR
    WHERE numsal = p_numsal;

    RETURN v_nb;
END;
/

/*
  3. Verifier que le projet est affecte a la division du salarie.
     La division du salarie est obtenue par son service.
*/
CREATE OR REPLACE TRIGGER trg_travaillesur_meme_division
BEFORE INSERT OR UPDATE ON TRAVAILLESUR
FOR EACH ROW
DECLARE
    v_div_projet  PROJET.codediv%TYPE;
    v_div_salarie SERVICE.codediv%TYPE;
BEGIN
    SELECT codediv
    INTO v_div_projet
    FROM PROJET
    WHERE numproj = :NEW.numproj;

    SELECT serv.codediv
    INTO v_div_salarie
    FROM SALARIE s
         JOIN SERVICE serv ON serv.codeserv = s.codeserv
    WHERE s.numsal = :NEW.numsal;

    IF v_div_projet <> v_div_salarie THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Le projet et le salarie ne sont pas dans la meme division.'
        );
    END IF;
END;
/

/* 4. Procedure infoDivision. */
CREATE OR REPLACE PROCEDURE infoDivision (
    p_codediv IN DIVISION.codediv%TYPE
) IS
BEGIN
    FOR p IN (
        SELECT numproj, nomproj
        FROM PROJET
        WHERE codediv = p_codediv
        ORDER BY nomproj
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Projet ' || p.numproj || ' - ' || p.nomproj);

        FOR s IN (
            SELECT sal.numsal, sal.nomsal, sal.qualification
            FROM TRAVAILLESUR ts
                 JOIN SALARIE sal ON sal.numsal = ts.numsal
            WHERE ts.numproj = p.numproj
            ORDER BY sal.nomsal
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                '  ' || s.numsal || ' - ' || s.nomsal || ' - ' || s.qualification
            );
        END LOOP;
    END LOOP;
END;
/

/* -------------------------------------------------------------------------- */
/* III. Bases de donnees reparties                                            */
/* -------------------------------------------------------------------------- */

/*
  1. Modele reparti possible pour Paris, Bordeaux et Lille.

  Fragmentation horizontale par site :
    - Formateur selon idSite ;
    - Inscrit selon idSite ;
    - FormationSession selon le site qui organise la session ;
    - InscriptionSession, Enseigne et Evaluation selon la session locale.

  Tables de reference :
    - Site repliquee sur les trois sites ;
    - Formation, Module et FormationModule centralisees sur le site qui gere le
      catalogue, puis repliquees par vues materialisees sur les autres sites.

  Justification :
    - les inscriptions et evaluations sont traitees localement ;
    - le catalogue doit rester coherent, car certains formateurs le font evoluer ;
    - la replication du catalogue accelere les consultations frequentes.
*/

CREATE OR REPLACE VIEW v_formateurs_global AS
SELECT * FROM Formateur@Paris
UNION ALL
SELECT * FROM Formateur@Bordeaux
UNION ALL
SELECT * FROM Formateur@Lille;

CREATE OR REPLACE VIEW v_sessions_global AS
SELECT * FROM FormationSession@Paris
UNION ALL
SELECT * FROM FormationSession@Bordeaux
UNION ALL
SELECT * FROM FormationSession@Lille;

/*
  2. Pour acceder a une base distante, creer un database link, donner les droits
     necessaires et utiliser les objets distants avec @nom_du_lien.
*/
CREATE DATABASE LINK lien_paris
CONNECT TO user_paris IDENTIFIED BY mot_de_passe
USING 'PARIS';

/*
  3. Pour optimiser l'affichage frequent du catalogue, utiliser des vues
     materialisees locales sur Formation, Module et FormationModule.
*/
CREATE MATERIALIZED VIEW mv_catalogue_formation
REFRESH ON DEMAND
AS
SELECT f.idFormation,
       f.nom AS nom_formation,
       f.descriptif AS descriptif_formation,
       m.idModule,
       m.nom AS nom_module,
       m.descriptif AS descriptif_module,
       m.nbHeures
FROM Formation@Catalogue f
     JOIN FormationModule@Catalogue fm ON fm.idFormation = f.idFormation
     JOIN Module@Catalogue m ON m.idModule = fm.idModule;

/*
  4. On n'indexe pas tous les champs car les index prennent de la place,
     ralentissent les INSERT/UPDATE/DELETE et ne sont utiles que pour certains
     predicats, tris et jointures.
*/

