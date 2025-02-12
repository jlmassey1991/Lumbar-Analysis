##########################################################


  # Title:  Weighted Survival Analysis for Cyrpto
  # Editor: Jason Massey
  # Date:   01/28/2025


##########################################################



#####################

# Libraries

#####################
library("dplyr")
library("ggplot2")
library("tidyr")
library("survival")
library("survminer")
library("PSweight")
library("broom")
library("haven")
library("summarytools")
library("WeightIt")


options(scipen=999)

#####################

# Reading Data

#####################

# Read in LP Data
survival <- read_sas("C:/Users/qne4/CDC/NCEZID-MDB - Data Science and Informatics (DSI)/Data Science/people/Massey-Jason/Data Support (MDB)/Kaitlin Benedict/lumbar survival/lp2.sas7bdat")


#########
# NOTES #
#########

# dataset: lp2
# time variable: LOS (continuous length of hospital stay in LOS)
# exposure: only1LP (dichotomous. 0=received more than 1 LP, 1=received only 1 LP)
# outcome: died2 (dichotomous. 0=alive at hospital discharge, 1=died)
# potential confounders (age is continuous, the rest are categorical):
# age
# race_eth2 
# std_payor_c 
# prov_region 
# urban_rural 
# beds_grp_c 
# icd_acutekidney 
# icd_anemia 
# icd_HIV
# icd_hypokalemia 
# icd_hyponatremia 
# icd_neutropenia 
# icd_overweight 
# icd_transplant
# any_CSFdrain 
# med_AMB_any 
# med_fluc 
# med_5FC
# 
# -instead of the separate variables icd_HIV and icd_transplant, could
# consider the composite variable called "Category" instead


#####################

# Alternative Datasets 

#####################

survival2 <- subset(survival, LOS <= 140)
survival3 <- subset(survival, LOS <= 138)

#################################################################

# Calculating Probability Treatment of Weights (Propensity scoring etc)

#################################################################

# Subsetting variables to create dataframe we want for analysis 
propensity = subset(survival, select = c(LOS, only1LP, died2, AGE, race_eth2, std_payor_c, 
    PROV_REGION, URBAN_RURAL, beds_grp_c, icd_acutekidney, icd_anemia, icd_HIV,
    icd_hypokalemia, icd_hyponatremia, icd_neutropenia, icd_overweight, icd_transplant,
    any_CSFdrain, med_AMB_any, med_fluc, med_5FC, category  ))
  
# Frequencies of All Variables (good for categorical variables)
dfSummary(propensity, style = "grid", plain.ascii = TRUE)

#Omitting NAs for 
#propensity <- na.omit(propensity)

#Converting categorical variables to factor type for regression models 
factor.list <- c("race_eth2", "std_payor_c","PROV_REGION","URBAN_RURAL","beds_grp_c")
propensity[,factor.list] <- lapply(propensity[,factor.list],factor)
sapply(propensity, class)


######################################
# Calcultaing Propensity Scores 
######################################

# PS Model
iptw.model=glm(only1LP ~ AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
               icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
               icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc + med_5FC,
               data = propensity,
               family = binomial(link="logit"))

# Using predictive values and selecting variables to use 
new.propensity <-augment(iptw.model,
                         propensity,
                         type.predict = "response") %>%
  rename(propensity=.fitted) %>%
  select(LOS, only1LP, died2, AGE, race_eth2, std_payor_c, 
         PROV_REGION, URBAN_RURAL, beds_grp_c, icd_acutekidney, icd_anemia, icd_HIV,
         icd_hypokalemia, icd_hyponatremia, icd_neutropenia, icd_overweight, icd_transplant,
         any_CSFdrain, med_AMB_any, med_fluc, med_5FC, propensity, category)

# Viewing first rows of modified dataframe 
head(new.propensity) 



######################################
# Generate probability weights
######################################

# Creating unstable, stable, treated, and overlapping weights
# using indicator function for binary exposure, only1LP  
# For example, when only1LP = 0 then uw =        [ 0 ] + [ 1 - 0 /(1-PS(i) ] =  1/(1-propensity)
#                           = 1 then uw =  [ 1/PS(i) ] + [ 0 ]               =   1/propesnity

ipw.data<-new.propensity %>%
  mutate(uw=(only1LP/propensity)+(1-only1LP)/(1-propensity)) %>%
  
  mutate(sw=mean(only1LP)*(only1LP/propensity)+mean(only1LP)*(1-only1LP)/(1-propensity)) %>%
  
  mutate(tr=propensity*(only1LP/propensity)+propensity*(1-only1LP)/(1-propensity)) %>%
  
  mutate(ov=propensity*(1-propensity)*(only1LP/propensity)+
           propensity*(1-propensity)*(1-only1LP)/(1-propensity))


###############################################

# Outcome Regression Models for each weight 

###############################################

# NOTE: It's ok to include weights and adjust for covariates. 

model1.fit=coxph(Surv(LOS, died2) ~ only1LP + AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
                   icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
                   icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc+med_5FC,
                 data = ipw.data,
              weights = uw)

model2.fit=coxph(Surv(LOS, died2) ~ only1LP + AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
                   icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
                   icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc+med_5FC,
                 data = ipw.data,
                 weights = sw)

