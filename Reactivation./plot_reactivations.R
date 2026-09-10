# REACTIVATIONS-----------------------------------------------------------
library(ggplot2);library(dplyr); require(dplyr); require(rstatix); library(readxl) ; library(lsr) ;library(viridis)
library(patchwork) ; library(lme4) ;library(ggsignif); library(lmerTest)
library(tidyverse)
library(lme4)
library(emmeans)


datax <- read_excel("C:/Users/asus/Desktop/Post_doc/Replay_paper/final_revision/allegati/new/df_avg_visual_reacvtication_state_specific.xlsx")

head(datax)

datax_avg =  datax %>%
  group_by(Participant_ID,Condition,State) %>%
  summarise(mean_rts = mean(`Mean Reactivation Strength`)) %>%
  ungroup()

datax_avg$Condition <- factor(
  datax_avg$Condition,
  levels = c("REST_PRE","Rest_1min","Rest_2min","Rest_3min","Rest_4min","Rest_5min", "REST_POST")
)
# Average across participants for plotting
plot_data <- datax_avg %>%
  group_by(Condition, State) %>%
  summarise(
    n = n(),
    sd_rts = sd(mean_rts),
    mean_rts = mean(mean_rts),
    .groups = "drop"
  ) %>%
  mutate(
    se = sd_rts / sqrt(n),
    ymin = mean_rts - se,
    ymax = mean_rts + se
  )
state_colors <- c(
  "Scene"     = "#2166AC",
  "Tool"      = "#4393C3",
  "Face"      = "#D6604D",
  "Body"      = "#B2182B",
  "Scrambled" = "#572949"
)

fig1=ggplot(
  plot_data,
  aes(
    x = Condition,
    y = mean_rts,
    group = State,
    colour = State
  )
) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  theme_bw() +
  labs(
    x = "Condition",
    y = "Average Reactivation",
    colour = "State"
  ) + 
  theme(
    
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(linewidth = 1),
    text = element_text(size = 20, family = "sans"),
    axis.text.x = element_text(angle = 30, hjust = 1, size = 14)
  ) +
  scale_color_manual(
    values =c(
      "Scene"     = "#2166AC",
      "Tool"      = "#4393C3",
      "Face"      = "#D6604D",
      "Body"      = "#B2182B",
      "Scrambled" = "#572949"
    )
  )



datax_avg <- datax %>%
  group_by(Participant_ID, Condition, State) %>%
  summarise(
    mean_rts = mean(`Mean Reactivation Strength`, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Participant_ID = factor(Participant_ID),
    
    Condition = factor(
      Condition,
      levels = c(
        "REST_PRE",
        "Rest_1min",
        "Rest_2min",
        "Rest_3min",
        "Rest_4min",
        "Rest_5min",
        "REST_POST"
      )
    ),
    
    State = factor(
      State,
      levels = c(
        "Scene",
        "Tool",
        "Face",
        "Body",
        "Scrambled"
      )
    )
  )

datax_avg <- datax_avg %>%
  mutate(
    Time = case_when(
      Condition == "REST_PRE"  ~ 0,
      Condition == "Rest_1min" ~ 1,
      Condition == "Rest_2min" ~ 2,
      Condition == "Rest_3min" ~ 3,
      Condition == "Rest_4min" ~ 4,
      Condition == "Rest_5min" ~ 5,
      Condition == "REST_POST" ~ 6
    )
  )


model2 <- lmer(
  mean_rts ~ Time * State +
    (1 + Time | Participant_ID),
  data = datax_avg,
  REML = TRUE
)
anova(model2)
summary(model)

# ============================================================
# Overall reactivation across rest, irrespective of state
# ============================================================

overall_reactivation <- datax_avg %>%
  group_by(Participant_ID, Condition) %>%
  summarise(
    mean_reactivation = mean(mean_rts, na.rm = TRUE),
    .groups = "drop"
  )

# Boxplot
fig2 <- ggplot(
  overall_reactivation,
  aes(
    x = Condition,
    y = mean_reactivation
  )
) +
  geom_boxplot(
    width = 0.6,
    outlier.shape = NA
  ) +
  geom_jitter(
    width = 0.12,
    size = 2,
    alpha = 0.6
  ) +
  theme_bw() +
  labs(
    x = "Condition",
    y = "Average Reactivation"
  ) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(linewidth = 1),
    text = element_text(size = 20, family = "sans"),
    axis.text.x = element_text(
      angle = 30,
      hjust = 1,
      size = 14
    )
  )

fig2

