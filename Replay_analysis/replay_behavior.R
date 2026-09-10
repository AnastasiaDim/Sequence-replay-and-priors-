# REPLAY VISUAL VS MOTOR --------------------------------------------------
library(ggplot2);library(dplyr); require(dplyr); require(rstatix); library(readxl) ; library(lsr) ;library(viridis)
library(patchwork) ; library(lme4) ;library(ggsignif); library(lmerTest)
library(tidyverse)
library(lme4)
library(emmeans)


visual <- read_excel("C:/Users/asus/Desktop/Post_doc/Replay_paper/final_revision/sequenceness_results_lag05NN.xlsx")
motor <- read_excel("C:/Users/asus/Desktop/Post_doc/Replay_paper/final_revision/sequenceness_results_lag08MM.xlsx")

# Add modality labels and combine the datasets
motor_long <- motor %>%
  pivot_longer(
    cols = -c(Subject, Group),
    names_to = "Condition",
    values_to = "Replay"
  ) %>%
  mutate(Modality = "Motor")

visual_long <- visual %>%
  pivot_longer(
    cols = -c(Subject, Group),
    names_to = "Condition",
    values_to = "Replay"
  ) %>%
  mutate(Modality = "Visual")

dat <- bind_rows(motor_long, visual_long) %>%
  separate(
    Condition,
    into = c("Direction", "State"),
    sep = "_",
    remove = FALSE
  )

dat


make_long <- function(df, modality) {
  
  df %>%
    pivot_longer(
      cols = -c(Subject, Group),
      names_to = c("Direction", "RestPeriod"),
      names_pattern = "^(Fwd|Bwd)_(.*)$",
      values_to = "Replay"
    ) %>%
    mutate(
      Modality = modality,
      
      Direction = factor(
        Direction,
        levels = c("Fwd", "Bwd"),
        labels = c("Forward", "Backward")
      ),
      
      RestPeriod = factor(
        RestPeriod,
        levels = c(
          "Before",
          "Rest1",
          "Rest2",
          "Rest3",
          "Rest4",
          "Rest5",
          "After"
        )
      ),
      
      Subject = factor(Subject),
      Group = factor(Group)
    )
}

dat <- bind_rows(
  make_long(motor, "Motor"),
  make_long(visual, "Visual")
) %>%
  mutate(
    Modality = factor(
      Modality,
      levels = c("Motor", "Visual")
    )
  )

glimpse(dat)


model <- lmer(
  Replay ~ Modality * RestPeriod + Direction +
    (1 + Modality | Subject),
  data = dat,
  REML = TRUE
)


anova(model)
summary(model)


# REPLAY AND BEHAVIOUR -------------------------------------------------

##SLOPE

replay <- read_excel("C:/Users/asus/Desktop/Post_doc/Replay_paper/final_revision/sequenceness_results_lag05NN.xlsx")
slope_df1 <- readRDS("C:/Users/asus/Desktop/Post_doc/Replay_paper/final_revision/slope_df1.rds")
slope_df1 <- slope_df1 %>%
  arrange(Subject) %>%
  mutate(Subject = row_number())

####tryign to predict slope by replay 

df = replay %>% left_join(
  slope_df1 %>% select(Subject,Slope),
  by = "Subject"
)

head(df)

# Calculate midpoint (median of Slope)
md <- median(df$Slope, na.rm = TRUE)

# Forward Rest 1 vs Slope
p1 <- ggplot(df, aes(x = Slope, y = Fwd_Rest1, colour = Slope)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = md
  ) +
  labs(
    x = "Slope",
    y = "Forward Rest 1",
    colour = "Slope"
  ) +
  theme_bw()

# Backward Rest 1 vs Slope
p2 <- ggplot(df, aes(x = Slope, y = Bwd_Rest1, colour = Slope)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = md
  ) +
  labs(
    x = "Slope",
    y = "Backward Rest 1",
    colour = "Slope"
  ) +
  theme_classic()

