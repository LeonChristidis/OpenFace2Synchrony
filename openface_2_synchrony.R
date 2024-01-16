###### packages ######

# run this code to install and load all packages

if (!require("pacman")) install.packages("pacman")
pacman::p_load(rio, foreach, doParallel, ggplot2, dplyr, data.table, ggpubr, scales, install = T)

###### import the data ######

# save your file path in face_path
face_path <- "C:/.../folder"

# data will be saved in a list of data frames making it easier to apply functions to all dyads without the need of a giant data frame
# "recursive" means "thorugh folders" -> if OpenFace data is stored in different subfolders, set this to TRUE
# if 2 people are in the same data, change column names accordingly
# here::here overcomes issues with working directory -> R file do not need to be in the same folder as openface output files
# dir_ls lists directories in which fread is applied (fread is much faster than read.csv)

all_data <-
  here::here(face_path) %>%
  fs::dir_ls(glob = "*.csv" , recursive = T) %>% 
  purrr::map(~ data.table::fread(.x, select = c("frame", 
                                                "timestamp", 
                                                "confidence", 
                                                "pose_Rx", 
                                                "pose_Ry", 
                                                "pose_Rz", 
                                                "pose_Tx", 
                                                "pose_Ty", 
                                                "pose_Tz")), .id = "source")

# the following code assumes that each data frame has names like [case_number]_patient and [case_number]_therapist

###### check video length ######

# if an error happens while splitting the videos, there may end up having unequal lengths

# get unique case numbers if patient and therapist files are separated and still have the same case number
cases <- gsub("\\D", "", names(all_data)) %>% unique()

# create empty list
overview <- NULL

for (case in cases) {
  
  # store both case files in a list
  c_list <- all_data[grep(paste(case),names(all_data))]
  
  # measure their lengths
  comp <- sapply(c_list, nrow)
  
  if (comp[[1]] != comp[[2]]) {
    
    # if lengths is not equal store name and values in a data frame
    mid <- data.frame(file = names(comp),
                      frames = as.numeric(comp))
    
    # create an overview by binding them
    overview <- rbind(overview, mid)
    
  }
  
  # remove after every iteration
  rm(c_list)
  rm(comp)
  rm(mid)
  
}

# add case number and calculate difference in length
overview <- overview %>% mutate(case = gsub("\\D", "", file)) %>% group_by(case) %>% 
  mutate(diff=abs(frames-lag(frames,default=first(frames))))

# export
rio::export(overview, "overview_different_framecount.xlsx")

# if some of the data is not aligned drop these cases to continue working
drop_cases_temp <- grep(paste(unique(overview$case), collapse='|'),names(all_data))

# drop the cases
all_data[drop_cases_temp] <- NULL

##### calculate mean video length ####

# create empty vector
mean_vec <- vector("numeric")

for (i in 1:length(all_data)) {
  
  # store length of each data frame in a vector
  mean_vec[i] <- as.numeric(length(all_data[[i]]$frame))
  
}

# mean video lengths in frames
mean(mean_vec)

# mean lengths in minutes
mean(mean_vec)/25/60
sd(mean_vec)/25/60

##### calculate Euclidean distances #####

# modified OpenDBM function to calculate head movement based on rotation angles (Rx, Ry, Rz)
# head_pose_dist function at: https://github.com/AiCure/open_dbm/blob/master/opendbm/dbm_lib/dbm_features/raw_features/movement/head_motion.py

head_pose_dist <- function(of_results) {
  
  # Compute head pose distance frame by frame
  
  # Initialize lists to store distance and error values
  distance_list <- c()
  error_list <- c()
  
  # Loop through rows of of_results dataframe
  for (index in 1:nrow(of_results)) {
    dst <- NA  # Initialize dst as NA
    
    # Check if index is 1 or confidence < 0.2
    if (index > 1 &&
        (as.numeric(of_results$confidence[index]) >= 0.95 && 
         as.numeric(of_results$confidence[index - 1]) >= 0.95)) {
      point_x <- c(
        as.numeric(of_results$pose_Rx[index - 1]),
        as.numeric(of_results$pose_Ry[index - 1]),
        as.numeric(of_results$pose_Rz[index - 1])
      )
      point_y <- c(
        as.numeric(of_results$pose_Rx[index]),
        as.numeric(of_results$pose_Ry[index]),
        as.numeric(of_results$pose_Rz[index])
      )
      
      # Calculate Euclidean distance using tryCatch
      tryCatch({
        dst <- sqrt(sum((point_x - point_y)^2))  # Calculate Euclidean distance
      }, error = function(e) {
        cat("Exception met on head_pose_dist method:", e$message, "\n")
      })
      
      distance_list <- c(distance_list, abs(dst))
      error_list <- c(error_list, "Pass")
    } else {
      # If confidence conditions are not met, append NA to distance_list
      distance_list <- c(distance_list, dst)
      
      if (as.numeric(of_results$confidence[index]) < 0.9) {
        error_list <- c(error_list, "confidence less than 90%")
      } else {
        error_list <- c(error_list, "confidence less than 90% in the previous frame")
      }
    }
  }
  
  # Return the lists of distances and error values
  return(distance_list)
}

