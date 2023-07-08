/*
	-- Step 1: Drop Objects
	DROP VIEW IF EXISTS MasterAPI.AttributeSpec
	DROP VIEW IF EXISTS MasterAPI.Attributes
	DROP TABLE IF EXISTS MasterData.AttributeSpec
	DROP TABLE IF EXISTS MasterData.Attributes
	DROP FUNCTION IF EXISTS FunctionAPI.GetPrice

	-- Step 2: Drop Schemas
	DROP SCHEMA IF EXISTS MasterData 
	GO
	DROP SCHEMA IF EXISTS MasterAPI 
	GO
	DROP SCHEMA IF EXISTS FunctionAPI 
	GO

	-- Optional
	ALTER TABLE MasterData.AttributeSpec DROP CONSTRAINT IF EXISTS DT_AttributeSpec_Dttm_Change
	ALTER TABLE MasterData.Attribute DROP CONSTRAINT IF EXISTS DT_Attributes_Dttm_Change
*/

-- ==========================================================
-- Create initial MasterData Schema
-- ==========================================================
CREATE SCHEMA MasterData 
GO
CREATE SCHEMA MasterAPI 
GO
CREATE SCHEMA FunctionAPI 
GO

--EXEC sys.sp_addextendedproperty 
--	@name=N'Column_Description', @value=N'Enum key uniquely representing precision adjustment method; matches Mes.MesMath.PrecisionAdjustMethod in Mes.Core' , 
--	@level0type=N'SCHEMA',@level0name=N'MasterData', 
--	@level1type=N'TABLE',@level1name=N'PrecisionAdjustMethod', 
--	@level2type=N'COLUMN',@level2name=N'PrecisionAdjustMethodID'
--GO

-- ==========================================================
-- Create the table for each attribute
-- ==========================================================
CREATE TABLE MasterData.Attributes (
    AttributeId INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(500),
    Abbriviation VARCHAR(10),
	Dttm_Change [datetime2](3) NOT NULL
)
GO
ALTER TABLE MasterData.Attributes ADD CONSTRAINT DT_Attributes_Dttm_Change DEFAULT (sysdatetime()) FOR Dttm_Change
GO

-- ==========================================================
-- Create the table for storing attribute specs
-- ==========================================================
CREATE TABLE MasterData.AttributeSpec (
    AttributeSpecId INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
    AttributeId INT NOT NULL,
    Rate DECIMAL(10, 2) NOT NULL,
	Dttm_Change [datetime2](3) NOT NULL,	
    FOREIGN KEY (AttributeId) REFERENCES MasterData.Attributes(AttributeId)
)
GO
ALTER TABLE MasterData.AttributeSpec ADD CONSTRAINT DT_AttributeSpec_Dttm_Change DEFAULT (sysdatetime()) FOR Dttm_Change
GO

-- ==========================================================
-- Insert the attribute data
-- ==========================================================
	INSERT INTO MasterData.Attributes (Name, Description, Abbriviation)
	VALUES
		('Unfinished Cabinets', '(No deduction for sealed and varnished interiors) *Unfinished cabinets not covered by Prevo Warranty', 'UNFIN'),
		('Stained Birch Interiors', 'For cabinets that do not have glass doors', 'SBI'),
		('Painted Birch Interiors', 'For cabinets that do not have glass interiors', 'PBI'),
		('Matching Interior', 'Same species and finish as cabinet exterior', 'FININTSP'),
		('Accent Color Interior', 'Different than cabinet exterior', 'FININTAC'),
		('Accent Color Back Interior', 'Different than cabinet exterior', 'ACIB'),
		('Primed Exterior w/ Seal and Varnish Interior', 'Primed Cabinets not covered by Prevo Warranty', 'PRIME/SV'),
		('Primed Exterior/Interior', 'Primed Cabinets not covered by Prevo Warranty', 'PRIME'),
		('Eased', 'Random sanding of door and panel edges and corners (done prior to finishing)', 'EASED'),
		('Rub Through (Wear)', 'Random sanding of door and panel edges and corners (Done after paint has cured and before glaze is applied)', 'RUB'),
		('Dents', 'Random size impressions made into the wood (done prior to finishing)', 'DENTS'),
		('Splits', 'Wood splits replicated in random locations on doors, drawers, front frames, and cabinet sides', 'SPLITS'),
		('Worm Holes', 'A cluster of small holes that create the effects of worms and termites. Worm holes are random on doors, drawers, front frames, and cabinet sides', 'WORMHOLES'),
		('Rasping', 'A hand filling process done with a rough wood file on door and panel edges (done prior to finishing)', 'RASP'),
		('Spatter', 'A random spray of brown or black specks to replicate small ink or fly specks. Usually done on a stained finish for an antique appearance', 'SPATTER'),
		('Cow Tailing', 'A random pattern of brown or black wisps applied by hand with a colored pencil', 'COWTAIL'),
		('Wire Brushing', 'A distressing technique that creates a unique weathered effect', 'WBRUSH');
	GO
	   
