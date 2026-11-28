
create database IMPC;
use IMPC;

create table Raw_IMPC_Data(
Gene_Accession_ID varchar(255),
Gene_Symbol varchar(100),
Allele_Symbol varchar(100),
Strain_Name Varchar(100),
Parameter_Stable_ID varchar(100),
P_Value varchar(100), -- NA values can be inluded without conversion errors 
Parameter_name varchar(255),
Mouse_Life_Stage varchar(100),
Lacz_Blood varchar(100),
Lacz_Brain varchar(100),
Lacz_Colon varchar(100),
Lacz_Eye varchar(100),
Lacz_Heart varchar(100),
Lacz_kidney varchar(100),
Lacz_Liver varchar(100),
Lacz_Lung varchar(100),
Lacz_Skeletal_Muscle varchar(100),
Lacz_Skin varchar(100),
Lacz_Vascular_System varchar(100),
Analysis_ID varchar(255)
);

-- Check if table has been created 
select * from Raw_IMPC_Data;
select count(*) from Raw_IMPC_Data; -- Total number of rows 

-- Create Staging table - clean dataset
create table Group4_Clean_Data(
Gene_Accession_ID varchar(255),
Gene_Symbol varchar(100),
Allele_Symbol varchar(100),
Strain_Name Varchar(100),
Parameter_Stable_ID varchar(100),
P_Value varchar(100), -- NA values can be inluded without conversion errors 
Parameter_name varchar(255),
Mouse_Life_Stage varchar(100),
Lacz_Blood varchar(100),
Lacz_Brain varchar(100),
Lacz_Colon varchar(100),
Lacz_Eye varchar(100),
Lacz_Heart varchar(100),
Lacz_kidney varchar(100),
Lacz_Liver varchar(100),
Lacz_Lung varchar(100),
Lacz_Skeletal_Muscle varchar(100),
Lacz_Skin varchar(100),
Lacz_Vascular_System varchar(100),
Analysis_ID varchar(255),
File_Name varchar(100)
);

select * from Group4_Clean_Data;
select count(*) from Group4_Clean_Data;

-- Create Gene table
create table Gene(
Gene_Accession_ID Varchar(100) not null,
Gene_Symbol Varchar(100),
Gene_Name Varchar(100), 
Gene_Symbol_Disease varchar(100),
Gene_Symbol_Ontology varchar(100),
primary key (Gene_Accession_ID)
);

select * from Gene;

-- Populate table 
insert into Gene (Gene_Accession_ID, Gene_Symbol)
select distinct Gene_Accession_ID, Gene_Symbol
from Group4_Clean_Data; 
-- Duplicate  Gene_Accession_ID

-- Search for the duplicate
select Gene_Accession_ID, Gene_Symbol
from Group4_Clean_Data
where Gene_Accession_ID = 'MGI:1917272'; -- Find the  specific Gene

-- Search for all duplicates 
select sum(Duplicate_count) as Total_Duplicates
from(
select Gene_Accession_ID,
Count(*) as Duplicate_count
from Group4_Clean_Data
where Gene_Accession_ID is not null
group by Gene_Accession_ID 
having count(*) > 1 -- count every time a duplicate appears more than once 
) as duplicates;

-- 28,220 records belonging to duplicated gene accession IDs

select count(distinct Gene_Accession_ID) as total_unique_Genes
from Group4_Clean_Data
where Gene_Accession_ID is not null 
and trim(Gene_Accession_ID) <> '';

insert into Gene(Gene_Accession_ID)
select distinct Gene_Accession_ID
from Group4_Clean_Data
where Gene_Accession_ID is not null
and trim(Gene_Accession_ID) <> '';

select * from Gene;

-- Populating the Gene symbol column 
select distinct 
Gene_Accession_ID,
Gene_Symbol
from Group4_Clean_data
where Gene_symbol is not null
and trim(Gene_symbol) <> ''
and Upper(trim(Gene_symbol)) <> 'NA';