model3.fit=coxph(Surv(LOS, died2) ~ only1LP + AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
                   icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
                   icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc+med_5FC,
                 data = ipw.data,
                 weights = tr)

model4.fit=coxph(Surv(LOS, died2) ~ only1LP + AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
                   icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
                   icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc+med_5FC,
                 data = ipw.data,
                 weights = ov)



# Check fit 
tidy(model1.fit)
tidy(model2.fit)
tidy(model3.fit)
tidy(model4.fit)

# Adjusted Cox Regression estimates after weighting:
summary(model1.fit)
summary(model2.fit)
summary(model3.fit)
summary(model4.fit)



##############################################

# Assessing the PH Assumptions for Covariates 

##############################################

# Test (small p means time dependent and needs to be addressed)
# All large --> Met 
test.ph <- cox.zph(model4.fit)
test.ph

# Plots (check Schoenfeld residuals)
# All look good --> Met 
ggcoxzph(test.ph)

# Plots (check to see most points fall on line)
# All look good --> Met 
ggcoxdiagnostics(model4.fit, type = "dfbeta",
                 linear.predictions = FALSE, ggtheme = theme_bw())


# If needed 
#ggcoxfunctional(Surv(LOS, died2) ~ AGE + log(AGE) + sqrt(AGE), data = ipw.data)

#NOTE: Are the assumptions met ? --> Yes, Met 




####################################

# Checking Balance of Covariates 

####################################

# Propensity Weight Formula 
ps.mult <- only1LP ~ AGE + race_eth2 + std_payor_c + PROV_REGION + URBAN_RURAL + beds_grp_c + 
  icd_acutekidney + icd_anemia+ icd_HIV + icd_hypokalemia + icd_hyponatremia +
  icd_neutropenia + icd_overweight + icd_transplant + any_CSFdrain + med_AMB_any + med_fluc + med_5FC

#Checking Balance for each Weight 
propensity <- as.data.frame(propensity)

bal.ipw <- SumStat(ps.formula = ps.mult,
                   weight = c("IPW"), data = propensity)

bal.treat <- SumStat(ps.formula = ps.mult,
                    weight = c("treated"), data = propensity)

bal.over <- SumStat(ps.formula = ps.mult,
                    weight = c("overlap"), data = propensity)

#Balance Plots 
plot(bal.ipw, type = "density")
plot(bal.treat, type = "density")
plot(bal.over, type = "density")


# Produce MSD Results
plot(bal.ipw, metric = "ASD")
plot(bal.treat, metric = "ASD")
plot(bal.over, metric = "ASD")




##########################

# Final Estimates Table

##########################

# Confidence Limits  
ci <- confint.default(model4.fit)
colnames(ci) <- c('UpperCI', 'LowerCI')
ci <- ci[, c(2,1)]

# Exp for estimates and limits for OR and CI
est4 <- exp(cbind(OR = coef(model4.fit),ci))
est4 <- as.data.frame(est4)

# Final Results
summary(model4.fit)

# 2.67(2.09,3.42) hazard of mortality in 1 LP vs >1 LP 
# for LOS <= 150: HR = 2.68 (2.09, 3.43)
# for LOS <= 138: HR = 2.64 (2.06, 3.38)



# Fit Survival Curves
fit<- survfit(Surv(LOS, died2) ~ only1LP, weights = ov, data = ipw.data)

# Plot survival curves (PDF)
ggsurvplot(fit, data = ipw.data,
legend.title = "No. of Lumbar Punctures Received",
legend.labs = c(">1 LP", "1 LP"),
xlab = "Length of Stay (LOS)",
pval = TRUE,
conf.int = TRUE
)

# Plot Log Cumulative Hazard Function
ggsurvplot(fit,
           fun = "cumhaz",
           data = ipw.data,
           legend.title = "No. of Lumbar Punctures Received",
           legend.labs = c(">1 LP", "1 LP"),
           xlab = "Length of Stay (LOS)",
           pval = TRUE,
        
)






#Checking Stratified Models
model_HIV=coxph(Surv(LOS, died2) ~ only1LP + AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
                   icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
                   icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc+med_5FC,
                 data = subset(ipw.data, 
                               category == "HIV"),
                 weights = uw)

model_NHNT=coxph(Surv(LOS, died2) ~ only1LP + AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
                  icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
                  icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc+med_5FC,
                data = subset(ipw.data, 
                              category == "NHNT"),
                weights = uw)

model_transplant=coxph(Surv(LOS, died2) ~ only1LP + AGE+ race_eth2+ std_payor_c+ PROV_REGION+ URBAN_RURAL+ beds_grp_c+ 
                  icd_acutekidney+ icd_anemia+ icd_HIV+ icd_hypokalemia+ icd_hyponatremia+
                  icd_neutropenia+ icd_overweight+ icd_transplant+ any_CSFdrain+ med_AMB_any+ med_fluc+med_5FC,
                data = subset(ipw.data, 
                              category == "Transplant"),
                weights = uw)

# Stratified Results
summary(model_HIV)            # 3.65 hazard of mortality 
summary(model_NHNT)           # 2.32 hazard of mortality  
summary(model_transplant)     # 2.96 hazard of mortality  

# Note: need to stratify from beginning datasets - hold off for now 





