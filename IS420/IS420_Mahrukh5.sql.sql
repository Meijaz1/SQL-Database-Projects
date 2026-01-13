CREATE OR REPLACE PROCEDURE list_papers_conf_topic(
    p_conference_id IN NUMBER,
    p_topic_id IN NUMBER
) 
AS
    v_conference_count NUMBER;
    v_topic_count NUMBER;
    v_paper_count NUMBER := 0;
    
    CURSOR c_papers IS
        SELECT DISTINCT p.paper_id, p.paper_title
        FROM paper p
        INNER JOIN submission s ON p.paper_id = s.paper_id
        WHERE s.conference_id = p_conference_id
          AND p.topic_id = p_topic_id
        ORDER BY p.paper_id;
    
BEGIN
    -- Step 1: Validate conference ID
    SELECT COUNT(*)
    INTO v_conference_count
    FROM conference
    WHERE conference_id = p_conference_id;
    
    IF v_conference_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid conference ID');
        RETURN;
    END IF;
    
    -- Step 2: Validate topic ID
    SELECT COUNT(*)
    INTO v_topic_count
    FROM topic
    WHERE topic_id = p_topic_id;
    
    IF v_topic_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid topic ID');
        RETURN;
    END IF;
    
    -- Step 3: Display papers
    FOR paper_rec IN c_papers LOOP
        DBMS_OUTPUT.PUT_LINE('Paper ID: ' || paper_rec.paper_id || 
                           ', Title: ' || paper_rec.paper_title);
        v_paper_count := v_paper_count + 1;
    END LOOP;
    
    IF v_paper_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No papers found');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END list_papers_conf_topic;
/
-- View all conferences
SELECT conference_id,       conference_title FROM conference;

-- View all topics
SELECT topic_id, topic_name FROM topic;

-- View all papers with their topics
SELECT p.paper_id, p.paper_title, p.topic_id, t.topic_name
FROM paper p
LEFT JOIN topic t ON p.topic_id = t.topic_id;

-- View submissions (papers linked to conferences)
SELECT s.submission_id, s.paper_id, s.conference_id, p.paper_title
FROM submission s
LEFT JOIN paper p ON s.paper_id = p.paper_id;

-- View papers by conference and topic
SELECT s.conference_id, p.topic_id, COUNT(*) as paper_count
FROM submission s
JOIN paper p ON s.paper_id = p.paper_id
GROUP BY s.conference_id, p.topic_id
ORDER BY s.conference_id, p.topic_id;
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- TEST CASE 1: Normal Case - Valid IDs with papers
-- Replace with actual conference_id and topic_id that have papers
PROMPT ========================================
PROMPT TEST CASE 1: Valid Conference and Topic
PROMPT ========================================
BEGIN
    list_papers_conf_topic(1, 10);  -- CHANGE THESE to match your data
END;
/

-- TEST CASE 2: Invalid Conference ID
PROMPT ========================================
PROMPT TEST CASE 2: Invalid Conference ID
PROMPT ========================================
BEGIN
    list_papers_conf_topic(9999, 10);
END;
/

-- TEST CASE 3: Invalid Topic ID
PROMPT ========================================
PROMPT TEST CASE 3: Invalid Topic ID
PROMPT ========================================
BEGIN
    list_papers_conf_topic(1, 9999);
END;
/

-- TEST CASE 4: Both Invalid
PROMPT ========================================
PROMPT TEST CASE 4: Both IDs Invalid
PROMPT ========================================
BEGIN
    list_papers_conf_topic(9999, 9999);
END;
/

-- TEST CASE 5: Valid IDs but no matching papers
PROMPT ========================================
PROMPT TEST CASE 5: Valid IDs, No Papers
PROMPT ========================================
BEGIN
    list_papers_conf_topic(2, 5);  -- Use IDs that exist but have no papers
END;
/