update Gene 
Join(
select
Gene_Accession_ID, 
Min(trim(Gene_symbol))as Gene_Symbol
from Group4_Clean_Data   --  min select one symbol where there are repeated records with the same symbol 
where Gene_Symbol is not null  -- exclude values are not null, empty values, NA
and trim(Gene_Symbol) <> ''
and UPPER(trim(Gene_symbol)) <> 'NA'
group by Gene_Accession_ID
having count(distinct upper(trim(Gene_symbol))) = 1   -- 1 gene = multiple phenotype test records (records are grouped by accession_ID so we can identify the symbol assoicated with each gene)
) as source 
on Gene.Gene_Accession_ID = source.Gene_Accession_ID   --  macth the two tables
set Gene.Gene_Symbol = source.Gene_Symbol
where Gene.Gene_Symbol is null --  update empty symbols
or trim(Gene.Gene_Symbol) = '';

# Check the table 
select *
from Gene
order by Gene_Accession_ID;

create table Gene_Ontology(
Gene_Ontology_ID int auto_increment,
Source_Database varchar(255),
Object_Id varchar(255),
Gene_Symbol varchar(255),
Relation varchar(100),
GO_ID varchar(100),
Db_Reference varchar(100),
Evidence_Code varchar(100),
With_From text,
GO_Category varchar(100),
Object_Name varchar(255),
Object_Synonym varchar(255),
Object_Type varchar(255),
Taxon_ID varchar(100),
Date varchar(100),
Assigned_By varchar(100),
primary key (Gene_Ontology_ID)
);


-- Number of Rows table has
select count(*) as total_rows
from Gene_Ontology;

select * from Gene_Ontology;

create table Disease_Associations (
Disease_Association_ID int auto_increment,
Human_Gene_Symbol varchar(255), 
Human_Gene_Name varchar(255),
HGNC_ID varchar(100),
DO_Name varchar(255),
DO_ID varchar(100),
Mouse_Genotype_Associations varchar(255),
Gene_Symbol varchar(255),
Gene_Accession_ID varchar(255),
primary key(Disease_Association_ID)
);


select count(*) as total_rows 
from Disease_Associations;

-- view the table
select * 
from Disease_Associations;

--  add missing Accesion_IDS
insert into Gene(Gene_Accession_ID)
select distinct d.Gene_Accession_ID 
from Disease_Associations as d
left join Gene as g 
on trim(d.Gene_Accession_ID) = trim(g.Gene_Accession_ID)
where d.Gene_Accession_ID is not null
and trim(d.Gene_Accession_ID) <> ''
and Upper(trim(d.Gene_Accession_ID)) <> 'NA'
and g.Gene_Accession_ID is null;


-- Add foreign key
alter table Disease_Associations
add constraint fk_disease_gene -- ensures integrity/accuracy in RDBMS (Rule disease association must be linked to a gene in the Gene table)
foreign key (Gene_Accession_ID) -- 1:M (1 gene can be associated with many diseases)
references Gene(Gene_Accession_ID); -- fk must match the Gene_Accession_ID

show create table Disease_Associations;

-- create a staging tabe to populate the parameter table using the IMPC_Parameter_description.txt
create table Parameter_Reference(
 impcParameterOrigId int,
 name varchar(255),
 description text,
 parameterId varchar(50)
 );

select count(*) from Parameter_Reference;

create table Parameter (  -- main table 
Parameter_ID int auto_increment,
Parameter_Stable_ID varchar(100) not null unique,
Parameter_Name varchar(255) not null,
Parameter_Description text,
primary key (Parameter_ID)
);

select * from Parameter;
select count(*) from Parameter;

-- Add missing parameter IDs from other providers
insert into Parameter 
(Parameter_Stable_ID, Parameter_Name, Parameter_Description)
select trim(g.Parameter_Stable_ID),
min(trim(g.Parameter_Name)),
null
from Group4_Clean_Data as g
left join Parameter as p
on trim(g.Parameter_Stable_ID) = trim(p.Parameter_Stable_ID)
where g.File_Name not like '%|_1.csv'
and p.Parameter_Stable_ID is null 
group by trim(g.Parameter_Stable_ID);

