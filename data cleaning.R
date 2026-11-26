library(dplyr)
library(tidyverse)

unclean_dataset <- read.csv("combined_gene_data_og.csv")

dataset <- read.csv("combined_gene_data(in).csv")

sum(is.na(dataset$parameter_stable_id))
sum(is.na(dataset$gene_symbol))
sum(is.na(dataset$lacz_colon))
sum(is.na(dataset$lacz_liver))
sum(is.na(dataset$lacz_vascular_system))



#create a vector of all the appropriate values for lacz columns based on sop
sop_lacz <- c("No data", "ambiguous", "expression", "imageOnly", "no expression",
              "tissue not available")

#lowercase all the observations in the column 
dataset <- dataset %>% 
  mutate(lacz_colon = tolower(lacz_colon))

dataset <- dataset %>% 
  mutate(lacz_liver = tolower(lacz_liver))

dataset <- dataset %>% 
  mutate(lacz_vascular_system = tolower(lacz_vascular_system))


#subset the dataframe in order to see all of the typos 
subset_df <- dataset %>%
  filter(! lacz_colon %in% sop_lacz)

unique(subset_df$lacz_colon)


# remove all of the special characters from each observation
library(stringr)
dataset <- dataset %>%
  mutate(lacz_colon = str_replace_all(lacz_colon, "[^[:alnum:]]", ""))

dataset <- dataset %>%
  mutate(lacz_liver = str_replace_all(lacz_liver, "[^[:alnum:]]", ""))

dataset <- dataset %>%
  mutate(lacz_vascular_system = str_replace_all(lacz_vascular_system, "[^[:alnum:]]", ""))

#insert the spaces back in so that it matches the sop properly 
dataset <- mutate(dataset, lacz_colon = recode(.x = lacz_colon, "nodata" = "No data")) 
dataset <- mutate(dataset, lacz_colon = recode(.x = lacz_colon, "noexpression" = "no expression"))
dataset <- mutate(dataset, lacz_colon = recode(.x = lacz_colon, "tissuenotavailable" = "tissue not available"))

dataset <- mutate(dataset, lacz_liver = recode(.x = lacz_liver, "nodata" = "No data")) 
dataset <- mutate(dataset, lacz_liver = recode(.x = lacz_liver, "noexpression" = "no expression"))
dataset <- mutate(dataset, lacz_liver = recode(.x = lacz_liver, "tissuenotavailable" = " tissue not available"))


dataset <- mutate(dataset, lacz_vascular_system = recode(.x = lacz_vascular_system, "nodata" = "No data")) 
dataset <- mutate(dataset, lacz_vascular_system = recode(.x = lacz_vascular_system, "noexpression" = "no expression"))
dataset <- mutate(dataset, lacz_vascular_system = recode(.x = lacz_vascular_system, "tissuenotavailable" = " tissue not available"))

#check to make sure it matches the sop 
unique(dataset$lacz_colon)
unique(dataset$lacz_liver)
unique(dataset$lacz_vascular_system)

# the command below is used to see how many rows say "name" instead of one of the values in the sop.
# need to figure out what to do with those and the na values
dataset %>%
  filter(lacz_vascular_system == "name") %>% View()


# i used this to see where the na values in these two columns are , 
# not sure what to do about them since they are ids...
filter(dataset, is.na(dataset$gene_symbol)) %>% View()
filter(dataset, is.na(dataset$parameter_stable_id)) %>% View()


# i used this command to see if the parameter id was the same for the matching parameter name
# i need to figure out if the ids all match their perspective names
dataset %>% 
  filter(parameter_name=="Limb grasp") %>%
  View()

unique(dataset$parameter_name)

# i used this to look at only the parameter name and id columns and see only distinct values 
dataset %>%
  select(parameter_name, parameter_stable_id) %>% 
  distinct() %>%
  View()


#remove incorrect characters from gene symbol column
dataset <- dataset %>%
  mutate(gene_symbol = str_replace_all(gene_symbol, "[^[:alnum:]]", ""))

# what to do with na values?
sum(is.na(dataset$gene_symbol))


# i used this command to see how many contain more than 3 underscores 
dataset %>%
  filter(str_count(parameter_stable_id, "_") != 3) %>% View()

# used to remove all special characters except for underscores 
dataset <- dataset %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "[^[:alnum:]_]", "")) 



# need to correct the incorrect ones that contain extra underscores
# that are splitting up the data incorrectly 
# how to recode to fix underscores that are placed incorrectly 

