-- Teardown (safe to skip if first run)
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE trace CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE package CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE location CASCADE CONSTRAINTS';
  EXECUTE IMMEDIATE 'DROP TABLE customer CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- 1) CUSTOMER
CREATE TABLE customer (
  cid     INT,
  cname   VARCHAR2(50),
  cemail  VARCHAR2(50),
  balance NUMBER,
  CONSTRAINT pk_customer PRIMARY KEY (cid)
);

INSERT INTO customer VALUES (1, 'Ella',   'ella@gmail.com',   0);
INSERT INTO customer VALUES (2, 'Eric',   'eric@gmail.com',   0);
INSERT INTO customer VALUES (3, 'Olivia', 'olivia@gmail.com', 0);

-- 2) LOCATION
CREATE TABLE location (
  lid    INT,
  ltype  INT, -- 1: customer address, 2: warehouse, 3: truck
  address VARCHAR2(100),
  CONSTRAINT pk_location PRIMARY KEY (lid),
  CONSTRAINT ck_location_ltype CHECK (ltype IN (1,2,3))
);

INSERT INTO location VALUES (1, 1, '1000 Hilltop Rd, Baltimore, MD');
INSERT INTO location VALUES (2, 1, '1234 Baltimore National Pike, Columbia, MD');
-- warehouse
INSERT INTO location VALUES (3, 2, '1234 Frederick Rd, Catonsville, MD');
-- warehouse
INSERT INTO location VALUES (4, 2, '1758 Main Street, Baltimore, MD');
-- truck
INSERT INTO location VALUES (5, 3, 'Truck ID 1234');
INSERT INTO location VALUES (6, 3, 'Truck ID 2234');

-- 3) PACKAGE
CREATE TABLE package (
  pid           INT,           -- package id
  sender_id     INT,           -- sender's customer id
  receiver_id   INT,           -- receiver's customer id
  sender_lid    INT,           -- location id where sender drops off
  receiver_lid  INT,           -- location id for delivery
  dropoff_date  DATE,          -- date package is dropped off
  delivery_date DATE,          -- estimated delivery date
  weight        NUMBER,        -- weight of package
  cost          NUMBER,        -- shipping cost
  current_lid   INT,           -- current location of the package
  CONSTRAINT pk_package PRIMARY KEY (pid),
  CONSTRAINT fk_pkg_sender    FOREIGN KEY (sender_id)    REFERENCES customer (cid),
  CONSTRAINT fk_pkg_receiver  FOREIGN KEY (receiver_id)  REFERENCES customer (cid),
  CONSTRAINT fk_pkg_sender_l  FOREIGN KEY (sender_lid)   REFERENCES location (lid),
  CONSTRAINT fk_pkg_receiver_l FOREIGN KEY (receiver_lid) REFERENCES location (lid),
  CONSTRAINT fk_pkg_current_l FOREIGN KEY (current_lid)  REFERENCES location (lid)
);

-- package 1: Ella -> Eric, currently at location 5 (truck)
INSERT INTO package VALUES
(1, 1, 2, 1, 2, DATE '2025-10-01', DATE '2025-10-02', 3, 6.00, 5);

-- package 2: Ella -> Olivia, delivered (current_lid = 2)
INSERT INTO package VALUES
(2, 1, 3, 1, 2, DATE '2025-10-02', DATE '2025-10-03', 2, 5.00, 2);

-- package 3: Olivia -> Ella, currently at a warehouse (lid 3)
INSERT INTO package VALUES
(3, 3, 1, 2, 1, DATE '2025-10-05', DATE '2025-10-06', 2, 5.00, 3);

