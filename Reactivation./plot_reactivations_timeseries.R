library(R.matlab)
library(dplyr)
library(ggplot2)
library(tidyr)


# ============================================================
# 1. Find all participant .mat files
# ============================================================
#choose directory with the files either the visual one or the motor ones 

setwd("C:/Users/asus/Desktop/Post_doc/Replay_paper/First_revision/Results-20251008T084157Z-1-001/Results/visual/rest1eo_mask/preds")
files <- list.files(
  pattern = "\\.mat$",
  full.names = TRUE
)

# Optional: see which files were found
files


# ============================================================
# 2. Load each participant
# ============================================================

all_data <- lapply(files, function(f) {
  
  # Load .mat file
  mat <- readMat(f)
  
  # Extract predictions
  file <- mat$preds.mask
  
  # Make sure it is a matrix
  file <- as.matrix(file)
  
  # ----------------------------------------------------------
  # Keep maximum 30,000 time points
  # If participant has fewer than 30,000, use all available
  # ----------------------------------------------------------
  
  n_time <- min(nrow(file), 30000)
  
  file <- file[1:n_time, ]
  
  # ----------------------------------------------------------
  # Make a data frame
  # ----------------------------------------------------------
  
  df <- data.frame(
    Time = 1:n_time,
    Face = file[, 1],
    Scene = file[, 2],
    Body = file[, 3],
    Tool = file[, 4],
    Scrambled = file[, 5]
  )
  
  # Participant ID from filename
  df$Participant <- basename(f)
  
  return(df)
})


# ============================================================
# 3. Combine everyone into one data frame
# ============================================================

all_data <- bind_rows(all_data)

head(all_data)
dim(all_data)


# ============================================================
# 4. Average across time points for each participant
# ============================================================
#
# This gives you ONE mean value per participant for each state.
#

participant_means <- all_data %>%
  group_by(Participant) %>%
  summarise(
    Face = mean(Face, na.rm = TRUE),
    Scene = mean(Scene, na.rm = TRUE),
    Body = mean(Body, na.rm = TRUE),
    Tool = mean(Tool, na.rm = TRUE),
    Scrambled = mean(Scrambled, na.rm = TRUE),
    .groups = "drop"
  )

participant_means


# ============================================================
# 5. Average across participants
# ============================================================

overall_means <- participant_means %>%
  summarise(
    Face = mean(Face, na.rm = TRUE),
    Scene = mean(Scene, na.rm = TRUE),
    Body = mean(Body, na.rm = TRUE),
    Tool = mean(Tool, na.rm = TRUE),
    Scrambled = mean(Scrambled, na.rm = TRUE)
  )

overall_means


# ============================================================
# 1. Define your time window HERE
# ============================================================

START_TIME <- 7
END_TIME   <- 8


# ============================================================
# 2. Convert time points to seconds
# ============================================================

TR_SECONDS <- 300 / 30000

all_timecourse <- all_data %>%
  mutate(
    Time_sec = (Time - 1) * TR_SECONDS
  ) %>%
  filter(
    Time_sec >= START_TIME,
    Time_sec <= END_TIME
  )


# ============================================================
# 3. Convert categories to long format
# ============================================================

all_timecourse_long <- all_timecourse %>%
  pivot_longer(
    cols = c(Face, Scene, Body, Tool, Scrambled),
    names_to = "State",
    values_to = "Reactivation"
  )


# ============================================================
# 4. Average across participants at each time point
# ============================================================

mean_timecourse <- all_timecourse_long %>%
  group_by(Time, Time_sec, State) %>%
  summarise(
    Mean_Reactivation = mean(Reactivation, na.rm = TRUE),
    SD = sd(Reactivation, na.rm = TRUE),
    N = sum(!is.na(Reactivation)),
    SE = SD / sqrt(N),
    .groups = "drop"
  )


# ============================================================
# 5. Check that we actually have data
# ============================================================

print(range(mean_timecourse$Time_sec))
print(table(mean_timecourse$State))


