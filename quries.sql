/*

Cleaning Data in SQL Queries

*/

USE DataCleaning

Select *
From dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


Select saleDate, CONVERT(Date,SaleDate)
From dbo.NashvilleHousing;




 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select a.parcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) as FinalPropertyAddress   
From dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
ON a.parcelID = b.parcelID
AND a.UniqueID <> b.UniqueID
WHERE a.propertyAddress IS NULL;


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousing a
JOIN dbo.NashvilleHousing b
ON a.parcelID = b.parcelID
AND a.UniqueID <> b.UniqueID
WHERE a.propertyAddress IS NULL;



--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


SELECT 
PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS StreetAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)  + 2, LEN(PropertyAddress)) AS City
FROM dbo.NashvilleHousing;


ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)  + 2, LEN(PropertyAddress));


SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
FROM dbo.NashvilleHousing;



SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.NashvilleHousing;


ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

ALTER TABLE dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

AlTER TABLE dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);


UPDATE dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3
), OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


SELECT OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM dbo.NashvilleHousing;


SELECT *
FROM dbo.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT SoldAsVacant, COUNT(*)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant;


SELECT SoldAsVacant, 
CASE 
WHEN SoldAsVacant = '1' THEN 'Yes'
WHEN SoldAsVacant = '0' THEN 'No'
ELSE SoldAsVacant
END
FROM dbo.NashvilleHousing;


-- SELECT COLUMN_NAME, DATA_TYPE
-- FROM INFORMATION_SCHEMA.COLUMNS
-- WHERE TABLE_NAME = 'NashvilleHousing'
--   AND COLUMN_NAME = 'SoldAsVacant';


-- Changing type or column and then storing values as Yes, and No instead of 1 and 0 with following steps:


-- 1. Add a new text column
ALTER TABLE NashvilleHousing
ADD SoldAsVacant_New VARCHAR(3);

-- 2. Populate it
UPDATE NashvilleHousing
SET SoldAsVacant_New =
    CASE
        WHEN SoldAsVacant = 1 THEN 'Yes'
        WHEN SoldAsVacant = 0 THEN 'No'
    END;


-- Before dropping the original column, it's a good idea to verify the data:
SELECT SoldAsVacant, SoldAsVacant_New
FROM NashvilleHousing;


-- 3. Drop the old column
ALTER TABLE NashvilleHousing
DROP COLUMN SoldAsVacant;

-- 4. Rename the new column
EXEC sp_rename
    'NashvilleHousing.SoldAsVacant_New',
    'SoldAsVacant',
    'COLUMN';


-- Verifying the change:

SELECT SoldAsVacant, COUNT(*)
FROM dbo.NashvilleHousing
GROUP BY SoldAsVacant;



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowCTE AS(
SELECT * ,
ROW_NUMBER() OVER  (PARTITION BY parcelID, salePrice, saleDate, legalReference ORDER BY UniqueID) AS row_num
FROM dbo.NashvilleHousing
)

-- DELETE 
-- FROM RowCTE
-- WHERE row_num > 1;

-- Show me only copies that are NOT the first one.
SELECT * 
FROM RowCTE
WHERE row_num > 1;


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



ALTER TABLE dbo.NashvilleHousing
DROP COLUMN OwnerAddress, taxDistrict, propertyAddress, saleDate;

SELECT *
FROM dbo.NashvilleHousing;






-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO

















