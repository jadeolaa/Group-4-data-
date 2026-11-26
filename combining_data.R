library(dplyr)
library(tidyr)
library(stringr)

# combine all cleaned columns to create a dataframe 

mak <- read.csv("cleaned_combined_data_mak.csv")
che <- read.csv("Final_Cleaned_5_Columns.csv")
meg <- read.csv("my_5_cleaned_columns_megi.csv")
joy <- read.csv("cleaned_combined_data_Joy 5 columns.csv")


cleaned_data <- data.frame(c(meg, che, joy, mak))

# use relocate command to order columns the same as original 

cleaned_data <- cleaned_data %>% relocate(gene_accession_id)
cleaned_data <- cleaned_data %>% relocate(gene_symbol, .after = gene_accession_id)
cleaned_data <- cleaned_data %>% relocate(strain_name, .after = allele_symbol)
cleaned_data <- cleaned_data %>% relocate(parameter_stable_id, .after = strain_name)
cleaned_data <- cleaned_data %>% relocate(p_value, .after = parameter_stable_id)
cleaned_data <- cleaned_data %>% relocate(parameter_name, .after = p_value)
cleaned_data <- cleaned_data %>% relocate(mouse_life_stage, .after=parameter_name)
cleaned_data <- cleaned_data %>% relocate(lacz_blood, .after = mouse_life_stage)
cleaned_data <- cleaned_data %>% relocate(lacz_brain, .after = lacz_blood)
cleaned_data <- cleaned_data %>% relocate(lacz_colon, .after=lacz_brain)
cleaned_data <- cleaned_data %>% relocate(lacz_eye, .after=lacz_colon)
cleaned_data <- cleaned_data %>% relocate(lacz_heart, .after= lacz_eye)
cleaned_data <- cleaned_data %>% relocate(lacz_kidney, .after=lacz_heart)
cleaned_data <- cleaned_data %>% relocate(lacz_liver, .after=lacz_kidney)
cleaned_data <- cleaned_data %>% relocate(lacz_lung, .after=lacz_liver)
cleaned_data <- cleaned_data %>% relocate(lacz_skeletal_muscle, .after=lacz_lung)
cleaned_data <- cleaned_data %>% relocate(lacz_skin, .after=lacz_skeletal_muscle)
cleaned_data <- cleaned_data %>% relocate(lacz_vascular_system, .after=lacz_skin)
cleaned_data <- cleaned_data %>% relocate(analysis_id, .after=lacz_vascular_system)

# add csv file name column from dataset to cleaned_data
cleaned_data <- cleaned_data %>% mutate(file_name = c(dataset$file_name))
  

# for all columns starting with lacz, replace.na with "no data"
cleaned_data <- cleaned_data %>% mutate(across(starts_with("lacz"), ~ replace_na(.x, "no data")))


# change no data to No data for consistency in lacz columns 
cleaned_data <- cleaned_data %>% mutate(across(starts_with("lacz"), ~ recode(.x, "no data" = "No data"))) 

# change missing values that say name to na

cleaned_data <- cleaned_data %>%
  mutate(across(where(is.character), ~ na_if(.x, "NAME")))

cleaned_data %>%
  filter(if_any(everything(), ~ .x == "NAME")) %>% View() #check to see if it worked 

# add in the correct gene symbol for missing values
cleaned_data <- cleaned_data %>%
  mutate(gene_symbol = coalesce(gene_symbol, str_extract(allele_symbol, "^[^<]+")))

cleaned_data %>% filter(is.na(gene_symbol)) %>% View() #check to see which values are missing

# make sure all are capitalized to prevent inconsistencies 
cleaned_data <- cleaned_data %>%
  mutate(parameter_stable_id = str_to_upper(parameter_stable_id))

# delete row that contain all na values  
cleaned_data <- cleaned_data %>%
  slice(-2)


cleaned_data %>% filter(is.na(parameter_stable_id)) %>% View()
cleaned_data %>% filter(is.na(gene_symbol)) %>% View()






# save final cleanest data set to a csv file for further use 

write.csv(cleaned_data,"group4_clean_data.csv", row.names = FALSE)

cleaned_data <- read.csv("group4_clean_data.csv")




# change gene_symbol values that are 0 to their true values using allele_symbol 
cleaned_data <- cleaned_data %>%
  mutate(
    gene_symbol = if_else(
      gene_symbol == 0,
      str_extract(allele_symbol, "^[^<]+"),
      as.character(gene_symbol)
    )
  ) 

cleaned_data %>% filter(gene_symbol == 0) # make sure there aren't any zeroes 



# check for any duplicate csv files 
sum(duplicated(cleaned_data$file_name))





