###############################################################################
# SCRIPT FILE FOR THE GUIDE, "EPIDEMIOLOGIC SURVEILLANCE DATA PROCESSING"
# Written by Nel Jason L. Haw, MS
###############################################################################

###############################################################################
## DATE TODAY IS 2021-07-16
###############################################################################


########################### BEGINNING INSTRUCTIONS ############################
# 1. Make sure this script file, and the two input files,
#    fakelablinelist.csv and fakecaselinelist.csv are in the same directory
# 2. Better yet, create an RStudio Project on the directory where these files
#    are. File > New Project...
###############################################################################



####### LOADING PACKAGES ####### 
# If using for the first time, use the following install.packages commands in comments
# Internet connection required, only need to do this once ever
# install.packages("tidyverse")
# install.packages("readxl")
# install.packages("writexl")
# install.packages("tidystringdist")
library(tidyverse)        # General data analysis package
library(readxl)           # For reading Excel files
library(writexl)          # For exporting to Excel
library(tidystringdist)   # For fuzzy matching



###############################################################################
###############################################################################
### Anytime we enclose the code in a double row of hash keys, we are saying ###
### that this part of the code must be updated every time the code is run.  ###
###############################################################################
###############################################################################


###############################################################################
###############################################################################

####### IMPORTING THE DUMMY DATA ####### 

#### Import dummy laboratory linelist
lab_today <- read_xlsx("../SurveillanceR/labs/fakelablinelist_2021-07-16.xlsx")

#### Import dummy case linelist
case_yday <- read_xlsx("../SurveillanceR/cases/fakecaselinelist_2021-07-15.xlsx")

##############################################################################
##############################################################################


####### INSPECTING OUR DATA ####### 

#### Show first six rows
head(lab_today)
head(case_yday)

#### Display the data structure
str(lab_today)
str(case_yday)



####### IDENTIFYING CASES WITH UPDATES IN THE LABORATORY LINELIST ####### 
#### Create a data frame of ID variable pairs
# By default, expand.grid treats the string values as factors, 
# so we have to instruct R not to do that
dedup_df <- expand.grid(lab_today$LabSpecimenID, case_yday$CaseID, 
                        stringsAsFactors = FALSE)
# By default expand.grid saves the columns as V1 and V2. 
# But that's not helpful at all. We can rename them using colnames()
colnames(dedup_df) <- c("lab_today_id", "case_yday_id")


#### Select columns in aid of manual deduplication
# The pipe %>% operator makes code more readable. For example:
# select(dataframe, columns) can be expressed as dataframe %>% select(columns)
lab_today_info <- lab_today %>% 
  select(LabSpecimenID, Name, Age, Sex, Municipality, DateOnset, Result)
case_yday_info <- case_yday %>% 
  select(CaseID, Name, Age, Sex, Municipality, DateOnset)


#### Merge dedup_df with info from lab_today_info
# When merging, there are two data frames, labeled as x and y
# by.x and by.y are the variable names with which to link the two data frames
# In x, the ID is lab_today_id, in y, the ID is LabSpecimenID
dedup_df_info <- merge(x = dedup_df, y = lab_today_info, 
                       by.x = "lab_today_id", by.y = "LabSpecimenID")

# We want to put the case_yday_id column at the end
dedup_df_info <- dedup_df_info %>% relocate(case_yday_id, .after = last_col())


#### Merge with info from case_yday_info
## NOTE that the x data frame is now dedup_df_info, NOT dedup_df
# When merging, there are two data frames, labeled as x and y
# by.x and by.y are the variable names with which to link the two data frames
# In x, the ID is case_yday_id, in y, the ID is CaseID
dedup_df_info <- merge(x = dedup_df_info, y = case_yday_info, 
                       by.x = "case_yday_id", by.y = "CaseID")


# The columns Name, Age, Sex, and Municipality appear in both x and y data frames
# The command appends a suffix .x or .y to indicate which column came from which

# We want to put the case_yday_id right before the Name.y column
# Visually this remind us that lab_today_info are columns with suffix .x
# and case_yday_info are columns with suffix .y
dedup_df_info <- dedup_df_info %>% relocate(case_yday_id, .before = Name.y)


