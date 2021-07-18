---
title: "Epidemiologic Surveillance Data Processing"
author: "Created by Nel Jason Haw"
date: "Last updated July 16, 2021"
output:
  rmdformats::robobook:
      number_sections: yes
      toc_depth: 3
---



<br>

This guide aims to provide step-by-step instructions on how to conduct common data processing tasks for infectious disease surveillance using the open-source programming language R and the integrated development environment (IDE) for R.

<br>

# The Basics

## For whom is this guide?
This guide is primarily targeted towards field epidemiologists who...

* Do not have access to proprietary statistical software such as SAS and Stata
* Do not have any solid background in any statistical programming language
* Work collaboratively as part of routine infectious disease surveillance

## Getting started with R
* We need to first install [R](https://cran.r-project.org/bin/windows/base/) and [RStudio](https://www.rstudio.com/products/rstudio/download/#download). Both are free and open source tools. We must install R first, then RStudio. [TechVidVan has provided a great starter guide on installing R and RStudio](https://techvidvan.com/tutorials/install-r/).
* Most of R's capabilities come in the form of **PACKAGES**. Packages are created by a vibrant community of R programmers, many of whom are epidemiologists. [DataCamp has an FAQ guide on what R packages are](https://www.datacamp.com/community/tutorials/r-packages-guide).
* Open RStudio for the first time may be overwhelming. [Antoine Soetewey’s Stats and R blog has a beginner-level introduction to the RStudio interface](https://statsandr.com/blog/how-to-install-r-and-rstudio/#the-main-components-of-rstudio).
* [Finally, Harvard Chan Bioinformatic Core (HBC) has an excellent 1.5 day tutorial on the basics of R](https://hbctraining.github.io/Intro-to-R-flipped/schedules/links-to-lessons.html)
* There are also excellent Coursera courses from Johns Hopkins University on getting familiar with R: [R Programming](https://www.coursera.org/learn/r-programming) and [Introduction to Tidyverse](https://www.coursera.org/learn/tidyverse/).

## Tidy Data Principles
Often, the data we have as part of epidemiologic surveillance may not be the version ready for any type of statistical analysis. This raw data MUST be processed into tidy data. At the basic level:

* Each row = one observation representing the unit of analysis
* Each column = one variable
* Each cell = standard data format, usually defined by a coding manual
* If there are going to be multiple tables, there should be an identifying (ID) variable linking tables together.

Tidy data **must not have**:

* Any blanks, unless these are true missing data
* Too many special characters, unless absolutely necessary
* Merged cells ANYWHERE - merged cells may be good visually but not for analysis
* Colors to identify variables - these must be defined as a new column (variable), as colors cannot be read into analysis

For example, say we have five COVID-19 confirmed cases, and our raw data looks something like this on a spreadsheet:

![Raw data from surveillance example](https://i.ibb.co/xMHy3T9/RawData.png)

This raw data file:

* Does not have a standard format for the cells - the dates are all encoded inconsistently
* Has merged cells horizontally and vertically
* "Flattens" the tests together with the cases
* Has colored cells but no explanation - in this case, the yellow ones were the latest reported cases (in this hypothetical case, it is Oct 2) and the rest of the rows have no indication of when they were reported

We should split the data into two tables: one where each row is a case, another where each row is a test. The two tables are linked by a common, static ID. A tidy data version of the file above could look something like this instead:

The first table (each row = confirmed case)

| ID   | DateOnset  | Municipality | Community      | DateReport |
| ---: | ----------:| :----------- | :------------- | ----------:|
| 1    | 2020-09-27 | Funky Town   | Highland Z     | 2020-10-01 |
| 2    | 2020-09-26 | Funky Town   | Highland Y     | 2020-10-01 |
| 3    | 2020-09-28 | Providence   | People Village | 2020-10-02 |
| 4    | 2020-09-25 | Border Town  | Crescent Hill  | 2020-09-30 |
| 5    | 2020-09-30 | New Horizons | Block A1       | 2020-10-02 |

The second table (each row = test)

| ID   | DateTest   | Result   |
| ---: | ---:       | :---     |
| 1    | 2020-09-30 | Positive |
| 2    | 2020-09-30 | Positive |
| 2    | 2020-10-02 | Positive |
| 3    | 2020-10-01 | Positive |
| 4    | 2020-09-29 | Positive |
| 4    | 2020-10-03 | Negative |
| 5    | 2020-10-01 | Positive |

Additionally, there should be some sort of coding manual. For example:

* `ID`: Unique ID assigned to each confirmed case (when a case has been assigned two ID numbers, discard the latest ID number and move on - DO NOT shift ID numbers upward)
* `DateOnset`: Date of symptom onset as reported by the patient (format: YYYY-MM-DD)
* `Municipality`: Municipality indicated in the current address reported by the patient (Names according to official geographic listing of national statistical authority)
* `Community`: Community indicated in the current address reported by the patient (Names according to official geographic listing of national statistical authority)
* `DateReport`: Date when case was officially reported to the surveillance system (format: YYYY-MM-DD)
* `DateTest`: Date when case was swabbed for confirmatory testing (format: YYYY-MM-DD)
* `Result`: Result of test conducted (Positive, Negative, Equivocal, Invalid)

We may prepare the tidy data using a spreadsheet program like Microsoft Excel, which may be familiar to most people. But we do not recommend this as we want our data processing to be **reproducible**. We want every modification of our data accounted for, and we want our rules on data processing to be clear that anyone else looking at the data may be able to follow along.

To learn more about tidy data, refer to the following reference by Hadley Wickham [(Paper)](http://vita.had.co.nz/papers/tidy-data.pdf) [(Video)](http://vimeo.com/33727555).


# Description of the Dummy Data

We  assume that we are working on surveillance on a new infectious disease. There is one reference laboratory that conducts confirmatory testing for this infectious disease, and we define confirmed cases as those who test positive with the confirmatory test. We only test suspect cases, defined as those with symptoms relevant to this infectious disease, which means we expect that everyone who has been tested has a date of symptom onset, although we typically expect that this field is blank more often than not.

We test suspect cases regularly, sometimes twice within a 24-hour window. We are interested in both the first positive test result and the first negative test result after that, as we define clinical recovery as the day that a case has received a negative test result. For simplicity, we  deal with only positive or negative test results, although in practice we expect test results to be inconclusive/equivocal or samples collected to be invalid for testing.

The reference laboratory has an information system, and everyday, the reference laboratory provides us with a **laboratory linelist** containing test results within the past 24 hours. The reference laboratory exports the file as a Microsoft Excel spreadsheet (`.xlsx`). Everyday, we process the laboratory linelist from the past 24 hours and all the cases since the beginning of the surveillance activity into the **case linelist**. We repeat this process everyday.

* Each row in the **laboratory linelist** is a **laboratory result**, and a unique ID number of the laboratory result is automatically assigned by the reference laboratory information system using the variable `LabSpecimenID`.
  + Additionally, there is another ID number `CaseID`, that the information system automatically generates whenever there is a new name in the system. If there is an *exact* match of an existing name in the system, the laboratory information system carries over the same `CaseID` to the new laboratory result. However, if the person has been tested before, but the name is not an exact match, the laboratory information system creates a new `CaseID` as if both laboratory results were from distinct individuals.
  + This means that the `CaseID` variable does not *uniquely* identify the persons being tested, and we  need to deduplicate these names manually later.
* Each row in the **case linelist** is a **confirmed case**, and the unique `CaseID` number from the laboratory linelist is carried over to the case linelist. We used to process the case linelist in Microsoft Excel, so this is also a Microsoft Excel spreadsheet. Moving forward, we want to update this case linelist using R.
  + We process this case linelist daily to add new cases from the latest laboratory linelist, and update information of existing cases.
  + As we manually deduplicate our data, we retain the lowest `CaseID` value.

The variables in the laboratory linelist (`fakelablinelist.xlsx`) are as follows:

* `LabSpecimenID`: Unique ID of laboratory result
* `CaseID`: Laboratory information system's attempt to identify cases using exact match of names; manual deduplication required
* `Name`: Name of the individual as encoded into the information system
* `Age`: Calculated age based on date of birth encoded into the information system. For simplicity, we  not show the date of birth variable, but it is ideal that ages are calculated from date of birth and not just reporting what the age was at the time of testing
* `Sex`: Male or female (we assume this country only accepts two legal sexes)
* `Municipality`: Municipality where the individual resides, as encoded into the information system
* `DateSpecimenCollection`: Date when specimen was collected
* `DateResultReleased`: Date when the result was released
* `DateOnset`: Reported date of onset of symptoms relevant to the infectious disease
* `Result`: Positive or negative

When we conduct data processing, it is important that we set up clear **adjudication** or validation rules. Most of the time, the validation  come outside of data processing. For example, we may instruct the reporting health facility to reencode the laboratory result in the information system. We may also review other health records and replace values manually in the information system. If we need to make modifications during data processing, we must be clear about the **adjudication rules**. We  work with a fairly simple set of rules to demonstrate this point.

The variables in the case linelist (`fakecaselinelist.csv`), as well as the adjudication rules are as follows:

* `CaseID`: This is the processed `CaseID` variable from the laboratory information system.
  + We first conduct manual deduplication and tag groups of laboratory results that are considered under the same individual.
  + After deduplicating, we retain the lowest `CaseID` number, e.g. between `11708` and `12890`, we retain `11708`.
* The variables `Name`, `Age`, `Sex`, and `Municipality` are carried over from the laboratory linelist.
  + If there are conflicts in the values on any of these variables, then we need to review other health records or recheck with the reporting health facility.
  + In this example, we  work with discrepancies in the `Name` value. The name with the most complete information is retained. For example, if one value has the middle name and the other does not, then the one with the middle name is retained.
* The dates of specimen collection and result released are set up differently from the laboratory linelist. Specifically, in this case, we are primarily concerned with the first positive results (`DateSpecimenCollection_PositiveFirst` and `DateResultReleased_PositiveFirst`) and first negative result after that (`DateSpecimenCollection_NegativeFirst` and `DateResultReleased_NegativeFirst`).
    + This means that not all laboratory results from the same person are going to be used in this linelist of cases. There  be some loss of information.
    + This means that we have to restructure the values from the `DateSpecimenCollection`, `DateResultReleased`, and `Result` from the laboratory linelist to fit the columns in the case linelist.
* The date of symptom onset `DateOnset` is also carried over from the laboratory linelist, unless there are discrepancies with the values from a more recent laboratory result entry. 
  + For this example, our rule is that we keep the earliest recorded date of symptom onset, e.g. if the original date of symptom onset recorded was July 1, 2021, but the latest laboratory result recorded it as July 3, 2021, then we keep July 1, 2021.
  + We  also check whether the date of symptom onset is on or before the date of specimen collection, as our hypothetical testing policy states that only symptomatic cases are going to be tested. If the date of symptom onset is after the date of specimen collection, then we replace the date of symptom onset with the date of specimen collection.

<br>

# Setting Up

## Downloading the files

We may download all the files in the [Github repository here](https://github.com/neljasonhaw/SurveillanceR). Click on the green button Code then click Download ZIP. Unzip and look for the file names `fakelablinelist.csv` and `fakecaselinelist.csv`.

There is also an R script file called `DataProcessing.R`. That R script file contains all the codes in this guide. We may open that as we follow along. All of the other files are not relevant for the guide or are output files that  be generated as part of the analysis.

While the files may usually be found in our Downloads folder, we move it to a new folder anywhere else in our computer (say, your Documents folder) and give it a name. This new folder  serve as our working directory, so remember where it is.

## Creating a new RStudio Project

1. Open RStudio. On the menu bar, select `File` > `New Project`...
2. The `New Project Wizard` dialog box opens. Select `Existing Directory`.
3. Under `Project working directory`, select `Browse...` and locate the folder of the working directory.
4. Select `Create Project`. At this point, we have created a new project file (.Rproj) as well as set the working directory.
5. Create a new R script file using the keyboard shortcut `Ctrl-Shift-N` or going to `File` > `New File` > `R Script` or clicking on the `New File` button on the topmost left corner right below the menu bar then clicking `R Script`. The left side of the environment should split into two - with the script file found on the upper left side. The script file is similar to a do file for those who are familiar with Stata. Ideally, we should be saving all our code in a script file in case we need to redo or repeat analyses so that all we have to do is to run the script rather than coding everything from scratch again.
6. Save the script file every now and then. Give it a name. In the repository, this is named `DataProcessing.R`. Open that script file if we just want to run the code.

Alternatively, if we are familiar with setting up Git on RStudio, we may also set up the RStudio project by cloning the repository instead of downloading the ZIP file.

## Loading packages

We  use the following packages. We make sure the packages are installed beforehand using the `install.packages()` function.


```r
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
```

## Importing dummy data

We  now import both linelists. We  store the the laboratory linelist in a tibble called `lab_today`, while we  store the case linelist in a tibble called `case_yday`. [Tibbles are data frames](https://r4ds.had.co.nz/tibbles.html) that make data manipulation using the `tidyverse` package a little easier.


```r
# Import dummy laboratory linelist
lab_today <- read_xlsx("fakelablinelist.xlsx")
# Import dummy case linelist
case_yday <- read_xlsx("fakecaselinelist.xlsx")
```

We take a peek of our data by displaying the first six rows using the `head()` function in base R.


```r
# Show first six rows
head(lab_today)
```

```
## # A tibble: 6 x 10
##   LabSpecimenID CaseID Name        Age Sex   Municipality   DateSpecimenCollect~
##   <chr>          <dbl> <chr>     <dbl> <chr> <chr>          <dttm>              
## 1 AB-0458214     13597 Agata Lu~    35 F     Port Sipleach  2021-07-15 00:00:00 
## 2 AB-0458203     44979 Ailsa Hu~    70 F     Mexe           2021-07-15 00:00:00 
## 3 AB-0458219     44980 Amal Ford    40 M     Grand Wellwor~ 2021-07-15 00:00:00 
## 4 AB-0458206     13479 Ceara We~     2 F     Chorgains      2021-07-15 00:00:00 
## 5 AB-0458229     18793 Dustin P~    10 M     Grand Wellwor~ 2021-07-15 00:00:00 
## 6 AB-0458209     12579 Elijah H~    38 M     Mexe           2021-07-15 00:00:00 
## # ... with 3 more variables: DateResultReleased <dttm>, DateOnset <dttm>,
## #   Result <chr>
```

```r
head(case_yday)
```

```
## # A tibble: 6 x 10
##   CaseID Name     Age Sex   Municipality DateSpecimenCollec~ DateResultReleased~
##    <dbl> <chr>  <dbl> <chr> <chr>        <dttm>              <dttm>             
## 1  13597 Agata~    35 F     Port Siplea~ 2021-07-02 00:00:00 2021-07-03 00:00:00
## 2  13479 Ceara~     2 F     Chorgains    2021-07-01 00:00:00 2021-07-02 00:00:00
## 3  18793 Dusti~    10 M     Grand Wellw~ 2021-07-08 00:00:00 2021-07-09 00:00:00
## 4  12579 Elija~    38 M     Mexe         2021-07-03 00:00:00 2021-07-04 00:00:00
## 5  13289 Ella-~    58 F     Grand Wellw~ 2021-07-02 00:00:00 2021-07-03 00:00:00
## 6  13547 Franc~     2 M     Eastmsallbu~ 2021-07-10 00:00:00 2021-07-11 00:00:00
## # ... with 3 more variables: DateSpecimenCollection_NegativeFirst <dttm>,
## #   DateResultReleased_NegativeFirst <dttm>, DateOnset <dttm>
```

We may also view the full tibbles by using the `View()` function, i.e. `View(lab_today)` and `View(case_yday)` on the Console (by default, on the bottom right of RStudio). A new tab opens on the Script editor (by default, on the upper left of RStudio).

The full laboratory linelist `lab_today` looks like this:

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> LabSpecimenID </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection </th>
   <th style="text-align:left;"> DateResultReleased </th>
   <th style="text-align:left;"> DateOnset </th>
   <th style="text-align:left;"> Result </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> AB-0458214 </td>
   <td style="text-align:right;"> 13597 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> AB-0458203 </td>
   <td style="text-align:right;"> 44979 </td>
   <td style="text-align:left;"> Ailsa Hurst </td>
   <td style="text-align:right;"> 70 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> AB-0458219 </td>
   <td style="text-align:right;"> 44980 </td>
   <td style="text-align:left;"> Amal Ford </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> AB-0458206 </td>
   <td style="text-align:right;"> 13479 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> AB-0458229 </td>
   <td style="text-align:right;"> 18793 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> AB-0458209 </td>
   <td style="text-align:right;"> 12579 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-06 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> AB-0458217 </td>
   <td style="text-align:right;"> 13289 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> AB-0458218 </td>
   <td style="text-align:right;"> 44985 </td>
   <td style="text-align:left;"> Emilee Horn </td>
   <td style="text-align:right;"> 50 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> AB-0458207 </td>
   <td style="text-align:right;"> 44986 </td>
   <td style="text-align:left;"> Martin Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> AB-0458227 </td>
   <td style="text-align:right;"> 44987 </td>
   <td style="text-align:left;"> Martin F Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-12 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 11 </td>
   <td style="text-align:left;"> AB-0458204 </td>
   <td style="text-align:right;"> 44988 </td>
   <td style="text-align:left;"> Eve Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 12 </td>
   <td style="text-align:left;"> AB-0458221 </td>
   <td style="text-align:right;"> 44988 </td>
   <td style="text-align:left;"> Eve Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 13 </td>
   <td style="text-align:left;"> AB-0458222 </td>
   <td style="text-align:right;"> 44981 </td>
   <td style="text-align:left;"> Fabien Escobar </td>
   <td style="text-align:right;"> 55 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 14 </td>
   <td style="text-align:left;"> AB-0458201 </td>
   <td style="text-align:right;"> 44990 </td>
   <td style="text-align:left;"> Fern Christian Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 15 </td>
   <td style="text-align:left;"> AB-0458215 </td>
   <td style="text-align:right;"> 44991 </td>
   <td style="text-align:left;"> Fern Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 16 </td>
   <td style="text-align:left;"> AB-0458220 </td>
   <td style="text-align:right;"> 44982 </td>
   <td style="text-align:left;"> Franciszek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 17 </td>
   <td style="text-align:left;"> AB-0458223 </td>
   <td style="text-align:right;"> 44983 </td>
   <td style="text-align:left;"> Harmony Howe </td>
   <td style="text-align:right;"> 74 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 18 </td>
   <td style="text-align:left;"> AB-0458202 </td>
   <td style="text-align:right;"> 44994 </td>
   <td style="text-align:left;"> Ishaaq Baker </td>
   <td style="text-align:right;"> 50 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 19 </td>
   <td style="text-align:left;"> AB-0458210 </td>
   <td style="text-align:right;"> 44992 </td>
   <td style="text-align:left;"> Jessica Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 20 </td>
   <td style="text-align:left;"> AB-0458230 </td>
   <td style="text-align:right;"> 44993 </td>
   <td style="text-align:left;"> Jess Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 21 </td>
   <td style="text-align:left;"> AB-0458224 </td>
   <td style="text-align:right;"> 44984 </td>
   <td style="text-align:left;"> Kanye Novak </td>
   <td style="text-align:right;"> 65 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 22 </td>
   <td style="text-align:left;"> AB-0458216 </td>
   <td style="text-align:right;"> 44995 </td>
   <td style="text-align:left;"> Kyran Roach </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-13 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 23 </td>
   <td style="text-align:left;"> AB-0458225 </td>
   <td style="text-align:right;"> 18400 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-06 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 24 </td>
   <td style="text-align:left;"> AB-0458213 </td>
   <td style="text-align:right;"> 44996 </td>
   <td style="text-align:left;"> Maud Shields </td>
   <td style="text-align:right;"> 65 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> Negative </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 25 </td>
   <td style="text-align:left;"> AB-0458212 </td>
   <td style="text-align:right;"> 44997 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
</tbody>
</table>

The full case linelist `case_today` looks like this

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection_PositiveFirst </th>
   <th style="text-align:left;"> DateResultReleased_PositiveFirst </th>
   <th style="text-align:left;"> DateSpecimenCollection_NegativeFirst </th>
   <th style="text-align:left;"> DateResultReleased_NegativeFirst </th>
   <th style="text-align:left;"> DateOnset </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 13597 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 13479 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-01 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-08 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 18793 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-09 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 12579 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> 2021-07-04 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:right;"> 13289 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:right;"> 13547 </td>
   <td style="text-align:left;"> Francissek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:right;"> 18400 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-07 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-06 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:right;"> 13566 </td>
   <td style="text-align:left;"> Penelope F. Fields </td>
   <td style="text-align:right;"> 45 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve M. Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
</tbody>
</table>

## Reading the dates correctly

If we look at the data structure of both tibbles `lab_today` and `case_today` using the base R function `str()`, we notice the dates are read as a calendar date and time object (`POSIXct`). 


```r
str(lab_today)
```

```
## tibble [25 x 10] (S3: tbl_df/tbl/data.frame)
##  $ LabSpecimenID         : chr [1:25] "AB-0458214" "AB-0458203" "AB-0458219" "AB-0458206" ...
##  $ CaseID                : num [1:25] 13597 44979 44980 13479 18793 ...
##  $ Name                  : chr [1:25] "Agata Lucas" "Ailsa Hurst" "Amal Ford" "Ceara West" ...
##  $ Age                   : num [1:25] 35 70 40 2 10 38 58 50 18 18 ...
##  $ Sex                   : chr [1:25] "F" "F" "M" "F" ...
##  $ Municipality          : chr [1:25] "Port Sipleach" "Mexe" "Grand Wellworth" "Chorgains" ...
##  $ DateSpecimenCollection: POSIXct[1:25], format: "2021-07-15" "2021-07-15" ...
##  $ DateResultReleased    : POSIXct[1:25], format: "2021-07-14" "2021-07-16" ...
##  $ DateOnset             : POSIXct[1:25], format: NA "2021-07-11" ...
##  $ Result                : chr [1:25] "Positive" "Negative" "Positive" "Negative" ...
```

```r
str(case_yday)
```

```
## tibble [9 x 10] (S3: tbl_df/tbl/data.frame)
##  $ CaseID                              : num [1:9] 13597 13479 18793 12579 13289 ...
##  $ Name                                : chr [1:9] "Agata Lucas" "Ceara West" "Dustin Payne" "Elijah Henson" ...
##  $ Age                                 : num [1:9] 35 2 10 38 58 2 14 45 58
##  $ Sex                                 : chr [1:9] "F" "F" "M" "M" ...
##  $ Municipality                        : chr [1:9] "Port Sipleach" "Chorgains" "Grand Wellworth" "Mexe" ...
##  $ DateSpecimenCollection_PositiveFirst: POSIXct[1:9], format: "2021-07-02" "2021-07-01" ...
##  $ DateResultReleased_PositiveFirst    : POSIXct[1:9], format: "2021-07-03" "2021-07-02" ...
##  $ DateSpecimenCollection_NegativeFirst: POSIXct[1:9], format: NA NA ...
##  $ DateResultReleased_NegativeFirst    : POSIXct[1:9], format: NA NA ...
##  $ DateOnset                           : POSIXct[1:9], format: "2021-06-30" "2021-07-08" ...
```

By default, Microsoft Excel reads dates as mm/dd/yyyy (for countries using mm/dd/yyyy format) but this is not a good date format. **By default, we should always use yyyy-mm-dd**, as it is always clear which one is the month and date. This date format is also the default in R, so when importing Excel spreadsheets, R tries to read mm/dd/yyyy as dates. In the event that there are variables that are not read as dates, we may use the `as.POSIXct()` function in base R. For syntax on the date formats, [check this link](https://www.r-bloggers.com/2013/08/date-formats-in-r/). For example:


```r
# Sample vector of dates
sampledate <- c("07/01/2021", "07/02/2021", "07/03/2021")
str(sampledate)       # Read as string
```

```
##  chr [1:3] "07/01/2021" "07/02/2021" "07/03/2021"
```

```r
# Read as calendar date and time
sampledate <- as.POSIXct(sampledate, format = "%m/%d/%Y")
str(sampledate)       # Read as calendar date and time
```

```
##  POSIXct[1:3], format: "2021-07-01" "2021-07-02" "2021-07-03"
```

## Overview of the data processing workflow

Before we begin the actual data processing, we  first outline the steps that we  be taking.

1. Process new cases from the laboratory linelist.
  + Identify cases that have updates in the laboratory linelist.
    + Create a data frame of ID variable pairs - `LabSpecimenID` from the laboratory linelist and `CaseID` from the case linelist. Save results in data frame `dedup_df`.
    + Add names and other information in aid of manual deduplication.
      + Store laboratory linelist information in tibble `lab_today_info`.
      + Store case linelinse information in tibble `case_yday_info`.
      + Merge tibble `lab_today_info` into data frame `dedup_df`. Store results in data frame `dedup_df_info`.
      + Merge tibble `case_yday_info` into data frame `dedup_df_info`.
    + Generate similarity scores using Jaro-Winkler (`jw`) distance. Store results in data frame `dedup_df_jw`.
      + Keep results with `jw` less than or equal to 0.3.
    + Manually inspect results in data frame `dedup_df_jw`.
      + Subset rows that are duplicates from case linelist. These are the rows that we  check later on to update the date of existing cases. Store results in data frame `dedup_df_jw_manual`.
  + Identify new cases within the laboratory linelist.
    + Filter positive results from laboratory linelist. Store in tibble `lab_today_pos`
    + Filter out duplicates already indentified from the data frame `dedup_df_jw_manual` as those cases are not new cases.


## Overview of functions

The following functions  be used from the following packages:

1. Base R
  + `expand.grid()`: Creates a data frame from all combinations of two vectors
  + `merge()`: Merges two data frames by common columns
2. `tidyverse` (specifically, `dplyr`)
  + `arrange()`: Sorts data frame based on specified column
  + `filter()`: Filters rows based on certain conditions
  + `relocate()`: Arranges columns in a data frame
  + `select()`: Selects columns in a data frame
  + We  also learn two operators:
    + The pipe `%>%` operator, which "pipes" arguments in a function to make code more readable
    + The `%in%` operator, which makes filtering values easier
3. `readxl`
  + `read_xlsx`: Imports Micrsoft Excel spreadsheet files in `.xlsx` format
4. `tidystringdist`
  + `tidy_stringdist()`: Generates similarity scores between two string values`


<br>

# Processing New Cases from Laboratory Linelist

We now deduplicate new cases from the lab linelist. We need to conduct two deduplication activities:

* First, we need to check if any of the results from the laboratory linelist (`lab_today`) have already been added as cases in the case linelist (`case_yday`), and use these results to update the data of these cases.
* Second, we  need to deduplicate new cases within the laboratory linelist. There might be cases whose names appear twice in the laboratory linelist but are new cases that are not yet found on the case linelist.

Because our hypothetical laboratory information system can only detect exact matches of names for the generation of the `CaseID`, we  need to use fuzzy matching to manually deduplicate names.


## Identifying cases that have updates in the laboratory linelist

### Creating a data frame of ID variable pairs
We  create a tibble (`dedup_df`) that contains the column `LabSpecimenID` of the tibble `lab_today` paired with all `CaseID` values in the tibble `case_yday`. Recall that these ID variables uniquely identify each row. Therefore, the tibble `dedup_df` represents all pairs of IDs that  be useful for deduplication. We  use the base R function `expand.grid()` to generate a data frame of all ID pairs. To make our code readable, we use `dplyr`'s pipe operator (`%>%`) instead of nesting parentheses.


```r
# Generate all pairwise matches of IDs
# By default, expand.grid treats the string values as factors, 
# so we  have to instruct R not to do that
dedup_df <- expand.grid(lab_today$LabSpecimenID, case_yday$CaseID, 
                        stringsAsFactors = FALSE)
# By default expand.grid saves the columns as V1 and V2. 
# But that's not helpful at all. We can rename them using colnames()
colnames(dedup_df) <- c("lab_today_id", "case_yday_id")
```


### Add names and other information in aid of manual deduplication
We  now add more information to the names to aid us in decision making on whether or not the pairs are duplicates. In our linelist, `Name`, `Age`, `Sex`, and `Municipality` all help in making that decision. We  also add the ID variables (`LabSpecimenID` and `CaseID`), `DateOnset` and `Result`.

We  first retrieve the relevant columns from `lab_today` and `case_yday` using `dplyr`'s `select()` function. We  then store the results in the tibbles `lab_today_info` and `case_yday_info`.


```r
# Select columns in aid of manual deduplication
lab_today_info <- lab_today %>% 
  select(LabSpecimenID, Name, Age, Sex, Municipality, DateOnset, Result)
case_yday_info <- case_yday %>% 
  select(CaseID, Name, Age, Sex, Municipality, DateOnset)
```

Then, we merge the data from the tibble `lab_today_info` into the data frame `dedup_df` and store into a new data frame called `dedup_df_info` using the base R function `merge()`. We  also arrange the columns as we go along with the merging using `dplyr`'s `relocate()` function.


```r
# Merge with info from lab_today_info
# When merging, there are two data frames, labeled as x and y
# by.x and by.y are the variable names with which to link the two data frames
# In x, the ID is lab_today_id, in y, the ID is LabSpecimenID
dedup_df_info <- merge(x = dedup_df, y = lab_today_info, 
                       by.x = "lab_today_id", by.y = "LabSpecimenID")

# We want to put the case_yday_id column at the end
dedup_df_info <- dedup_df_info %>% relocate(case_yday_id, .after = last_col())
```

At this point, the data frame `dedup_df_info` has the relevant columns from the tibble `lab_today_info` merged with the column `lab_today_id` from the data frame `dedup_df`, and we have placed the column `case_yday_id` at the end. Now, we  execute similar steps to merge the data from `case_yday_info`.


```r
# Merge with info from case_yday_info
## NOTE that the x data frame is now dedup_df_info, NOT dedup_df
# When merging, there are two data frames, labeled as x and y
# by.x and by.y are the variable names with which to link the two data frames
# In x, the ID is case_yday_id, in y, the ID is CaseID
dedup_df_info <- merge(x = dedup_df_info, y = case_yday_info, 
                       by.x = "case_yday_id", by.y = "CaseID")


# The columns Name, Age, Sex, and Municipality appear in both x and y data frames
# The command appends a suffix .x or .y to indicate which column came from which

# We want to put the case_yday_id right before the Name.y column
# Visually this  remind us that lab_today_info are columns with suffix .x
# and case_yday_info are columns with suffix .y
dedup_df_info <- dedup_df_info %>% relocate(case_yday_id, .before = Name.y)
```

### Generating similarity scores
We  now run the `tidy_stringdist()` function to generate similarity scores of all our pairwise names. You may read more about the different methods under this command by reading the documentation (Type `?tidy_stringdist-metrics` on the Console). If we do not specify the method, the command generates a score using all available methods (which can be time-consuming), so in this example, we  just use one - the Jaro-Winkler distance (`jw`), which provides similarity scores on a scale of 0 to 1, where 0 is an exact match (the lower the score, the likelier it is a duplicate). We  store the results in the data frame `dedup_df_jw` and retain pairs with a score of 0.3 and below for further inspection using `dplyr`'s `filter()` function, then sort by `jw` using `dplyr`'s `arrange()` function. Feel free to experiment with what method and cutoff works.


```r
# Use Jaro-Winkler distance to generate similarity scores
# v1 and v2 are the column of names
dedup_df_jw <- tidy_stringdist(dedup_df_info, v1 = "Name.x", 
                               v2 = "Name.y", method = "jw")

# Filter jw <= 0.3
dedup_df_jw <- dedup_df_jw %>% filter(jw <= 0.3)

# Sort by jw
dedup_df_jw <- dedup_df_jw %>% arrange(jw)
```

### Manually selecting duplicates
Now with the data frame `dedup_df_jw`, we  manually select rows that are duplicates by looking at the entire data frame. We  type `View(dedup_df_jw)` on the Console to view it as a separate tab on the Script editor. Take note of the rows that we  mark as duplicates.

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> lab_today_id </th>
   <th style="text-align:left;"> Name.x </th>
   <th style="text-align:right;"> Age.x </th>
   <th style="text-align:left;"> Sex.x </th>
   <th style="text-align:left;"> Municipality.x </th>
   <th style="text-align:left;"> DateOnset.x </th>
   <th style="text-align:left;"> Result </th>
   <th style="text-align:right;"> case_yday_id </th>
   <th style="text-align:left;"> Name.y </th>
   <th style="text-align:right;"> Age.y </th>
   <th style="text-align:left;"> Sex.y </th>
   <th style="text-align:left;"> Municipality.y </th>
   <th style="text-align:left;"> DateOnset.y </th>
   <th style="text-align:right;"> jw </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> AB-0458209 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-06 </td>
   <td style="text-align:left;"> Negative </td>
   <td style="text-align:right;"> 12579 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> AB-0458217 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
   <td style="text-align:right;"> 13289 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> AB-0458206 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> Negative </td>
   <td style="text-align:right;"> 13479 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> AB-0458214 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
   <td style="text-align:right;"> 13597 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-06-30 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> AB-0458225 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-06 </td>
   <td style="text-align:left;"> Negative </td>
   <td style="text-align:right;"> 18400 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-06 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> AB-0458229 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:left;"> Positive </td>
   <td style="text-align:right;"> 18793 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:right;"> 0.0000000 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> AB-0458220 </td>
   <td style="text-align:left;"> Franciszek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Negative </td>
   <td style="text-align:right;"> 13547 </td>
   <td style="text-align:left;"> Francissek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:right;"> 0.0370370 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> AB-0458212 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
   <td style="text-align:right;"> 13566 </td>
   <td style="text-align:left;"> Penelope F. Fields </td>
   <td style="text-align:right;"> 45 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-01 </td>
   <td style="text-align:right;"> 0.0555556 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> AB-0458204 </td>
   <td style="text-align:left;"> Eve Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Positive </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve M. Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-06-30 </td>
   <td style="text-align:right;"> 0.0714286 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> AB-0458221 </td>
   <td style="text-align:left;"> Eve Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> Positive </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve M. Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-06-30 </td>
   <td style="text-align:right;"> 0.0714286 </td>
  </tr>
</tbody>
</table>
In this example, all but Row 8 are duplicates. Penelope Fields is a 16 year old female from Mexe, while Penelope F. Fields is a 45 year old female who is also from Mexe. It is likely that these two are related which is why the names are similar, or the age (or date of birth) was encoded incorrectly. We would need to revalidate this information again **outside** of this data processing workflow, but let us assume in this case we have checked that they really are two different persons.

Now we save the row numbers in a new tibble called `dedup_df_jw_manual` using the subset functions in base R. We can place a vector of row numbers inside the bracket beside a data frame, then followed by a comma with nothing else (to indicate we are selecting all columns).


```r
# Selecting duplicates - only Row 8 is not a duplicate
# View(dedup_df_jw) to view the tibble
dedup_df_jw_manual <- dedup_df_jw[c(1:7, 9:10),]
```

The tibble `dedup_df_jw_manual` now contains laboratory results of cases already existing in the case linelist, and we  need to update their information later on with this tibble. The next step deduplicates names among new cases **within** the laboratory linelist.


## Identifying new cases within the laboratory linelist

### Filtering positive results
We  first filter only positive results from the laboratory linelist (`lab_today`) because these contain all the new cases and current cases with subsequent positive results. We  save the filtered data in a tibble called `lab_today_pos`.


```r
# Filter positive results only
lab_today_pos <- lab_today %>% filter(Result == "Positive")
```

Then, we  filter out the duplicates that we have identified from `dedup_df_jw_manual`. We  use the `filter()` function with the `%in%` operator. The `%in%` operator works like this: If the code is written as `X %in% Y`, then this means that we filter `X` based on the values in `Y`. In our case, `X` is the `LabSpecimenID` and `Y` is `dedup_df_jw_manual$lab_today_id`. Since we need the values that are **NOT** in `Y`, we  need to enclose the entire expression with `!()` which gives us the opposite of what we need to filter. We save the filtered data in a tibble called `lab_today_pos_nodup`


```r
# !() means we want the opposite result of the filter expression
# X %in% Y means we want to filter X based on values in Y
# We want to filter by laboratory result ID
# X: LabSpecimenID in lab_today_pos, Y: dedup_df_jw_manual$lab_today_id
lab_today_pos_nodup <- lab_today_pos %>% 
  filter(!(LabSpecimenID %in% dedup_df_jw_manual$lab_today_id))
```

Taking a look at the resulting tibble (`View(lab_today_pos_nodup)`):

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> LabSpecimenID </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection </th>
   <th style="text-align:left;"> DateResultReleased </th>
   <th style="text-align:left;"> DateOnset </th>
   <th style="text-align:left;"> Result </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> AB-0458219 </td>
   <td style="text-align:right;"> 44980 </td>
   <td style="text-align:left;"> Amal Ford </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> AB-0458207 </td>
   <td style="text-align:right;"> 44986 </td>
   <td style="text-align:left;"> Martin Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> AB-0458227 </td>
   <td style="text-align:right;"> 44987 </td>
   <td style="text-align:left;"> Martin F Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-12 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> AB-0458201 </td>
   <td style="text-align:right;"> 44990 </td>
   <td style="text-align:left;"> Fern Christian Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> AB-0458215 </td>
   <td style="text-align:right;"> 44991 </td>
   <td style="text-align:left;"> Fern Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> AB-0458210 </td>
   <td style="text-align:right;"> 44992 </td>
   <td style="text-align:left;"> Jessica Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:left;"> AB-0458230 </td>
   <td style="text-align:right;"> 44993 </td>
   <td style="text-align:left;"> Jess Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:left;"> AB-0458212 </td>
   <td style="text-align:right;"> 44997 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
</tbody>
</table>

This is the tibble that contains new cases, but has not yet been deduplicated. For example, rows 2 and 3, 4 and 5, and 6 and 7 are potentially duplicates. Notice how Penelope Fields is in this tibble because we have determined beforehand that the Penelope F. Fields in the case linelist is not the same Penelope Fields.

### Setting up the deduplication pairs
We  now create a tibble (`dedup_new_df`) of `LabspecimenID` in the tibble `lab_today_pos_nodup` paired with all other `LabSpecimenID` in the same tibble. We  use the `expand.grid()` function again. To save some space, we automatically delete the pairs that are equal to one another using the `filter()` function.


```r
# Create a tibble that pairs all LabSpecimenID with themselves
dedup_new_df <- expand.grid(lab_today_pos_nodup$LabSpecimenID, 
                            lab_today_pos_nodup$LabSpecimenID,
                            stringsAsFactors = FALSE)

# Name columns
colnames(dedup_new_df) <- c("LabSpecimenID1", "LabSpecimenID2")

# Filter out values equal to one another
dedup_new_df <- dedup_new_df %>% filter(!(LabSpecimenID1 == LabSpecimenID2))
```

### Add names and other information for deduplication and adjudication
We  now add more information to the names to aid us in decision making on whether or not the pairs are duplicates, and to decide which among the duplicates do we retain. We  use age, sex, and municipality, date of symptom onset, date of specimen collection. and date of result released to make that decision. We  also add the `CaseID` variable. We  store the filtered columns in the tibble `lab_today_pos_nodup_info`.


```r
# Select columns in aid of manual deduplication
lab_today_pos_nodup_info <- lab_today_pos_nodup %>% 
  select(LabSpecimenID, CaseID, Name, Age, Sex, Municipality, 
         DateOnset, DateSpecimenCollection, DateResultReleased)
```

Then we use those to merge back into `dedup_new_df` and save into a new data frame called `dedup_new_df_info`


```r
# Merge with LabSpecimen1
dedup_new_df_info <- merge(x = dedup_new_df, y = lab_today_pos_nodup_info,
                           by.x = "LabSpecimenID1", by.y = "LabSpecimenID")

# Merge with LabSpecimen2 - note that x is now dedup_new_df_info
dedup_new_df_info <- merge(x = dedup_new_df_info, y = lab_today_pos_nodup_info,
                           by.x = "LabSpecimenID2", by.y = "LabSpecimenID")

# Relocate LabSpecimen2 before CaseID.y
dedup_new_df_info <- dedup_new_df_info %>% relocate(LabSpecimenID2, .before = CaseID.y)
```

### Generate similariity scores
We  now run the `tidy_stringdist()` function to generate similarity scores of all our pairwsise names. We  use the `jw` method and retain scores 0.3 and below for further inspection. We  store the results in a new data frame called `dedup_new_df_jw`. We  also sort the results by `jw` and `Name.x` (the first name column) in aid of manual inspection.


```r
# Use Jaro-Winkler distance to generate similarity scores
# v1 and v2 are the column of names
dedup_new_df_jw <- tidy_stringdist(dedup_new_df_info, v1 = "Name.x", 
                                   v2 = "Name.y", method = "jw")

# Filter jw <= 0.3
dedup_new_df_jw <- dedup_new_df_jw %>% filter(jw <= 0.3)

# Sort by jw and Name.x
dedup_new_df_jw <- dedup_new_df_jw %>% arrange(jw, Name.x)
```


### Manually selecting duplicates
Now with the data frame `dedup_new_df_jw`, we  manually select rows that are duplicates by looking at the entire data frame. We  type `View(dedup_new_df_jw)` on the Console to view it as a separate tab on the Script editor. Take note of the rows that we  choose to retain.

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> LabSpecimenID1 </th>
   <th style="text-align:right;"> CaseID.x </th>
   <th style="text-align:left;"> Name.x </th>
   <th style="text-align:right;"> Age.x </th>
   <th style="text-align:left;"> Sex.x </th>
   <th style="text-align:left;"> Municipality.x </th>
   <th style="text-align:left;"> DateOnset.x </th>
   <th style="text-align:left;"> DateSpecimenCollection.x </th>
   <th style="text-align:left;"> DateResultReleased.x </th>
   <th style="text-align:left;"> LabSpecimenID2 </th>
   <th style="text-align:right;"> CaseID.y </th>
   <th style="text-align:left;"> Name.y </th>
   <th style="text-align:right;"> Age.y </th>
   <th style="text-align:left;"> Sex.y </th>
   <th style="text-align:left;"> Municipality.y </th>
   <th style="text-align:left;"> DateOnset.y </th>
   <th style="text-align:left;"> DateSpecimenCollection.y </th>
   <th style="text-align:left;"> DateResultReleased.y </th>
   <th style="text-align:right;"> jw </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> AB-0458227 </td>
   <td style="text-align:right;"> 44987 </td>
   <td style="text-align:left;"> Martin F Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-12 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> AB-0458207 </td>
   <td style="text-align:right;"> 44986 </td>
   <td style="text-align:left;"> Martin Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:right;"> 0.0444444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> AB-0458207 </td>
   <td style="text-align:right;"> 44986 </td>
   <td style="text-align:left;"> Martin Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> AB-0458227 </td>
   <td style="text-align:right;"> 44987 </td>
   <td style="text-align:left;"> Martin F Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-12 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:right;"> 0.0444444 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:left;"> AB-0458230 </td>
   <td style="text-align:right;"> 44993 </td>
   <td style="text-align:left;"> Jess Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> AB-0458210 </td>
   <td style="text-align:right;"> 44992 </td>
   <td style="text-align:left;"> Jessica Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:right;"> 0.1269231 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:left;"> AB-0458210 </td>
   <td style="text-align:right;"> 44992 </td>
   <td style="text-align:left;"> Jessica Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> AB-0458230 </td>
   <td style="text-align:right;"> 44993 </td>
   <td style="text-align:left;"> Jess Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:right;"> 0.1269231 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:left;"> AB-0458201 </td>
   <td style="text-align:right;"> 44990 </td>
   <td style="text-align:left;"> Fern Christian Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> AB-0458215 </td>
   <td style="text-align:right;"> 44991 </td>
   <td style="text-align:left;"> Fern Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:right;"> 0.2474916 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:left;"> AB-0458215 </td>
   <td style="text-align:right;"> 44991 </td>
   <td style="text-align:left;"> Fern Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> AB-0458201 </td>
   <td style="text-align:right;"> 44990 </td>
   <td style="text-align:left;"> Fern Christian Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:right;"> 0.2474916 </td>
  </tr>
</tbody>
</table>

There are no rows to exclude as all the rows are duplicates of one another. Rows 1 and 2, 3 and 4, and 5 and 6 are duplicates of one another. We save the results in a new data frame `dedup_new_df_jw_manual`. We add a new column called `DuplicateID` which  manually tag rows as duplicates of one another.


```r
# No rows to exclude, so save everything
dedup_new_df_jw_manual <- dedup_new_df_jw

# Add a new column that manually tags the duplicates
# Row 1 and 2  have DuplicateID 1
# Row 3 and 4  have DuplicateID 2
# Row 5 and 6  have DuplicateID 3
dedup_new_df_jw_manual$DuplicateID <- c(1, 1, 2, 2, 3, 3)
```

<br> 

# Saving new case data

## Filtering new cases with no duplication issues
Now we filter out the `LabSpecimenID` values from the tibble `lab_today_pos_nodup` that appear in `LabSpecimenID1` from the tibble `dedup_new_df_jw_manual`. We save the results in a new tibble `lab_today_pos_nodup_nodup` (`nodup` is used twice to indicate we have removed duplicates twice over).


```r
lab_today_pos_nodup_nodup <- lab_today_pos_nodup %>% 
  filter(!(LabSpecimenID %in% dedup_new_df_jw_manual$LabSpecimenID1))
```

We see we have two cases:

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:left;"> LabSpecimenID </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection </th>
   <th style="text-align:left;"> DateResultReleased </th>
   <th style="text-align:left;"> DateOnset </th>
   <th style="text-align:left;"> Result </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:left;"> AB-0458219 </td>
   <td style="text-align:right;"> 44980 </td>
   <td style="text-align:left;"> Amal Ford </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:left;"> AB-0458212 </td>
   <td style="text-align:right;"> 44997 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> Positive </td>
  </tr>
</tbody>
</table>

## Preparing to add to case linelist
Now we transform the tibble `lab_today_pos_nodup_nodup` into the columns of the tibble `case_yday` so that we may append them later. We store the new tibble as `case_today`. Recall that:

* We carry over the values of `CaseID`, `Name`, `Age`, `Sex`, `Municipality`, and `DateOnset`.
* The values in `DateSpecimenCollection` and `DateResultReleased` are carried over to `DateSpecimenCollection_PositiveFirst` and `DateResultReleased_PositiveFirst`, respectively.
* `DateSpecimenCollection_NegativeFirst` and `DateResultReleased_NegativeFirst` are blank as these are new cases.

Because the columns of `lab_today_pos_nodup_nodup` are mapped 1:1 to `case_yday`, we can first duplicate the tibble `lab_today_pos_nodup_nodup` as a new tibble called `case_today` and rename/remove/add blank columns from `case_today` to resemble `case_yday`. We rename columns using `dplyr`'s `rename()` function (syntax: `newname` = `oldname`). We remove columns using `dplyr`'s `select()` function and enclose the column names to delete using `-()`. We add blank date columns by simply creating them and assigning them `NA` values and declaring their class using `as.POSIXct()` for dates.


```r
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

# Move date onset to the end
case_today <- case_today %>% relocate(DateOnset, .after = last_col())
```

The `case_today` linelist should look something like this:

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection_PositiveFirst </th>
   <th style="text-align:left;"> DateResultReleased_PositiveFirst </th>
   <th style="text-align:left;"> DateSpecimenCollection_NegativeFirst </th>
   <th style="text-align:left;"> DateResultReleased_NegativeFirst </th>
   <th style="text-align:left;"> DateOnset </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 44980 </td>
   <td style="text-align:left;"> Amal Ford </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 44997 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
</tbody>
</table>

<br> 

# Adjudicating on data 

## Compiling new cases

Now we  decide which information to use from each columns among the new cases in `dedup_new_df_jw_manual`. Recall the simple adjudication rules:

* For `CaseID`, the lower number is kept.
* For `Name`, the longer one is kept.
* For `DateOnset`, the earlier one is kept.
* For `DateSpecimenCollection`, the earlier one is kept for `DateSpecimenCollection_PositiveFirst`.
* For `DateResultReleased`, the earlier one is kept for `DateResultReleased_PositiveFirst`.
* `DateSpecimenCollection_NegativeFirst` and `DateResultReleased_NegativeFirst` are both blank.

Because we tagged the duplicates manually, we would have to select the values we need manually as well. There is no workaround for this, and it might be tempting to do this in Microsoft Excel. **DON'T.** Resist all temptation. The code  end up long, but the advantage is that we have a clear paper trail of what decisions we have made.

We  use `dplyr`'s `group_by()` function to tell R that we plan to adjudicate by `DuplicateID`. Then, we use the `dplyr`'s `summarize()` function to define our columns according to `case_today` as we  append them later, as well as implement the adjudication rules. We  use the base R functions `min()` and `max()` for the ones where we need to identify the minimum and maximum values. For `DateOnset`, we also have to specify that we have to exclude `NA` from deciding which is the minimum value. For `Name`, we use the base R function `which.max()` to identify the row number of the longest number of characters, and we use the base R function `nchar()` to calculate the number of characters. We then save our result in the tibble `case_today_dedup`:


```r
# Use all the .x-suffixed columns
# Adjudication rules
# * For `CaseID`, the lower number is kept.
# * For `Name`, the longer one is kept.
# * For `DateOnset`, the earlier one is kept.
# * For `DateSpecimenCollection`, the earlier one is kept for `DateSpecimenCollection_PositiveFirst`.
# * For `DateResultReleased`, the earlier one is kept for `DateResultReleased_PositiveFirst`.
# * `DateSpecimenCollection_NegativeFirst` and `DateResultReleased_NegativeFirst` are both blank.
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
            DateOnset = min(DateOnset.x[!is.na(DateOnset.x)]))

# Finally, remove the DuplicateID as we do not need it anymore
case_today_dedup <- case_today_dedup %>% select(-(DuplicateID))
```

Then, we append the cases from `case_today_dedup` into `case_today` and **we finally have a clean linelist of cases today** - deduplicated and adjudicated. We use the base R function `rbind()` to do this.


```r
# Bind the rows together of case_today and case_today_dedup
case_today <- rbind(case_today, case_today_dedup)
```

Our new case linelist `case_today` now looks like this:

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection_PositiveFirst </th>
   <th style="text-align:left;"> DateResultReleased_PositiveFirst </th>
   <th style="text-align:left;"> DateSpecimenCollection_NegativeFirst </th>
   <th style="text-align:left;"> DateResultReleased_NegativeFirst </th>
   <th style="text-align:left;"> DateOnset </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 44980 </td>
   <td style="text-align:left;"> Amal Ford </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 44997 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 44986 </td>
   <td style="text-align:left;"> Martin F Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 44992 </td>
   <td style="text-align:left;"> Jessica Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:right;"> 44990 </td>
   <td style="text-align:left;"> Fern Christian Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-14 </td>
  </tr>
</tbody>
</table>

## Updating current cases

### Retrieving ID pairs
We first retrieve the `LabSpecimenID` and `CaseID` pairs from the data frame `dedup_df_jw`. In that data frame, these correspond to the columns `lab_today_id` and `case_yday_id`. We store the ID pairs in a data frame called `dedup_df_jw_IDpairs`


```r
# Retrieve ID pairs
dedup_df_jw_IDpairs <- dedup_df_jw %>% select(lab_today_id, case_yday_id)
```

### Merging with the rest of the information
Then, we retrieve all the columns we need from the tibble `lab_today` and merge them with the `lab_today_id` in the data frame `dedup_df_jw_IDpairs`. We  store the results in a tibble called `dedup_df_jw_allinfo`


```r
# Merge to retrieve all info
# all.x = TRUE means to retain all rows of x regardless if there is a match,
# all.y = FALSE means to drop rows of y if there is no match.
dedup_df_jw_allinfo <- merge(x = dedup_df_jw_IDpairs, y = lab_today,
                             by.x = "lab_today_id", by.y = "LabSpecimenID",
                             all.x = TRUE, all.y = FALSE)
```

### Preparing to add to case linelist
Now we transform the the data frame `dedup_df_jw_allinfo` into the columns of the tibble `case_yday` so that it  be easier for us to update case information. We store the new tibble as `case_yday_newinfo`. 

* We carry over the values of `CaseID`, `Name`, `Age`, `Sex`, `Municipality`, and `DateOnset`
* The values in `DateSpecimenCollection` and `DateResultReleased` are assigned to `DateSpecimenCollection_PositiveFirst` and `DateResultReleased_PositiveFirst` if the result is positive, and `DateSpecimenCollection_NegativeFirst` and `DateResultReleased_NegativeFirst` if the result is negative. We  use the `dplyr`'s `mutate()` and `case_when()` functions for this. Note that the pipe operator (`%>%`) can be used to execute multiple instructions at once.
* We  then remove the columns `lab_today_id`, `CaseID`, `DateSpecimenCollection`, `DateResultReleased` and `Result` since we  not need them anymore after this. `CaseID` in this data frame pertain to the autogenerated `CaseID` from the laboratory linelist. We need the column `case_yday_id` because that is the ID variable that  allow us to link them to the tibble `case_yday`. then we  rename `case_yday_id` to `CaseID`. 


```r
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

# Relocate DateOnset at the end
case_yday_newinfo <- case_yday_newinfo %>% relocate(DateOnset, .after = last_col())
```

The tibble should now look like this:

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection_PositiveFirst </th>
   <th style="text-align:left;"> DateResultReleased_PositiveFirst </th>
   <th style="text-align:left;"> DateSpecimenCollection_NegativeFirst </th>
   <th style="text-align:left;"> DateResultReleased_NegativeFirst </th>
   <th style="text-align:left;"> DateOnset </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 13479 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 12579 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-06 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 13566 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:right;"> 13597 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-14 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:right;"> 13289 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:right;"> 13547 </td>
   <td style="text-align:left;"> Franciszek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-11 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:right;"> 18400 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-06 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:right;"> 18793 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-09 </td>
  </tr>
</tbody>
</table>

### Add the information from the case linelist for comparison
Now, we  add rows to the tibble `case_yday_newinfo` that contain information from the case linelist. We  save these results in a tibble called `case_yday_oldinfo`. We  then combine the two tibbles into a new tibble called `case_yday_recon`. In this tibble, we  implement the adjudication rules and save them in a new tibble called `case_yday_update`

* For `Name`, the longer one is kept.
* For all date columns, the earliest one is kept.


```r
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
            DateOnset = min(DateOnset[!is.na(DateOnset)]))
```

The tibble `case_yday_update` should now look like this:

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection_PositiveFirst </th>
   <th style="text-align:left;"> DateResultReleased_PositiveFirst </th>
   <th style="text-align:left;"> DateSpecimenCollection_NegativeFirst </th>
   <th style="text-align:left;"> DateResultReleased_NegativeFirst </th>
   <th style="text-align:left;"> DateOnset </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 12579 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> 2021-07-04 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 13289 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 13479 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-01 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 13547 </td>
   <td style="text-align:left;"> Francissek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:right;"> 13566 </td>
   <td style="text-align:left;"> Penelope F. Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:right;"> 13597 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve M. Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:right;"> 18400 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-07 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-06 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:right;"> 18793 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-09 </td>
  </tr>
</tbody>
</table>
<br>

# Compiling the latest case linelist

## Putting the processed tibbles altogether

At this point, we have a linelist of processed new cases called `case_today`, and a linelist of current cases with updated information called `case_yday_update`. To compile the full latest case linelist, we need one more linelist: current cases with no updates. We filter out `CaseID` values from the tibble `case_yday` that are not in `case_yday_update`. We  save this linelist as a new tibble `case_yday_noupdate`


```r
# Retrieve cases with no update
case_yday_noupdate <- case_yday %>% filter(!(CaseID %in% case_yday_update$CaseID))
```

Finally, we can combine the three tibbles `case_today`, `case_yday_update`, and `case_yday_noupdate` into the latest case linelist. We can save this in a tibble called `case_latest`


```r
# Combine the three tibbles to the full latest case linelist, and arrange by CaseID
case_latest <- rbind(case_today, case_yday_update, case_yday_noupdate)
case_latest <- case_latest %>% arrange(CaseID)
```

The latest case linelist now looks like this:

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection_PositiveFirst </th>
   <th style="text-align:left;"> DateResultReleased_PositiveFirst </th>
   <th style="text-align:left;"> DateSpecimenCollection_NegativeFirst </th>
   <th style="text-align:left;"> DateResultReleased_NegativeFirst </th>
   <th style="text-align:left;"> DateOnset </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 12579 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> 2021-07-04 </td>
   <td style="text-align:left;"> 2021-07-10 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-11 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 13289 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 13479 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-01 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-16 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 13547 </td>
   <td style="text-align:left;"> Francissek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-16 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:right;"> 13566 </td>
   <td style="text-align:left;"> Penelope F. Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:right;"> 13597 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve M. Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:right;"> 18400 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-07 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-06 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:right;"> 18793 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-09 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:right;"> 44980 </td>
   <td style="text-align:left;"> Amal Ford </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 11 </td>
   <td style="text-align:right;"> 44986 </td>
   <td style="text-align:left;"> Martin F Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 12 </td>
   <td style="text-align:right;"> 44990 </td>
   <td style="text-align:left;"> Fern Christian Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-14 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 13 </td>
   <td style="text-align:right;"> 44992 </td>
   <td style="text-align:left;"> Jessica Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 14 </td>
   <td style="text-align:right;"> 44997 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
</tbody>
</table>

## Checking date consistencies

Finally, we  check whether the date of symptom onset is on or before the date of specimen collection of the first positive test result. We mentioned earlier that when we find dates of symptom onset that are greater than the date of specimen collection, we replace the date of symptom onset with the date of specimen collection.


```r
case_latest <- case_latest %>%
  mutate(DateOnset = 
           case_when(DateOnset <= DateSpecimenCollection_PositiveFirst ~ DateOnset,
                     DateOnset > DateSpecimenCollection_PositiveFirst ~ DateSpecimenCollection_PositiveFirst,
                     NA ~ as.POSIXct(NA)))
```

<table class="table" style="font-size: 12px; margin-left: auto; margin-right: auto;">
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> CaseID </th>
   <th style="text-align:left;"> Name </th>
   <th style="text-align:right;"> Age </th>
   <th style="text-align:left;"> Sex </th>
   <th style="text-align:left;"> Municipality </th>
   <th style="text-align:left;"> DateSpecimenCollection_PositiveFirst </th>
   <th style="text-align:left;"> DateResultReleased_PositiveFirst </th>
   <th style="text-align:left;"> DateSpecimenCollection_NegativeFirst </th>
   <th style="text-align:left;"> DateResultReleased_NegativeFirst </th>
   <th style="text-align:left;"> DateOnset </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 1 </td>
   <td style="text-align:right;"> 12579 </td>
   <td style="text-align:left;"> Elijah Henson </td>
   <td style="text-align:right;"> 38 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> 2021-07-04 </td>
   <td style="text-align:left;"> 2021-07-10 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-11 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 2 </td>
   <td style="text-align:right;"> 13289 </td>
   <td style="text-align:left;"> Ella-Mai Gregory </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-02 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 3 </td>
   <td style="text-align:right;"> 13479 </td>
   <td style="text-align:left;"> Ceara West </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Chorgains </td>
   <td style="text-align:left;"> 2021-07-01 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-16 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 4 </td>
   <td style="text-align:right;"> 13547 </td>
   <td style="text-align:left;"> Francissek Vickers </td>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-10 </td>
   <td style="text-align:left;"> 2021-07-11 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-16 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5 </td>
   <td style="text-align:right;"> 13566 </td>
   <td style="text-align:left;"> Penelope F. Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 6 </td>
   <td style="text-align:right;"> 13597 </td>
   <td style="text-align:left;"> Agata Lucas </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-03 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 7 </td>
   <td style="text-align:right;"> 13788 </td>
   <td style="text-align:left;"> Eve M. Mcbride </td>
   <td style="text-align:right;"> 58 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> San Wadhor </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> 2021-07-02 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-06-30 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 8 </td>
   <td style="text-align:right;"> 18400 </td>
   <td style="text-align:left;"> Leonidas Hudson </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-07 </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-15 08:00:00 </td>
   <td style="text-align:left;"> 2021-07-06 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:right;"> 18793 </td>
   <td style="text-align:left;"> Dustin Payne </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-08 </td>
   <td style="text-align:left;"> 2021-07-09 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-08 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:right;"> 44980 </td>
   <td style="text-align:left;"> Amal Ford </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Grand Wellworth </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 11 </td>
   <td style="text-align:right;"> 44986 </td>
   <td style="text-align:left;"> Martin F Romero </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 12 </td>
   <td style="text-align:right;"> 44990 </td>
   <td style="text-align:left;"> Fern Christian Mcarthur </td>
   <td style="text-align:right;"> 40 </td>
   <td style="text-align:left;"> M </td>
   <td style="text-align:left;"> Port Sipleach </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-14 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 13 </td>
   <td style="text-align:right;"> 44992 </td>
   <td style="text-align:left;"> Jessica Bauer </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Eastmsallbuck Creek </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> 2021-07-10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 14 </td>
   <td style="text-align:right;"> 44997 </td>
   <td style="text-align:left;"> Penelope Fields </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:left;"> F </td>
   <td style="text-align:left;"> Mexe </td>
   <td style="text-align:left;"> 2021-07-15 </td>
   <td style="text-align:left;"> 2021-07-16 </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
   <td style="text-align:left;"> NA </td>
  </tr>
</tbody>
</table>
