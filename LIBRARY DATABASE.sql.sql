
CREATE DATABASE  LibraryDatabase; --Create Database
Use LibraryDatabase; -- Select Database from list of Databases in the SQL Server

-- Creating the Addresses Table
CREATE TABLE Addresses(
AddressID int IDENTITY(10,1) NOT NULL PRIMARY KEY,
Address1 nvarchar(50) NOT NULL,
Address2 nvarchar(50) NULL,
City nvarchar(50) NULL,
Postcode nvarchar(10) NOT NULL);

-- Creating the Members Information Table
CREATE TABLE MembersInfo(
MemberId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
Firstname nvarchar(30) NOT NULL,
MiddleName nvarchar(30) NULL,
LastName nvarchar(30) NOT NULL,
DateofBirth Date NOT NULL,
Gender nvarchar(20) NOT NULL ,
AddressID Int NOT NULL FOREIGN KEY (AddressID) 
REFERENCES Addresses(AddressID),
Username nvarchar(30) UNIQUE NOT NULL,
PasswordHarsh binary(64) NOT NULL, 
Salt UNIQUEIDENTIFIER,
MemberEmail nvarchar(100)  NULL, CHECK(MemberEmail Like '%_@_%._%'),
TelephoneNo nvarchar(20) NULL,
Member_JoinDate Date  NOT NULL,
Member_EndDate Date  NULL);


--Creating the ItemTypes table
CREATE TABLE ItemTypes(
ItemTypeID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
Itemtype nvarchar(20) NOT NULL);

--Creating the LibraryCatalogue table
CREATE TABLE LibraryCatalogue(
ItemId int IDENTITY(100,1) NOT NULL PRIMARY KEY,
ItemStatus nvarchar(30) NOT NULL CHECK(ItemStatus IN ( 'Available', 'On loan', 'Overdue', 'Lost_Or_Removed')),
ItemTitle nvarchar(50) NOT NULL,
ItemTypeID Int NOT NULL FOREIGN KEY (ItemTypeId)
REFERENCES ItemTypes(ItemTypeId) ,
Author nvarchar(30) NULL,
YearPublished Date NOT NULL,
Date_Itemadded Date NOT NULL,
Date_Identified_asLost_removed Date NULL,
ISBN nvarchar(30) NULL);

--Creating the Libraryloan table
CREATE TABLE LibraryLoan(
LoanId int IDENTITY(200,1) NOT NULL PRIMARY KEY,
ItemId int NOT NULL FOREIGN KEY (ItemId)
REFERENCES LibraryCatalogue(ItemId),
MemberId  int NOT NULL FOREIGN KEY (MemberId)
REFERENCES MembersInfo(MemberId),
Date_TakenOut Date NOT NULL,
DueDate Date  NULL,
DateReturned Date NULL,
Days_Overdue Int NOT NULL DEFAULT 0);

--Creating the OverdueFines_Repayment table
CREATE TABLE OverdueFines_Repayment(
RepaymentId int IDENTITY(500,1) NOT NULL PRIMARY KEY,
MemberId int NOT NULL FOREIGN KEY (MemberId)
REFERENCES MembersInfo(MemberId),
LoanId  int NOT NULL FOREIGN KEY (LoanId)
REFERENCES LibraryLoan(LoanId),
AmountPaid money NOT NULL,
RepaymentMethod nvarchar(20) NOT NULL CHECK(RepaymentMethod IN ( 'Cash', 'Card')),
Date_TimeofPayment DateTime NOT NULL DEFAULT GETDATE());

--QUESTION 2(A)
--A STORED PROCEDURE THAT SEARCHES THE LIBRARYCATALOGUE FOR MATCHING CHARACTER STRING BY TITLE
CREATE PROCEDURE Search_ItemTitle 
 @Title NVARCHAR(100)
AS
BEGIN
    SELECT *
    FROM LibraryCatalogue
    WHERE ItemTitle LIKE '%' + @Title + '%'
    ORDER BY yearpublished DESC;
END

-- The EXEC keyword executes the stored procedure
EXEC  Search_ItemTitle 'LORD ';

