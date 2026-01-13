CREATE OR REPLACE FUNCTION count_delivered_packages(
    p_cid IN NUMBER,
    p_start_date IN DATE,
    p_end_date IN DATE
) RETURN NUMBER IS
    v_customer_exists NUMBER;
    v_package_count NUMBER;
BEGIN
    -- Check if customer exists
    SELECT COUNT(*) INTO v_customer_exists
    FROM customer
    WHERE cid = p_cid;
    
    IF v_customer_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid cid');
        RETURN -1;
    END IF;
    
    -- Count delivered packages
    SELECT COUNT(*) INTO v_package_count
    FROM package p
    JOIN trace t ON p.pid = t.pid AND p.current_lid = t.lid
    WHERE p.receiver_id = p_cid
    AND t.status = 3
    AND p.delivery_date BETWEEN p_start_date AND p_end_date;
    
    RETURN v_package_count;
END;
/
SET SERVEROUTPUT ON;

DECLARE
    v_result NUMBER;
BEGIN
    -- Test Case 1: Valid customer ID (customer 3 - Olivia)
    DBMS_OUTPUT.PUT_LINE('--- Test Case 1: Valid Customer ID ---');
    v_result := count_delivered_packages(3, DATE '2025-10-01', DATE '2025-10-31');
    DBMS_OUTPUT.PUT_LINE('Customer ID 3 (Olivia): ' || v_result || ' delivered packages');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test Case 2: Invalid customer ID
    DBMS_OUTPUT.PUT_LINE('--- Test Case 2: Invalid Customer ID ---');
    v_result := count_delivered_packages(999, DATE '2025-10-01', DATE '2025-10-31');
    DBMS_OUTPUT.PUT_LINE('Customer ID 999: ' || v_result || ' packages');
END;
/
CREATE OR REPLACE PROCEDURE print_package_trace(
    p_pid IN NUMBER
) IS
    v_package_exists NUMBER;
    v_latest_lid NUMBER;
    v_status_text VARCHAR2(20);
    
    CURSOR trace_cursor IS
        SELECT l.address, t.ltime, t.status, t.lid
        FROM trace t
        JOIN location l ON t.lid = l.lid
        WHERE t.pid = p_pid
        ORDER BY t.ltime ASC;
BEGIN
    -- Check if package exists
    SELECT COUNT(*) INTO v_package_exists
    FROM package
    WHERE pid = p_pid;
    
    IF v_package_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid package ID');
        RETURN;
    END IF;
    
    -- Print header
    DBMS_OUTPUT.PUT_LINE('Trace for Package ID: ' || p_pid);
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    
    -- Print all trace records
    FOR trace_rec IN trace_cursor LOOP
        -- Convert status number to text
        CASE trace_rec.status
            WHEN 1 THEN v_status_text := 'In Transit';
            WHEN 2 THEN v_status_text := 'Out for Delivery';
            WHEN 3 THEN v_status_text := 'Delivered';
            ELSE v_status_text := 'Unknown';
        END CASE;
        
        DBMS_OUTPUT.PUT_LINE('Location: ' || trace_rec.address);
        DBMS_OUTPUT.PUT_LINE('Time: ' || TO_CHAR(trace_rec.ltime, 'YYYY-MM-DD HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('Status: ' || v_status_text);
        DBMS_OUTPUT.PUT_LINE('');
        
        -- Keep track of latest location ID
        v_latest_lid := trace_rec.lid;
    END LOOP;
    
    -- Update current_lid in package table
    UPDATE package
    SET current_lid = v_latest_lid
    WHERE pid = p_pid;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Current location id is ' || v_latest_lid);
END;
/
SET SERVEROUTPUT ON;

BEGIN
    print_package_trace(1);
END;
/
SET SERVEROUTPUT ON;

BEGIN
    print_package_trace(999);
END;
/

