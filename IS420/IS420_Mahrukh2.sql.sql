-- ==============================================================
-- STEP 2 : Create tables and insert sample data
-- ==============================================================

-- Drop existing tables (ignore errors if they don't exist)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE Member CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE MembershipType CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE Club CASCADE CONSTRAINTS';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
-----------------------------------------------------------------
-- Table 1 : CLUB
-----------------------------------------------------------------
CREATE TABLE Club (
    club_id     NUMBER PRIMARY KEY,
    club_name   VARCHAR2(100) NOT NULL,
    location    VARCHAR2(100) NOT NULL
);
-----------------------------------------------------------------
-- Table 2 : MEMBERSHIPTYPE
-----------------------------------------------------------------
CREATE TABLE MembershipType (
    membership_type_id NUMBER PRIMARY KEY,
    type_name          VARCHAR2(50) NOT NULL,
    monthly_fee        NUMBER(8,2)  NOT NULL,
    benefits           VARCHAR2(100)
);
-----------------------------------------------------------------
-- Table 3 : MEMBER
-----------------------------------------------------------------
CREATE TABLE Member (
    member_id          NUMBER PRIMARY KEY,
    first_name         VARCHAR2(50) NOT NULL,
    last_name          VARCHAR2(50) NOT NULL,
    email              VARCHAR2(100) UNIQUE NOT NULL,
    phone              VARCHAR2(20)  UNIQUE NOT NULL,
    membership_type_id NUMBER,
    club_id            NUMBER,
    join_date          DATE NOT NULL,
    FOREIGN KEY (membership_type_id) REFERENCES MembershipType(membership_type_id),
    FOREIGN KEY (club_id)            REFERENCES Club(club_id)
);
-----------------------------------------------------------------
-- Insert rows into CLUB
-----------------------------------------------------------------
INSERT ALL
INTO Club VALUES (1, 'Legends Gym – Westminster',      'Westminster MD')
INTO Club VALUES (2, 'Legends Gym – Baltimore',        'Baltimore MD')
INTO Club VALUES (3, 'Legends Gym – Downtown Baltimore','Baltimore MD')
INTO Club VALUES (4, 'Legends Gym – Hanover',          'Hanover MD')
INTO Club VALUES (5, 'Legends Gym – Bel Air',          'Bel Air MD')
SELECT 1 FROM dual;
-----------------------------------------------------------------
-- Insert rows into MEMBERSHIPTYPE
-----------------------------------------------------------------
INSERT ALL
INTO MembershipType VALUES (1, 'Basic Tier',   19.99, 'Entry into Home Club')
INTO MembershipType VALUES (2, 'Silver Tier',  34.99, 'Home Club + 1 Club, 1 Free Drink / Month')
INTO MembershipType VALUES (3, 'Gold Tier',    49.99, 'Home + 2 Clubs, 3 Drinks, 3 Classes, Pool')
INTO MembershipType VALUES (4, 'Premium Tier', 79.99, 'All Clubs, 5 Drinks, 3 Classes, Pool')
INTO MembershipType VALUES (5, 'VIP Tier',    119.99, 'All Clubs, Unlimited Drinks, 5 Classes, Pool')
SELECT 1 FROM dual;
-----------------------------------------------------------------
-- Insert rows into MEMBER
-----------------------------------------------------------------
INSERT ALL
INTO Member VALUES (11,'Conor','Doyle','cdoyle@umbc.edu','123-456-7890',5,1,DATE '2023-08-23')
INTO Member VALUES (12,'Lizzie','Dinh','dinh@gmail.com','321-645-0987',1,3,DATE '2024-04-23')
INTO Member VALUES (13,'Dan','Morelli','moreDan@yahoo.com','213-546-8790',2,4,DATE '2024-07-02')
INTO Member VALUES (14,'John','Doe','doe@comcast.net','908-765-4321',4,4,DATE '2024-07-22')
INTO Member VALUES (15,'Jane','Dere','dere@umbc.edu','456-231-9367',3,5,DATE '2025-03-23')
SELECT 1 FROM dual;
-----------------------------------------------------------------
-- Commit changes and display verification queries
-----------------------------------------------------------------
COMMIT;

-- Verification queries (for screenshots)
SELECT * FROM Club;
SELECT * FROM MembershipType;
SELECT * FROM Member;
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE proc_list_mem_by_club_type'; 
EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE OR REPLACE PROCEDURE proc_list_mem_by_club_type
(
    p_club_id            IN Club.club_id%TYPE,
    p_membership_type_id IN MembershipType.membership_type_id%TYPE
)
AS
    v_cnt_club  PLS_INTEGER;
    v_cnt_type  PLS_INTEGER;
    v_rows      PLS_INTEGER := 0;

    CURSOR c_members IS
        SELECT m.member_id,
               m.first_name || ' ' || m.last_name AS full_name
        FROM   Member m
        WHERE  m.club_id = p_club_id
        AND    m.membership_type_id = p_membership_type_id
        ORDER  BY m.last_name, m.first_name;
BEGIN
    SELECT COUNT(*) INTO v_cnt_club FROM Club WHERE club_id = p_club_id;
    SELECT COUNT(*) INTO v_cnt_type FROM MembershipType WHERE membership_type_id = p_membership_type_id;

    IF v_cnt_club = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid club ID: ' || p_club_id);
        RETURN;
    ELSIF v_cnt_type = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid membership type ID: ' || p_membership_type_id);
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Members in club_id=' || p_club_id ||
                         ' with membership_type_id=' || p_membership_type_id || ':');

    FOR r IN c_members LOOP
        v_rows := v_rows + 1;
        DBMS_OUTPUT.PUT_LINE('  • Member ID: ' || r.member_id ||
                             ' | Name: ' || r.full_name);
    END LOOP;

    IF v_rows = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (No members matched your criteria.)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Total matches: ' || v_rows);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found during validation.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/