-- Check for blank or Null stable IDs
select count(*)
from Parameter
where Parameter_Stable_ID is null
or Parameter_Stable_ID = '';

-- Add missing parameter IDS frm other providers 
insert into Parameter (Parameter_Stable_ID, Parameter_Name, Parameter_Description)
select trim(g.ParameterId),
min(trim(name)),
min(nullif(trim(description), '')) 
from Parameter_Reference
group by trim(ParameterId);

-- Check for blank/Null stable Ids
select count(*) from Parameter
where Parameter_Stable_ID is null or Parameter_Stable_ID = '';

--  check that all parameter ids match the parameter table
select count(distinct trim(g.parameter_stable_id)) as unmatched_parameter_ids
from group4_clean_data as g
left join parameter as p
on trim(g.parameter_stable_id) = trim(p.parameter_stable_id)
where g.file_name not like '%\_1.csv'
and p.parameter_stable_id is null;

--  Check IDs that appear with more than one name in reference file
select trim(parameterId), group_concat(distinct trim(name) separator ' | ') as names
from Parameter_Reference
group by trim(ParameterId)
having count(distinct trim(name)) >1;

describe Parameter_Reference;

create table Parameter_Origin ( -- contains Origin_Ids that dont fit in  the Parameter (Links each Origin ID to its Parameter)
Parameter_Origin_ID int not null, 
Parameter_ID int not null,
primary key(Parameter_Origin_ID),
foreign key (Parameter_ID) references Parameter(Parameter_ID) -- fk links to Parameter(main table)
);

-- populate Parameter Origin table from the staging table
insert into Parameter_Origin (Parameter_Origin_ID, Parameter_ID)
select distinct r.impcParameterOrigID, p.Parameter_ID
from Parameter_Reference r
join Parameter p on p.Parameter_Stable_ID = trim(r.ParameterId)
where r.impcParameterOrigId is not null;

select * from Parameter_Origin;

create table Parameter_Group(
Group_ID int auto_increment primary key,
Group_Name varchar(100) not null unique -- weight, images, brain, adrenal glands, blood, Cardiovascular development
);

select * from Parameter_Group;

-- P_G_M is a M:M relationship links groups to Paramaeters 
-- 1 Parameter can be in several groups and 1 group can have many parameters
-- composite primary key : neither column is unique alone but the pair is 
-- The same parameter cant be added to the same group twice 

create table Parameter_Group_Member(
Group_ID int not null,   -- fk Parameter group
Parameter_Stable_ID varchar(100) not null,  -- fk Parameter table
primary key (Group_ID, Parameter_Stable_ID),
foreign key(Group_ID) references Parameter_Group (Group_ID),
foreign key (Parameter_Stable_ID) references Parameter (Parameter_Stable_ID)
);

select * from Parameter_Group_Member;

# Populate Parameter_Group
insert into Parameter_Group (Group_Name)
values('weight'), ('images'), ('brain'), ('adrenal glands'), ('blood'), ('cardiovascular development');

-- Weight 
insert into Parameter_Group_Member (Group_ID, Parameter_Stable_ID)
select g.Group_ID, p.Parameter_Stable_ID
from Parameter p
join Parameter_Group g on g.Group_Name = 'weight'
where p.Parameter_Name like '%weight%';  -- %Parameter% Clause

-- images 
insert into Parameter_Group_Member (Group_ID, Parameter_Stable_ID)
select g.Group_ID, p.Parameter_Stable_ID
from Parameter p
join Parameter_Group g on g.Group_Name = 'images'
where p.Parameter_Name like '%images%';  

-- brain 
insert into Parameter_Group_Member (Group_ID, Parameter_Stable_ID)
select g.Group_ID, p.Parameter_Stable_ID
from Parameter p
join Parameter_Group g on g.Group_Name = 'brain'
where p.Parameter_Name like '%brain%';  

-- blood 
insert into Parameter_Group_Member (Group_ID, Parameter_Stable_ID)
select g.Group_ID, p.Parameter_Stable_ID
from Parameter p
join Parameter_Group g on g.Group_Name = 'blood'
where p.Parameter_Name like '%blood%';

