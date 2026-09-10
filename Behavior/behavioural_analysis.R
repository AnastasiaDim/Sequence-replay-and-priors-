#Anastasia Dimakou - analysis for replay paper  
# Set environment ---------------------------------------------------------
rm(list=ls()); graphics.off()
library(ggplot2);library(dplyr); require(dplyr); require(rstatix); library(readxl) ; library(lsr) ;library(viridis)
library(patchwork) ; library(lme4) ;library(ggsignif); library(lmerTest)
# Set the working directory to the project folder if needed
# setwd("PATH_TO_PROJECT")


# Load and summarize data  ------------------------------------------------
datax = read_excel("EEG_BEHAVIOURAL/EEG_Behavioural/RTS_final/FINAL_GENERAL_RAW_RTS.xlsx")
str(datax); head(datax)
datax$Participant= as.character(datax$Participant)
datax$Block = as.factor(datax$Block)
datax$Miniblock = as.factor(datax$Miniblock)
datax$Image = as.character(datax$Image)


#from the EEG analysis we exclude subjects 10 (noisy),41 (missed triggers), and 29(noisy)
participants_to_remove <- c(10, 41, 29)

# Filter out rows with participant IDs to remove

data_fil <- datax %>%
  filter(!Participant %in% participants_to_remove) %>%
  mutate(Participant = as.numeric(as.factor(Participant)))
#Total participants 40 fro the first 8 blocks, the odd block is not added so 640 trials x 40 = 25600
#saving the data up to here 

block_order2 = rep(c(rep(1,80),rep(2,80),rep(3,80),rep(4,80,),rep(5,80),rep(6,80),rep(7,80),rep(8,80)))   
block_order = rep(block_order2,40)
data_fil$block_order =block_order

# Do participants learn the association? ------------------------------------------
mean_acc<-data_fil %>%
  group_by(Participant) %>%
  summarise(mean_acc = sum(accuracy_offline/640*100))
set.seed(123)
res =t.test(mean_acc$mean_acc, mu = 16,alternative = "greater")
res
#plot
chance_level = 20
figure_1= ggplot(data = mean_acc, aes(y = mean_acc,x=factor(0))) + 
  geom_boxplot(width=0.1,outlier.shape = NA) + 
  geom_jitter(size=1.5,alpha = 0.2,colour="black",width = 0.05) +
  theme_bw() + 
  #geom_hline(yintercept = chance_level, color = "black", linetype = "dashed") +  
  labs(y = "Behavioral Accuracy (%)") +
  theme(plot.title = element_text(hjust = 0.5))+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),legend.position="none",panel.grid.major = element_blank()
        ,panel.grid.minor = element_blank(),panel.border=element_rect(size=1.5)) 

# Accuracy over time ---------------------------------------

data_fil$block_order = as.factor(data_fil$block_order)
mean_acc2<-data_fil %>%
  group_by(Participant,block_order) %>%
  summarise(mean_acc = sum(accuracy_offline/80*100))

figure_2= ggplot(data = mean_acc2, aes(y = mean_acc,x=block_order,fill=block_order,color=block_order)) + 
  geom_boxplot(width=0.7,outlier.shape = NA,alpha=0.09) + 
  geom_jitter(size=1.5,alpha = 0.4,width = 0.05,aes(colour=)) +
  theme_bw() + 
  #geom_hline(yintercept = chance_level, color = "black", linetype = "dashed") +  
  labs(y = "Behavioral Accuracy (%)",x="Block Order") +
  theme(plot.title = element_text(hjust = 0.8))+
  theme(legend.position="none",panel.grid.major = element_blank()
        ,panel.grid.minor = element_blank(),panel.border=element_rect(size=1),
        text = element_text(size = 15,family = "sans")) +
  #scale_fill_viridis(discrete = TRUE, guide = FALSE, option = "viridis") +
  #scale_color_viridis(discrete = TRUE, guide = FALSE, option = "viridis")
  #scale_colour_grey()+
  #scale_fill_grey()+
  scale_color_brewer(palette = "BrBG")+
  scale_fill_brewer(palette = "BrBG") +
  scale_x_discrete(labels=c("1" = "1st", "2" = "2nd",
                            "3" = "3rd","4" = "4th","5" = "5th","6" = "6th","7" = "7th","8" = "8th"))


data_fil$block_order = as.factor(data_fil$block_order)

model = lmer(mean_acc~block_order + (1|Participant),data=mean_acc2)
summary(model)
anova(model)
plot(effects::allEffects.default(model))

