from sklearn.metrics import accuracy_score, precision_score, roc_auc_score
from sklearn.model_selection import KFold
import mne
import pandas as pd
import numpy as np
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import KFold, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, precision_score, roc_auc_score

def analyze_eeg_data(participant_number):
    i=participant_number
    fname = f'/home/dimakou/Tangerine/data/Task_Motor/P{i}_Task_Motor.set'
    data = mne.io.read_epochs_eeglab(fname)

    # Handle multiple events warning
    mne.set_log_level(verbose='WARNING')

    # Remove eye-tracking channels
    selected_channels = [ch_name for ch_name in data.ch_names if ch_name not in [
        'TIME', 'L-GAZE-X', 'L-GAZE-Y', 'L-AREA', 'R-GAZE-X', 'R-GAZE-Y', 'R-AREA', 'INPUT']]
    data = data.pick_channels(selected_channels)

    # Set the montage for the current participant's data
    data.set_montage('GSN-HydroCel-256')
    data = data.resample(sfreq=100)

    # Load the corresponding behavioral data
    df = pd.read_excel(f'/home/dimakou/Tangerine/data/P{i}.xlsx')

    category_trials = df[(df['Image'] == 'scenes') & (df['Block'].isin([1, 2, 3, 4]))].index.values
    other_trials = df[(df['Image'].isin(['scrambled','faces','bodies'])) & (df['Block'].isin([1, 2, 3, 4]))].index.values

    np.random.seed(42)
    if len(category_trials) < len(other_trials):
        other_trials = np.random.choice(other_trials, len(category_trials), replace=False)

    filtered_data = data[np.hstack([category_trials, other_trials])]

    labels = np.zeros(len(filtered_data), dtype=int)
    labels[len(category_trials):] = 1  

    n_times = len(filtered_data.times)
    n_channels = len(filtered_data.ch_names)
    accuracy_scores = np.zeros(n_times)
    precision_scores = np.zeros(n_times) 
    weights_matrix = np.zeros((n_times, n_channels))
    intercepts = np.zeros(n_times)

    log_reg = LogisticRegression(penalty='l1', max_iter=1000, solver='liblinear')
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('log_reg', log_reg)
    ])

    kf = KFold(n_splits=10, shuffle=True, random_state=42)

    scoring = {
        'accuracy': 'accuracy',
        'precision': 'precision',
    }

    for t in range(n_times):
        X = filtered_data.get_data()[:, :, t]
        y = labels

        # Perform K-fold cross-validation
        for score_name, score_value in scoring.items():
            scores = cross_val_score(pipeline, X, y, cv=kf, scoring=score_value)

            # Store the mean scores for this time point and score type
            if score_name == 'accuracy':
                accuracy_scores[t] = scores.mean()
            elif score_name == 'precision':
                precision_scores[t] = scores.mean()
          

        # Fit the model to extract weights
        pipeline.fit(X, y)
        log_reg = pipeline.named_steps['log_reg']
        weights_matrix[t, :] = log_reg.coef_[0]
        intercepts[t] = log_reg.intercept_[0]
    return accuracy_scores, precision_scores,  weights_matrix,intercepts

all_accuracy_scores = []
all_weights_matrices = []
all_precision_scores = []
all_inter = []
for participant_number in range(1, 44):
    if participant_number == 10 or participant_number == 41:
        continue
    
    # Analyze EEG data
    accuracy_scores, precision_scores, weights_matrix, intercepts = analyze_eeg_data(participant_number)
    
    # Store the results
    all_accuracy_scores.append(accuracy_scores)
    all_weights_matrices.append(weights_matrix)
    all_precision_scores.append(precision_scores)
    all_inter.append(intercepts)
    # Save the individual weights matrix for each participant
    export_weights = pd.DataFrame(weights_matrix)
    fname = f'P{participant_number}_weights_scenes_motor.xlsx'
    export_weights.to_excel(fname, index=False, header=False)

# Save all accuracy scores
export_accuracy = pd.DataFrame(all_accuracy_scores)
export_accuracy.to_excel('accuracy_scores_scene_motor.xlsx', index=False, header=False)

# Save all precision scores
export_precision = pd.DataFrame(all_precision_scores)
export_precision.to_excel('precision_scores_scene_motor.xlsx', index=False, header=False)

# Convert lists to arrays for further calculations
all_accuracy_scores = np.array(all_accuracy_scores)
all_weights_matrices = np.array(all_weights_matrices)

# Compute averages and standard deviation
average_accuracy_scores = np.mean(all_accuracy_scores, axis=0)
average_weights_matrix = np.mean(all_weights_matrices, axis=0)
std_accuracy_scores = np.std(all_accuracy_scores, axis=0)


export4= pd.DataFrame(all_inter)
export4.to_excel('intercept_scores_scenes_motor.xlsx',index=False,header=False)  

# Save the average weights matrix
export_avg_weights = pd.DataFrame(average_weights_matrix)
export_avg_weights.to_excel('weights_scores_scene_motor.xlsx', index=False, header=False)
