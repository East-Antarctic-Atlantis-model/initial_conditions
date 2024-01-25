rm(list = ls())
## creating the templates for the EAAM
library(shinyrAtlantis)
library(stringr)
library(tidyverse)
library(dplyr)
library(ncdf4)

setwd("C:/Users/ilarias/OneDrive - University of Tasmania/GitRepos/Initial_conditions")
grp.file = 'source_files/AntarcticGroups_v2.csv'
bgm.file = 'source_files/Antractica_xy.bgm'
cum.depths = c(0, 20, 50, 100, 200, 300, 400, 750, 1000, 2000, 5000)
csv.name = 'template/EAAM_29'
make.init.csv(grp.file, bgm.file, cum.depths, csv.name, ice_model = TRUE)

## external set of tools that harvest the old.nc file
# If using original 'tool.R' file, then remove exclude_row = 11 from the harvest_ini function
source("sharper-tools.R")
old_init_file='source_files/final_with_ice_input_v2.nc'
## Getting the total values, total sum and abundance as well as default values
harvest_ini(old_init_file, fillVal=TRUE, output_file = 'template/old_EAAM29', exclude_row = 11)
## Getting the mean for RN and SN
harvest_ini(old_init_file, calculate_mean=TRUE, output_file = 'template/old_EAAM29', exclude_row = 11)

## Load the original data from 'old_EAAM_Sums.csv' into 'orig' dataframe
orig <- read.csv('template/old_EAAM29_Sums.csv', sep = ',')
## Load the template data from 'EAAM_horiz.csv' into 'template.h' dataframe
template.h <- read.csv('template/EAAM_29_horiz.csv')

## Get column names of the 'orig' dataframe
col <- colnames(orig)
## Iterate through each row of 'template.h' to match and update values
for (i in 1 : nrow(template.h)){
  ## Find the positions of matching column names in 'orig'
  pos <- which(col %in% template.h$Variable[i])
  ## Skip to the next row if no matching column found
  if (length(pos) == 0 | is.null(pos)) next()
  ## Update the values in 'template.h' with corresponding values from 'orig'
  template.h[i, 2 : ncol(template.h)] <- orig[, pos]
}

## Load default values from 'old_EAAMFillValues.csv' into 'orig.default'
orig.default <- read.csv('template/old_EAAM29FillValues.csv', sep = ',')

## Load means data from 'old_EAAM_Means.csv' into 'orig.m' dataframe
orig.m  <- read.csv('template/old_EAAM29_Means.csv', sep = ',')
col.nam <- colnames(orig.m)

## Define a subset of columns to update in 'template.h'
col <- c('NH3', 'NO3', 'DON', 'Si', 'Chl_a')
## Iterate through each row of 'template.h' to match and update values
for (i in 1 : nrow(template.h)){
  ## Find the positions of matching column names in 'orig.m'
  pos <- which(col %in% template.h$Variable[i])
  ## Skip to the next row if no matching column found
  if (length(pos) == 0 | is.null(pos)) next()
  ## Find the corresponding positions in 'col.nam' for the matched columns
  t.pos <- which(col.nam %in% col[pos])
  ## Update the values in 'template.h' with corresponding values from 'orig.m'
  template.h[i, 2 : ncol(template.h)] <- orig.m[, t.pos]
}

## Write the updated 'template.h' to 'EAAM_horiz_filled.csv' file
write.table(template.h, file = 'template/EAAM_horiz_29_filled.csv', sep = ',', row.names=FALSE)

## Define default and required values to fill
default.val <- c(grep('*_StructN', orig.default$Variables), grep('*_ResN', orig.default$Variables), grep('*_F$', colnames(orig.m)))
required_vals <- c(grep('*_StructN', colnames(orig.m)), grep('*_ResN', colnames(orig.m)), grep('*_F$', colnames(orig.m)))
## Load the initial condition template data from 'EAAM_init.csv' into 'template.ini'
template.ini <- read.csv('template/EAAM_29_init.csv')