BEGIN EXECUTE IMMEDIATE 'DROP FUNCTION fn_cnt_mem_by_club_type';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
CREATE OR REPLACE FUNCTION fn_cnt_mem_by_club_type
(
    p_club_id            IN Club.club_id%TYPE,
    p_membership_type_id IN MembershipType.membership_type_id%TYPE
) RETURN PLS_INTEGER
IS
    v_cnt_club  PLS_INTEGER;
    v_cnt_type  PLS_INTEGER;
    v_total     PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_cnt_club FROM Club WHERE club_id = p_club_id;
    IF v_cnt_club = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid club ID: ' || p_club_id);
    END IF;

    SELECT COUNT(*) INTO v_cnt_type FROM MembershipType WHERE membership_type_id = p_membership_type_id;
    IF v_cnt_type = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid membership type ID: ' || p_membership_type_id);
    END IF;

    SELECT COUNT(*) INTO v_total
    FROM Member
    WHERE club_id = p_club_id
      AND membership_type_id = p_membership_type_id;

    RETURN v_total;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('fn_cnt_mem_by_club_type failed: ' || SQLERRM);
        RAISE;
END;
/
SET SERVEROUTPUT ON;

EXEC proc_list_mem_by_club_type(4, 2);
EXEC proc_list_mem_by_club_type(4, 4);
EXEC proc_list_mem_by_club_type(99, 2);
EXEC proc_list_mem_by_club_type(1, 2);
VAR v NUMBER
EXEC :v := fn_cnt_mem_by_club_type(4, 2);
PRINT v
EXEC :v := fn_cnt_mem_by_club_type(4, 4);
PRINT v
BEGIN
  DBMS_OUTPUT.PUT_LINE('Count=' || fn_cnt_mem_by_club_type(99, 2));
EXCEPTION
  WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Caught error (as expected): ' || SQLERRM);
END;
/