# RTS Over time --------------------------------------------------------
X2<- data_fil %>%
  filter(Image != "scrambled" & accuracy_offline==1 & ResponseTime>80)

X2$block_order = as.factor(X2$block_order)

mean_time_rts <- X2 %>%
  group_by(Participant,block_order) %>%
  summarise(mean_rt_block = median(ResponseTime)) %>%
  ungroup()

Means <-  X2 %>%  
  group_by(block_order) %>%
  summarise(AVG = median(ResponseTime)) %>%
  ungroup()

figure_3= ggplot(data = mean_time_rts, aes(y = mean_rt_block,x=block_order,colour=block_order,fill=block_order)) + 
  geom_boxplot(width=0.5,outlier.shape = NA,alpha=0.09) + 
  geom_jitter(size=1.5,alpha = 0.6,width = 0.05,aes(colour=block_order)) +
  geom_line(data = Means, mapping = aes(x = block_order, y = AVG),group=1) +
  theme_bw() + 
  #geom_hline(yintercept = chance_level, color = "black", linetype = "dashed") +  
  labs(y = "Reaction Times (ms)",x="Block Order") +
  theme(plot.title = element_text(hjust = 0.8))+
  theme(legend.position="none",panel.grid.major = element_blank()
        ,panel.grid.minor = element_blank(),panel.border=element_rect(size=1),
        text = element_text(size = 15,family = "sans")) +
  #scale_fill_viridis(discrete = TRUE, guide = FALSE, option = "cividis") +
  #scale_color_viridis(discrete = TRUE, guide = FALSE, option = "cividis")
  scale_color_brewer(palette = "BrBG")+
  scale_fill_brewer(palette = "BrBG") +
  scale_x_discrete(labels=c("1" = "1st", "2" = "2nd",
                            "3" = "3rd","4" = "4th","5" = "5th","6" = "6th","7" = "7th","8" = "8th"))

mean_time_rts$block_order = as.factor(mean_time_rts$block_order)
model2 = lmer(mean_rt_block~block_order + (1|Participant),data=mean_time_rts)
summary(model2)
anova(model2)
plot(effects::allEffects.default(model2))

figure_1 + figure_2 +figure_3

# EFFECT OF SEQUENCE ------------------------------------------

mean_acc_seq<-data_fil %>%
  group_by(Participant,Block) %>%
  summarise(mean_acc = sum(accuracy_offline/80*100))

mean_block_rts<-X2 %>%
  group_by(Participant,Block) %>%
  summarise(mean_rts = median(ResponseTime))

mean_block_score <- mean_block_rts %>%
  group_by(Participant) %>%
  mutate(score = mean_rts - mean_rts[Block == 1])

mean_block_score2 <- mean_block_score %>%
  group_by(Block) %>%
  summarise(score = mean(score))


figure_4 = ggplot(data = mean_acc_seq, aes(y = mean_acc,x=Block,colour=Block,fill=Block)) + 
  geom_boxplot(width=0.5,outlier.shape = NA,alpha=0.09) + 
  geom_jitter(size=1.5,alpha = 0.4,width = 0.05,aes(colour=)) +
  theme_bw() + 
  # geom_hline(yintercept = chance_level, color = "black", linetype = "dashed") +  
  labs(y = "Behavioural Accuracy (%)",x="Sequence Probability (%)") +
  theme(plot.title = element_text(hjust = 0.8))+
  theme(legend.position="none",panel.grid.major = element_blank()
        ,panel.grid.minor = element_blank(),panel.border=element_rect(size=1),
        text = element_text(size = 15,family = "sans")) +
  #scale_fill_viridis(discrete = TRUE, guide = FALSE, option = "viridis") +
  #scale_color_viridis(discrete = TRUE, guide = FALSE, option = "viridis")
  scale_color_brewer(palette = "RdBu")+
  scale_fill_brewer(palette = "RdBu") +
  scale_x_discrete(labels=c("1" = "0%", "2" = "10%",
                            "3" = "20%","4" = "30%","5" = "70%","6" = "80%","7" = "90%","8" = "100%"))


Means2 <-  X2 %>%  
  group_by(Block) %>%
  summarise(AVG = median(ResponseTime)) %>%
  ungroup()