--QUESTION 2(B)
--A STORED PROCEDURE THAT RETURNS A FULL LIST OF ALL ITEMS CURRENTLY ON LOAN WHICH HAVE  
--WHICH HAVE A DUE  DATE OF LESS THAN FIVE DAYS FROM THE CURRENT 
 CREATE PROCEDURE items_duedateless_5
AS(
SELECT  LibraryCatalogue.ItemTitle, LibraryLoan.ItemId, DueDate
FROM LibraryLoan INNER JOIN LibraryCatalogue ON LibraryLoan.ItemId = LibraryCatalogue.ItemId
  WHERE  DateReturned IS NULL
     AND DATEDIFF(dd, GETDATE(), DueDate) !< 0
     AND DATEDIFF(dd, GETDATE(), DueDate) < 5);

Exec items_duedateless_5

--QUESTION 2(C)
-- A STORED PROCEDURE THAT INSERTS A NEW MEMBER INTO THE LIBRARY DATABASE
CREATE PROCEDURE Insert_NewMember
@Firstname nvarchar(30), @MiddleName nvarchar(30),@LastName nvarchar(30),@DateofBirth date,
@Gender nvarchar(20),@Address1 nvarchar(50),@Address2 nvarchar(50),@City nvarchar(50),
@Postcode nvarchar(10),@Username nvarchar(30),@PasswordHarsh nvarchar(64),@MemberEmail nvarchar(100),
@TelephoneNo nvarchar(20),@Member_JoinDate date
AS
BEGIN TRANSACTION
BEGIN TRY
DECLARE @salt UNIQUEIDENTIFIER=NEWID()
DECLARE @AddressID int;
INSERT INTO Addresses (Address1, Address2, City, Postcode)
VALUES (@Address1, @Address2, @City, @Postcode); 
SET @AddressID = SCOPE_IDENTITY();
INSERT INTO MembersInfo (Firstname, MiddleName, LastName, DateofBirth, Gender, AddressID, Username, PasswordHarsh, Salt, MemberEmail, TelephoneNo, Member_JoinDate)
VALUES (@Firstname, @MiddleName, @LastName, @DateofBirth, @Gender, @AddressID, @Username, HASHBYTES('SHA2_512', @PasswordHarsh + CAST(@Salt AS NVARCHAR(36))), @Salt, @MemberEmail, @TelephoneNo, @Member_JoinDate);
COMMIT TRANSACTION
END TRY
BEGIN CATCH
--Looks like there was an error!
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION
DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
ERROR_SEVERITY()
RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;

EXEC Insert_NewMember 
@Address1 = '6 Victoria Crescent', @Address2 = NULL,@City = 'Leeds',
@Postcode = 'LDM25',@Firstname = 'James',@MiddleName = NULL,
@LastName = 'Church',@DateofBirth = '1993-04-21',@Gender = 'Male',
@Username = 'REnnY33',@PasswordHarsh = 'Scaramanga',
@MemberEmail = 'Manga@gmail.com', @TelephoneNo = '+4478093432',
@Member_JoinDate = '2022-01-12'

--QUESTION 2(D)
-- A STORED STORED PROCEDURE THAT UPDATES DETAILS OF AN EXISTING MEMBER
CREATE PROCEDURE Update_MemberDetails
@Firstname nvarchar(30) = NULL,@MiddleName nvarchar(30) = NULL,@LastName nvarchar(30) = NULL,
@DateofBirth Date = NULL,@Gender nvarchar(20) = NULL,@AddressID Int = NULL,@Username nvarchar(30) = NULL,
@PasswordHarsh binary(64) = NULL,@Salt UNIQUEIDENTIFIER = NULL,@MemberEmail nvarchar(100) = NULL,
@TelephoneNo nvarchar(20) = NULL,@Member_JoinDate Date = NULL,@Member_EndDate Date = NULL
AS
BEGIN TRANSACTION
BEGIN TRY
    UPDATE MembersInfo
    SET 