-- ==========================================================
-- Insert the attribute specs
-- ==========================================================
	INSERT INTO MasterData.AttributeSpec (AttributeId, Rate)
	VALUES
		(1, -0.05),
		(2, 0.1),
		(3, 0.1),
		(4, 0.2),
		(5, 0.3),
		(6, 0.2),
		(7, 0),
		(8, 0),
		(9, 0.03),
		(10, 0.03),
		(11, 0.03),
		(12, 0.03),
		(13, 0.03),
		(14, 0.03),
		(15, 0.03),
		(16, 0.03),
		(17, 0.08);
	GO

-- ==========================================================
-- Create views for each table
-- ==========================================================
	CREATE VIEW MasterAPI.Attributes AS
	SELECT AttributeId, Name, Description, Abbriviation, Dttm_Change
	FROM MasterData.Attributes
	GO
	CREATE VIEW MasterAPI.AttributeSpec AS
	SELECT AttributeSpecId, AttributeId, Rate, Dttm_Change
	FROM MasterData.AttributeSpec
	GO

-- ==========================================================
-- The Function
-- ==========================================================
	CREATE FUNCTION FunctionAPI.GetPrice(
	  @InitialPrice FLOAT,
	  @Attributes VARCHAR(MAX) = ''
	)
	RETURNS FLOAT
	AS
	BEGIN
	  -- Filtered attribute list based on the array of attributes that are sent and create temp table
	  DECLARE @FilteredAttributes TABLE (
		Abbriviation VARCHAR(MAX),
		Rate FLOAT
	  )

	  -- ======================
		/* DEBUG */  --DECLARE  @InitialPrice FLOAT = 2000
		/* DEBUG */  --DECLARE @Attributes VARCHAR(MAX) = 'FININTAC, DENTS'
	  -- ======================
	  -- Hardcoded these for the test 
	  -- Normally these would be kept in a separate table as customer specs
	  DECLARE @DefaultFinish varchar(10) = 'UNFIN'
	  DECLARE @StandardRate FLOAT = .01
	  DECLARE @MinimumPrice FLOAT = 300
	  -- ======================

	  /* DEBUG */  --SELECT @InitialPrice InitialPrice, @Attributes Attributes, @DefaultFinish DefaultFinish, @StandardRate StandardRate, @MinimumPrice MinimumPrice

	  -- Fill the filtered temp table
	  IF @Attributes IS NULL OR LEN(@Attributes) = 0
	  BEGIN
		INSERT INTO @FilteredAttributes
		SELECT A.Abbriviation, B.Rate
		FROM MasterAPI.Attributes A 
		LEFT JOIN MasterAPI.AttributeSpec B ON B.AttributeId = A.AttributeId
		WHERE A.Abbriviation = @DefaultFinish
	  END
	  ELSE
	  BEGIN
		INSERT INTO @FilteredAttributes
		SELECT A.Abbriviation, B.Rate
		FROM MasterAPI.Attributes A 
		LEFT JOIN MasterAPI.AttributeSpec B ON B.AttributeId = A.AttributeId
		WHERE A.Abbriviation IN (SELECT RTRIM(LTRIM(value)) FROM STRING_SPLIT(@Attributes, ','))
	  END

	  /* DEBUG */  --SELECT * FROM @FilteredAttributes

	  -- Sets the two rates that get applied - the highest rate cost and the standard rate cost
	  DECLARE @HighestRateCost FLOAT
	  DECLARE @StandardRateCost FLOAT

	  SELECT @HighestRateCost = MAX(Rate) * @InitialPrice
	  FROM @FilteredAttributes

	  SET @StandardRateCost = @StandardRate * @InitialPrice

	  -- Gets any additional attributes added using the standard adjustment
	  DECLARE @TotalAdditionalCost FLOAT

	  SELECT @TotalAdditionalCost = SUM(@StandardRateCost)
	  FROM @FilteredAttributes
	  WHERE Abbriviation <> (SELECT TOP 1 Abbriviation FROM @FilteredAttributes ORDER BY Rate DESC)
  
	  /* DEBUG */  --SELECT @HighestRateCost HighestRateCost, @StandardRateCost StandardRateCost, @TotalAdditionalCost TotalAdditionalCost, @StandardRateCost StandardRateCost

	  -- Sets the Final price by adding the initial price, highest rate cost, and any additional costs using the standard rate
	  DECLARE @FinalPrice FLOAT  
	  SET @FinalPrice = ISNULL(@InitialPrice,0) + ISNULL(@HighestRateCost,0) + ISNULL(@TotalAdditionalCost,0)

	  -- Checks if the final result is below the minimum price that is allowed
	  IF @FinalPrice < @MinimumPrice
	  BEGIN
		SET @FinalPrice = @MinimumPrice
	  END
  
	  /* DEBUG */  --SELECT @FinalPrice FinalPrice, @InitialPrice InitialPrice, @HighestRateCost HighestRateCost, @TotalAdditionalCost TotalAdditionalCost

	  -- Returns the final price
	  RETURN @FinalPrice
	END
	GO

