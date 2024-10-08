# Set all code chucks as "echo=TRUE"

knitr::opts_chunk$set(echo = TRUE) 

# Clear Plots 

if(!is.null(dev.list())) dev.off()

# Clear console

cat("\014")

# Clear workspace

rm(list = ls()) 

# Set repository

options(repos="https://cran.rstudio.com")

# Load Packages

library(stringi)
library(tidyverse)
library(ggplot2)
library(dagitty)
library(devtools)
library(usethis)
library(ggdag)
library(dplyr)
library(tinytex)
library(foreign)
library(jtools)
library(huxtable)
library(ggstance)
library(summarytools) 
library(pwr)
library(lemon)
library(knitr) 
library(broom.mixed)
library(AER)
library(sas7bdat)
library(readr)
library(tidyr)
library(DT)
library(ggmap)
library(skimr)
library(visdat)
library(vcd)
library(pastecs)
library(car)
library(Hmisc)
library(DataExplorer)
library(jsonlite)
library(stringi)
library(cbsodataR)
library(learnr)
library(ISLR)
library(naniar)
library(glmnet)
library(zoo)
library(corrplot)
library(MASS)
library(ISLR)
library(boot)
library(glmnet)
library(rgl)
library(sf)
library(corrplot)
library(boot)
library(leaflet)
library(Rcpp)
library(tmap)
library(tmaptools)
library(data.table)
library(stargazer)
library(plm)
library(lmtest)
library(multiwayvcov)
library(estimatr)

# New layour for summarize

knit_print.data.frame <- lemon_print

# Telling Summary tools we are working in R Markdown

st_options(plain.ascii = FALSE, style = "rmarkdown")
st_css()

# Set Memory limit

memory.limit(9999999999)
memory.limit()

## 1. Empirical Approach

# 2.1 NVM Dataset
  
Target variable = database$obj_hid_TRANSACTIEPRIJS

# Load database from a SAS file 

database <- read.sas7bdat("nvm.sas7bdat")

# 2.2 NVM CSV Geolocated file 

# 18 observations were not possible to be geolocated

# Load database from a SAS file 

datageolocated <- read.csv("dfgeolocation.csv")

# Check for missing values in our geocoding

sum(is.na(datageolocated$lon))
sum(is.na(datageolocated$lat))

## 3. Cluster and clean my data

# 3.1 Group by Amsterdam and apartments observations

# Cluster Data from Amsterdam

dataams <- database %>%
  filter(obj_hid_WOONPLAATS == "AMSTERDAM")

# Cluster only apartments in Amsterdam (more Homogeneous)

dataamsappt <- dataams %>%
  filter(obj_hid_CATEGORIE == 2)

# 3.2 Remove outliers

# Remove outliers - top 1% and bottom 1% of observations)

dataamsappt2 <- dataamsappt %>%
  filter(obj_hid_TRANSACTIEPRIJS >= quantile(obj_hid_TRANSACTIEPRIJS, 0.01) & obj_hid_TRANSACTIEPRIJS <= quantile(obj_hid_TRANSACTIEPRIJS, 0.99))

# Check distribution of target variable

hist(dataamsappt2$obj_hid_TRANSACTIEPRIJS)

summary(dataamsappt2$obj_hid_TRANSACTIEPRIJS)

# 3.4 Drop NA observations

# Mutate zero value to missing values

dataamsappt2$obj_hid_M2[dataamsappt2$obj_hid_M2 == "0"] <-"NA"

dataamsappt2$obj_hid_M2 <- as.numeric(dataamsappt2$obj_hid_M2)

plot(dataamsappt2$obj_hid_M2)

## 4 Mutate variables

# 4.0 Mutate variables - Date and Year

# Create a date format

dataamsappt2$registrationdate <- as.POSIXct(dataamsappt2$obj_hid_DATUM_AANMELDING, origin = "1960-01-01")

# Scatter Plot - Check distribution of our data variable

plot(dataamsappt2$registrationdate)

# Create dummies for years   

dataamsappt2$year <- substr(dataamsappt2$registrationdate, start = 1, stop = 4)

table(dataamsappt2$year)

# Remove observations before 2009

dataamsappt2$year[dataamsappt2$year == 2006] <-"NA"
dataamsappt2$year[dataamsappt2$year == 2007] <-"NA"
dataamsappt2$year[dataamsappt2$year == 2008] <-"NA"

table(dataamsappt2$year)

dataamsappt2$year <- as.numeric(dataamsappt2$year)
dataamsappt2 <- dataamsappt2[!is.na(dataamsappt2$year), ]

# Check remaining observations

table(dataamsappt2$year)