# Display side-by-side
p1 + p2

md <- median(df$Slope, na.rm = TRUE)

# Calculate overall mean across Rest 1-5
df_plot <- df %>%
  mutate(
    Fwd_Mean = rowMeans(select(., Fwd_Rest1:Fwd_Rest5), na.rm = TRUE),
    Bwd_Mean = rowMeans(select(., Bwd_Rest1:Bwd_Rest5), na.rm = TRUE)
  )

# Forward mean vs Slope
p1 <- ggplot(df_plot, aes(x = Slope, y = Fwd_Mean, colour = Slope)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = md
  ) +
  labs(
    x = "Slope",
    y = "Mean Forward (Rest 1-5)",
    colour = "Slope"
  ) +
  theme_classic()

# Backward mean vs Slope
p2 <- ggplot(df_plot, aes(x = Slope, y = Bwd_Mean, colour = Slope)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = md
  ) +
  labs(
    x = "Slope",
    y = "Mean Backward (Rest 1-5)",
    colour = "Slope"
  ) +
  theme_bw()
ggsave("replay_meanfor.png", p2, 
       width = 4, height = 5, units = "in", dpi = 600)


# Show together
p1 + p2

model = lm(Slope~Fwd_Mean,data=df_plot)
summary(model)
anova(model)


df_long <- df_plot %>%
  pivot_longer(
    cols = starts_with("Fwd_Rest"),
    names_to = "Rest",
    values_to = "Response"
  )

model <- lm(
  Slope ~ Response * Rest,
  data = df_long
)

summary(model)
anova(model)


# REPLAY AND BEHAVIOUR----------------------------------------------

#Load and summarize data  ------------------------------------------------
setwd("C:/Users/asus/Desktop/PhD/ONGOING_PROJECTS/BEHAVIOUR")

datax = read_excel("EEG_BEHAVIOURAL/EEG_Behavioural/RTS_final/FINAL_GENERAL_RAW_RTS.xlsx")

#from the EEG analysis we exclude subjects 10 (noisy),41 (missed triggers), and 29(noisy)
participants_to_remove <- c(10, 41, 29)

# Filter out rows with participant IDs to remove
data_fil <- datax %>%
  filter(!Participant %in% participants_to_remove) %>%
  mutate(Participant_order = as.numeric(as.factor(Participant)))

block_order2 = rep(c(rep(1,80),rep(2,80),rep(3,80),rep(4,80,),rep(5,80),rep(6,80),rep(7,80),rep(8,80)))   
block_order = rep(block_order2,40)


data_fil$block_order =block_order

X2<- data_fil %>%
  filter(Image != "scrambled" & accuracy_offline==1 & ResponseTime>80)

mean_block_rts <- X2 %>%
  group_by(Participant_order, Block,block_order) %>%
  summarise(mean_rts = median(ResponseTime), .groups = "drop")


baseline_df <- mean_block_rts %>%
  filter(Block == 1) %>%
  select(Participant_order, baseline_rt = mean_rts)


analysis_df <- mean_block_rts %>%
  left_join(baseline_df, by = "Participant_order") %>%
  mutate(gain_score = mean_rts - baseline_rt) %>%
  arrange(Participant_order, block_order)
#up to here gain scor across all blokcs and partciapnts 
ggplot(data = analysis_df, aes(x = Block, y = gain_score, fill = Block)) + 
  geom_col() +  # Use geom_col() to use the given score values
  theme_bw()





first_two_blocks <- analysis_df %>%
  group_by(Participant_order) %>%
  slice(1:2) %>%
  mutate(Time = c("Before", "After")) %>%
  ungroup()

next_blocks <- analysis_df %>%
  group_by(Participant_order) %>%
  slice(3:4) %>%
  mutate(Time = c("Before", "After")) %>%
  ungroup()

next_blocks2 <- analysis_df %>%
  group_by(Participant_order) %>%
  slice(5:6) %>%
  mutate(Time = c("Before", "After")) %>%
  ungroup()