-- ==========================================================
-- Final Tests
-- ==========================================================
SELECT 
	--Test 1: The example provided by Nate
	FunctionAPI.GetPrice(2000, 'FININTAC, DENTS') Test1,
	
	--Test 2: What if its null
	FunctionAPI.GetPrice(2000, null) Test2,

	--Test 3: What if no attributes are sent 
	--FunctionAPI.GetPrice(2000) Test3 -- Errors out
	
    --Test 4: What if the unfinished attribute is sent
	FunctionAPI.GetPrice(2000, 'UNFIN') Test4,

	--Test 5: What if lots of values are sent
	FunctionAPI.GetPrice(2000, 'FININTAC, DENTS, WBRUSH, PRIME/SV, SPLITS') Test5,
	
    --Test 6: What if an attribute is sent multiple times
	FunctionAPI.GetPrice(2000, 'SPLITS, DENTS, WBRUSH, PRIME/SV, SPLITS') Test6,

	--Test 7: What if a blank is sent at the end
	FunctionAPI.GetPrice(2000, 'FININTAC, DENTS, WBRUSH, PRIME/SV, SPLITS') Test7,

	--Test 8: What if a null is sent at the end
	FunctionAPI.GetPrice(2000, 'FININTAC, DENTS, WBRUSH, PRIME/SV, SPLITS, NULL') Test8,

	--Test 9: What is data outside of the customer attributes are sent
	FunctionAPI.GetPrice(2000, 'FININTAC, DENTS, WBRUSH, PRIME/SV, SPLITS, FAKE') Test9,

	--Test 10: What if the end amount is lower than the minimum set price
	FunctionAPI.GetPrice(10, 'FININTAC, DENTS, WBRUSH, PRIME/SV, SPLITS') Test10

	SELECT 
		  A.AttributeId
		, A.Name
		, A.Abbriviation
		, B.Rate
		, A.Description
	FROM 
		MasterAPI.Attributes A 
		LEFT JOIN MasterAPI.AttributeSpec B ON B.AttributeId = A.AttributeId