# Plot year variable

ggplot(dataamsappt2) + 
  geom_bar(mapping = aes(x = year))

# 4.1 Check the right filters for our data

## House construction year 

ggplot(data = dataamsappt2) +
  geom_bar(mapping = aes(x = obj_hid_BWPER))

# Quality of the apartment

ggplot(data = dataamsappt2) +
  geom_bar(mapping = aes(x = obj_hid_KWALITEIT))

# Type of parking

ggplot(data = dataamsappt2) +
  geom_bar(mapping = aes(x = obj_hid_PARKEER))

# Type of heating

ggplot(data = dataamsappt2) +
  geom_bar(mapping = aes(x = obj_hid_VERW))

# Is in the city center?

ggplot(data = dataamsappt2) +
  geom_bar(mapping = aes(x = obj_hid_LIGCENTR))

# 4.2 Create dummy for Categorical covariates

## Dummy for BWPER variable

dataamsappt2$constructionyear = 0
dataamsappt2$constructionyear[which(dataamsappt2$obj_hid_BWPER >= 5)] = 1

table(dataamsappt2$constructionyear)

##################################################################

## Dummy for KWALITEIT variable

dataamsappt2$quality = 0
dataamsappt2$quality[which(dataamsappt2$obj_hid_KWALITEIT > 1)] = 1

table(dataamsappt2$quality)

##################################################################

# Dummy for PARKEER variable

dataamsappt2$parking = 0
dataamsappt2$parking[which(dataamsappt2$obj_hid_PARKEER > 0)] = 1

table(dataamsappt2$parking)

##################################################################

## Dummy for VERW variable

dataamsappt2$heating = 0
dataamsappt2$heating[which(dataamsappt2$obj_hid_VERW > 0)] = 1

table(dataamsappt2$heating)

##################################################################

## Dummy for LIGCENTR variable

dataamsappt2$citycenter = 0
dataamsappt2$citycenter[which(dataamsappt2$obj_hid_LIGCENTR > 2)] = 1

table(dataamsappt2$citycenter)

# 4.3 Dummy variable for Time

Opening of the Metroline 52: 22/07/2018

# Create dummies for date variable

dataamsappt2$time = 0
dataamsappt2$time[which(dataamsappt2$registrationdate >= "2018-07-22")] = 1

table(dataamsappt2$time)

# Look the distribution

ggplot(data = dataamsappt2) +
  geom_bar(mapping = aes(x = time))

# Transaction Price x Time

reg0 <- lm(obj_hid_TRANSACTIEPRIJS ~ time, data = dataamsappt2)
summary(reg0)

# Construct a linear line between X and Y variables

with(dataamsappt2, plot(time, obj_hid_TRANSACTIEPRIJS))
abline(reg0)

# Create dummies for anticipation effect - Test hypothesis

dataamsappt2$anticipation = 0
dataamsappt2$anticipation[which(dataamsappt2$registrationdate >= "2016-10-12")] = 1

table(dataamsappt2$anticipation)

# 4.4 Mutate variables - PC4

PC6 variable = obj_hid_POSTCODE

In our database, we have 69 PC4 postal codes within Amsterdam.

# Create a PC4 zip code variable

dataamsappt2$pc4 <- substr(dataamsappt2$obj_hid_POSTCODE, start = 1, stop = 4)

# Check mean and standard deviation per PC4

table(dataamsappt2$pc4) 

dataamsappt2 %>%
  group_by(pc4) %>%
  summarise(mean_price_per_pc6 = mean(obj_hid_TRANSACTIEPRIJS), sd_price_per_pc6 = sd(obj_hid_TRANSACTIEPRIJS))

# 4.5 Geocode my data - PC4 variable

Create treatment and control groups by PC4 zones

## Create a PC4 treatment variable

# PC4 zones affected by the whole Metroline 52 (8 stations)

dataamsappt2$metroline <- ifelse(dataamsappt2$pc4 %in% c("1082", "1083", "1077", "1078", "1079", "1071", "1072", "1073", "1074", "1054", "1016", "1017", "1012", "1011", "1031", "1021", "1032", "1022", "1025", "1034"), 1, 0)

table(dataamsappt2$metroline)

# North PC4 zones affected by Metroline

dataamsappt2$metrolinenorth <- ifelse(dataamsappt2$pc4 %in% c("1031", "1021", "1032", "1022", "1025", "1034"), 1, 0)

table(dataamsappt2$metrolinenorth)

# South (Zuid) PC4 zones affected by Metroline

dataamsappt2$metrolinesouth <- ifelse(dataamsappt2$pc4 %in% c("1082", "1083", "1077", "1079", "1078", "1071", "1072"), 1, 0)