next_blocks3 <- analysis_df %>%
  group_by(Participant_order) %>%
  slice(6:7) %>%
  mutate(Time = c("Before", "After")) %>%
  ungroup()



first_two_blocks <- first_two_blocks %>%
  mutate(Block_Pair = "1_2")

next_blocks <- next_blocks %>%
  mutate(Block_Pair = "3_4")

next_blocks2 <- next_blocks2 %>%
  mutate(Block_Pair = "5_6")

next_blocks3 <- next_blocks3 %>%
  mutate(Block_Pair = "6_7")

all_blocks <- bind_rows(
  first_two_blocks,
  next_blocks,
  next_blocks2,
  next_blocks3
)
df_plot2 <- all_blocks %>%
  left_join(replay, by = c("Participant_order"="Subject" ))

head(df_plot2)




# Average of Rest1-4

df_avg <- df_plot2 %>%
  mutate(
    Mean_Rest = rowMeans(select(., Bwd_Rest1:Bwd_Rest4), na.rm = TRUE)
  )

md <- median(df_avg$gain_score, na.rm = TRUE)

ggplot(df_avg,
       aes(x = gain_score ,
           y = Mean_Rest,
           colour = gain_score)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +
  facet_wrap(~Time) +
  theme_bw() +
  labs(
    y = "Mean Backward (Rest 1-4)",
    x = "Mean Gain Score"
  ) +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = md
  )












rest_df <- bind_rows(
  
  df_plot2 %>%
    filter(Block_Pair == "1_2") %>%
    transmute(Participant_order, Time,
              Rest = "Rest 1",
              Replay = Bwd_Rest1,
              gain_score),
  
  df_plot2 %>%
    filter(Block_Pair == "3_4") %>%
    transmute(Participant_order, Time,
              Rest = "Rest 2",
              Replay = Bwd_Rest2,
              gain_score),
  
  df_plot2 %>%
    filter(Block_Pair == "5_6") %>%
    transmute(Participant_order, Time,
              Rest = "Rest 3",
              Replay = Bwd_Rest3,
              gain_score),
  
  df_plot2 %>%
    filter(Block_Pair == "6_7") %>%
    transmute(Participant_order, Time,
              Rest = "Rest 4",
              Replay = Bwd_Rest4,
              gain_score)
)

md <- median(rest_df$gain_score, na.rm = TRUE)



ggplot(df_avg,
       aes(x = gain_score,
           y = Mean_Rest,
           colour = gain_score)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +
  facet_wrap(~Time) +
  
  theme_bw() +
  labs(
    x = "Mean Gain Score",
    y = "Mean Forward (Rest 1-4)"
  ) +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = median(df_avg$gain_score, na.rm = TRUE)
  )




ggplot(rest_df,
       aes(x = gain_score ,
           y = Replay,
           colour = gain_score)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +
  facet_grid(Time ~ Rest) +
  theme_bw() +
  labs(
    y = "Backward Resting State",
    x = "Mean Gain Score"
  ) +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = md
  )

mod_avg <- lm(gain_score ~ Mean_Rest * Time, data = df_avg)

summary(mod_avg)
rest3_df <- rest_df %>%
  filter(Rest == "Rest 3") %>%
  mutate(Time = factor(Time, levels = c("Before", "After")))


ggplot(rest3_df,
       aes(x = gain_score,
           y = Replay,
           colour = gain_score)) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = TRUE, colour = "black") +

  facet_wrap(~Time, nrow = 1) +
  theme_bw() +
  labs(
    y = "Backward Resting State",
    x = "Mean Gain Score"
  ) +
  scale_colour_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = md
  )



rest3 <- df_plot2 %>%
  filter(Block_Pair == "5_6")

before <- rest3 %>%
  filter(Time == "Before")

after <- rest3 %>%
  filter(Time == "After")

summary(lm(gain_score ~ Bwd_Rest3, data = before))
summary(lm(gain_score ~ Bwd_Rest3, data = after))



