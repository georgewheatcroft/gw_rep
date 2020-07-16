/* just a simple trigger which moves contacts from initial table to "action tables" which some scripts I wrote would pull from and action */
CREATE OR REPLACE TRIGGER "MY_DB"."INSERTTOACTIONTABLES"
  AFTER INSERT OR UPDATE
  on "MY_DB"."M_SITE_SEGMENT"
  
Declare 
        v_count NUMBER;

BEGIN

select COUNT(*) --expensive, will look to improve
INTO v_count
FROM M_SITE_SEGMENT
WHERE APP_OR_REJECT is not null;
--if count >0, must have contacts which have been assigned for approval or rejection                    
IF v_count >0
        THEN
                                                        
        INSERT INTO
        M_SITE_APPROVED (M_SITE_SEGMENT_GUID, TID, SEGMENT, ID, ROLE, UPDATED_BY, APP_OR_REJECT, UPDATED_DATE)
        SELECT 
        M_SITE_SEGMENT_GUID, TID, SEGMENT, ID, ROLE, UPDATED_BY, APP_OR_REJECT, UPDATED_DATE 
        FROM 
        M_SITE_SEGMENT WHERE APP_OR_REJECT = 'APPROVED';
                                                                                          
        INSERT INTO 
        M_SITE_REJECTED (M_SITE_SEGMENT_GUID, TID, SEGMENT, ID, ROLE, UPDATED_BY, APP_OR_REJECT, UPDATED_DATE)
        SELECT 
        M_SITE_SEGMENT_GUID, TID, SEGMENT, ID, ROLE, UPDATED_BY, APP_OR_REJECT, UPDATED_DATE 
        FROM 
        M_SITE_SEGMENT WHERE APP_OR_REJECT = 'REJECTED';     
        
        DELETE
        FROM
        "MY_DB".M_SITE_SEGMENT     
        WHERE
        APP_OR_REJECT = 'APPROVED' or APP_OR_REJECT = 'REJECTED';
                                                                                                                                                              
        DBMS_OUTPUT.PUT_LINE('Trigger: Insert to action Tables Executed');

ELSE 
        DBMS_OUTPUT.PUT_LINE('Trigger: Insert to action Tables NOT executed');    

END IF;

end;