## Get column names from 'orig.m' for required values
col.names <- colnames(orig.m)[required_vals]
## Extract fill values from 'orig.default' based on default values
fillvals <- orig.default[default.val, ]
## Iterate through each row of 'template.ini' to update sediment and wc.hor.scalar values
for (i in 1 : nrow(template.ini)){
  ## Find the positions of matching column names in 'col.names'
  pos <- which(col.names %in% template.ini[i, 1])
  ## Skip to the next row if no matching column found
  if (length(pos) == 0) next()
  ## Extract the values from 'orig.m' for the matching columns
  values <- orig.m[1 : 2, required_vals[pos]]
  ## Replace missing values with corresponding fill values
  if (any(is.na(values))){
    replace <- fillvals$fillvalues[which(fillvals$Variables %in% template.ini[i, 1])]
    values[is.na(values)] <- replace
  }
  ## Update 'template.ini' with the calculated values
  template.ini[i, c("sediment", "wc.hor.scalar")] <- values
}
## Write the updated 'template.ini' to 'EAAM_init_filled.csv' file
write.table(template.ini, 'template/EAAM_init_29_filled.csv', row.names = FALSE, sep = ',')

## IS - EAAM-specific

### Change init_filled.csv to match EAAM specifications ############################################################################
init.file.ch <- read.csv('template/EAAM_init_29_filled.csv', sep = ',')

# wc.hor.pattern: Change constant to custom for nutrients
custom_update <- c("NH3", "NO3", "MicroNut", "Si", "DON", "Det_Si", "Chl_a")  # Add more variable names as needed
init.file.ch$wc.hor.pattern[init.file.ch$name %in% custom_update] <- "custom"
init.file.ch$wc.ver.pattern[init.file.ch$name %in% custom_update] <- "uniform"

SED_update <- c("SED")
init.file.ch$wc.hor.pattern[init.file.ch$name %in% SED_update] <- "custom"
init.file.ch$wc.ver.pattern[init.file.ch$name %in% SED_update] <- "surface"

# sediment: customise values
init.file.ch$sediment[init.file.ch$name %in% c("NH3", "NO3")] <- 0.5
init.file.ch$sediment[init.file.ch$name %in% c("DON")] <- 0
init.file.ch$sediment[init.file.ch$name %in% c("Micronut")] <- 2.7
init.file.ch$sediment[init.file.ch$name %in% c("Oxygen")] <- 0.5
init.file.ch$sediment[init.file.ch$name %in% c("Si")] <- 0.5
init.file.ch$sediment[init.file.ch$name %in% c("Det_Si")] <- 0.5
init.file.ch$sediment[init.file.ch$name %in% c("Light")] <- 1e-06
init.file.ch$sediment[init.file.ch$name %in% c("DayLight")] <- 1e-06
init.file.ch$sediment[init.file.ch$name %in% c("Pelagic_Bacteria_N")] <- 0.122807
init.file.ch$sediment[init.file.ch$name %in% c("Sediment_bacteria_N")] <- 7.017544
init.file.ch$sediment[init.file.ch$name %in% c("Labile_Detritus_N")] <- 228.070175438596
init.file.ch$sediment[init.file.ch$name %in% c("Refractory_Detritus_N")] <- 228.070175438596


# wc.hor.scalar: customise values
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Micronut")] <- 0
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Oxygen")] <- 8000
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Si")] <- 70
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Det_Si")] <- 1
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Light")] <- 0
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("DayLight")] <- 0
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Pelagic_Bacteria_N")] <- 0.122807
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Sediment_bacteria_N")] <- 0.122807


## "Extras"
# change long_name for MicroNut
init.file.ch$long_name[init.file.ch$name %in% c("MicroNut")] <- "Iron"

# set chl_a to surface
#init.file.ch$wc.ver.pattern[init.file.ch$name %in% custom_update] <- "surface"


# Change 1 to 0 for insed and inwc for ice groups ###################################################################################
init.file.ch$insed[init.file.ch$name %in% c("Ice_Diatoms_N", "Ice_Diatoms_S", "Ice_Diatoms_F", "Ice_Mixotrophs_N", "Ice_Mixotrophs_F", "Ice_Bacteria_N", "Ice_Zoobiota_N", "Ice_Zoobiota_F")] <- 0
init.file.ch$inwc[init.file.ch$name %in% c("Ice_Diatoms_N", "Ice_Diatoms_S", "Ice_Diatoms_F", "Ice_Mixotrophs_N", "Ice_Mixotrophs_F", "Ice_Bacteria_N", "Ice_Zoobiota_N", "Ice_Zoobiota_F")] <- 0

# Change T and sal values for Antarctica
init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("Temp")] <- 1
init.file.ch$sediment[init.file.ch$name %in% c("Temp")] <- 1

init.file.ch$wc.hor.scalar[init.file.ch$name %in% c("sal")] <- 33
init.file.ch$sediment[init.file.ch$name %in% c("sal")] <- 33