figure_5= ggplot(data = mean_block_rts, aes(y = mean_rts,x=Block,colour=Block,fill=Block)) + 
  geom_boxplot(width=0.5,outlier.shape = NA,alpha=0.09) + 
  geom_jitter(size=1.5,alpha = 0.6,width = 0.05,aes(colour=Block)) +
  geom_line(data = Means2, mapping = aes(x = Block, y = AVG),group=1) +
  theme_bw() + 
  #geom_hline(yintercept = chance_level, color = "black", linetype = "dashed") +  
  labs(y = "Reaction Times (ms)",x="Sequence Probability (%)") +
  theme(plot.title = element_text(hjust = 0.8))+
  theme(legend.position="none",panel.grid.major = element_blank()
        ,panel.grid.minor = element_blank(),panel.border=element_rect(size=1),
        text = element_text(size = 15,family = "sans")) +
  #scale_fill_viridis(discrete = TRUE, guide = FALSE, option = "viridis") +
  #scale_color_viridis(discrete = TRUE, guide = FALSE, option = "viridis")
  scale_color_brewer(palette = "RdBu")+
  scale_fill_brewer(palette = "RdBu") +
  scale_x_discrete(labels=c("1" = "0%", "2" = "10%",
                            "3" = "20%","4" = "30%","5" = "70%","6" = "80%","7" = "90%","8" = "100%"))



figure_6= ggplot(data = mean_block_score2,aes(x = Block, y = score, fill = Block)) + 
  geom_col() +  # Use geom_col() to use the given score values
  theme_bw() +
  theme(legend.position="none", panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(), panel.border = element_rect(size=1.5)) +
  labs(y = expression(
    Delta*RT == RT[sequence] - RT[random[baseline]]~"(ms)"), x = "Sequence probability (%)") +
  theme(plot.title = element_text(hjust = 0.8))+
  theme(legend.position="none",panel.grid.major = element_blank()
        ,panel.grid.minor = element_blank(),panel.border=element_rect(size=1),
        text = element_text(size = 15,family = "sans")) +
  #scale_fill_viridis(discrete = TRUE, guide = FALSE, option = "mako") +
  #scale_color_viridis(discrete = TRUE, guide = FALSE, option = "viridis")
  scale_color_brewer(palette = "RdBu")+
  scale_fill_brewer(palette = "RdBu") +
  scale_x_discrete(labels=c("1" = "0%", "2" = "10%",
                            "3" = "20%","4" = "30%","5" = "70%","6" = "80%","7" = "90%","8" = "100%"))

figure_4 + figure_5 +figure_6

mean_acc_seq$Block = as.factor(mean_acc_seq$Block)
model3 = lmer(mean_acc~Block + (1|Participant),data=mean_acc_seq)
summary(model3)
anova(model3)
plot(effects::allEffects.default(model3))


mean_block_rts$Block = as.factor(mean_block_rts$Block)
model4 = lmer(mean_rts~Block + (1|Participant),data=mean_block_rts)
summary(model4)
anova(model4)
plot(effects::allEffects.default(model4))

# Behavioural index ------------------------------------------------

mean_block_rts$Block = as.numeric(mean_block_rts$Block)
slope_list <- list()

for (participant_id in unique(mean_block_rts$Participant)) {
  
  participant_data <- subset(mean_block_rts, Participant == participant_id)
  
  
  md <- lm(mean_rts~ Block, data = participant_data)
  
  
  slope_list[[as.character(participant_id)]] <- coef(md)[2]
}

slope_df1 <- data.frame(
  Participant = as.numeric(names(slope_list)),
  Slope = unlist(slope_list)
)


mid<-median(slope_df1$Slope)
less_than_median <- subset(slope_df1, Slope < mid)
more_than_median <- subset(slope_df1, Slope > mid)
figure_7 = ggplot(
  slope_df1,
  aes(x = reorder(Participant, -Slope), y = Slope, fill = Slope)
) +
  geom_bar(stat = "identity") +
  labs(
    x = "Participant",
    y = "Learning Slope",
    fill = "Learning Slope"
  ) +
  theme_bw() +
  scale_fill_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = mid
  )+
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(linewidth = 1),
    text = element_text(size = 15, family = "sans"),
    axis.text.x = element_text(size = 8, angle = 45, hjust = 1)
  )


# Awareness with slope--------------------------------

awareness= read_excel("C:/Users/asus/Desktop/PhD/ONGOING_PROJECTS/BEHAVIOUR/EEG_BEHAVIOURAL/EEG_Behavioural/RTS_final/FINAL_GENERAL_CLEANED.xlsx",sheet=2)
Q1 = data.frame(awareness$Q1,awareness$p)
Q1 <- Q1 %>%
  rename(Participant = awareness.p) %>%
  mutate(
    Participant = as.integer(gsub("^P", "", Participant)),
    Participant = factor(
      Participant,
      levels = setdiff(1:43, c(10, 29, 41))
    )
  )
