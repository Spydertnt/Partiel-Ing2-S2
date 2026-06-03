/*
  Corrige - Examen TAD CY TECH ING2 GIA / SIE 2022-2023
  Sujet : remboursements de medicaments par la securite sociale.
*/

/* -------------------------------------------------------------------------- */
/* Exercice 1 - QCM                                                           */
/* -------------------------------------------------------------------------- */

/*
  1. a
     Oui, avec un SAVEPOINT puis ROLLBACK TO SAVEPOINT.

  2. d
     Un schema Oracle est associe a un utilisateur et porte son nom.

  3. c
     Un tablespace est une zone logique de stockage contenant des segments
     comme des tables et des index.

  4. b
     Une vue simple ne stocke pas les donnees.

  5. a, c, f
     Beaucoup de modifications : eviter les index bitmap. Les index B-tree
     restent les choix generiques possibles.

  6. c
     L'optimiseur choisit la meilleure maniere d'executer une requete.

  7. c, d
     T2.E est deja cle primaire, donc deja indexee. T1.C aide la jointure.
     T1.D peut aider le tri. Un index normal sur T1.B n'aide pas directement
     ABS(T1.B), sauf index fonctionnel :
       CREATE INDEX idx_abs_b ON T1(ABS(B));
*/

/* -------------------------------------------------------------------------- */
/* Exercice 2 - A. PL/SQL                                                     */
/* -------------------------------------------------------------------------- */

/* 1. Gerer la cle de l'ordonnance avec la sequence OrdID. */
CREATE OR REPLACE TRIGGER trg_ordonnance_pk
BEFORE INSERT ON Ordonnance
FOR EACH ROW
BEGIN
    IF :NEW.no_ordo IS NULL THEN
        :NEW.no_ordo := OrdID.NEXTVAL;
    END IF;
END;
/

/* 2. Verifier qu'un assure existe lors de l'insertion d'un ayant droit. */
CREATE OR REPLACE TRIGGER trg_ayant_droit_assure
BEFORE INSERT OR UPDATE OF no_secu ON Ayant_Droit
FOR EACH ROW
DECLARE
    v_nb NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_nb
    FROM Assure
    WHERE no_secu = :NEW.no_secu;

    IF v_nb = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Assure inexistant.');
    END IF;
END;
/

/* 3. Creer une ordonnance vide pour un ayant droit. */
CREATE OR REPLACE PROCEDURE creer_ordonnance_ayant_droit (
    p_no_ayant_droit IN Ayant_Droit.no_ayant_droit%TYPE,
    p_date_ordo      IN Ordonnance.date_ordo%TYPE
) IS
    v_no_secu Ayant_Droit.no_secu%TYPE;
    v_no_ordo Ordonnance.no_ordo%TYPE;
BEGIN
    SELECT no_secu
    INTO v_no_secu
    FROM Ayant_Droit
    WHERE no_ayant_droit = p_no_ayant_droit;

    INSERT INTO Ordonnance(no_ordo, date_ordo, no_secu, payable)
    VALUES (OrdID.NEXTVAL, p_date_ordo, v_no_secu, 'FALSE')
    RETURNING no_ordo INTO v_no_ordo;

    INSERT INTO Ordo_Ayant_Droit(no_ordo, no_ayant_droit)
    VALUES (v_no_ordo, p_no_ayant_droit);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ayant droit inexistant.');
END;
/

/* 4. Afficher le n-ieme et le n+1-ieme plus anciens ayants droit inscrits. */
CREATE OR REPLACE FUNCTION anciens_ayants_droit (
    p_n IN NUMBER
) RETURN VARCHAR2 IS
    v_result VARCHAR2(1000) := '';
    v_rang   NUMBER := 0;
BEGIN
    FOR ad IN (
        SELECT no_ayant_droit, nom, prenom, date_naissance
        FROM Ayant_Droit
        ORDER BY date_naissance ASC, no_ayant_droit ASC
    ) LOOP
        v_rang := v_rang + 1;

        IF v_rang = p_n OR v_rang = p_n + 1 THEN
            v_result := v_result
                || v_rang || ' - '
                || ad.no_ayant_droit || ' '
                || ad.nom || ' '
                || ad.prenom || ' '
                || TO_CHAR(ad.date_naissance, 'DD/MM/YYYY') || CHR(10);
        END IF;

        EXIT WHEN v_rang = p_n + 1;
    END LOOP;

    RETURN v_result;
END;
/

/*
  5. Cumul_Remb_Sec_Soc contient une donnee calculee. Un trigger evite que le
     cumul devienne incoherent lorsqu'une ordonnance devient payable.
*/
CREATE OR REPLACE TRIGGER trg_cumul_remboursement
AFTER INSERT OR UPDATE OF payable ON Ordonnance
FOR EACH ROW
DECLARE
    v_montant NUMBER := 0;
    v_annee   NUMBER;
BEGIN
    IF :NEW.payable = 'TRUE'
       AND (INSERTING OR NVL(:OLD.payable, 'FALSE') <> 'TRUE') THEN

        SELECT NVL(SUM(om.qte_medicament * m.tarif), 0)
        INTO v_montant
        FROM Ordo_Medic om
             JOIN Medicament m ON m.no_medicament = om.no_medicament
        WHERE om.no_ordo = :NEW.no_ordo;

        v_annee := EXTRACT(YEAR FROM :NEW.date_ordo);

        UPDATE Cumul_Remb_Sec_Soc
        SET montant_cumule = montant_cumule + v_montant
        WHERE no_secu = :NEW.no_secu
          AND annee = v_annee;

        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO Cumul_Remb_Sec_Soc(no_secu, annee, montant_cumule)
            VALUES (:NEW.no_secu, v_annee, v_montant);
        END IF;
    END IF;
END;
/

/* -------------------------------------------------------------------------- */
/* Exercice 2 - B. Base de donnees repartie                                   */
/* -------------------------------------------------------------------------- */

/*
  1. Repartition possible par centre.

  Dans chaque centre local, par exemple Centre69, Centre95, Centre971 :
    - fragment horizontal de Assure selon no_centre ;
    - Ayant_Droit des assures du centre ;
    - Ordonnance des assures du centre ;
    - Ordo_Ayant_Droit et Ordo_Medic lies aux ordonnances locales ;
    - Cumul_Remb_Sec_Soc des assures du centre.

  Donnees communes :
    - Medicament peut etre replique dans chaque centre, car le catalogue est
      souvent lu et peu modifie ;
    - Centre_Sec_Soc peut etre replique ou maintenu dans un centre de reference.

  Justification :
    - les traitements quotidiens restent locaux au centre de rattachement ;
    - les donnees d'un assure sont proches du centre qui les gere ;
    - les responsables peuvent reconstruire une vision globale avec UNION ALL.
*/

CREATE OR REPLACE VIEW v_assures_global AS
SELECT * FROM Assure@Centre69
UNION ALL
SELECT * FROM Assure@Centre95
UNION ALL
SELECT * FROM Assure@Centre971;

CREATE OR REPLACE VIEW v_ordonnances_global AS
SELECT * FROM Ordonnance@Centre69
UNION ALL
SELECT * FROM Ordonnance@Centre95
UNION ALL
SELECT * FROM Ordonnance@Centre971;

/*
  2. Pour obtenir les meilleures performances sur Centre_Sec_Soc depuis les
     autres centres, creer une vue materialisee locale rafraichie regulierement.
*/
CREATE MATERIALIZED VIEW mv_centre_sec_soc
REFRESH ON DEMAND
AS
SELECT no_centre, adresse, ville, cp
FROM Centre_Sec_Soc@Centre69;