table(dataamsappt2$metrolinesouth)

# PC4 treatment variables as as factors

dataamsappt2$metroline <- as.factor(dataamsappt2$metroline)
dataamsappt2$metrolinenorth <- as.factor(dataamsappt2$metrolinenorth)
dataamsappt2$metrolinesouth <- as.factor(dataamsappt2$metrolinesouth)

# Check the Price variation in time

ggplot(dataamsappt2, aes(time, obj_hid_TRANSACTIEPRIJS, col = metroline)) + 
  stat_summary(geom = 'line') + 
  theme_minimal()

# Price per treatment

ggplot(data = dataamsappt2, mapping = aes(x = metroline, y = obj_hid_TRANSACTIEPRIJS)) +
  geom_boxplot()

# Price North vs South

ggplot(data = dataamsappt2, mapping = aes(x = metrolinenorth, y = obj_hid_TRANSACTIEPRIJS)) +
  geom_boxplot()

ggplot(data = dataamsappt2, mapping = aes(x = metrolinesouth, y = obj_hid_TRANSACTIEPRIJS)) +
  geom_boxplot()

# 4.6 Geocode my data - Adress variable

# Create a location variable

dataamsappt2 <- dataamsappt2 %>%
  mutate(obj_hid_location=paste(obj_hid_STRAATNAAM, obj_hid_HUISNUMMER, ", ", obj_hid_POSTCODE))

# Mutate latitude and longitude variables

dataamsappt2$lon <- datageolocated$lon
dataamsappt2$lat <- datageolocated$lat

# Check if latitudes and longitudes are corrected

for (i in 1:78421) { 
  print(dataamsappt2$lon[i] - datageolocated$lon[i])
  print(dataamsappt2$lat[i] - datageolocated$lat[i])
}

# Drop 18 NA missing values

dataamsappt22 <- dataamsappt2[!is.na(dataamsappt2$lat), ] 

# 4.7 Calculate the distances - Adress variable

# Locations of 8 stations

stationzuid <- c(52.3399743,	4.8751142)
stationeuropaplein <- c(52.3409014,	4.8816896)
stationdepijp <- c(52.3504653,	4.8877109)
stationvilzelgracht <- c(52.3569381,	4.8895414)
stationrokin <- c(52.3695424,	4.889993)
stationcentraal <- c(52.3772198, 4.8937488)
stationnoorderpark <- c(52.3870791,	4.9116314)
stationnoord <- c(52.3958632,	4.9153591)

# Define Euclidean distance

euclidean <- function(a, b) sqrt(sum((a - b)^2))

# Test function

euclidean(stationnoorderpark, stationnoord)*100 

## Creating distance variables - Loop thru dataset 

