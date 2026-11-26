library(tidyverse)


impc_procedure <- read.csv("IMPC_procedure.txt")
impc_parameter_description <- read.csv("IMPC_parameter_description.txt")


disease_information <- read_tsv("Disease_information.txt")
disease_information <- disease_information %>% select(-...9)

disease_information <-
  disease_information %>% 
  separate_rows(mouse_genotype_associations, sep = "\\|")

write.csv(disease_information, "disease_information.csv", row.names = FALSE)


raw_data <- read.csv("combined_gene_data_og.csv")

raw_data <- raw_data %>% select(-missing_fields, -file_status, -file_name)
write.csv(raw_data, "raw_data.csv", row.names = FALSE)



impc_procedure %>% 
  distinct(name, description, isMandatory, impcParameterOrigId) %>% View()


unique_impc_procedure <- impc_procedure %>% 
  distinct(name, description, isMandatory)

write.csv(unique_impc_procedure, "unique_impc_descriptions.csv", row.names = FALSE)


gene_table <- cleaned_data %>% distinct(gene_accession_id,gene_symbol,allele_symbol)
write.csv(gene_table, "gene_table.csv", row.names = FALSE)

sum(duplicated(gene_table))


gene_table %>% filter(gene_accession_id == "MGI:99917")
