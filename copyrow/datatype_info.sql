USE [SYSDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[_datatype_info](
    [TYPE_NAME] [nvarchar](128) NULL,
    [DATA_TYPE] [smallint] NULL,
    [PRECISION] [int] NULL,
    [LITERAL_PREFIX] [varchar](32) NULL,
    [LITERAL_SUFFIX] [varchar](32) NULL,
    [CREATE_PARAMS] [varchar](32) NULL,
    [NULLABLE] [smallint] NULL,
    [CASE_SENSITIVE] [smallint] NULL,
    [SEARCHABLE] [smallint] NOT NULL,
    [UNSIGNED_ATTRIBUTE] [smallint] NULL,
    [MONEY] [smallint] NOT NULL,
    [AUTO_INCREMENT] [smallint] NULL,
    [LOCAL_TYPE_NAME] [nvarchar](128) NULL,
    [MINIMUM_SCALE] [smallint] NULL,
    [MAXIMUM_SCALE] [smallint] NULL,
    [SQL_DATA_TYPE] [smallint] NULL,
    [SQL_DATETIME_SUB] [smallint] NULL,
    [NUM_PREC_RADIX] [int] NULL,
    [INTERVAL_PRECISION] [smallint] NULL,
    [USERTYPE] [smallint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO

INSERT INTO SYSDB.._datatype_info
exec sys.sp_datatype_info
