---
title: The Title of Your Study Here
subtitle: Add a Subtitle if Needed
author: Björn Lindberg
bibliography: bibliography.bib
csl: bmcemerg.csl
---

*The study plan should be 3-4 pages long and written in
[markdown](https://rmarkdown.rstudio.com/) (like this
document). Remove all comments in italic when you use this document as
a template for your own study plan.* 

__Jag har lagt källor som kommentarer i md filen för nu, fixar korrekt citering senare.__

Introduction
============

<!-- I don't think you need the subheadings in the study plan, the introduction is too short. You may want to have them in your progress report but that's up to you -->
__TRAUMA IS A GLOBAL PROBLEM AND MORE SO IN LOW INCOME REGION:__ Globally about 13% of all Disease Adjusted Life Years (DALY) lost can be attributed to trauma<!-- I prefer trauma over injuries, and define trauma as the clinical entity composed of both the injury and the body's associated response --> <!--(Global, regional, and national disability-adjusted life-years (DALYs) for 359 diseases and injuries and healthy life expectancy (HALE) for 195 countries and territories, 1990–2017: a systematic analysis for the Global Burden of Disease Study 2017, the lancet)--> And about 8% of deaths globally, or about 4.5 million deaths, was caused by trauma in 2017 <!-- Try to merge these first two sentences --> <!-- https://www.thelancet.com/lancet/visualisations/gbd-compare --> Trauma often require extensive medical treatment and sometimes admission to the ICU<!-- Spell out the first time-->. In a paper publiced 2012 Charles mock et al calculated that in 2010 90% of all deaths due to trauma and injuries was in low and middle income cuntries with much higher mortality rates compared to high income countries and that an improvement in trauma care globally to that level of high income countries could save between 1.7 and 2 million lives annually. <!-- Feels like this should come before the statement about that trauma may require ICU admission --> <!-- (An Estimate of the Number of Lives that Could be Saved through Improvements in Trauma Care Globally, World jurnal of surgery 2012) -->

__What is SOFA and qSOFA:__ One of the complications of severe injuries is a state called sepsis and septic shock. The main causes for septic shock is infection and non communicable diseases but around four percent is caused by trauma. <!-- Global, regional, and national sepsis incidence and mortality, 1990–2017: analysis for the Global Burden of Disease Study, the lancet -->  According to the third consensus definition of sepsis and septic shock sepsis is a SOFA <!-- Spell out --> score of 2 points or more and septic shock a subset of sepsis where the patient is in need of vasopressor treatment of have a serum lactate level over 2mmol/L after adequate fluid treatment. In settings where laboratory analysises can not be performed rapidly qSOFA has been developed constituting of three parts: respiratory rate of 22/min or greater, reduced GCS or systolic BP of 100 mmHg and less. A score of more than two indicates higher severity and lower expected survival.  <!--The Third International Consensus Definitions for Sepsis and Septic Shock (Sepsis-3), JAMA 2016 --> <!-- Developing a New Definition and Assessing New Clinical Criteria for Septic Shock, JAMA 2016 --> <!-- Assessment of Clinical Criteria for Sepsis, JAMA 2016 -->

__WHAT IS THE REASON FOR WRITING THIS AND THE SCOPE OF THE ARTICLE__ The, SOFA, qSOFA score has been studied and evaluated before and after the Sepsis-3 consensus definition. <!-- Has it been studied as a predictor of ICU-admission in non-septic patients in other settings?:-->But it has not yet been sufficiently studied if qSOFA is a good predictor of admission to the ICU of trauma patients in hospitals in low resource settings. In that case qSOFA could be used to direct the resourses and care to the most critically ill patients and thus save lifes in low income cuntries. <!--Källor?? samma som ovan?-->

<!-- End with the aim -->


__något mer som bör tas upp i indroduction?__

<!--*The background/introduction should summarise the scope of the problem,
what is known about the problem, what is not known, what specific
knowledge gap the study is supposed to fill and why this is
important. It should end be stating the aim of the study. The
background should be 4-5 paragraphs long and each paragraph should be
between 3-5 sentences. Strive to make the paragraphs about the same
length.* -->

<!--*bibliography.bib includes an example reference. Add additional
references in that file as bibtex entries and cite as
[@Courvoisier2011].*-->

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

-->

A retrospective analysis of a cohort study of 16 000 trauma patients admitted to four university hospitals in urban India between 2013 and 2015 that seeks to study the predictive value of qSOFA on the primary outcome of ICU admissions. 

## Participants
<!-- 
5a) Specify key elements of the study setting (e.g., primary care, secondary care,
general population) including number and location of centres. [D;V]
5b) Describe eligibility criteria for participants. [D;V]
5c) Give details of treatments received, if relevant.  [D;V]
-->


## Outcome
<!--
6a) Clearly define the outcome that is predicted by the prediction model, including how
and when assessed. [D;V]
6b) Report any actions to blind assessment of the outcome to be predicted. [D;V]
-->


## Predictors
<!--
7a) Clearly define all predictors used in developing or validating the multivariable
prediction model, including how and when they were measured. [D;V]
7b) Report any actions to blind assessment of predictors for the outcome and other
predictors. [D;V]
-->


## Sample size
<!--
8) Explain how the study size was arrived at [D;V]
-->


## Missing data
<!--
9) Describe how missing data were handled (e.g., complete-case analysis, single
imputation, multiple imputation) with details of any imputation method. [D;V]

-->


## Statistical analysis methods
<!--
10a) Describe how predictors were handled in the analyses. [D]
10b) Specify type of model, all model-building procedures (including any predictor
selection), and method for internal validation. [D]
10c. For validation, describe how the predictions were calculated. [V]
10d) Specify all measures used to assess model performance and, if relevant, to
compare multiple models [D;V]
10e. Describe any model updating (for example, recalibration) arising from the validation, if done. [V]

-->

## Risk groups
<!--
Item 11. Provide details on how risk groups were created, if done. [D;V]
-->


<!-- Go ahead and add the TRIPOD subheadings. Read for example https://bjssjournals.onlinelibrary.wiley.com/doi/abs/10.1002/bjs.10862 for a description of the cohort-->

Från PPF "This will be a retrospective analysis of a cohort of trauma patients admitted to four public university hospitals in urban India between 2013 and 2015. The complete cohort includes 16 000 patients. The primary outcome will be ICU admission. The predictors included in qSOFA are respiratory rate, Glasgow coma scale, and systolic blood pressure. Validity will be assessed in terms of predictive performance, which in turn will be measures as discrimination an calibration. Calibration will further be visualised using calibration plots. An optimal cutoff will be identified using the Youden index and sensitivity, specificity, precision, recall, positive and negative predictive values will assessed at this cutoff. The original model will finally be compared to a updated model, using the same predictive performance measures. Updating will be performed using logistic regression. Bootstrapping will be used to estimate 95% confidence intervals associated with point estimates. Missing data will be handled using multiple imputation. "


<!--*Refer to the appropriate reporting guideline for details. If you are
developing, updating or validating a clinical prediction model then
use
[TRIPOD](https://www.equator-network.org/reporting-guidelines/tripod-statement/). If
you are conducting an observational study, for example a cohort or
case control study in which you assess associations between some
exposure and an outcome then use
[STROBE](https://www.equator-network.org/reporting-guidelines/strobe/).*-->