-- adrenal glands: name contains adrenal
insert into Parameter_Group_Member (Group_ID, Parameter_Stable_ID)
select g.Group_ID, p.Parameter_Stable_ID
from Parameter p
join Parameter_Group g on g.Group_Name = 'adrenal glands'
where p.Parameter_Name like '%adrenal%';

-- cardiovascular development name contains 'cardio or 'heart'
insert into Parameter_Group_Member (Group_ID, Parameter_Stable_ID)
select g.Group_ID, p.Parameter_Stable_ID
from Parameter p
join Parameter_Group g on g.Group_Name = 'cardiovascular development'
where p.Parameter_Name like '%cardio%';

-- check the number of parameters in each group 
-- Parameter_Group_Member has 1 row per parameter per group
-- join to parameter Group (g) to show the group name instead of the ID
select g.Group_Name, count(*) as n_parameters -- alias
from Parameter_Group_Member m
join Parameter_Group g  on g.Group_ID = m.Group_ID
group by g.Group_Name;


create table IMPC_Procedure (
Procedure_ID int auto_increment,
name varchar(255),
description text,
isMandatory varchar(50),
impcParameterOrigId int not null,
primary key (Procedure_ID),
foreign key(impcParameterOrigId)
references Parameter_Origin(Parameter_origin_ID)
);

select count(*) as total_procedures
from IMPC_Procedure;

-- Check imported data 
select *
from IMPC_Procedure
limit 20;


-- trouble shooting (duplicates in Analysis_ID.csv)
-- In order to create the Phenotype_test table 
select count(*) as duplicate_analysis_ids
from(
select Analysis_ID
from Group4_Clean_Data
group by Analysis_ID
having count(*) > 1
) as duplicates;

select Analysis_ID,
count(*) as copies
from Group4_Clean_Data
group by Analysis_Id 
having count(*) > 1
order by copies desc;

-- Confiriming the duplicate file name _1
select File_Name, count(*) as Number_of_Rows
from Group4_Clean_Data
where File_Name like '%\_1.csv'
group by File_Name;

-- Check remaning records have unique Analysis_ID values and exlcude them using where 
select count(*) Remaining_Rows,
count(distinct Analysis_ID) as Unique_Analysis_IDs
from Group4_Clean_Data
where File_Name not like '%\_1.csv';

-- Phenotype_Test 
create table Phenotype_Test(
Analysis_ID varchar(255) not null,
Gene_Accession_ID varchar(100) not null,
Parameter_Stable_ID varchar(100) not null, -- Every Phenoytpe > linked to a parameter 
P_Value varchar(100),
primary key(Analysis_ID),
foreign key(Gene_Accession_ID)
references Gene(Gene_Accession_ID),
foreign key(Parameter_Stable_ID)
references `Parameter`(Parameter_Stable_ID)
);

select * from Phenotype_Test;

-- Populate  Phenotype_Test table 
insert into Phenotype_Test(
Analysis_ID,
Gene_Accession_ID,
Parameter_Stable_ID, 
P_Value
)
select 
g.Analysis_ID,
g.Gene_Accession_ID,
trim(g.Parameter_Stable_ID),
g.P_Value
from Group4_Clean_Data as g
inner join Parameter as p 
on trim(g.Parameter_Stable_ID) = trim(p.Parameter_Stable_ID)
where g.File_Name not like '%\_1.csv';

-- Phenytpe_Test table validation
select * from Phenotype_Test;
select count(*) as Total_Rows
from Phenotype_Test;

select count(distinct Analysis_ID) as Unique_Analysis
from Phenotype_Test;

select count(*) as Unmatched_Genes
from Phenotype_Test pt
left join gene g
    on pt.Gene_Accession_ID = g.Gene_Accession_ID
where g.Gene_Accession_ID is null;


create table Mouse_Information(
Mouse_Information_ID int auto_increment,
Gene_Accession_ID varchar(100) not null,
Allele_symbol varchar(255), 
Strain_Name varchar(255),
Mouse_Life_Stage varchar(255),
primary key (Mouse_Information_ID),
foreign key (Gene_Accession_ID)
references Gene(Gene_Accession_ID)
);