Firstname = COALESCE(@Firstname, Firstname),MiddleName = COALESCE(@MiddleName, MiddleName),
LastName = COALESCE(@LastName, LastName),DateofBirth = COALESCE(@DateofBirth, DateofBirth),
Gender = COALESCE(@Gender, Gender),AddressID = COALESCE(@AddressID, AddressID),Username = COALESCE(@Username, Username),
PasswordHarsh = COALESCE(@PasswordHarsh, PasswordHarsh),Salt = COALESCE(@Salt, Salt),
MemberEmail = COALESCE(@MemberEmail, MemberEmail),TelephoneNo = COALESCE(@TelephoneNo, TelephoneNo),
Member_JoinDate = COALESCE(@Member_JoinDate, Member_JoinDate),Member_EndDate = COALESCE(@Member_EndDate, Member_EndDate)
    WHERE Username = @Username;
COMMIT TRANSACTION
END TRY
BEGIN CATCH
--Looks like there was an error!
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION
DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity =
ERROR_SEVERITY()
RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH;

--The EXEC keyword executes the stored procedure created in 2c
EXEC Update_MemberDetails @Username = 'sjdoe', @LastName = 'Majid'
--Select query to view updated record
SELECT * FROM MembersInfo

--QUESTION 3
-- A VIEW ON LIBRARY LOAN SHOWING ALL PREVIOUS AND CURRENT LOANS, AND INCLUDING DETAILS 
--OF THE ITEM BORROWED, BORROWED DATE, DUE DATE AND ANY ASSOCIATED FINES FOR EACH LOAN
CREATE VIEW View_LoanHistory
AS
SELECT 
 LoanId, LibraryCatalogue.ItemId,LibraryCatalogue.ItemTitle,MembersInfo.MemberId,
 MembersInfo.FirstName + ' ' +ISNULL(MembersInfo.MiddleName, ' ')+ ' '+ MembersInfo.LastName AS FullName,
 Date_TakenOut DueDate,DateReturned,Days_Overdue,
     CASE 
        WHEN DATEDIFF(dd,DueDate,GETDATE()) > 0 THEN (DATEDIFF(dd,DueDate,GETDATE())* 10)  
		WHEN DATEDIFF(dd,DueDate,GETDATE()) !< 0 THEN 0
		ELSE 0
    END AS Overdue_Fine
FROM
    LibraryLoan
    INNER JOIN LibraryCatalogue ON LibraryLoan.ItemId = LibraryCatalogue.ItemId
    INNER JOIN MembersInfo ON LibraryLoan.MemberId = MembersInfo.MemberId;

-- select query to call the created view
SELECT * FROM View_LoanHistory

--QUESTION 4
-- A TIGGER THAT UPDATES THE ITEM STATUS IN THE LIBRACATALOGUE TO AVAILBLE WHEN AND ITEM IS RETURNED
CREATE TRIGGER update_ItemStatus ON LibraryLOAN
AFTER UPDATE
AS 
BEGIN
IF UPDATE(DateReturned)
   BEGIN
   Update LibraryCatalogue
     SET ItemStatus = 'Available'
     FROM LibraryCatalogue Lc
     Join LibraryLoan Ll ON Lc.ItemId = Ll.ItemId
	 Where Ll.ItemId In (Select ItemId from inserted)
	 and Ll.DateReturned IS NOT NULL
	 END
END

--An update query on the Library loan to demonstrate the trigger
UPDATE LibraryLoan
SET DateReturned = GETDATE()
WHERE LOANId = 205

--Select query to view affected rows
SELECT * FROM LibraryLoan
SELECT * FROM Librarycatalogue


--Question 5
-- A FUNCTION WHICH ALLOWS THE LIBRARY TO IDENTIFY THE TOTAL NUMBER OF LOANS MADE ON A SPECIFIC DATE
 CREATE FUNCTION total_loans (@date_out AS DATE)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT COUNT(*) 
        FROM LibraryLoan
        WHERE Date_TakenOut = @date_out);
END

--Select query to call the function
SELECT dbo.total_loans ('2022-12-03') AS Total_loans


