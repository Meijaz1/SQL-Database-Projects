# SQL & PL/SQL Projects (Oracle SQL Developer)

This repository contains SQL and PL/SQL scripts developed in Oracle SQL Developer as part of IS420 coursework. The work demonstrates database design (DDL), sample data setup (DML), relational querying, and PL/SQL programming using procedures, functions, cursors, validation logic, and test cases.

---

## Contents

### 1) Package Tracking Database (SQL + PL/SQL)
Designed a relational schema to model a package delivery system with customers, locations (addresses/warehouses/trucks), packages, and trace events.
Includes table creation with primary/foreign keys, constraints, sample inserts, reporting queries, indexing, and PL/SQL programs to analyze and update package status.

**Key Concepts**
- DDL/DML, PK/FK relationships, CHECK constraints
- JOIN queries for sender/receiver, current location, delivery status
- Indexing for performance (`package`, `trace`)
- PL/SQL: cursors, updates, DBMS_OUTPUT, validation + test runs

---

### 2) Gym Membership Database (SQL + PL/SQL)
Built a database for a multi-location gym system with clubs, membership tiers, and members. Implemented a stored procedure and function to list/count members by club and membership type with input validation and clear output messaging.

**Key Concepts**
- Normalized tables + referential integrity
- Procedures + functions with parameter validation
- Cursor loops + formatted output
- Test executions and expected error handling

---

### 3) Conference Papers: Procedures for Conference + Topic Filtering (PL/SQL)
Implemented stored procedures to list papers submitted to a conference filtered by topic, including checks for invalid conference/topic IDs and “no results” cases.

**Key Concepts**
- Cursor-based reporting
- Validation logic using COUNT checks
- DBMS_OUTPUT messaging and test cases

---

### 4) PL/SQL Practice: Loops, Computation, and Cursor Reporting
Includes additional PL/SQL exercises such as computing LCM using loop-only logic and producing formatted reports using cursors (e.g., summarizing packages sent by a specific customer and updating account totals).

**Key Concepts**
- Loops and numeric computation
- Cursors and aggregation
- Updates + commits with reporting output

---

## How to Run (Oracle SQL Developer)
1. Open Oracle SQL Developer and connect to your database.
2. Open a script file from this repo.
3. Run the script top-to-bottom (use **Run Script / F5**).
4. Enable output when needed:
   ```sql
   SET SERVEROUTPUT ON;
