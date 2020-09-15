---
title: The Title of Your Study Here
subtitle: Add a Subtitle if Needed
author: Björn Lindberg
bibliography: bibliography.bib
csl: bmcemerg.csl
---

*The study plan should be 3-4 pages long and written in
[markdown](https://rmarkdown.rstudio.com/) (like this
document).*

__Jag har lagt källor som kommentarer i md filen för nu, fixar korrekt citering senare.__

Introduction
============

<!--__TRAUMA IS A GLOBAL PROBLEM AND MORE SO IN LOW INCOME REGION:__--> 
Trauma, defiended as the clinical entity composed of both the injury and the body's associated response, is a global health problem and about 13% of all Disease Adjusted Life Years (DALY) lost worldwide, and about 8% of the deaths globally, or about 4.5 million, was caused by trauma in 2017. [@GBD2017DALY] <!-- https://www.thelancet.com/lancet/visualisations/gbd-compare --> In a paper publiced 2012 Charles mock et al calculated that in 2010 90% of all deaths due to trauma and injuries was in low and middle income cuntries with much higher mortality rates compared to high income countries and that an improvement in trauma care globally to that level of high income countries could save between 1.7 and 2 million lives annually. [@Mock2012] Trauma often require extensive medical treatment and sometimes admission to the Intensive care unit (ICU) which can be a problem in low reasorce settings.  

<!--__What is SOFA and qSOFA:__--> 
One of the possible complications of trauma is a state called sepsis and septic shock. The main causes for sepsis is infection and non communicable diseases but around four percent is caused by trauma. [@Rudd2020] According to the third consensus definition of sepsis and septic shock, sepsis is defined as the sequential organ failure assessment score (SOFA score) of 2 points or more and septic shock a subset of sepsis where the patient is in need of vasopressor treatment or have a serum lactate level over 2mmol/L after adequate fluid treatment. In settings where laboratory analysises can not be performed rapidly qSOFA has been developed constituting of three parts: respiratory rate of 22/min or greater, reduced Glascow coma scale (GCS) or systolic blood preassure of 100 mmHg or less. A score of more than two is coralated with higher severity of disease and a lower expected survival.  [@Sepsis3] [@Shankar2016] [@Seymour2016]

The, SOFA, qSOFA score has been studied and evaluated before and after the Sepsis-3 consensus definition 2016 but mainly in the context of infectious and non communicable diseases and in high resource settings. But it has not yet been sufficiently studied if qSOFA is a good predictor of admission to the ICU in trauma patients admitted to hospitals in low resource settings. In that case qSOFA could be used to direct the resourses and care to the most critically ill patients and thus save lives in low income cuntries.

<!-- Has it been studied as a predictor of ICU-admission in non-septic patients in other settings?:-->
__I know what i want to say but not how to say it. That most of the studies, at least that i can find, on SOFA and qSOFA focus on the infectious part and are performed in high resource settings. I have been able to find some trauma oriented papers but then all beeing focused in high resource settings. But it seem nonsensical to refrence papers about things that i'm not interested about in this paper and i cant really refrence a lack of papers in a particular area either?__   

The aim of this paper is to asses the validity of qSOFA in predicting ICU admission in trauma patients admitted to hospitals in low sesource settings. <!-- End with the aim --> 

<!--*The background/introduction should summarise the scope of the problem,
what is known about the problem, what is not known, what specific
knowledge gap the study is supposed to fill and why this is
important. It should end be stating the aim of the study. The
background should be 4-5 paragraphs long and each paragraph should be
between 3-5 sentences. Strive to make the paragraphs about the same
length.* -->

*bibliography.bib includes an example reference. Add additional
references in that file as bibtex entries and cite as
[@Courvoisier2011].*

<!--*bmcemerg.csl is a citation style language file that governs how 
citations and the reference list will be formatted. Leave as it is.* -->

Methods
=======

## Source of data

<!-- 
4a) Describe the study design or source of data (e.g., randomized trial, cohort, or
registry data), separately for the development and validation data sets, if applicable
4b) Specify the key study dates, including start of accrual; end of accrual; and, if
applicable, end of follow-up. 

This study involved an analysis of the observational cohort Towards Improved Trauma Care Outcomes in India (TITCO), for which data were collected before the conception of this study. Ethics committees at all participating centres approved the collation of the database and granted a waiver of consent for patients with trauma (Lokmanya Tilak Municipal General Hospital, IEC/11/13; King Edward Memorial Hospital, IEC(I)/OUT/222/14; Seth Sukhlal Karnani Memorial Hospital, IEC/279; All‐India Institute of Medical Sciences, IEC/NP‐279/2013 RP‐01/2013). The study was conducted using anonymized data, and was registered at ClinicalTrials.gov (NCT03069755) before the research was undertaken.

