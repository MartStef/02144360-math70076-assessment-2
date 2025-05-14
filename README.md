---
title: "README"
output: html_document
---

Aim of project - to build a reliable CNN model for image classification.
This model will be trained and tested on the Stanford car data set 
(you can find more information in [metadata.txt] (./data/raw/metadata.txt))

It is recommended that the user uses the latest version of RStudio and R version
of 4.4.3 or above

For this project, we work with torch and torchvision packages,
which should be installed as follows (in the Console):
install.packages("torch")
install.packages("torchvision")

library(torch)
library(torchvision)

torch::install_torch()

The code and analyses are structured as follows:

## data/

This directory contains all raw and derived data sets.
Since the raw data set is quite large (2GB), the user can find instructions 
on how to download it in [metadata.txt] (./data/raw/metadata.txt).

The user can find the derived data in this folder, which contains train and validation sets
on 50 of the 196 classes (chosen at random). These data sets are used to train and evaluate
the models we build in order to aid fast training times and reproducability.

## src/

This directory contains the source code of the project.

 - src/download-data.R contains the code needed to download the raw data locally
 
 - src/data-manipulation.R contains the code needed to get the derived data
 
## analyses/

This directory contains the codes to implement the two CNN models and to create all plots 
used in the Report.

## outputs/

This directory contains the png files of all plots used in the Report.

## reports/

This directory contains Rmd, PDF, and HTML files of the Report, which summarizes the
findings of this small study.

 
 
 
 
 
 
 
 