Q1$Participant = as.numeric(Q1$Participant)

aware_slope = left_join(slope_df1,Q1,by="Participant")
# writexl::write_xlsx(
#  slope_df1,
# "slope.xlsx"
#)   

#clustering on slope 

km_res <- kmeans(aware_slope$Slope, 2)$cluster
aware_slope$class <- as.factor(km_res)

centroids <- slope_df1[, .(x = mean(x), y = mean(y)), by = class]

figure_8= ggplot(aware_slope, aes(x = factor(class), y = Slope, color = factor(class))) +
  geom_jitter(width = 0.2, size = 3) +
  scale_color_manual(values = c(
    "2" = "#2166AC",
    "1" = "#B2182B"
  )) +
  theme_bw() 


wss <- numeric(5)

for (k in 1:5) {
  wss[k] <- kmeans(slope_df1$Slope, centers = k)$tot.withinss
}

figure_9= plot(1:5, wss, type = "b",
               xlab = "Number of clusters (k)",
               ylab = "Within-cluster sum of squares")


figure_10 =  ggplot(aware_slope, aes(x = awareness.Q1, y = Slope, color = Slope, shape = awareness.Q1)) +
  geom_jitter(width = 0.2, size = 3) +
  theme_bw() +
  labs(
    x = "Clustering Groups",
    y = "Learning Slope",
    color = "Slope",
    shape = "Awareness"
  ) +
  scale_color_gradient2(
    low = "#2166AC",
    mid = "grey90",
    high = "#B2182B",
    midpoint = mid
  ) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(size = 1),
    text = element_text(size = 15, family = "sans"),
    axis.text.x = element_text(size = 8, angle = 45, hjust = 1)
  )



data=aware_slope
groups <- split(data, data$class)
groups[["1"]]  # participants in group 1
groups[["2"]]  # group 2
groups[["3"]]  # group 3

X2$Participant = as.numeric(X2$Participant)
data2 <- left_join(data, X2, by = "Participant")

summary_all <- data2 |>
  group_by(Block) |>
  summarise(
    mean_RT = mean(ResponseTime, na.rm = TRUE),
    se_RT = sd(ResponseTime, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )


summary_class <- data2 |>
  group_by(Block, class) |>
  summarise(
    mean_RT = mean(ResponseTime, na.rm = TRUE),
    se_RT = sd(ResponseTime, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )


by_class <- data2 |>
  group_by(Block, class) |>
  summarise(
    mean_rts = mean(ResponseTime, na.rm = TRUE),
    se = sd(ResponseTime, na.rm = TRUE) / sqrt(n()),
    group = as.character(class),
    .groups = "drop"
  )

overall <- data2 |>
  group_by(Block) |>
  summarise(
    mean_rts = mean(ResponseTime, na.rm = TRUE),
    se = sd(ResponseTime, na.rm = TRUE) / sqrt(n()),
    group = "Overall",
    .groups = "drop"
  )

combined_data <- bind_rows(by_class, overall)

combined_data$group <- factor(
  combined_data$group,
  levels = c("1", "2", "Overall"),
  labels = c(
    "Low learning, Mixed awareness",
    "High learning, Full awareness",
    "Overall"
  )
)

cols <- c(
  "Low learning, Mixed awareness" = "#B2182B",  # red
  "High learning, Full awareness" = "#2166AC",  # blue
  "Overall" = "black"
)

figure_11=ggplot(combined_data,
                 aes(x = Block, y = mean_rts, group = group, colour = group)) +
  
  geom_ribbon(
    aes(
      ymin = mean_rts - se,
      ymax = mean_rts + se,
      fill = group
    ),
    alpha = 0.2,
    colour = NA
  ) +
  
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  
  scale_color_manual(values = cols) +
  scale_fill_manual(values = cols) +
  
  theme_bw() +
  
  labs(
    x = "Sequence Probability",
    y = "Reaction Time (ms)",
    colour = "Group",
    fill = "Group"
  )+
  scale_x_discrete(labels = c(
    "1" = "0%",
    "2" = "10%",
    "3" = "20%",
    "4" = "30%",
    "5" = "70%",
    "6" = "80%",
    "7" = "90%",
    "8" = "100%"
  ))+
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(size = 1),
    text = element_text(size = 15, family = "sans"),
    axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
    
    # ???? legend INSIDE plot, bottom
    legend.position = c(0.03, 0.1),
    legend.justification = c(0, 0)
    
  )


figure_10 + figure_11
