# OpenFace2Synchrony

## Description
This R script provides a bridge between OpenFace 2.0 outputs and subsequent nonverbal synchrony calculations either using [Altmann's (2013)](https://github.com/10101-00001) approach or rMEA [Kleinbub & Ramseyer (2020)](https://doi.org/10.1080/10503307.2020.1844334). 

The main function is based on OpenDBM's [head_pose_dist function](https://github.com/AiCure/open_dbm/blob/master/opendbm/dbm_lib/dbm_features/raw_features/movement/head_motion.py). However, the function was altered and the scope for calculation narrowed. OpenDBM’s head_post_dist function filters out frames that detect a face with a confidence of .2 or higher, the present function uses a threshold of .95 instead. Additionally, the Euclidean distance was only calculated when the frame before the current one (index-1) showed a confidence of at least .95 as well. This was done in order to avoid onset peaks of movement that resulted from erroneous calculations of the Euclidean distance based on preceding frames with low confidence ratings and therefore unreliable calculations of the head position. 
The script is written in R which may be more accessible to psychologists. It assists with the management of relativley large data sets, cuts computing times short using foreach loops and generates outputs that are usable for common synchrony calculations.

## Contributors to this project

This script was developed in close collaboration with the following researchers:

Uwe Altmann (MSB), Philipp Müller (DFKI), Mina Ameli (DFKI), Fabrizio Nunnari (DFKI), Janet Wessler (DFKI)