write.table(init.file.ch, 'template/EAAM_init_29_filled_2.csv', row.names = FALSE, sep = ',')


# CREATE HORIZONTAL CSV FOR 29 POLYGON VERSION ########################################################################################
# Read in the file
split.file <- read.csv('template/EAAM_horiz_29_filled.csv', sep = ',')
orig.h.mean <- read.csv('template/old_EAAM29_Means.csv', sep = ',')
orig.h.sum <- read.csv('template/old_EAAM29_Sums.csv', sep = ',')


# Add a row for nutrients custom values in horiz_filled.csv file #######################################################################
micronut_row <- NO3_row <- NH3_row <- DON_row <- Si_row <- Det_Si_row <- Chl_a_row <- data.frame(matrix(ncol = ncol(split.file), nrow = 1))

colnames(micronut_row) <- colnames(split.file)
colnames(NO3_row) <- colnames(split.file)
colnames(NH3_row) <- colnames(split.file)
colnames(DON_row) <- colnames(split.file)
colnames(Si_row) <- colnames(split.file)
colnames(Det_Si_row) <- colnames(split.file)
colnames(Chl_a_row) <- colnames(split.file)

micronut_row$Variable <- "MicroNut"
NO3_row$Variable <- "NO3"
NH3_row$Variable <- "NH3"
DON_row$Variable <- "DON"
Si_row$Variable <- "Si"
Det_Si_row$Variable <- "Det_Si"
Chl_a_row$Variable <- "Chl_a"

micronut_row[, paste0("box", 0:27)] <- orig.h.mean$MicroNut # fill blank row with sum of MicroNut values
NO3_row[, paste0("box", 0:27)] <- orig.h.mean$NO3
NH3_row[, paste0("box", 0:27)] <- orig.h.mean$NH3
DON_row[, paste0("box", 0:27)] <- orig.h.mean$DON
Si_row[, paste0("box", 0:27)] <- orig.h.mean$Si
Det_Si_row[, paste0("box", 0:27)] <- orig.h.mean$Det_Si
Chl_a_row[, paste0("box", 0:27)] <- orig.h.mean$Chl_a

split.file <- rbind(split.file, micronut_row, NO3_row, NH3_row, DON_row, Si_row, Det_Si_row, Chl_a_row) # add row to bottom of file

# Insert a new column named "New_Column" between columns 2 and 3 ############################################################################
split.file <- split.file %>% mutate(box = NA, .after = box21)
# Rename columns in right order
box_cols <- grep("box", colnames(split.file)) # get column indices
new_box_names <- paste0("box", seq_along(box_cols) - 1) # create new names
colnames(split.file)[box_cols] <- new_box_names # assign new names

# Halving the values in 'box21' column ONLY IF the variable name contains _Nums
rows_with_Nums <- grepl("*_Nums", split.file$Variable) # find Nums
indices_with_Nums <- which(rows_with_Nums)
# Halve the variable values of box 21 where rows_with_Nums is True
split.file[indices_with_Nums, "box21"] <- split.file[indices_with_Nums, "box21"] / 2
# Copy the values from col 'box21' to column 'box22'
split.file$box22 <- split.file$box21
# save new values
write.table(split.file, 'template/EAAM_horiz_29_filled_2.csv', row.names = FALSE, sep = ',')



# #############################################################################################################################################
counter <- 23

# Increment the counter for the next file
bgm.file = 'EAAM_29_polygons_xy.bgm'
init.file <- 'template/EAAM_init_29_filled_2.csv'
horiz.file <-'template/EAAM_horiz_29_filled_2.csv'
make.init.nc(bgm.file, cum.depths, init.file, horiz.file, paste0('EAAM_29_test_', counter, '.nc'), ice_model=TRUE)

# Move the file to the working Atlantis folder
original_file_path <- paste('C:/Users/ilarias/OneDrive - University of Tasmania/GitRepos/Initial_conditions/', paste0('EAAM_29_test_', counter, '.nc'), sep = '')
destination_directory <- 'C:/Users/ilarias/OneDrive - University of Tasmania/AtlantisRepository/EA_model/EA_29poly/'

# Rename the file to the destination directory without spaces
new_file_name <- paste0('EAAM_29_test_', counter, '.nc')

new_file_path <- file.path(destination_directory, new_file_name)
file.rename(original_file_path, new_file_path)
