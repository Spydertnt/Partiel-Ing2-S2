CREATE OR REPLACE TRIGGER cleLocation
BEFORE INSERT ON Location
FOR EACH ROW
DECLARE
BEGIN
    :new.no_location := LocID.nextval;
END;
/

CREATE OR REPLACE TRIGGER checkPermis
BEFORE INSERT ON location
FOR EACH ROW
DECLARE
    c_permis client.permis_conduire%type;
BEGIN
    SELECT permis_conduire INTO c_permis FROM client WHERE no_client = :new.no_client;
    IF c_permis IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Le client n''a pas de permis de conduire valide.');
    END IF;
END;
/

CREATE OR REPLACE PROCEDURE affectVehicule(loc IN NUMBER, veh IN NUMBER) IS
 loc_stat location.statut%type;
 cpt NUMBER(1,0);
BEGIN
    SELECT * FROM vehicule WHERE no_vehicule = veh;
    SELECT statut INTO loc_stat FROM location WHERE no_location = loc;

    IF loc_stat != "en cours" THEN 
        RAISE_APPLICATION_ERROR(-20003, 'Location terminée ou non existante.');
    END IF;

    SELECT COUNT(*) INTO cpt 
    FROM location l 
    JOIN vehicule_location vl ON l.no_location = vl.no_location 
    WHERE vl.no_vehicule = veh AND l.statut = "en cours";

    IF cpt > 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Le véhicule est déjà  affecté à  une location en cours.');
    END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Le véhicule ou la location n''existe pas.');
        WHEN dup_val_on_index THEN
            RAISE_APPLICATION_ERROR(-20005, 'Le véhicule est déjà  affecté à  cette location.');
    END;

CREATE OR REPLACE FUNCTION topCLient (n INT) RETURN VARCHAR IS
    result VARCHAR(500);
    cpt_location NUMBER(3,0);

    CURSOR listClient is
    SELECT no_client, nom, prenom, COUNT(*) 
    INTO no_c, nom_c, prenom_c, cpt_location
    FROM client c JOIN location l ON c.no_client = l.no_client
    GROUP BY c.no_client, c.nom, c.prenom
    ORDER BY cpt_location
    LIMIT n+1;

/*      CURSOR listClient is
        SELECT *
        FROM (
            SELECT c.no_client, c.nom, c.prenom, COUNT(*) AS cpt_location
            FROM client c JOIN location l ON c.no_client = l.no_client
            GROUP BY c.no_client, c.nom, c.prenom
            ORDER BY COUNT(*) DESC
        )
        WHERE ROWNUM <= n + 1; */

BEGIN
    cpt := 1;
    result := '';
    FOR c = listClient 
    LOOP
        IF cpt = n OR cpt_location = n+1 THEN
            result := result || c.no_client || ' ' || c.nom || ' ' || c.prenom || ' ' || c.cpt_location || CHR(10);
        END IF;
    END LOOP;
END;

Siège
client(...)
facturation(...)
agences(....)
Create view location_view as
Select *
From location@agenceLink
UNION 
Select *
from location@agence2Link

Agences
location(...)
vehicule(...)
vehicule_location(...)
cumul_dep_client(...)
create materialized view client as
SELECT no_client, permis_conduire
from client@siegeLink
REFRESH ON DEMAND;