-- 4) TRACE
CREATE TABLE trace (
  tid   INT,         -- trace id
  pid   INT,         -- package id
  lid   INT,         -- location id
  ltime TIMESTAMP,   -- timestamp at the location
  status INT,        -- 1: in transit, 2: out for delivery, 3: delivered
  CONSTRAINT pk_trace PRIMARY KEY (tid),
  CONSTRAINT fk_trace_pkg FOREIGN KEY (pid) REFERENCES package (pid),
  CONSTRAINT fk_trace_loc FOREIGN KEY (lid) REFERENCES location (lid),
  CONSTRAINT ck_trace_status CHECK (status IN (1,2,3))
);

-- package 1, trace: location 1, 3, 5
INSERT INTO trace VALUES (1, 1, 1, TIMESTAMP '2025-10-01 10:00:00.00', 1);
INSERT INTO trace VALUES (2, 1, 3, TIMESTAMP '2025-10-01 20:00:00.00', 1);
INSERT INTO trace VALUES (3, 1, 5, TIMESTAMP '2025-10-02 10:00:00.00', 2);

-- package 2, trace: location 1, 4, 6, 2
INSERT INTO trace VALUES (4, 2, 1, TIMESTAMP '2025-10-02 10:00:00.00', 1);
INSERT INTO trace VALUES (5, 2, 4, TIMESTAMP '2025-10-02 18:00:00.00', 1);
INSERT INTO trace VALUES (6, 2, 6, TIMESTAMP '2025-10-03 08:00:00.00', 2);
INSERT INTO trace VALUES (7, 2, 2, TIMESTAMP '2025-10-03 18:00:00.00', 3);

-- package 3, trace: location 2, 3
INSERT INTO trace VALUES (8, 3, 2, TIMESTAMP '2025-10-05 10:00:00.00', 1);
INSERT INTO trace VALUES (9, 3, 3, TIMESTAMP '2025-10-05 18:00:00.00', 1);

COMMIT;
-- A) Current status + location for each package
SELECT p.pid,
       c_from.cname AS sender,
       c_to.cname   AS receiver,
       l.address    AS current_location,
       p.delivery_date
FROM package p
JOIN customer c_from ON c_from.cid = p.sender_id
JOIN customer c_to   ON c_to.cid   = p.receiver_id
LEFT JOIN location l ON l.lid      = p.current_lid
ORDER BY p.pid;

-- B) Full trace for a package (replace :pid)
SELECT t.pid, t.tid, t.ltime, t.status, l.address
FROM trace t
JOIN location l ON l.lid = t.lid
WHERE t.pid = :pid
ORDER BY t.ltime;

-- C) Packages not yet delivered (by latest trace status)
SELECT p.pid
FROM package p
LEFT JOIN (
  SELECT pid, MAX(ltime) AS last_time
  FROM trace
  GROUP BY pid
) last ON last.pid = p.pid
LEFT JOIN trace t ON t.pid = p.pid AND t.ltime = last.last_time
WHERE NVL(t.status, 1) <> 3
ORDER BY p.pid;

-- D) Mark a package delivered now (set current location = receiver address)
--    Replace :pid
UPDATE package p
SET current_lid = p.receiver_lid, delivery_date = TRUNC(SYSDATE)
WHERE p.pid = :pid;

INSERT INTO trace (tid, pid, lid, ltime, status)
SELECT (SELECT NVL(MAX(tid),0)+1 FROM trace),
       p.pid, p.receiver_lid, SYSTIMESTAMP, 3
FROM package p
WHERE p.pid = :pid;

-- E) Total spent per customer as sender
SELECT c.cname, SUM(p.cost) AS total_shipping_spend
FROM customer c
JOIN package p ON p.sender_id = c.cid
GROUP BY c.cname
ORDER BY total_shipping_spend DESC NULLS LAST;
CREATE INDEX ix_package_sender    ON package(sender_id);
CREATE INDEX ix_package_receiver  ON package(receiver_id);
CREATE INDEX ix_package_current   ON package(current_lid);
CREATE INDEX ix_trace_pid_time    ON trace(pid, ltime);

