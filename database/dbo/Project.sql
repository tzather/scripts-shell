-- Create a new table called '[Project]' in schema '[dbo]'
-- Drop the table if it already exists
IF OBJECT_ID('[dbo].[Project]', 'U') IS NOT NULL
  DROP TABLE [dbo].[Project]
GO

-- Create the table in the specified schema
CREATE TABLE [dbo].[Project] (
  [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY, -- Primary Key column
  [Name] NVARCHAR(100) NOT NULL,
);
GO