-- Populate table 
insert into Mouse_Information( 
Gene_Accession_ID,
Allele_Symbol,
Strain_Name,
Mouse_Life_Stage
)
select distinct 
trim(g.Gene_Accession_ID),
trim(g.Allele_Symbol),
trim(g.Strain_Name),
nullif(trim(g.Mouse_Life_Stage), 'NA')
from Group4_Clean_Data as g
inner join gene as ge
on trim(g.Gene_Accession_ID) = trim(ge.Gene_Accession_ID)
where g.File_Name not like '%\_1.csv';

select count(*) as Missing_Alleles
from Mouse_Information
where Allele_Symbol is null or trim(Allele_Symbol) = '';


select * from Mouse_Information;

-- Check for duplicate mouse records 
select
Gene_Accession_ID,
Allele_Symbol,
Strain_Name,
Mouse_Life_Stage,
count(*) as Records
from Mouse_Information
group by Gene_Accession_ID, Allele_Symbol, Strain_Name, Mouse_Life_Stage
having count(*) > 1;


create table LacZ(
Lacz_ID int auto_increment,
Gene_Accession_ID varchar(100) not null,
Lacz_Blood varchar(100),
Lacz_Brain varchar(100),
Lacz_Colon varchar(100),
Lacz_Eye varchar(100),
Lacz_Heart varchar(100),
Lacz_Kidney varchar(100),
Lacz_Liver varchar(100),
Lacz_Lung varchar(100),
Lacz_Skeletal_Muscle varchar(100),
Lacz_Skin varchar(100),
Lacz_Vascular_System varchar(100),
primary key (Lacz_ID),
foreign key (Gene_Accession_ID)
references Gene(Gene_Accession_ID)
);

-- check for duplicates
select
Gene_Accession_ID,
count(*) as Occurrences
from Group4_Clean_Data
where File_Name not like '%\_1.csv'
group by Gene_Accession_ID
order by Occurrences desc;

select distinct
Lacz_Blood,
Lacz_Brain,
Lacz_Colon,
Lacz_Eye,
Lacz_Heart,
Lacz_Kidney,
Lacz_Liver,
Lacz_Lung,
Lacz_Skeletal_Muscle,
Lacz_Skin,
Lacz_Vascular_System,
count(*) as Occurrences
from Group4_Clean_Data
where File_Name not like '%\_1.csv'
group by
Lacz_Blood,
Lacz_Brain,
Lacz_Colon,
Lacz_Eye,
Lacz_Heart,
Lacz_Kidney,
Lacz_Liver,
Lacz_Lung,
Lacz_Skeletal_Muscle,
Lacz_Skin,
Lacz_Vascular_System
order by Occurrences desc;

-- Populate table 
insert into Lacz (
Gene_Accession_ID,
Lacz_Blood,
Lacz_Brain,
Lacz_Colon,
Lacz_Eye,
Lacz_Heart,
Lacz_Kidney,
Lacz_Liver,
Lacz_Lung,
Lacz_Skeletal_Muscle,
Lacz_Skin,
Lacz_Vascular_System
)
select distinct
Gene_Accession_ID,
Lacz_Blood,
Lacz_Brain,
Lacz_Colon,
Lacz_Eye,
Lacz_Heart,
Lacz_Kidney,
Lacz_Liver,
Lacz_Lung,
Lacz_Skeletal_Muscle,
Lacz_Skin,
Lacz_Vascular_System
from Group4_Clean_Data
where File_Name not like '%\_1.csv';

select count(*) as Total_Records
from Lacz;

select * from Lacz;

-- Check if gene has multiple lacz records 
select
Gene_Accession_ID,
count(*) as Occurrences
from Lacz
group by Gene_Accession_ID
having count(*) > 1;

-- check lacz record links to a valid gene 
select count(*) as Missing_Gene_Links
from Lacz
where Gene_Accession_ID is null;


