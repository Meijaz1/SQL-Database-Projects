-- Procedure: list_papers_a
-- Purpose: List papers that were submitted to a given conference AND are on a given topic.
-- Inputs:
--   p_conf_id  IN NUMBER  -- conference id to filter by
--   p_topic_id IN NUMBER  -- topic id to filter by
-- Outputs:
--   Printed lines to DBMS_OUTPUT with paper_id and paper_title; or messages when invalid IDs / none found.
-- Exceptions:
--   Catches generic errors and prints SQLERRM.

CREATE OR REPLACE PROCEDURE list_papers_a(
    p_conf_id IN NUMBER,
    p_topic_id IN NUMBER
)
AS
    v_cnt_conf   NUMBER := 0;    -- store conference existence check
    v_cnt_topic  NUMBER := 0;    -- store topic existence check
    v_rows_found NUMBER := 0;    -- count of output rows printed

    -- Cursor: find paper rows that are on the topic AND have a submission for the conference
    CURSOR cur_papers IS
        SELECT p.paper_id, p.paper_title
        FROM   paper p
               JOIN submission s ON p.paper_id = s.paper_id
        WHERE  s.conference_id = p_conf_id
          AND  p.topic_id = p_topic_id
        ORDER BY p.paper_id;
BEGIN
    -- Validate that the conference exists
    SELECT COUNT(*) INTO v_cnt_conf FROM conference WHERE conference_id = p_conf_id;

    -- Validate that the topic exists
    SELECT COUNT(*) INTO v_cnt_topic FROM topic WHERE topic_id = p_topic_id;

    -- If either is missing, print which one and exit
    IF v_cnt_conf = 0 OR v_cnt_topic = 0 THEN
        IF v_cnt_conf = 0 AND v_cnt_topic = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Invalid conference ID AND invalid topic ID.');
        ELSIF v_cnt_conf = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Invalid conference ID: ' || p_conf_id);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Invalid topic ID: ' || p_topic_id);
        END IF;
        RETURN;
    END IF;

    -- Both IDs valid: print header then loop through matching papers
    DBMS_OUTPUT.PUT_LINE('Papers for Conference ' || p_conf_id ||
                         ' on Topic ' || p_topic_id || ':');

    FOR r IN cur_papers LOOP
        v_rows_found := v_rows_found + 1;
        DBMS_OUTPUT.PUT_LINE('  Paper ID: ' || r.paper_id ||
                             ' | Title: ' || r.paper_title);
    END LOOP;

    -- If no rows matched, inform user
    IF v_rows_found = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  (No papers found for this conference + topic)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Total papers: ' || v_rows_found);
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected: No data found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
        RAISE;
END;
/
SET SERVEROUTPUT ON;
EXEC list_papers_a(1, 10);
EXEC list_papers_a(2, 10);
EXEC list_papers_a(999, 10);
EXEC list_papers_a(999, 999);
SELECT * FROM conference;
SELECT * FROM topic;
SELECT * FROM paper;
SELECT * FROM submission;