head_pose_vel <- function(of_results) {
  # Compute head pose distance frame by frame
  
  # Initialize lists to store distance and error values
  distance_list <- c()
  error_list <- c()
  
  # Loop through rows of of_results dataframe
  for (index in 1:nrow(of_results)) {
    dst <- NA  # Initialize dst as NA
    
    # Check if index is 1 or confidence < 0.2
    if (index > 1 &&
        (as.numeric(of_results$confidence[index]) >= 0.95 && 
         as.numeric(of_results$confidence[index - 1]) >= 0.95)) {
      point_x <- c(
        as.numeric(of_results$pose_Tx[index - 1]),
        as.numeric(of_results$pose_Ty[index - 1]),
        as.numeric(of_results$pose_Tz[index - 1])
      )
      point_y <- c(
        as.numeric(of_results$pose_Tx[index]),
        as.numeric(of_results$pose_Ty[index]),
        as.numeric(of_results$pose_Tz[index])
      )
      
      # Calculate Euclidean distance using tryCatch
      tryCatch({
        dst <- sqrt(sum((point_x - point_y)^2))  # Calculate Euclidean distance
      }, error = function(e) {
        cat("Exception met on head_pose_dist method:", e$message, "\n")
      })
      
      distance_list <- c(distance_list, abs(dst))
      error_list <- c(error_list, "Pass")
    } else {
      # If confidence conditions are not met, append NA to distance_list
      distance_list <- c(distance_list, dst)
      
      if (as.numeric(of_results$confidence[index]) < 0.9) {
        error_list <- c(error_list, "confidence less than 90%")
      } else {
        error_list <- c(error_list, "confidence less than 90% in the previous frame")
      }
    }
  }
  
  # Return the lists of distances and error values
  return(distance_list)
}

##### apply function #####

# Define a function to process each data frame

process_data <- function(df) {
  
  df[,"dist"] <- head_pose_dist(df)
  df[,"vel"] <- head_pose_vel(df)
  return(df)
}

# ATTENTION: this parallel processing is for WINDOWS systems only! 
# Apple and UNIX systems have to apply it differently or use a normal for loop
# parallel processing cuts processing time at least in half

# detect cores of CPU
cores=detectCores(logical = FALSE)

# make a cluster
cl <- makeCluster(cores[1]-1)

# register the cluster
registerDoParallel(cl)

# check of cluster available and how many cores
foreach::getDoParRegistered()
foreach::getDoParWorkers()

# Use foreach to apply the function to each data frame in parallel
result_list <- foreach(k = 1:length(all_data)) %dopar% {
  
  # calculate distances
  df <- process_data(all_data[[k]])
  
  return(df)
}

# get original names
names(result_list) <- names(all_data)

# override original data
all_data <- result_list

# remove output list
rm(result_list)

# Stop the parallel backend
stopCluster(cl)

# save data locally in an Rdata file to ensure you do not have to run the loop again
save(all_data, file = "all_data_dist_vel.Rdata")

# load("all_data.Rdata")

# remove unnecessary variables

for (dyad in seq_along(all_data)) {
  
  # store name
  name <- paste(names(all_data[dyad]))
  # select important variables
  all_data[[dyad]] <- dplyr::select(all_data[[dyad]], !starts_with("pose"))
  # attach old name
  names(all_data)[dyad] <- paste(name)
  
}

##### bind dyads together ######

# define function

