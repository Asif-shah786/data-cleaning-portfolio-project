-- DataCleaning.sql
-- Drops and recreates the DataCleaning database, stages the CSV, cleans it, and loads a production-ready table.
SET NOCOUNT ON;

USE master;
GO

IF DB_ID(N'DataCleaning') IS NOT NULL
BEGIN
    ALTER DATABASE DataCleaning SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataCleaning;
END
GO

CREATE DATABASE DataCleaning;
GO

USE DataCleaning;
GO

IF OBJECT_ID(N'dbo.NashvilleHousingRaw', N'U') IS NOT NULL
    DROP TABLE dbo.NashvilleHousingRaw;

CREATE TABLE dbo.NashvilleHousingRaw
(
    UniqueID nvarchar(100) NULL,
    ParcelID nvarchar(500) NULL,
    LandUse nvarchar(500) NULL,
    PropertyAddress nvarchar(500) NULL,
    SaleDate nvarchar(100) NULL,
    SalePrice nvarchar(100) NULL,
    LegalReference nvarchar(500) NULL,
    SoldAsVacant nvarchar(50) NULL,
    OwnerName nvarchar(500) NULL,
    OwnerAddress nvarchar(500) NULL,
    Acreage nvarchar(100) NULL,
    TaxDistrict nvarchar(500) NULL,
    LandValue nvarchar(100) NULL,
    BuildingValue nvarchar(100) NULL,
    TotalValue nvarchar(100) NULL,
    YearBuilt nvarchar(50) NULL,
    Bedrooms nvarchar(50) NULL,
    FullBath nvarchar(50) NULL,
    HalfBath nvarchar(50) NULL
);
GO

IF OBJECT_ID(N'dbo.NashvilleHousing', N'U') IS NOT NULL
    DROP TABLE dbo.NashvilleHousing;

CREATE TABLE dbo.NashvilleHousing
(
    UniqueID int NOT NULL,
    ParcelID varchar(100) NULL,
    LandUse varchar(100) NULL,
    PropertyAddress varchar(250) NULL,
    SaleDate date NULL,
    SalePrice decimal(18,2) NULL,
    LegalReference varchar(100) NULL,
    SoldAsVacant bit NULL,
    OwnerName varchar(250) NULL,
    OwnerAddress varchar(300) NULL,
    Acreage decimal(10,2) NULL,
    TaxDistrict varchar(150) NULL,
    LandValue decimal(18,2) NULL,
    BuildingValue decimal(18,2) NULL,
    TotalValue decimal(18,2) NULL,
    YearBuilt smallint NULL,
    Bedrooms smallint NULL,
    FullBath smallint NULL,
    HalfBath smallint NULL,
    CONSTRAINT PK_NashvilleHousing UNIQUE CLUSTERED (UniqueID)
);
GO

-- Stage the CSV using SQL Server CSV-compatible BULK INSERT on Linux path
BULK INSERT dbo.NashvilleHousingRaw
FROM '/var/opt/mssql/data/nashville.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIELDQUOTE = '"',
    KEEPNULLS,
    TABLOCK,
    MAXERRORS = 1000,
    ERRORFILE = '/var/opt/mssql/data/nashville_bulk_errors'
);
GO

-- Clean and insert into production table using defensive conversions
INSERT INTO dbo.NashvilleHousing
(
    UniqueID,
    ParcelID,
    LandUse,
    PropertyAddress,
    SaleDate,
    SalePrice,
    LegalReference,
    SoldAsVacant,
    OwnerName,
    OwnerAddress,
    Acreage,
    TaxDistrict,
    LandValue,
    BuildingValue,
    TotalValue,
    YearBuilt,
    Bedrooms,
    FullBath,
    HalfBath
)
SELECT
    TRY_CAST(NULLIF(LTRIM(RTRIM(UniqueID)), N'') AS int) AS UniqueID,
    LEFT(NULLIF(LTRIM(RTRIM(ParcelID)), N''), 100) AS ParcelID,
    LEFT(NULLIF(LTRIM(RTRIM(LandUse)), N''), 100) AS LandUse,
    LEFT(NULLIF(LTRIM(RTRIM(PropertyAddress)), N''), 250) AS PropertyAddress,
    TRY_PARSE(NULLIF(LTRIM(RTRIM(SaleDate)), N'') AS date USING 'en-US') AS SaleDate,
    TRY_CAST(NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(SalePrice)), N'"', N''), N',', N''), N'') AS decimal(18,2)) AS SalePrice,
    LEFT(NULLIF(LTRIM(RTRIM(LegalReference)), N''), 100) AS LegalReference,
    CASE
        WHEN UPPER(NULLIF(LTRIM(RTRIM(SoldAsVacant)), N'')) IN (N'YES', N'Y', N'TRUE', N'1') THEN 1
        WHEN UPPER(NULLIF(LTRIM(RTRIM(SoldAsVacant)), N'')) IN (N'NO', N'N', N'FALSE', N'0') THEN 0
        ELSE NULL
    END AS SoldAsVacant,
    LEFT(NULLIF(LTRIM(RTRIM(OwnerName)), N''), 250) AS OwnerName,
    LEFT(NULLIF(LTRIM(RTRIM(OwnerAddress)), N''), 300) AS OwnerAddress,
    TRY_CAST(NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(Acreage)), N'"', N''), N',', N''), N'') AS decimal(10,2)) AS Acreage,
    LEFT(NULLIF(LTRIM(RTRIM(TaxDistrict)), N''), 150) AS TaxDistrict,
    TRY_CAST(NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(LandValue)), N'"', N''), N',', N''), N'') AS decimal(18,2)) AS LandValue,
    TRY_CAST(NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(BuildingValue)), N'"', N''), N',', N''), N'') AS decimal(18,2)) AS BuildingValue,
    TRY_CAST(NULLIF(REPLACE(REPLACE(LTRIM(RTRIM(TotalValue)), N'"', N''), N',', N''), N'') AS decimal(18,2)) AS TotalValue,
    TRY_CAST(NULLIF(LTRIM(RTRIM(YearBuilt)), N'') AS smallint) AS YearBuilt,
    TRY_CAST(NULLIF(LTRIM(RTRIM(Bedrooms)), N'') AS smallint) AS Bedrooms,
    TRY_CAST(NULLIF(LTRIM(RTRIM(FullBath)), N'') AS smallint) AS FullBath,
    TRY_CAST(NULLIF(LTRIM(RTRIM(HalfBath)), N'') AS smallint) AS HalfBath
FROM dbo.NashvilleHousingRaw;
GO

-- Verification: row counts and sample data
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN SaleDate IS NULL THEN 1 ELSE 0 END) AS MissingSaleDate,
    SUM(CASE WHEN SalePrice IS NULL THEN 1 ELSE 0 END) AS MissingSalePrice,
    SUM(CASE WHEN TotalValue IS NULL THEN 1 ELSE 0 END) AS MissingTotalValue,
    SUM(CASE WHEN UniqueID IS NULL THEN 1 ELSE 0 END) AS MissingUniqueID
FROM dbo.NashvilleHousing;

SELECT TOP (20)
    UniqueID,
    ParcelID,
    LandUse,
    SaleDate,
    SalePrice,
    SoldAsVacant,
    Acreage,
    TotalValue,
    YearBuilt
FROM dbo.NashvilleHousing
ORDER BY UniqueID;
GO