for (i in 1:78403) { 
  dataamsappt22$distzuid[i] <- euclidean(stationzuid, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
  dataamsappt22$disteuropaplein[i] <- euclidean(stationeuropaplein, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
  dataamsappt22$distdepijp[i] <- euclidean(stationdepijp, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
  dataamsappt22$distvilzelgracht[i] <- euclidean(stationvilzelgracht, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
  dataamsappt22$distrokin[i] <- euclidean(stationrokin, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
  dataamsappt22$distcentraal[i] <- euclidean(stationcentraal, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
  dataamsappt22$distnoorderpark[i] <- euclidean(stationnoorderpark, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
  dataamsappt22$distnoord[i] <- euclidean(stationnoord, c(dataamsappt22$lat[i],dataamsappt22$lon[i]))*100
}

# Check distance variables

summary(dataamsappt22$distzuid)
summary(dataamsappt22$disteuropaplein)
summary(dataamsappt22$distdepijp)
summary(dataamsappt22$distvilzelgracht)
summary(dataamsappt22$distrokin)
summary(dataamsappt22$distcentraal)
summary(dataamsappt22$distnoorderpark)
summary(dataamsappt22$distnoord)

# Create month variable 

dataamsappt22$registrationdate1 <- as.Date(dataamsappt22$registrationdate, format = "%Y-%m-%d")

dataamsappt22 <- dataamsappt22 %>%
  mutate(registrationdate2=paste(substr(dataamsappt22$registrationdate1, start = 1, stop = 7)))

# 4.8 Geocode my data - Within 1 km distance

# Create treatment and control groups by 1 km range

# Create treatment dummy for observations within 1 km 

dataamsappt22$metrolinetreatment <- ifelse(dataamsappt22$distzuid <= 1 | dataamsappt22$disteuropaplein <= 1 | dataamsappt22$distdepijp <= 1 | dataamsappt22$distvilzelgracht <= 1 | dataamsappt22$distrokin <= 1 | dataamsappt22$distcentraal <= 1 | dataamsappt22$distnoorderpark <= 1 | dataamsappt22$distnoord <= 1, 1 ,0)

table(dataamsappt22$metrolinetreatment)

# Create treatment dummy for observations within 1 km (Only North)

dataamsappt22$metrolinetreatmentnorth <- ifelse(dataamsappt22$distnoorderpark <= 1 | dataamsappt22$distnoord <= 1, 1 ,0)

table(dataamsappt22$metrolinetreatmentnorth)

#################################################

# Within 1 Km treatment variables as as factors

dataamsappt22$metrolinetreatment <- as.factor(dataamsappt22$metrolinetreatment)
dataamsappt22$metrolinetreatmentnorth <- as.factor(dataamsappt22$metrolinetreatmentnorth)

# Check the Price variation in time

ggplot(dataamsappt22, aes(time, obj_hid_TRANSACTIEPRIJS, col = metrolinetreatment)) + 
  stat_summary(geom = 'line') + 
  theme_minimal()

# 4.9 Within Metroline52 stations

Create treatment and control groups within a certain distance from Metro station

# PC4 zones as discrete treatment

dataamsappt3 <- dataamsappt22 %>%
  filter(pc4 == "1082" | pc4 == "1083" | pc4 == "1077" | pc4 == "1078" | pc4 == "1079" | pc4 == "1071" | pc4 == "1072" | pc4 == "1073" | pc4 == "1074" | pc4 == "1054" | pc4 == "1016" | pc4 == "1017" | pc4 == "1012" | pc4 == "1011" | pc4 == "1031" | pc4 == "1021" | pc4 == "1032" | pc4 == "1022" | pc4 == "1025" | pc4 == "1034")

# North analysis

dataamsappt3$metroline52north <- ifelse(dataamsappt3$pc4 %in% c("1031", "1021", "1032", "1022", "1025", "1034"), 1, 0)

table(dataamsappt3$metroline52north)

########################################################

# Within 1 km as continuous treatment 

dataamsappt4 <- dataamsappt22 %>%
  filter(dataamsappt22$distzuid <= 1 | dataamsappt22$disteuropaplein <= 1 | dataamsappt22$distdepijp <= 1 | dataamsappt22$distvilzelgracht <= 1 | dataamsappt22$distrokin <= 1 | dataamsappt22$distcentraal <= 1 | dataamsappt22$distnoorderpark <= 1 | dataamsappt22$distnoord <= 1)

# North analysis

dataamsappt4$metrolinetreatment52north <- ifelse(dataamsappt4$distnoorderpark <= 1 | dataamsappt4$distnoord <= 1, 1, 0)

table(dataamsappt4$metrolinetreatment52north)

## 5. Descriptive Statistics

# 5.1 Whole Dataset

# Amsterdam apartment database (Cleaned base)

skim(dataamsappt22)

# Check for missing values

vis_miss(dataamsappt2, warn_large_data = FALSE)

# 5.2 Target Variable - Price of transaction

# Summary

summary(dataamsappt22$obj_hid_TRANSACTIEPRIJS)

sd(dataamsappt22$obj_hid_TRANSACTIEPRIJS)

hist(dataamsappt22$obj_hid_TRANSACTIEPRIJS,
     xlab="Transaction Price", main="")

# Transaction Price x M²

regpm2 <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ obj_hid_M2, data = dataamsappt22)
summary(regpm2)

# Construct a linear line between X and Y variables

with(dataamsappt22, plot(obj_hid_M2, log1p(obj_hid_TRANSACTIEPRIJS)))
abline(regpm2)

# Transaction Price x Year of construction

regpm3 <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ constructionyear, data = dataamsappt22)
summary(regpm3)

# Construct a linear line between X and Y variables

with(dataamsappt22, plot(constructionyear, log1p(obj_hid_TRANSACTIEPRIJS)))
abline(regpm3)

# 5.3 PC4 postal code zones

PC4 with lower observations: 1014, 1036, 1046, 1109 (North of the city)

# Table PC4

table(dataamsappt22$pc4)

# Look the distribution of PC4 

ggplot(data = dataamsappt2) +
  geom_bar(mapping = aes(x = pc4))

# Location as a factor

dataamsappt22$pc4 <- as.factor(dataamsappt22$pc4)

# Plot Transaction Price x Year by PC4

ggplot(dataamsappt22, aes(year, obj_hid_TRANSACTIEPRIJS, col = pc4)) + 
  stat_summary(geom = 'line') + 
  theme_minimal() + xlab("Year") + ylab("Transaction Price")

# Distribution of Transaction Price per PC4

ggplot(data = dataamsappt22, mapping = aes(x = pc4, y = obj_hid_TRANSACTIEPRIJS)) +
  geom_boxplot() + xlab("PC4 areas") + ylab("Transaction Price")

##################################

# Discrete treatment zones

dataamsappt22 %>%
  filter(metroline == 1) %>%
  ggplot(dataamsappt22, mapping = aes(year, obj_hid_TRANSACTIEPRIJS, col = pc4)) + 
  stat_summary(geom = 'line') + 
  theme_minimal()

# Discrete control zones

dataamsappt22 %>%
  filter(metroline == 0) %>%
  ggplot(dataamsappt22, mapping = aes(year, obj_hid_TRANSACTIEPRIJS, col = pc4)) + 
  stat_summary(geom = 'line') + 
  theme_minimal()

##################################

# Discrete treatment zones North

dataamsappt22 %>%
  filter(metrolinenorth == 1) %>%
  ggplot(dataamsappt22, mapping = aes(year, obj_hid_TRANSACTIEPRIJS, col = pc4)) + 
  stat_summary(geom = 'line') + 
  theme_minimal()

# Discrete control zones North

dataamsappt22 %>%
  filter(metrolinenorth == 0) %>%
  ggplot(dataamsappt22, mapping = aes(year, obj_hid_TRANSACTIEPRIJS, col = pc4)) + 
  stat_summary(geom = 'line') + 
  theme_minimal()

# 5.5 Year variable

# Plot distribution of transaction price per year

dataamsappt22$year <- as.factor(dataamsappt22$year)

ggplot(data = dataamsappt22, mapping = aes(x = year, y = obj_hid_TRANSACTIEPRIJS)) +
  geom_boxplot() + xlab("Years") + ylab("Transaction Price")

# 6. D-i-D Assumptions

# 6.1 Remove NA values

# Clean NA values in m2 variable

dataamsappt33 <- dplyr::filter(dataamsappt22, !is.na(obj_hid_M2))

# 6.1 Check for balance between control and treatment groups

Is the variance of our covatiates equal among treatment and control groups?

# PC4 Discrete Treatment

# Cross tables between variables - Compare characteristics of treatment and control groups 

ctable(dataamsappt22$metroline, dataamsappt22$quality)
ctable(dataamsappt22$metroline, dataamsappt22$parking)
ctable(dataamsappt22$metroline, dataamsappt22$heating)
ctable(dataamsappt22$metroline, dataamsappt22$citycenter)

## Without NA values

ctable(dataamsappt33$metroline, dataamsappt33$quality)
ctable(dataamsappt33$metroline, dataamsappt33$parking)
ctable(dataamsappt33$metroline, dataamsappt33$heating)
ctable(dataamsappt33$metroline, dataamsappt33$citycenter)

# T-tests

t.test(dataamsappt22$quality ~ dataamsappt22$metroline)
t.test(dataamsappt22$parking ~ dataamsappt22$metroline)
t.test(dataamsappt22$heating ~ dataamsappt22$metroline)
t.test(dataamsappt22$citycenter ~ dataamsappt22$metroline)

# Mean and SD of non-categorical covariates

dataamsappt22 %>%
  group_by(metroline) %>% 
  summarise(mean=mean(obj_hid_M2, na.rm=TRUE), sd=sd(obj_hid_M2, na.rm = TRUE))

dataamsappt22 %>%
  group_by(metroline) %>% 
  summarise(mean=mean(obj_hid_NKAMERS), sd=sd(obj_hid_NKAMERS))

## Without NA values

dataamsappt33 %>%
  group_by(metroline) %>% 
  summarise(mean=mean(obj_hid_M2, na.rm=TRUE), sd=sd(obj_hid_M2, na.rm = TRUE))

dataamsappt33 %>%
  group_by(metroline) %>% 
  summarise(mean=mean(obj_hid_NKAMERS), sd=sd(obj_hid_NKAMERS))

##########################################################################

# Within 1 km Continous Treatment

ctable(dataamsappt22$metrolinetreatment, dataamsappt22$quality)
ctable(dataamsappt22$metrolinetreatment, dataamsappt22$parking)
ctable(dataamsappt22$metrolinetreatment, dataamsappt22$heating)
ctable(dataamsappt22$metrolinetreatment, dataamsappt22$citycenter)

## Without NA values

ctable(dataamsappt33$metrolinetreatment, dataamsappt33$quality)
ctable(dataamsappt33$metrolinetreatment, dataamsappt33$parking)
ctable(dataamsappt33$metrolinetreatment, dataamsappt33$heating)
ctable(dataamsappt33$metrolinetreatment, dataamsappt33$citycenter)

# T-tests

t.test(dataamsappt22$quality ~ dataamsappt22$metrolinetreatment)
t.test(dataamsappt22$parking ~ dataamsappt22$metrolinetreatment)
t.test(dataamsappt22$heating ~ dataamsappt22$metrolinetreatment)
t.test(dataamsappt22$citycenter ~ dataamsappt22$metrolinetreatment)

# Mean and SD of non-categorical covariates

dataamsappt22 %>%
  group_by(metrolinetreatment) %>% 
  summarise(mean=mean(obj_hid_M2, na.rm=TRUE), sd=sd(obj_hid_M2, na.rm=TRUE))

dataamsappt22 %>%
  group_by(metrolinetreatment) %>% 
  summarise(mean=mean(obj_hid_NKAMERS), sd=sd(obj_hid_NKAMERS))

## Without NA values

dataamsappt33 %>%
  group_by(metrolinetreatment) %>% 
  summarise(mean=mean(obj_hid_M2, na.rm=TRUE), sd=sd(obj_hid_M2, na.rm=TRUE))

dataamsappt33 %>%
  group_by(metrolinetreatment) %>% 
  summarise(mean=mean(obj_hid_NKAMERS), sd=sd(obj_hid_NKAMERS))

# 6.2 Parallel Trend Analysis

# PC4 Treatment - Monthly

ggplot(dataamsappt22, aes(registrationdate2, obj_hid_TRANSACTIEPRIJS, col = metroline, group = metroline)) + stat_summary(fun=mean, geom = 'line') + theme_minimal() + theme_minimal() + xlab("Month/Year") + ylab("Transaction Price") + geom_vline(xintercept = "2018-07", linetype="dashed", size=1)

####################################################

# Within 1 km Treatment - Monthly

ggplot(dataamsappt22, aes(registrationdate2, obj_hid_TRANSACTIEPRIJS, col = metrolinetreatment, group = metrolinetreatment)) + stat_summary(fun=mean, geom = 'line') + theme_minimal() + theme_minimal() + xlab("Month/Year") + ylab("Transaction Price") + geom_vline(xintercept = "2018-07", linetype="dashed", size=1) + labs(color = "metroline")

################################################### North

# PC4 Treatment - Monthly

ggplot(dataamsappt22, aes(registrationdate2, obj_hid_TRANSACTIEPRIJS, col = metrolinenorth, group = metrolinenorth)) + stat_summary(fun=mean, geom = 'line') + theme_minimal() + theme_minimal() + xlab("Month/Year") + ylab("Transaction Price") + geom_vline(xintercept = "2018-07", linetype="dashed", size=1)

# Within 1 km Treatment - Monthly

ggplot(dataamsappt22, aes(registrationdate2, obj_hid_TRANSACTIEPRIJS, col = metrolinetreatmentnorth, group = metrolinetreatmentnorth)) + stat_summary(fun=mean, geom = 'line') + theme_minimal() + theme_minimal() + xlab("Month/Year") + ylab("Transaction Price") + geom_vline(xintercept = "2018-07", linetype="dashed", size=1) + labs(color = "metroline")

# 6.3 Correlation Matrix - Multicollinearity

Choosing our covariate deck: 
  
  obj_hid_M2 = The usable are in squared meters 
obj_hid_KWALITEIT = Quality of the apartment -> quality dummy
obj_hid_NKAMERS = Number of rooms in a house
obj_hid_PARKEER = Parking type -> parking dummy
obj_hid_VERW = Type of heating / obj_hid_heating -> heating dummy
obj_hid_LIGCENTR = Is the apartment situated in the city center? 
  
correlationmatrixdummycleaned <- data.frame(dataamsappt33$quality, dataamsappt33$obj_hid_NKAMERS, dataamsappt33$parking, dataamsappt33$heating, dataamsappt33$citycenter)

plot_correlation(correlationmatrixdummycleaned)

cor(correlationmatrixdummycleaned)

corrmatix2 <- cor(correlationmatrixdummycleaned)

corrplot(corrmatix2, method = "color")
corrplot(corrmatix2, method = "color", order = "hclust")
corrplot(corrmatix2, method = "color", order = "alphabet", diag = FALSE)
corrplot(corrmatix2, method = "shade", order = "AOE", diag = FALSE)

## 7. Regressions

# 7.1 Overall results

Log Hedonic Regression + Fixed Effects + Difference-in-Differences estimator

# Load clustered errors package

library(miceadds)

# Hedonic Regression

regapptlogfactors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter, data=dataamsappt33)

summ(regapptlogfactors, confint=TRUE) 

stargazer(regapptlogfactors, title="Results", align=TRUE)

#################################################################

# Hedonic Regression + location and time fixed effects

regapptlog2factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt33)

summ(regapptlog2factors, confint=TRUE, diagnostics=TRUE)

stargazer(regapptlog2factors, title="Results", align=TRUE)

# Clustered errors 

regapptlog2factorsc <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), cluster = 'pc4', data = dataamsappt33)

m1coeffs <- data.frame(summary(regapptlog2factorsc))

##################################################################

# Adding discrete D-i-D treatment 

regapptlog3factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metroline + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt33)