#### Generate similarity scores
# Use Jaro-Winkler distance to generate similarity scores
# v1 and v2 are the column of names
dedup_df_jw <- tidy_stringdist(dedup_df_info, v1 = "Name.x", 
                               v2 = "Name.y", method = "jw")

# Filter jw <= 0.3
dedup_df_jw <- dedup_df_jw %>% filter(jw <= 0.3)

# Sort by jw
dedup_df_jw <- dedup_df_jw %>% arrange(jw)


##############################################################################
##############################################################################

# Selecting duplicates - only Row 8 is not a duplicate
# View(dedup_df_jw) to view the tibble
dedup_df_jw_manual <- dedup_df_jw[c(1:7, 9:10),]

##############################################################################
##############################################################################



####### IDENTIFYING NEW CASES WITHIN THE LABORATORY LINELIST ####### 
#### Filter positive results only
lab_today_pos <- lab_today %>% filter(Result == "Positive")

#### Filter out the duplicates identified from dedup_df_jw_manual
# !() means we want the opposite result of the filter expression
# X %in% Y means we want to filter X based on values in Y
# We want to filter by laboratory result ID
# X: LabSpecimenID in lab_today_pos, Y: dedup_df_jw_manual$lab_today_id
lab_today_pos_nodup <- lab_today_pos %>% 
  filter(!(LabSpecimenID %in% dedup_df_jw_manual$lab_today_id))


#### Create a data frame of ID variable pairs
# Create a tibble that pairs all LabSpecimenID with themselves
dedup_new_df <- expand.grid(lab_today_pos_nodup$LabSpecimenID, 
                            lab_today_pos_nodup$LabSpecimenID,
                            stringsAsFactors = FALSE)

# Name columns
colnames(dedup_new_df) <- c("LabSpecimenID1", "LabSpecimenID2")

# Filter out values equal to one another
dedup_new_df <- dedup_new_df %>% filter(!(LabSpecimenID1 == LabSpecimenID2))


#### Select columns in aid of manual deduplication
lab_today_pos_nodup_info <- lab_today_pos_nodup %>% 
  select(LabSpecimenID, CaseID, Name, Age, Sex, Municipality, 
         DateOnset, DateSpecimenCollection, DateResultReleased)


#### Merge twice
# Merge with LabSpecimen1
dedup_new_df_info <- merge(x = dedup_new_df, y = lab_today_pos_nodup_info,
                           by.x = "LabSpecimenID1", by.y = "LabSpecimenID")

# Merge with LabSpecimen2 - note that x is now dedup_new_df_info
dedup_new_df_info <- merge(x = dedup_new_df_info, y = lab_today_pos_nodup_info,
                           by.x = "LabSpecimenID2", by.y = "LabSpecimenID")

# Relocate LabSpecimen2 before CaseID.y
dedup_new_df_info <- dedup_new_df_info %>% 
  relocate(LabSpecimenID2, .before = CaseID.y)


#### Generate similarity scores
# Use Jaro-Winkler distance to generate similarity scores
# v1 and v2 are the column of names
dedup_new_df_jw <- tidy_stringdist(dedup_new_df_info, v1 = "Name.x", 
                                   v2 = "Name.y", method = "jw")

# Filter jw <= 0.3
dedup_new_df_jw <- dedup_new_df_jw %>% filter(jw <= 0.3)

# Sort by jw and Name.x
dedup_new_df_jw <- dedup_new_df_jw %>% arrange(jw, Name.x)


##############################################################################
##############################################################################

# No rows to exclude, so save everything
dedup_new_df_jw_manual <- dedup_new_df_jw

# Add a new column that manually tags the duplicates
# Row 1 and 2 have DuplicateID 1
# Row 3 and 4 have DuplicateID 2
# Row 5 and 6 have DuplicateID 3
dedup_new_df_jw_manual$DuplicateID <- c(1, 1, 2, 2, 3, 3)

##############################################################################
##############################################################################



