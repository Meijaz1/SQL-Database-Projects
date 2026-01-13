Drop Table Trace Cascade Constraints;
Drop Table Package Cascade Constraints;
Drop Table Location Cascade Constraints;
Drop Table Customer Cascade Constraints;
Create Table Customer
(Cid Int,
Cname Varchar(50),
Cemail Varchar(50),
Balance Number,
Primary Key(Cid));
Insert Into Customer Values
(1, 'Ella','ella@gmail.com',0);
Insert Into Customer Values
(2, 'Eric','eric@gmail.com',0);
Insert Into Customer Values
(3, 'Olivia','olivia@gmail.com',0);
Create Table Location
(Lid Int,
Ltype Int, -- 1: customer address, 2: warehouse, 3: truck
Address Varchar(100),
Primary Key(Lid));
Insert Into Location Values
(1, 1,'1000 Hilltop Rd, Baltimore, MD');
Insert Into Location Values
(2, 1,'1234 Baltimore National Pike, Columbia, MD');
--- warehouse
Insert Into Location Values
(3, 2,'1234 Frederick Rd, Catonsville, MD');
-- warehouse
Insert Into Location Values
(4, 2,'1758 Main Street, Baltimore, MD');
-- truck
Insert Into Location Values
(5, 3,'Truck ID 1234');
Insert Into Location Values
(6, 3,'Truck ID 2234');
Create Table Package
(Pid Int, -- package id
Sender_Id Int,-- sender's customer id
Receiver_Id Int,-- receiver's customer id
Sender_Lid Int, -- location id of where the sender drops off the package
Receiver_Lid Int, -- location id of where the package will be delivered
Dropoff_Date Date, -- date of the package is dropped off
Delivery_Date Date,-- estimated delivery date
Weight Number,-- weight of package
Cost Number, -- shipping cost
Current_Lid Int,-- current location of the package
Primary Key(Pid),
Foreign Key(Sender_Id) References Customer,
Foreign Key(Receiver_Id) References Customer,
Foreign Key(Sender_Lid) References Location,
Foreign Key(Receiver_Lid) References Location,
Foreign Key(Current_Lid) References Location);
-- package sent by Ella to Eric,
-- currently at location 5 (truck)
Insert Into Package Values
(1,1,2,1,2,Date '2025-10-1',Date '2025-10-2',3,6.00,5);
-- package sent by Ella to Olivia, delivered
Insert Into Package Values
(2,1,3,1,2,Date '2025-10-2',Date '2025-10-3',2,5.00,2);
-- package sent by Olivia to Ella, currently at a warehouse
Insert Into Package Values
(3,3,1,2,1,Date '2025-10-5',Date '2025-10-6',2,5.00,3);
Create Table Trace
(
Tid Int, --- trace id
Pid Int,-- package id
Lid Int, -- location id
Ltime Timestamp, -- timestamp at the location
Status Int, -- 1: in transit, 2: out for delivery, 3: delivered.
Primary Key(Tid),
Foreign Key(Pid) References Package,
Foreign Key(Lid) References Location
);
-- package 1, trace: location 1, 3, 5
Insert Into Trace Values
(1,1,1,Timestamp '2025-10-1 10:00:00.00',1);
-- at location 3, in transit
Insert Into Trace Values
(2,1,3,Timestamp '2025-10-1 20:00:00.00',1);
-- at location 5 truck, out for delivery
Insert Into Trace Values
(3,1,5,Timestamp '2025-10-2 10:00:00.00',2);
-- package 2, trace location 1, 4, 6, 2
Select S.Cname As Sender_Name,
       R.Cname As Receiver_Name
From Package P
Join Customer S On P.Sender_Id = S.Cid
Join Customer R On P.Receiver_Id = R.Cid
Where P.Pid = 1;
Select L.Address As Current_Location,
       T.Status
From Package P
Join Customer C On P.Sender_Id = C.Cid
Join Location L On P.Current_Lid = L.Lid
Join Trace T On P.Pid = T.Pid
Where C.Cname = 'Ella';
Select C.Cname
From Customer C
Join Package P On C.Cid = P.Sender_Id
Group By C.Cname
Having Count(P.Pid) >= 2;
Select Distinct T2.Pid, T2.Lid
From Trace T1
Join Trace T2 On T1.Lid = T2.Lid
Where T1.Pid = 1 And T2.Pid <> 1;