dataset <- dataset %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "__", "_")) %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "^IMP_C_", "IMPC_")) %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "^I_MPC_", "IMPC_")) %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "^IM_PC_", "IMPC_")) %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "^_MGP_", "MGP_")) %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "^M_GP_", "MGP_")) %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "([0-9]{2})_([0-9])_", "\\1\\2_")) %>%
  mutate(parameter_stable_id = str_replace_all(parameter_stable_id, "([0-9]{2})_([0-9])$", "\\1\\2")) %>%
  mutate(cleaned = str_remove_all(parameter_stable_id, "_")) %>%
  mutate(corrected = str_replace(cleaned,
      "^([A-Za-z]{3,6})([A-Za-z0-9]{3})([0-9]{3})([0-9]{3})$",
      "\\1_\\2_\\3_\\4")) %>%
  mutate(parameter_stable_id = if_else(!is.na(corrected), corrected,parameter_stable_id)) %>%
  select(-corrected, -cleaned)

# what about the ones that say name? is that the same as na?



# create a dataset to see all the incorrect values in parameter id section
# some do not start with impc.. are they valid? 
incorrect <- dataset %>%
  filter(!str_detect(parameter_stable_id,
                     "^[A-Za-z]+_[A-Za-z0-9]+_[0-9]{3}_[0-9]{3}$"))

## below is all of the code that i used to figure out how to 
# correct all the incorrect observations in the parameter id column
# i comnpared each observation to the variable valid_pattern to ensure each section 
# was properly separated using the correct number of underscores 
# i did this until the incorrect data set had 0 observations and that let me know
# that all the ids were correct. 
# i then executed the above code to replace all incorrect values with the correct ones 

incorrect <- incorrect %>% filter(parameter_stable_id != "NAME")

incorrect <- dataset %>%
  filter(!str_detect(parameter_stable_id,
                     "^[A-Za-z]+_[A-Za-z0-9]+_[0-9]{3}_[0-9]{3}$"))

valid_pattern <- "^[A-Za-z]{3,5}_[A-Za-z0-9]{3}_[0-9]{3}_[0-9]{3}$"

incorrect <- incorrect %>%
  filter(!str_detect(parameter_stable_id, valid_pattern))

incorrect <- incorrect %>%
  mutate(
    cleaned = str_remove_all(parameter_stable_id, "_")
  )

incorrect <- incorrect %>%
  mutate(
    corrected = str_replace(
      cleaned,
      "^([A-Za-z]{3,5})([A-Za-z0-9]{3})([0-9]{3})([0-9]{3})$",
      "\\1_\\2_\\3_\\4"
    )
  )

incorrect %>%
  select(parameter_stable_id, corrected) %>% View()


incorrect <- incorrect %>%
  mutate(
    parameter_stable_id = if_else(
      !is.na(corrected),
      corrected,
      parameter_stable_id
    )
  ) %>%
  select(-cleaned, -corrected)

sum(!str_detect(dataset$parameter_stable_id, valid_pattern))


dataset <- dataset %>%
  mutate(row_id = row_number())

incorrect <- incorrect %>%
  mutate(
    corrected = str_replace(
      cleaned,
      "^([A-Za-z]{3,5})([A-Za-z0-9]{3})([0-9]{3})([0-9]{3})$",
      "\\1_\\2_\\3_\\4"
    )
  )


# now i need to extract just these columns from the dataset that
# i personally cleaned so that my group can make a new dataset
# with all of our cleaned columns 
# the 4 of us cleaned 5 columns each 

mak_clean_columns <- dataset %>% select(gene_symbol, parameter_stable_id, lacz_colon,
                                        lacz_liver, lacz_vascular_system)

write.csv(mak_clean_columns, "cleaned_combined_data_mak.csv", row.names = FALSE)

write.csv(dataset, "cleaned_combined_data_wmakcolum.csv", row.names = FALSE)


# fixing parameter id section
cleaned_data %>% filter(!startsWith(parameter_stable_id, "IMPC")) %>% View()

cleaned_data %>%
  summarise(unique_count = n_distinct(parameter_stable_id, na.rm = TRUE))

sop_parameters <- read.csv("impc_parameter_description.txt")

test <- cleaned_data %>% select(parameter_stable_id, parameter_name) %>% 
  filter(parameter_name == "Heart weight") %>%
  filter(startsWith(parameter_stable_id, "IMPC"))

unique(test)