-- Gene Ontology relationship 
-- Check gene symbol duplicates 
select
Gene_Symbol_Ontology,
count(*) as Occurrences
from Gene
where Gene_Symbol_Ontology is not null
group by Gene_Symbol_Ontology
having count(*) > 1;

-- 1:M relationship 
alter table Gene_Ontology
add Gene_Accession_ID varchar(100);

update Gene_Ontology go
join Gene g
on trim(go.Gene_Symbol) = trim(g.Gene_Symbol)
set go.Gene_Accession_ID = g.Gene_Accession_ID
where go.Gene_Accession_ID is null;

-- check there are no invalid Gene Accession IDs
select count(*) as Unmatched_Genes
from Gene_Ontology go
left join Gene g
on go.Gene_Accession_ID = g.Gene_Accession_ID
where go.Gene_Accession_ID is not null
and g.Gene_Accession_ID is null;

-- Add the foreign key
alter table Gene_Ontology
add constraint fk_gene_ontology_gene
foreign key (Gene_Accession_ID)
references Gene(Gene_Accession_ID);


-- Collaborators Queries 
# Query Genes Group4 Genes
select Gene_Accession_ID,Gene_Symbol
from Gene
where Gene_Symbol in ('Scart2', 'Pcsk4', 'Klk5', 'Ltn1', 'Mettl16');

-- Parameters, P values and Parameter groups
-- Retrieve phenotype parameters, p-values and groups for the five selected genes.
-- left join retains parameters that have not been assigned to a group.
-- cast ensures p-values are sorted numerically rather than alphabetically.
-- Retrieve the experimental procedures associated with the five selected genes.
select distinct
g.Gene_Symbol,
p.Parameter_Name,
pr.name as Procedure_Name
from Gene g
join Phenotype_Test pt on pt.Gene_Accession_ID = g.Gene_Accession_ID
join Parameter p on p.Parameter_Stable_ID = pt.Parameter_Stable_ID
join Parameter_Origin o on o.Parameter_ID = p.Parameter_ID
join IMPC_Procedure pr on pr.impcParameterOrigId = o.Parameter_Origin_ID
where g.Gene_Symbol in ('Scart2','Pcsk4','Klk5','Ltn1','Mettl16')
order by g.Gene_Symbol,p.Parameter_Name;

-- Check whether the 5 mouse genes have corresponding human disease associations
-- use left join so all the 5 genes appear even if no disease association with a particulr gene 
-- Retrieve human disease associations for the five selected mouse genes.

select
g.Gene_Symbol,
d.Human_Gene_Symbol,
d.Human_Gene_Name,
d.DO_Name,
d.DO_ID
from Gene g
left join Disease_Associations d
on d.Gene_Accession_ID = g.Gene_Accession_ID
where g.Gene_Symbol in ('Scart2','Pcsk4','Klk5','Ltn1','Mettl16')
order by g.Gene_Symbol,d.DO_Name;

-- Check if 5 genes appear in the GO table by Gene symbol 
select Gene_Symbol,GO_ID,Relation,GO_Category,Evidence_Code
from Gene_Ontology
where Gene_Symbol in ('Scart2','Pcsk4','Klk5','Ltn1','Mettl16')
order by Gene_Symbol,GO_ID;

-- link GO annotations match in gene accession ids 
update Gene_Ontology go
join Gene g
on trim(go.Gene_Symbol) = trim(g.Gene_Symbol)
set go.Gene_Accession_ID = g.Gene_Accession_ID
where go.Gene_Symbol in ('Scart2','Pcsk4','Klk5','Ltn1','Mettl16')
and go.Gene_Accession_ID is null;


select Gene_Symbol,Gene_Accession_ID,count(*) as Annotation_Count
from Gene_Ontology
where Gene_Symbol in ('Scart2','Pcsk4','Klk5','Ltn1','Mettl16')
group by Gene_Symbol,Gene_Accession_ID
order by Gene_Symbol;