####### SAVING NEW CASE DATA ####### 
#### Filtering new cases with no duplication issues
lab_today_pos_nodup_nodup <- lab_today_pos_nodup %>% 
  filter(!(LabSpecimenID %in% dedup_new_df_jw_manual$LabSpecimenID1))

#### Prepare case_today linelist
# Duplicate lab_today_pos_nodup_nodup
case_today <- lab_today_pos_nodup_nodup

# Rename DateSpecimenCollection and DateResultReleased
case_today <- case_today %>% 
  rename(DateSpecimenCollection_PositiveFirst = DateSpecimenCollection,
         DateResultReleased_PositiveFirst = DateResultReleased)

# Remove the LabSpecimenID and Result columns
case_today <- case_today %>% select(-c(LabSpecimenID, Result))

# Add blank date columns
case_today$DateSpecimenCollection_NegativeFirst <- as.POSIXct(NA)
case_today$DateResultReleased_NegativeFirst <- as.POSIXct(NA)

###############################################################################
###############################################################################

# Specify date today
DateToday <- as.POSIXct("2021-07-16")

###############################################################################
###############################################################################

# Add DateReport column
case_today$DateReport <- DateToday

# Move date onset before DateReport
case_today <- case_today %>% relocate(DateOnset, .before = "DateReport")



####### COMPILING NEW CASES ####### 
#### Apply adjudication rules
# Use all the .x-suffixed columns
# Adjudication rules
# * For `CaseID`, the lower number is kept.
# * For `Name`, the longer one is kept.
# * For `DateOnset`, the earlier one is kept.
# * For `DateSpecimenCollection`, the earlier one is kept for `DateSpecimenCollection_PositiveFirst`.
# * For `DateResultReleased`, the earlier one is kept for `DateResultReleased_PositiveFirst`.
# * `DateSpecimenCollection_NegativeFirst` and `DateResultReleased_NegativeFirst` are both blank.
# * `DateReport` is the date today.
case_today_dedup <- dedup_new_df_jw_manual %>% group_by(DuplicateID) %>% 
  summarize(CaseID = min(CaseID.x),
            Name = Name.x[which.max(nchar(Name.x))],
            Age = min(Age.x),    # Doesn't matter in our hypothetical example, same value anyway
            Sex = min(Sex.x),    # Doesn't matter in our hypothetical example, same value anyway
            Municipality = min(Municipality.x), # Doesn't matter in our hypothetical example, same value anyway
            DateSpecimenCollection_PositiveFirst = min(DateSpecimenCollection.x),
            DateResultReleased_PositiveFirst = min(DateResultReleased.x),
            DateSpecimenCollection_NegativeFirst = as.POSIXct(NA),
            DateResultReleased_NegativeFirst = as.POSIXct(NA),
            DateOnset = min(DateOnset.x[!is.na(DateOnset.x)]),
            DateReport = DateToday)

# Finally, remove the DuplicateID as we do not need it anymore
case_today_dedup <- case_today_dedup %>% select(-(DuplicateID))


#### Bind the rows together of case_today and case_today_dedup
case_today <- rbind(case_today, case_today_dedup)



####### UPDATING CURRENT CASES ####### 

#### Retrieve ID pairs
dedup_df_jw_IDpairs <- dedup_df_jw_manual %>% select(lab_today_id, case_yday_id)


#### Merge to retrieve all info
# all.x = TRUE means to retain all rows of x regardless if there is a match,
# all.y = FALSE means to drop rows of y if there is no match.
dedup_df_jw_allinfo <- merge(x = dedup_df_jw_IDpairs, y = lab_today,
                             by.x = "lab_today_id", by.y = "LabSpecimenID",
                             all.x = TRUE, all.y = FALSE)


#### Prepare case_yday_newinfo linelist
# Duplicate dedup_df_jw_allinfo
case_yday_newinfo <- dedup_df_jw_allinfo

# Keep the Name, Age, Sex, Municipality, and DateOnset columns as is
# Note that case_yday_id contains the CaseID as it appears in the case linelist
# CaseID here refers to the autogenerated CaseID from the laboratory linelist