--QUESTION 6
--INSERTING RECORDS INTO ADDRESS TABLE
INSERT INTO Addresses (Address1, Address2, City, Postcode)
VALUES 
  ('12 High Street', 'Flat 1', 'London', 'E1 7AB'),
  ('25 Oxford Road', 'Apartment 2', 'Manchester', 'M1 5AN'),
  ('6 Main Street', NULL, 'Birmingham', 'B3 3HJ'),
  ('42 Park Lane', 'Apartment 7', 'Bristol', 'BS1 5JH'),
  ('8 Station Road', NULL, 'Leeds', 'LS1 4DY'),
  ('17 Queen Street', NULL, 'Glasgow', 'G1 3ED'),
  ('14 Market Square', 'Apartment 11', 'Belfast', 'BT1 2FF'),
  ('2 The Grove', NULL, 'Cardiff', 'CF10 3BA'),
  ('33 Highfield Avenue', NULL, 'Edinburgh', 'EH16 5PJ'),
  ('1 Victoria Road', NULL, 'Sheffield', 'S2 2SS'),
  ('18 King Street', 'Flat 12', 'Liverpool', 'L1 8HT'),
  ('10 Bridge Street', 'Flat 4', 'Newcastle upon Tyne', 'NE1 8AD'),
  ('5 Church Road', NULL, 'Southampton', 'SO16 7GF'),
  ('29 Market Street', NULL, 'Nottingham', 'NG1 6HX'),
  ('3 Abbey Gardens', 'Apartment 20', 'Oxford', 'OX1 1AS');

  --INSERTING VALUES INTO MEMBERSINFO TABLE
  DECLARE @Salt UNIQUEIDENTIFIER = NEWID()
  INSERT INTO MembersInfo (Firstname, MiddleName, LastName, DateofBirth, Gender, AddressID, Username, PasswordHarsh, Salt, MemberEmail, TelephoneNo, Member_JoinDate, Member_EndDate)