-- check if these  specific genes match Gene_Ontolgy table
select Gene_Symbol,count(*) as Annotation_Count
from Gene_Ontology
where lower(trim(Gene_Symbol)) in ('scart2','pcsk4','klk5')
group by Gene_Symbol;

-- Check GO annotation linked to the five selected genes
select g.Gene_Symbol,count(go.Gene_Ontology_ID) as Linked_GO_Annotations
from Gene g
left join Gene_Ontology go
on g.Gene_Accession_ID = go.Gene_Accession_ID
where g.Gene_Symbol in ('Scart2','Pcsk4','Klk5','Ltn1','Mettl16')
group by g.Gene_Symbol
order by g.Gene_Symbol;

-- Check for phenotype tests without a matching gene or parameter
select count(*) as Unmatched_Phenotype_Tests
from Phenotype_Test pt
left join Gene g on pt.Gene_Accession_ID = g.Gene_Accession_ID
left join Parameter p on pt.Parameter_Stable_ID = p.Parameter_Stable_ID
where g.Gene_Accession_ID is null
or p.Parameter_Stable_ID is null;

-- Check for duplicate Analysis ID values in Phenotype Test.
select Analysis_ID,count(*) as Duplicate_Count
from Phenotype_Test
group by Analysis_ID
having count(*) > 1;

-- Check for missing p-values in Phenotype_Test.
select count(*) as Missing_P_Values
from Phenotype_Test
where P_Value is null or trim(P_Value) = '' or trim(P_Value) = 'NA';

-- Check p-values that are not in a normal decimal or scientific notation format.
select P_Value,count(*) as Record_Count
from Phenotype_Test
where P_Value not like '%e-%'
and P_Value not like '%E-%'
and P_Value not regexp '^[0-9.]+$'
and P_Value <> 'NA'
and P_Value is not null
group by P_Value;

-- Check for mouse information records without a matching gene.
select count(*) as Unmatched_Mouse_Records
from Mouse_Information mi
left join Gene g
on mi.Gene_Accession_ID = g.Gene_Accession_ID
where g.Gene_Accession_ID is null;

-- Check for Lacz records without a matching gene.
select count(*) as Unmatched_Lacz_Records
from Lacz l
left join Gene g
on l.Gene_Accession_ID = g.Gene_Accession_ID
where g.Gene_Accession_ID is null;

-- Check for parameter group members without a matching parameter.
select count(*) as Unmatched_Group_Parameters
from Parameter_Group_Member pgm
left join Parameter p
on pgm.Parameter_Stable_ID = p.Parameter_Stable_ID
where p.Parameter_Stable_ID is null;

-- Check for parameter origins without a matching parameter.
select count(*) as Unmatched_Parameter_Origins
from Parameter_Origin po
left join Parameter p
on po.Parameter_ID = p.Parameter_ID
where p.Parameter_ID is null;

-- Check for procedures without a matching parameter origin.
select count(*) as Unmatched_Procedures
from IMPC_Procedure pr
left join Parameter_Origin po
on pr.impcParameterOrigId = po.Parameter_Origin_ID
where po.Parameter_Origin_ID is null;

-- Check for disease associations without a matching gene.
select count(*) as Unmatched_Disease_Associations
from Disease_Associations d
left join Gene g
on d.Gene_Accession_ID = g.Gene_Accession_ID
where g.Gene_Accession_ID is null;

-- Check the number of records stored in each main database table.
select 'Gene' as Table_Name,count(*) as Total_Records from Gene
union all
select 'Disease_Associations',count(*) from Disease_Associations
union all
select 'Gene_Ontology',count(*) from Gene_Ontology
union all
select 'Phenotype_Test',count(*) from Phenotype_Test
union all
select 'Parameter',count(*) from Parameter
union all
select 'Parameter_Origin',count(*) from Parameter_Origin
union all
select 'IMPC_Procedure',count(*) from IMPC_Procedure
union all
select 'Parameter_Group',count(*) from Parameter_Group
union all
select 'Parameter_Group_Member',count(*) from Parameter_Group_Member
union all
select 'Mouse_Information',count(*) from Mouse_Information
union all
select 'Lacz',count(*) from Lacz;