bind_dyad <- function(all_data) {
  
  # create empty list
  new_list <- list()
  
  for (t in 1:length(all_data)) {
    
    # look for the word "Patient" in data frame names
    if (grepl("Patient", names(all_data)[t])) {
      
      # create new data frame name case_[case number]
      case_name <- paste0("case_", substr(names(all_data[t]), 1, 3))
      
      # join patient and therapist together according to matching case number
      result <- data.table(
        full_join(
          all_data[[t]],
          all_data[[paste0(substr(names(all_data[t]), 1, 3), "_Therapist")]],
          by = c("frame"),
          keep = TRUE,
          suffix = c("_patient", "_therapist")
        )
      )
      
      # Store the result in the new_list along with its name
      new_list[[case_name]] <- result
    }
  }
  
  # Remove any NULL values in the list (from iterations where if clause was not met, idk it works)
  new_list <- new_list[!sapply(new_list, is.null)]
  
  return(new_list)
}

# actually bind them together
case_list <- bind_dyad(all_data)

##### structure for MatLab Synchrony Code (Altmann, 2013) #####

# 1. column ME Rotation Angle Person A (patient)
# 2. column ME Rotation Angle Person B (therapist)
# 3. column 0 dummy values
# 4. column 0 dummy values
# 5. column ME Translation Person A
# 6. column ME Translation Angle Person B

# use uwe_list to continue operations, use case_list for visualization purposes
uwe_list <- case_list

for (j in 1:length(uwe_list)) {
  
  # select "ROIs" (dist, vel)
  uwe_list[[j]] <- dplyr::select(uwe_list[[j]], !contains("pose") & !contains("frame") & !contains("timestamp") & !contains("confidence"))
  
  # filter frames in which movement is physiological possible, 0.2 equals 286°/second in rotation
  uwe_list[[j]] <- dplyr::mutate(uwe_list[[j]], 
                                 dist_patient = ifelse(dist_patient > 0.2, NA, dist_patient),
                                 dist_therapist = ifelse(dist_therapist > 0.2, NA, dist_therapist))
  
  
  
  # select ROIs
  uwe_list[[j]] <- dplyr::mutate(uwe_list[[j]],dummy1 = rep(0, nrow(uwe_list[[j]])), 
                                 dummy2 = rep(0, nrow(uwe_list[[j]]))) %>%
    dplyr::select(starts_with("dist"), dummy1, dummy2, starts_with("vel"))
}

##### export data ######

# detect cores
cores=detectCores(logical = FALSE)

# make a cluster
cl <- makeCluster(cores[1]-1)

# register the cluster
registerDoParallel(cl)

foreach(df = names(uwe_list)) %dopar% {
  
  # define file path (leave "df" where it is), use "_mm_lt" as an identifier for Altmann's MatLab code
  file_path <- paste0("E:/openface_files/mea_data_uwe/", df, "_mm_lt.txt")
  
  # export data
  write.table(
    uwe_list[[df]], 
    sep = " ", 
    row.names = FALSE,
    col.names = FALSE,
    na = "NaN", # MatLab needs NaN values
    file = file_path
  )
  
}

# Stop the parallel backend
stopCluster(cl)

###### example visualization patient and therapist #####

# exclude variables you do not need
for (j in 1:length(case_list)) {
  
  # select "ROIs" (dist, vel)
  case_list[[j]] <- dplyr::select(case_list[[j]], !contains("pose") & !contains("timestamp"))
  
}

# long format for ggplot2
example_vis <- case_list[[1]] %>% pivot_longer(cols = c(3,4,6,7), names_to = "variable", values_to = "motion") %>% 
  mutate(person = ifelse(grepl("patient", variable), "patient", "therapist"), 
         type = ifelse(grepl("dist", variable), "rotation", "translation"))

# plot
example_vis %>% filter(frame >= 20000 & frame <= 20200, type == "rotation") %>% 
  ggplot(aes(x = frame, y = motion, color = person)) + 
  geom_line() + apatheme + 
  labs(title = "Exemplary Patient Therapist Movement Association over 8 seconds") + 
  theme(axis.line.x.top = element_blank(), 
        axis.ticks.x.top = element_blank(),
        axis.text.x.top = element_blank(),
        legend.position = "top") + scale_colour_manual(values = c("#00929C","#D53031"))



# Author: Leon Christidis (DFKI)
# Contributors: Uwe Altmann (MSB), Philipp Müller (DFKI), Mina Ameli (DFKI), Fabrizio Nunnari (DFKI), Janet Wessler (DFKI)