-->
For this paper a retrospective analysis of the observational cohort Towards Improved Trauma Care Outcomes in India(TITOC) was performed. The data for TITOC was collected during july 2013 to december 2015 and contains patients admitted due to trauma to one of the four public univeristy hospitals enrolled in the database. __What should i write about Ethics permits? should i name the different hospitals? give reasons for their inclusion in the TITOC?__


## Participants
<!-- 
5a) Specify key elements of the study setting (e.g., primary care, secondary care,
general population) including number and location of centres. [D;V]
5b) Describe eligibility criteria for participants. [D;V]
5c) Give details of treatments received, if relevant.  [D;V] NOT RELEVANT?
Patients included in the TITCO cohort were those presenting to one of the participating centres with traumatic injury following a transport accident, fall, assault, self‐harm or burn, and who were alive on arrival and admitted to the hospital for treatment. Patients with an isolated limb injury were excluded from the database as such patients are treated by orthopaedic surgeons and not within trauma care pathway, which comprises a first survey done by a surgical resident with an on‐call consultant surgeon and subsequent observation or surgery. Patients from the TITCO cohort who were aged 15 years or older and underwent surgical intervention within 24 h of arrival were included in this study.
-->

The TITOC cohort include patients admitted for treatment to one of the participating hospitals with traumatic injury, for example due to a transport accident, assult, fall or burns. Patients with isolated injurys to limbs and that therefore were treated by orthopaedics and not within the general trauma care were excluded from the database. __Do i have any further exclussion criteria? age? type of injury?__     


## Outcome
<!--
6a) Clearly define the outcome that is predicted by the prediction model, including how
and when assessed. [D;V]
6b) Report any actions to blind assessment of the outcome to be predicted. [D;V] NOT RELEVANT?
-->
The primary outcome of interest was admission to the ICU during hospitalization and treatment as reported in the TITOC cohort. __Any secondary outcomes?__


## Predictors
<!--
7a) Clearly define all predictors used in developing or validating the multivariable
prediction model, including how and when they were measured. [D;V]
7b) Report any actions to blind assessment of predictors for the outcome and other
predictors. [D;V]
-->
For each patient included in the study the qSOFA score was calculated using data meassured opon arrival to the hospital. The calculation of the qSOFA score includes the respiratory rate above 22, GCS below 15 and a systolic blood preassure below 100 where one point is awarded for meeting each of the specified criterias and thus yields a score of 0 to 3. __Any other predictors we should look at? anything regarding blind assessment?__

## Sample size
8) Explain how the study size was arrived at [D;V]
__No idea?__

## Missing data
<!--
9) Describe how missing data were handled (e.g., complete-case analysis, single
imputation, multiple imputation) with details of any imputation method. [D;V]
-->
To adress missing data multiple imputation was used. __How specific should this description be? should there be an explanation on how many regressions where used and the size of the random samples yielding the regressions? programs used? Are there any protocols thats usualy used that i can refer to? i know roughly what multiple imputation is but no idea how to implement it...__ 


## Statistical analysis methods
<!--
10c. For validation, describe how the predictions were calculated. [V]
10d) Specify all measures used to assess model performance and, if relevant, to
compare multiple models [D;V]
10e. Describe any model updating (for example, recalibration) arising from the validation, if done. [V]
-->

__okey i'm lost. something about predictive performance as written in the PPF but no idea how to explain nor implement it...__


<!-- Go ahead and add the TRIPOD subheadings. Read for example https://bjssjournals.onlinelibrary.wiley.com/doi/abs/10.1002/bjs.10862 for a description of the cohort-->

Från PPF "This will be a retrospective analysis of a cohort of trauma patients admitted to four public university hospitals in urban India between 2013 and 2015. The complete cohort includes 16 000 patients. The primary outcome will be ICU admission. The predictors included in qSOFA are respiratory rate, Glasgow coma scale, and systolic blood pressure. Validity will be assessed in terms of predictive performance, which in turn will be measures as discrimination and calibration. Calibration will further be visualised using calibration plots. An optimal cutoff will be identified using the Youden index and sensitivity, specificity, precision, recall, positive and negative predictive values will assessed at this cutoff. The original model will finally be compared to a updated model, using the same predictive performance measures. Updating will be performed using logistic regression. Bootstrapping will be used to estimate 95% confidence intervals associated with point estimates. Missing data will be handled using multiple imputation. "


<!--*Refer to the appropriate reporting guideline for details. If you are
developing, updating or validating a clinical prediction model then
use
[TRIPOD](https://www.equator-network.org/reporting-guidelines/tripod-statement/). If
you are conducting an observational study, for example a cohort or
case control study in which you assess associations between some
exposure and an outcome then use
[STROBE](https://www.equator-network.org/reporting-guidelines/strobe/).*-->