summ(regapptlog3factors, confint=TRUE, diagnostics=TRUE) 

stargazer(regapptlog3factors, title="Results", align=TRUE)

# Clustered errors

regapptlog3factorsc <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metroline + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), cluster = 'pc4', data = dataamsappt33)

m2coeffs <- data.frame(summary(regapptlog3factorsc))

##################################################################

# Adding continuous D-i-D treatment 

regapptlog4factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatment + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt33)

summ(regapptlog4factors, confint=TRUE, diagnostics=TRUE)

stargazer(regapptlog4factors, title="Results", align=TRUE)

# Clustered errors

regapptlog4factorsc <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatment + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), cluster = 'pc4', data=dataamsappt33)

m3coeffs <- data.frame(summary(regapptlog4factorsc))

# 7.2 North results

# Adding discrete D-i-D treatment 

regapptlog5factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinenorth + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt33)

summ(regapptlog5factors, confint=TRUE, diagnostics=TRUE)

stargazer(regapptlog5factors, title="Results", align=TRUE)

# Clustered errors

regapptlog5factorsc <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinenorth + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), cluster = 'pc4', data = dataamsappt33)

m4coeffs <- data.frame(summary(regapptlog5factorsc))

# Adding continuous D-i-D treatment

regapptlog6factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatmentnorth + obj_hid_M2 + quality +obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt33)