-- Problem 1: LCM of 2468 and 3702 using only a loop
DECLARE
  a    PLS_INTEGER := 2468;
  b    PLS_INTEGER := 3702;
  x    PLS_INTEGER;
  lcm  PLS_INTEGER;
BEGIN
  IF a = b THEN
    DBMS_OUTPUT.PUT_LINE('LCM = ' || a);
    RETURN;
  END IF;

  -- x is the larger of a and b
  x   := CASE WHEN a > b THEN a ELSE b END;
  lcm := x;

  -- Loop until we find the first common multiple
  LOOP
    IF MOD(lcm, a) = 0 AND MOD(lcm, b) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('LCM = ' || lcm);
      EXIT;
    ELSE
      lcm := lcm + x; -- try next multiple of the larger number
    END IF;
  END LOOP;
END;
/
-- Problem 1: LCM of 2468 and 3702 using only a loop
DECLARE
  a    PLS_INTEGER := 2468;
  b    PLS_INTEGER := 3702;
  x    PLS_INTEGER;
  lcm  PLS_INTEGER;
BEGIN
  IF a = b THEN
    DBMS_OUTPUT.PUT_LINE('LCM = ' || a);
    RETURN;
  END IF;

  -- x is the larger of a and b
  x   := CASE WHEN a > b THEN a ELSE b END;
  lcm := x;

  -- Loop until we find the first common multiple
  LOOP
    IF MOD(lcm, a) = 0 AND MOD(lcm, b) = 0 THEN
      DBMS_OUTPUT.PUT_LINE('LCM = ' || lcm);
      EXIT;
    ELSE
      lcm := lcm + x; -- try next multiple of the larger number
    END IF;
  END LOOP;
END;
/
SET SERVEROUTPUT ON

DECLARE
  v_total_cost NUMBER := 0;
  v_ella_cid   customer.cid%TYPE;

  /* Cursor declared before BEGIN */
  CURSOR c_pkgs IS
    SELECT
      p.pid,
      rcvr.cname AS receiver_name,
      p.cost,
      /* latest status text by the most recent timestamp */
      (SELECT CASE t.status
                WHEN 1 THEN 'in transit'
                WHEN 2 THEN 'out for delivery'
                WHEN 3 THEN 'delivered'
                ELSE 'unknown'
              END
         FROM trace t
        WHERE t.pid = p.pid
          AND t.ltime = (
                SELECT MAX(t2.ltime)
                FROM trace t2
                WHERE t2.pid = p.pid
              )
      ) AS latest_status
    FROM package p
    JOIN customer snd  ON snd.cid = p.sender_id
    JOIN customer rcvr ON rcvr.cid = p.receiver_id
    WHERE snd.cname = 'Ella'
    ORDER BY p.pid;

BEGIN
  /* 1) Find Ella (and exit if missing) */
  BEGIN
    SELECT cid INTO v_ella_cid
    FROM customer
    WHERE cname = 'Ella';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No such customer');
      RETURN;
  END;

  /* 2) Print packages Ella has sent */
  DBMS_OUTPUT.PUT_LINE('Packages sent by Ella:');
  DBMS_OUTPUT.PUT_LINE('PID | Receiver | Cost | Current Status');

  FOR r IN c_pkgs LOOP
    v_total_cost := v_total_cost + NVL(r.cost, 0);
    DBMS_OUTPUT.PUT_LINE(
      r.pid || ' | ' ||
      r.receiver_name || ' | ' ||
      TO_CHAR(NVL(r.cost,0), 'FM9999990.00') || ' | ' ||
      NVL(r.latest_status, 'unknown')
    );
  END LOOP;

  /* 3) Print total and update balance */
  DBMS_OUTPUT.PUT_LINE('Total cost of Ella''s sent packages = ' ||
                       TO_CHAR(v_total_cost, 'FM9999990.00'));

  UPDATE customer
     SET balance = v_total_cost
   WHERE cid = v_ella_cid;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Customer balance updated.');
END;
/
