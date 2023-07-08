clear

get-column() {
  Datatype=$1
  Length=$2
  Required=$3
  Default=$4

  # datatype
  if [ "$Datatype" == "nvarchar" ]; then
    DatatypString="$Datatype($Length)"
  else
    DatatypString="$Datatype"
  fi
  # default
  if [ ${#Default} -gt 0 ]; then
    DefaultString="DEFAULT($Default)"
  fi
  # nullable
  if [ "$Required" == "1" ]; then
    NullableString="NOT NULL"
  fi
  echo $DatatypString $DefaultString $NullableString
}

create-table() {
  schema=$1
  table=$2

  # create table with primary key column
  while IFS=, read -r Column Datatype Required Default Length Precision Unique FkSchema FkTable FkColumn; do
    echo "--create table with primary key column
IF OBJECT_ID('$schema.$table') IS NULL
  CREATE TABLE $schema.[$table](
    $Column $(get-column "$Datatype" "$Length" "$Required" "$Default"), 
    CONSTRAINT PK_${schema}_$table PRIMARY KEY NONCLUSTERED ($Column ASC) WITH (FILLFACTOR=70)
  );" >$schema/$table.table.sql
  done < <(head -n 2 $schema/$table.csv | tail -1)

  # create all other columns
  printf "%s\n" "--create all other columns" >>$schema/$table.table.sql
  while IFS=, read -r Column Datatype Required Default Length Precision Unique FkSchema FkTable FkColumn; do
    echo "IF COL_LENGTH('$schema.$table','$Column') IS NULL
  ALTER TABLE $schema.[$table] ADD $Column $(get-column "$Datatype" "$Length" "$Required" "$Default");" >>$schema/$table.table.sql
  done < <(tail -n +3 $schema/$table.csv)

  # create unique constraint
  printf "%s\n" "--create unique constraint" >>$schema/$table.table.sql
  while IFS=, read -r Column Datatype Required Default Length Precision Unique FkSchema FkTable FkColumn; do
    if [ ${#Unique} -gt 0 ]; then
      echo "IF (SELECT 1 FROM sys.indexes WHERE NAME = 'IX_${schema}_${table}_${Column}') IS NULL
  CREATE UNIQUE INDEX IX_${schema}_${table}_${Column} ON $schema.[$table]($Column) WITH(FILLFACTOR = 70)" >>$schema/$table.table.sql
    fi
  done < <(tail -n +3 $schema/$table.csv)

  # create foreign keys
  >$schema/$table.fk.sql
  while IFS=, read -r Column Datatype Required Default Length Precision Unique FkSchema FkTable FkColumn; do
    if [ ${#FkSchema} -gt 0 ]; then
      echo "IF (SELECT 1 FROM sys.foreign_keys WHERE NAME = 'FK_${schema}_${table}_${Column}_${FkSchema}_${FkTable}_${FkColumn}') IS NULL
  ALTER TABLE $schema.[$table] ADD CONSTRAINT FK_${schema}_${table}_${Column}_${FkSchema}_${FkTable}_${FkColumn} FOREIGN KEY($Column) REFERENCES ${FkSchema}.[${FkTable}](${FkColumn})" >>$schema/$table.fk.sql
    fi
  done < <(tail -n +3 $schema/$table.csv)

}

#  generate specific tables
rm -rf **/*.sql
for file in **/*.csv; do
  IFS='/' read -r schema table <<<${file%%.*}
  create-table $schema $table
done

# create database
echo "USE master;
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'Identity')
  DROP DATABASE [Identity];
GO
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = 'Identity')
  CREATE DATABASE [Identity];
GO
USE [Identity];
GO" >all.sql

# creae schema
echo "IF OBJECT_ID('List') IS NULL
  EXEC sys.sp_executesql N'CREATE SCHEMA List;'
GO" >>all.sql

# combine all the table files
for file in **/*.table.sql; do
  IFS='/' read -r schema table <<<${file%%.*}
  echo "
PRINT '$schema.$table.table.sql'
GO" >>all.sql
  cat $schema/$table.table.sql >>all.sql
  echo "GO" >>all.sql
done

# combine all the foreign key files
for file in **/*.fk.sql; do
  IFS='/' read -r schema table <<<${file%%.*}
  echo "
PRINT '$schema.$table.fk.sql'
GO" >>all.sql
  cat $schema/$table.fk.sql >>all.sql
  echo "GO" >>all.sql
done

# cat **/*.table.sql >all.sql
# cat **/*.fk.sql >>all.sql
