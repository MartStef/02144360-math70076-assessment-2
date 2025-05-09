---
title: "README"
output: html_document
---

Aim of project - to build a reliable CNN model for image classification.
This model will be trained and tested on the Stanford car data set 
(you can find more information in [metadata.txt] (./data/raw/metadata.txt))

The code and analyses are structured as follows:

## data/

This directory contains all raw and derived data sets.
Since the raw data set is quite large (2GB), the user can find instructions 
on how to download it in [metadata.txt] (./data/raw/metadata.txt).

## src/

This directory contains the source code of the project.

 - src/download-data.R contains the code needed to download the raw data locally