# ============================================================
# 6. Plot
# ============================================================

ggplot(
  mean_timecourse,
  aes(
    x = Time_sec,
    y = Mean_Reactivation,
    color = State,
    group = State
  )
) +
  
  # SEM
  geom_ribbon(
    aes(
      ymin = Mean_Reactivation - SE,
      ymax = Mean_Reactivation + SE,
      fill = State
    ),
    alpha = 0.15,
    color = NA
  ) +
  
  # Mean line
  geom_line(
    linewidth = 1.1
  ) +
  
  labs(
    x = "Time (seconds)",
    y = "Mean Reactivation Strength",
    color = "Category",
    fill = "Category",
    title = paste0(
      "Reactivation: ",
      START_TIME,
      "-",
      END_TIME,
      " seconds"
    )
  ) +
  
  theme_classic() +
  
  theme(
    text = element_text(size = 14),
    plot.title = element_text(
      hjust = 0.5,
      face = "bold"
    )
  )





# ============================================================
# 1. CHOOSE YOUR TIME WINDOW
# ============================================================

START_TIME <- 0
END_TIME   <- 1


# ============================================================
# 2. Convert time points to seconds
# ============================================================

TR_SECONDS <- 300 / 30000

all_timecourse <- all_data %>%
  mutate(
    Time_sec = (Time - 1) * TR_SECONDS
  ) %>%
  filter(
    Time_sec >= START_TIME,
    Time_sec <= END_TIME
  )


# ============================================================
# 3. Keep ONLY Face and Scene
# ============================================================

face_scene <- all_timecourse %>%
  pivot_longer(
    cols = c(Face, Scene),
    names_to = "State",
    values_to = "Reactivation"
  )


# ============================================================
# 4. Average across participants at each time point
# ============================================================

mean_face_scene <- face_scene %>%
  group_by(Time, Time_sec, State) %>%
  summarise(
    Mean_Reactivation = mean(Reactivation, na.rm = TRUE),
    SD = sd(Reactivation, na.rm = TRUE),
    N = sum(!is.na(Reactivation)),
    SE = SD / sqrt(N),
    .groups = "drop"
  )


# ============================================================
# 5. Plot Face vs Scene
# ============================================================

ggplot(
  mean_face_scene,
  aes(
    x = Time_sec,
    y = Mean_Reactivation,
    color = State,
    fill = State,
    group = State
  )
) +
  
  geom_ribbon(
    aes(
      ymin = Mean_Reactivation - SE,
      ymax = Mean_Reactivation + SE
    ),
    alpha = 0.25,
    color = NA
  ) +
  
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.2) +
  
  scale_color_manual(
    values = c(
      "Face" = "#D6604D",
      "Scene" = "#2166AC"
    ),
    labels = c(
      "Face" = "Face",
      "Scene" = "Scene"
    )
  ) +
  
  scale_fill_manual(
    values = c(
      "Face" = "#D6604D",
      "Scene" = "#2166AC"
    ),
    labels = c(
      "Face" = "Face",
      "Scene" = "Scene"
    )
  ) +
  
  labs(
    x = "Time (seconds)",
    y = "Reactivation Strength"
  ) +
  
  theme_classic() +
  
  theme(
    # Remove ALL lines
    axis.line = element_blank(),
    panel.border = element_blank(),
    panel.grid = element_blank(),
    
    # Keep normal vertical y-axis title
    axis.title.y = element_text(
      size = 14,
      angle = 90,
      color = "black"
    ),
    
    axis.title.x = element_text(
      size = 14,
      color = "black"
    ),
    
    axis.text = element_text(
      size = 12,
      color = "black"
    ),
    
    axis.ticks = element_line(
      color = "black",
      linewidth = 0.5
    ),
    
    # Legend inside
    legend.position = c(0.85, 0.85),
    legend.title = element_blank(),
    legend.text = element_text(size = 11),
    legend.background = element_blank(),
    legend.key = element_blank()
  )