summ(regapptlog6factors, confint=TRUE, diagnostics=TRUE)

stargazer(regapptlog6factors, title="Results", align=TRUE)

# Clustered errors

regapptlog6factorsc <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatmentnorth + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), cluster = 'pc4', data = dataamsappt33)

m5coeffs <- data.frame(summary(regapptlog6factorsc))

# 8. Robustness testss

# 8.1 Within Metro line 52

# Clean m² variables

dataamsappt34 <- dplyr::filter(dataamsappt3, !is.na(obj_hid_M2))

dataamsappt44 <- dplyr::filter(dataamsappt4, !is.na(obj_hid_M2))

# Run Regression

# Discrete

regapptlog10factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metroline52north + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt34)

summ(regapptlog10factors, confint=TRUE, diagnostics=TRUE)

# Clustered errors

regapptlog10factors <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metroline52north + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt34, cluster = 'pc4')

m3coeffsac <- data.frame(summary(regapptlog10factors)) 

############################################

# Continuous 

regapptlog11factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatment52north + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt44)

summ(regapptlog11factors, confint=TRUE, diagnostics=TRUE)

# Clustered erros

regapptlog11factors <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatment52north + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt44, cluster = 'pc4')

m3coeffsac <- data.frame(summary(regapptlog11factors)) 