VALUES
('John', 'William', 'Smith', '1985-03-15', 'Male', 10, 'jwsmith', HASHBYTES('SHA2_512', 'ytfW0r&d123' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'Jwsmith@gmail.com', '+4475551234', '2023-01-01', NULL),
('Sarah', 'Jane', 'Doe', '1990-07-12', 'Female', 11, 'sjdoe', HASHBYTES('SHA2_512', 'Sara#d223' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'sjdoe@yahoo.com', NULL, '2022-12-01', NULL),
('Adam', 'Joseph', 'Brown', '1995-11-23', 'Female', 12, 'ajbrown', HASHBYTES('SHA2_512', 'browny#Van2' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'mee@gmail.com', NULL, '2023-01-05', NULL),
('Emily', NULL, 'Davis', '1988-04-30', 'Female', 13, 'edavis', HASHBYTES('SHA2_512', 'Err@davis12' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'edavis@gmail.com', NULL, '2022-11-09', NULL),
('Robert', 'Michael', 'Johnson', '1979-12-08', 'Male', 14, 'rMjohnson', HASHBYTES('SHA2_512', 'Jooord12#3' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'rmjohnson@yahoo.com', '+447557890', '2022-12-21', NULL),
('Laura', 'Grace', 'Lee', '1983-06-10', 'Female', 15, 'lglee', HASHBYTES('SHA2_512', 'Word&d245' + CAST(@Salt AS NVARCHAR(36))), @Salt, NULL, '+4476322378', '2022-06-01', NULL),
('Daniel', NULL, 'Wilson', '1992-01-17', 'Male', 16, 'dpwilson', HASHBYTES('SHA2_512', 'bOnDJames@123' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'dpwilson@gmail.com', '+4475552345', '2023-02-01', NULL),
('Megan', 'Elizabeth', 'Taylor', '1997-08-27', 'Female', 17, 'Metaylor', HASHBYTES('SHA2_512', 'metaYorr&d123' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'metaylor@yahoo.com', NULL, '2022-12-15', NULL),
('William', 'Henry', 'Clark', '1980-05-20', 'Male', 18, 'whclark', HASHBYTES('SHA2_512', 'ytfClarkFF#1' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'whclark@hotmail.com', '+447553456', '2022-10-01', NULL),
('Amanda', 'Rose', 'Baker', '1989-02-05', 'Female', 19, 'arobaker', HASHBYTES('SHA2_512', 'JBaker$543' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'arobaker@gmail.com', NULL, '2022-10-21', NULL),
('Steven', NULL, 'Anderson', '1993-09-14', 'Male', 20, 'standerson', HASHBYTES('SHA2_512', 'Stander@son21' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'Standerson@yahoo.com', '+447554567', '2022-11-30', NULL),
('Rachel', 'Nicole', 'Evans', '1998-06-18', 'Female', 21, 'rnevans', HASHBYTES('SHA2_512', 'Rnevan#66tt' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'rnevans@hotmail.com', NULL, '2023-02-01', NULL),
('Matthew', 'Christopher', 'Clark', '1986-02-22', 'Male', 22, 'matthewclark', HASHBYTES('SHA2_512', 'MathewgreT@34' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'matthewclark@gmail.com', NULL, '2022-12-01', NULL),
('Sophia', NULL, 'Allen', '1994-06-18', 'Female', 23, 'sophiaallen', HASHBYTES('SHA2_512', 'Manga1@256' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'sophiaallen@gmail.com', NULL, '2022-10-29', NULL),
('Christopher', NULL, 'Green', '1993-09-12', 'Male', 24, 'christophergreen', HASHBYTES('SHA2_512', 'Alves&@555' + CAST(@Salt AS NVARCHAR(36))), @Salt, 'christophergreen@hotmail.com', '+447123409', '2022-11-19', NULL);


--INSERTING RECORDS INTO THE ITEMTYPES TABLE
INSERT INTO ItemTypes (ItemType)
VALUES ('Books'), ('Journals'), ('DVDs'), ('Other Media');


--INSERTING RECORDS INTO THE LIBRARYCATALOGUE TABLE
INSERT INTO LibraryCatalogue (ItemStatus, ItemTitle, ItemTypeID, Author, YearPublished, Date_Itemadded, Date_Identified_asLost_removed, ISBN)
VALUES 
('Available', 'The Great Gatsby', 1, 'F. Scott Fitzgerald', '1925-04-10', '2022-01-01', NULL, '978-3-16-148410-0'),
('On loan', 'The Lord Chandos Letter', 2, 'Harper Lee', '1960-07-11', '2022-01-02', NULL, NULL),
('Available', 'The Catcher in the Rye', 1, 'J.D. Salinger', '1951-07-16', '2022-01-03', NULL, '978-3-16-148410-0'),
('Overdue', 'The Da Vinci Code', 1, 'Dan Brown', '2003-03-18', '2022-01-04', '2023-03-31', '978-3-16-148410-0'),
('On loan', 'Jurassic Park', 3, 'Michael Crichton', '1990-11-20', '2022-01-05', NULL, NULL),
('On loan', 'The Matrix', 3, NULL, '1999-03-31', '2022-01-06', NULL, NULL),
('Available', 'Star Wars: Episode IV - A New Hope', 3, NULL, '1977-05-25', '2022-01-07', NULL, NULL),
('Lost_Or_Removed', 'The Shawshank Redemption', 1, 'Stephen King', '1982-09-14', '2022-01-08', '2023-02-28', '978-1-43-035595-1'),
('Available', 'The Lord of the Rings: The Fellowship of the Ring', 1, 'J.R.R. Tolkien', '1954-07-29', '2022-01-09', NULL, '978-0-451-52493-5'),
('On loan', 'Harry Potter and the Philosopher\"s Stone', 1, 'J.K. Rowling', '1997-06-26', '2022-01-10', NULL, '978-3-16-148410-0'),
('Available', 'Breaking Bad The Complete Series', 3, NULL, '2008-01-20', '2022-01-11', NULL, NULL),
('On loan', 'Game of Thrones: The Complete First Season', 3, NULL, '2011-04-17', '2022-01-12', NULL, NULL),
('Available', 'Stranger Things: Season 1', 3, NULL, '2016-07-15', '2022-01-13', NULL, NULL),
('Lost_Or_Removed', '1984', 1, 'George Orwell', '1949-06-08', '2022-01-14', '2023-01-31', '978-0-451-52493-5'),
('Available', 'The Lord of Castle Black ', 2, 'Mario Puzo', '1969-03-10', '2022-01-15', NULL, NULL);


--INSERTING RECORDS INTO THE LIBRARYLOAN TABLE
INSERT INTO LibraryLoan (ItemId, MemberId, Date_TakenOut, DueDate)
VALUES 
(100, 1, '2022-10-01', '2023-01-15'),
(101, 2, '2022-11-02', '2023-01-16'),
(102, 8, '2022-12-03', '2023-04-25'),
(103, 4, '2023-04-04', '2023-06-10'),
(104, 5, '2023-01-02', '2023-04-19'),
(105, 6, '2023-04-02', '2023-05-20'),
(106, 7, '2023-02-07', '2023-04-03'),
(107, 8, '2023-01-02', '2023-04-22'),
(108, 9, '2022-12-03', '2023-04-24'),
(109, 10, '2022-11-10', '2023-12-12'),
(110, 11, '2023-02-11', '2023-04-30'),
(111, 1, '2023-01-12', '2023-02-26'),
(112, 13, '2022-12-13', '2023-03-27'),
(113, 4, '2022-12-03', '2023-02-28'),
(114, 15, '2022-12-15', '2023-01-29');

--INSERTING RECORDS INTO THE OVERDUEFINES_REPAYMENT TABLE
INSERT INTO OverdueFines_Repayment (MemberId, LoanId, AmountPaid, RepaymentMethod)
VALUES 
(1, 200, 10.50, 'Cash'),
(2, 201, 15.75, 'Card'),
(4, 203, 18.25, 'Card'),
(7, 206, 14.75, 'Cash'),
(9, 208, 11.50, 'Cash'),
(1, 211, 16.50, 'Cash'),
(13, 212, 9.25, 'Cash'),
(4, 213, 19.75, 'Card'),
(15, 214, 22.00, 'Cash');

--VIEW RECORDS IN ADDRESS TABLE
SELECT * FROM ADDRESSES

--VIEW RECORDS IN MembersInfo TABLE
 SELECT * FROM MembersInfo

--VIEW RECORDS IN ItemTypes TABLE
SELECT * FROM ItemTypes

--VIEW RECORDS IN Librarycatalogue TABLE
SELECT * FROM Librarycatalogue

--VIEW RECORDS IN Libraryloan TABLE
SELECT * FROM Libraryloan

--VIEW RECORDS IN Libraryloan TABLE
 SELECT * FROM OverdueFines_Repayment
 


--QUESTION 7
--OTHER OBJECTS THAT ARE RELEVANT TO THE LIBRARY DATABASE

--a)
-- A TRIGGER THAT UPDATES THE DAYS_OVERDUE COLUMN WHEN THE DAYS_OVERDUE IS GREATER THAN ZERO
CREATE TRIGGER update_DaysOverdue ON LibraryLoan
AFTER UPDATE
AS 
BEGIN
    UPDATE LibraryLoan
    SET DAYS_OVERDUE = CASE 
                          WHEN DATEDIFF(dd,DueDate,GETDATE() ) > 0 
                          THEN DATEDIFF(dd,DueDate, GETDATE() ) 
						  WHEN DATEDIFF(dd, DueDate, GETDATE()) < 0 
                          THEN 0
                          ELSE 0
                       END
    WHERE LoanID IN (SELECT LoanID FROM inserted)
END;

-- An Update query to demonstrate the trigger
UPDATE LIBRARYLOAN
SET DUEDATE = '2023-4-15'
WHERE LOANID = 211
-- select query to view affected row
select * from libraryloan


--b)
-- A STORED PROCEDURE THAT RETURNS THE THE TOTAL_OVERDUEFINE, TOTA_AMOUNT PAID, 
--AND OUTSTANDING BALANCE OF A MEMBER
CREATE PROCEDURE Outstanding_balance @memberID int
AS
BEGIN
DECLARE @Overduefee_rate MONEY;
SET @Overduefee_rate = 10;
SELECT   sum(L.Days_Overdue * @Overduefee_rate) As Total_Overduefine,sum(R.AmountPaid) AS Totalamount_paid,
  (sum(L.Days_Overdue * @Overduefee_rate) - sum(R.AmountPaid)) AS Outstanding_Balance 
From LibraryLoan L
LEFT JOIN OverdueFines_Repayment R ON R.LoanID = L.LoanID
WHERE L.MemberId = @memberID
END

--Exec keyword to execute the stored procedure
Exec Outstanding_balance @memberID =1

--C
-- A TRIGGER TO UPDATE THE DATE_IDENTIFIED_ASLOST COLUMN IN THE LIBRARY CATALOGUE TABLE
--WHEN ITEMSTATUS IS LOST_OR_REMOVED

CREATE TRIGGER Date_Identified_asLost ON Librarycatalogue
AFTER UPDATE
AS
BEGIN
  UPDATE lc
  SET lc.Date_Identified_asLost_removed = 
    CASE 
      WHEN lc.Itemstatus = 'Lost_Or_Removed' THEN GETDATE()
    END
  FROM inserted i
  INNER JOIN LibraryCatalogue lc ON lc.ItemId = i.ItemId
END

--An update query on the Librarycatalogue to demonstrate the trigger
update LibraryCATALOGUE
set ItemStatus = 'Lost_Or_Removed'
where itemid = 100

--d
-- A TRIGGER THAT WILL MOVE THE MEMBERS THAT LEAVE THE LIBRARY INTO A FORMER MEMBERS TABLE 
--Create Former_Members table
CREATE TABLE FORMER_MEMBERS(
MemberId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
Firstname nvarchar(30) NOT NULL,
MiddleName nvarchar(30) NULL,
LastName nvarchar(30) NOT NULL,
DateofBirth Date NOT NULL,
Gender nvarchar(20) NOT NULL ,
AddressID Int NOT NULL FOREIGN KEY (AddressID) 
REFERENCES Addresses(AddressID),
Username nvarchar(30) UNIQUE NOT NULL,
PasswordHarsh binary(64) NOT NULL, 
Salt UNIQUEIDENTIFIER,
MemberEmail nvarchar(100)  NULL, CHECK(MemberEmail Like '%_@_%._%'),
TelephoneNo nvarchar(20) NULL,
Member_JoinDate Date  NOT NULL,
Member_EndDate Date  NULL);

--Create trigger
CREATE TRIGGER MoveToFormerMembers
ON MembersInfo
AFTER UPDATE
AS
BEGIN
  IF UPDATE (MEMBER_ENDDATE) 
  BEGIN
    INSERT INTO Former_Members(Firstname, MiddleName, LastName, DateofBirth,Gender, AddressID,Username, PasswordHarsh,Salt, MemberEmail, TelephoneNo, Member_JoinDate, Member_EndDate)
    SELECT Firstname, MiddleName, LastName, DateofBirth,Gender, AddressID,Username, PasswordHarsh,Salt, MemberEmail,TelephoneNo, Member_JoinDate, Member_EndDate
    FROM inserted
	DELETE FROM OverdueFines_Repayment
      WHERE MemberId IN 
	  (SELECT MemberId FROM inserted)
	DELETE FROM LibraryLoan
      WHERE MemberId IN 
	  (SELECT MemberId FROM inserted)
	 DELETE FROM MembersInfo
      WHERE MemberId IN 
	  (SELECT MemberId FROM inserted);     
  END
END

--An update query on Membersinfo to demonstrate the trigger
UPDATE MembersInfo
SET Member_EndDate = GETDATE()
WHERE MemberId = 1

-- select query to view affected rows
SELECT * FROM MembersInfo
SELECT * FROM FORMER_MEMBERS

SELECT * FROM overduefines_repayment
SELECT * FROM libraryloan



-- DATABASE SECURITY FEATURES

-- Create Login for authentication

CREATE LOGIN JAMESCHURCH
WITH PASSWORD = 'jamesjee@1';

--Create user to provide authorization
CREATE USER JAMESCHURCH FOR LOGIN JAMESCHURCH;
GO

-- Granting priviledge to a user
GRANT SELECT, INSERT, UPDATE ON Addresses TO
JAMESCHURCH WITH GRANT OPTION;

-- Execution of the priviledge
EXECUTE AS USER = 'JAMESCHURCH'
SELECT * FROM Addresses;
--Revert to take back control from user
REVERT;

--Create Role
CREATE ROLE TableInsertUser;

--Grant priviledges or created role
GRANT SELECT, UPDATE, INSERT ON MembersInfo TO
TableInsertUser

--Deny delete priviledge
DENY DELETE ON MembersInfo TO
TableInsertUser

--Grant role on the stored procedure created in 2b
GRANT EXECUTE ON dbo.[Insert_NewMember] TO TableInsertUser;

-- Add new member to role
ALTER ROLE TableInsertUser ADD MEMBER JAMESCHURCH;



   

