# Using mutate to assign columns of dates of specimen collection and dates of result released
case_yday_newinfo <- case_yday_newinfo %>%
  mutate(DateSpecimenCollection_PositiveFirst = 
           case_when(Result == "Positive" ~ DateSpecimenCollection,
                     NA ~ as.POSIXct(NA))) %>%
  mutate(DateResultReleased_PositiveFirst =
           case_when(Result == "Positive" ~ DateResultReleased,
                     NA ~ as.POSIXct(NA))) %>%
  mutate(DateSpecimenCollection_NegativeFirst = 
           case_when(Result == "Negative" ~ DateSpecimenCollection,
                     NA ~ as.POSIXct(NA))) %>%
  mutate(DateResultReleased_NegativeFirst = 
           case_when(Result == "Negative" ~ DateResultReleased,
                     NA ~ as.POSIXct(NA)))

# Remove extraneous columns
case_yday_newinfo <- case_yday_newinfo %>% 
  select(-c(CaseID, lab_today_id, DateSpecimenCollection, DateResultReleased, Result))

# Rename case_yday_id to CaseID
case_yday_newinfo <- case_yday_newinfo %>% rename(CaseID = case_yday_id)

# Add DateReport
case_yday_newinfo$DateReport <- DateToday

# Relocate DateOnset before DateReport
case_yday_newinfo <- case_yday_newinfo %>% relocate(DateOnset, .before = "DateReport")


#### Prepare case_yday_oldinfo linelist and adjudicate on data
# Retrieve the old case information
case_yday_oldinfo <- case_yday %>% filter(CaseID %in% case_yday_newinfo$CaseID)

# Combine rows and arrange by CaseID
case_yday_recon <- rbind(case_yday_oldinfo, case_yday_newinfo)
case_yday_recon <- case_yday_recon %>% arrange(CaseID)

# Adjudication rules
# * For `Name`, the longer one is kept.
# * For all date columns, the earliest one is kept
case_yday_update <- case_yday_recon %>% group_by(CaseID) %>% 
  summarize(Name = Name[which.max(nchar(Name))],
            Age = min(Age),    # Doesn't matter in our hypothetical example, same value anyway
            Sex = min(Sex),    # Doesn't matter in our hypothetical example, same value anyway
            Municipality = min(Municipality), # Doesn't matter in our hypothetical example, same value anyway
            DateSpecimenCollection_PositiveFirst =
              min(DateSpecimenCollection_PositiveFirst[!is.na(DateSpecimenCollection_PositiveFirst)]),
            DateResultReleased_PositiveFirst = 
              min(DateResultReleased_PositiveFirst[!is.na(DateResultReleased_PositiveFirst)]),
            DateSpecimenCollection_NegativeFirst =
              min(DateSpecimenCollection_NegativeFirst[!is.na(DateSpecimenCollection_NegativeFirst)]),
            DateResultReleased_NegativeFirst = 
              min(DateResultReleased_NegativeFirst[!is.na(DateResultReleased_NegativeFirst)]),
            DateOnset = min(DateOnset[!is.na(DateOnset)]),
            DateReport = min(DateReport[!is.na(DateReport)]))


#### Retrieve cases with no update
case_yday_noupdate <- case_yday %>% filter(!(CaseID %in% case_yday_update$CaseID))


####### PUTTING IT TOGETHER ####### 
#### Combine the three tibbles to the full latest case linelist, and arrange by CaseID
case_latest <- rbind(case_today, case_yday_update, case_yday_noupdate)
case_latest <- case_latest %>% arrange(CaseID)


#### Correct for date inconsistencies
case_latest <- case_latest %>%
  mutate(DateOnset = 
           case_when(DateOnset <= DateSpecimenCollection_PositiveFirst ~ DateOnset,
                     DateOnset > DateSpecimenCollection_PositiveFirst ~ DateSpecimenCollection_PositiveFirst,
                     NA ~ as.POSIXct(NA)))


##############################################################################
##############################################################################

# Export to Excel
write_xlsx(case_latest, "../SurveillanceR/cases/fakecaselinelist_2021-07-16.xlsx")

##############################################################################
##############################################################################