# Parallel Trend Analysis

ggplot(dataamsappt34, aes(registrationdate2, obj_hid_TRANSACTIEPRIJS, col = metroline52north, group = metroline52north)) + stat_summary(fun=mean, geom = 'line') + theme_minimal() + theme_minimal() + xlab("Month/Year") + ylab("Transaction Price") + geom_vline(xintercept = "2018-07", linetype="dashed", size=1)

# Within 1 km Treatment - Monthly

ggplot(dataamsappt44, aes(registrationdate2, obj_hid_TRANSACTIEPRIJS, col = metrolinetreatment52north, group = metrolinetreatment52north)) + stat_summary(fun=mean, geom = 'line') + theme_minimal() + theme_minimal() + xlab("Month/Year") + ylab("Transaction Price") + geom_vline(xintercept = "2018-07", linetype="dashed", size=1) + labs(color = "metroline")


# 8.2 Sample within 2km

## Create within 2km range variable

dataamsappt33$metrolinetreatmentkm <- ifelse(dataamsappt33$distzuid <= 2 | dataamsappt33$disteuropaplein <= 2 | dataamsappt33$distdepijp <= 2 | dataamsappt33$distvilzelgracht <= 2 | dataamsappt33$distrokin <= 2 | dataamsappt33$distcentraal <= 2 | dataamsappt33$distnoorderpark <= 2 | dataamsappt33$distnoord <= 2, 1 ,0)

table(dataamsappt33$metrolinetreatmentkm)

# Split database

dataamsappt66 <- dataamsappt33 %>%
  filter(metrolinetreatmentkm == 1)

# Create treatment variable within 1 km

dataamsappt66$metrolinetreatmentkm <- ifelse(dataamsappt66$distzuid <= 1 | dataamsappt66$disteuropaplein <= 1 | dataamsappt66$distdepijp <= 1 | dataamsappt66$distvilzelgracht <= 1 | dataamsappt66$distrokin <= 1 | dataamsappt66$distcentraal <= 1 | dataamsappt66$distnoorderpark <= 1 | dataamsappt66$distnoord <= 1, 1 ,0)

table(dataamsappt66$metrolinetreatmentkm)

## Run regression

regapptlog66factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatmentkm + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt66)

summ(regapptlog66factors, confint=TRUE, diagnostics=TRUE)

stargazer(regapptlog66factors, title="Results", align=TRUE)

# Clustered errors

regapptlog66factorsc <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatmentkm + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), cluster = 'pc4', data=dataamsappt66)

m3coeffsc <- data.frame(summary(regapptlog66factorsc))

#################################################

# Create treatment dummy for observations within 1 km (Only North)

dataamsappt66$metrolinetreatmentnorthkm <- ifelse(dataamsappt66$distnoorderpark <= 1 | dataamsappt66$distnoord <= 1, 1 ,0)

table(dataamsappt66$metrolinetreatmentnorthkm)

regapptlog67factors <- lm(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatmentnorthkm + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), data=dataamsappt66)

summ(regapptlog67factors, confint=TRUE, diagnostics=TRUE)

stargazer(regapptlog67factors, title="Results", align=TRUE)

# Clustered errors

regapptlog68factors <- lm.cluster(log1p(obj_hid_TRANSACTIEPRIJS) ~ time*metrolinetreatmentnorthkm + obj_hid_M2 + quality + obj_hid_NKAMERS + parking + heating + citycenter + factor(pc4) + factor(year), cluster = 'pc4', data=dataamsappt66)

m3coeffsc1 <- data.frame(summary(regapptlog68factors))

## Model assumptions

# Cross tabulations

ctable(dataamsappt66$metrolinetreatmentkm, dataamsappt66$quality)
ctable(dataamsappt66$metrolinetreatmentkm, dataamsappt66$parking)
ctable(dataamsappt66$metrolinetreatmentkm, dataamsappt66$heating)
ctable(dataamsappt66$metrolinetreatmentkm, dataamsappt66$citycenter)

# T-tests

t.test(dataamsappt66$quality ~ dataamsappt66$metrolinetreatmentkm)
t.test(dataamsappt66$parking ~ dataamsappt66$metrolinetreatmentkm)
t.test(dataamsappt66$heating ~ dataamsappt66$metrolinetreatmentkm)
t.test(dataamsappt66$citycenter ~ dataamsappt66$metrolinetreatmentkm)

# Categorical variables

dataamsappt66 %>%
  group_by(metrolinetreatmentkm) %>% 
  summarise(mean=mean(obj_hid_M2, na.rm=TRUE), sd=sd(obj_hid_M2, na.rm=TRUE))

dataamsappt66 %>%
  group_by(metrolinetreatmentkm) %>% 
  summarise(mean=mean(obj_hid_NKAMERS), sd=sd(obj_hid_NKAMERS))

# Parallel Trends

dataamsappt66$registrationdate1 <- as.Date(dataamsappt66$registrationdate, format = "%Y-%m-%d")

dataamsappt66 <- dataamsappt66 %>%
  mutate(registrationdate2=paste(substr(dataamsappt66$registrationdate1, start = 1, stop = 7)))

ggplot(dataamsappt66, aes(registrationdate2, obj_hid_TRANSACTIEPRIJS, col = metrolinetreatmentkm, group = metrolinetreatmentkm)) + stat_summary(fun=mean, geom = 'line') + theme_minimal() + theme_minimal() + xlab("Month/Year") + ylab("Transaction Price") + geom_vline(xintercept = "2018-07", linetype="dashed", size=1)

##. 10. Latex tables

# Table

stargazer(regapptlog2factors, regapptlog3factors, regapptlog4factors, regapptlog5factors, title="Results", align=TRUE)

# Correlation Matrix

stargazer(corrmatix2, title = "Correlation Matrix")

```

# End
