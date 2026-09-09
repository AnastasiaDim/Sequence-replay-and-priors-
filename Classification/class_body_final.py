import mne
import numpy as np
import pandas as pd
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold, cross_val_score, KFold

def analyze_eeg_data(participant_number):
    i = participant_number
    fname = f'/home/dimakou/Tangerine/data/P{i}_Task_Final_2.set'
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
    max_time = 0.499  # seconds
    time_indices = np.where(data.times <= max_time)[0]
    data1 = data.get_data()[:, :, time_indices]
    
    # Load the corresponding behavioral data
    df = pd.read_excel(f'/home/dimakou/Tangerine/data/P{i}.xlsx')

    category_trials = df[(df['Image'] == 'bodies') & (df['Block'].isin([1, 2, 3, 4]))].index.values
    other_trials = df[(df['Image'].isin(['faces','scenes','tools','scrambled'])) & (df['Block'].isin([1, 2, 3, 4]))].index.values

    np.random.seed(42)
    if len(category_trials) < len(other_trials):
        other_trials = np.random.choice(other_trials, len(category_trials), replace=False)

    # Create pseudo trials from fixation period
    fixation_period_start = -0.5  # Example: 500 ms before stimulus onset
    fixation_period_end = 0  # Example: up to stimulus onset
    fixation_indices = np.where((data.times >= fixation_period_start) & (data.times < fixation_period_end))[0]
    fixation_data = data1[:, :, fixation_indices]
    num_pseudo_trials_needed = int(len(other_trials) * 0.1)

    pseudo_trials = generate_pseudo_trials(fixation_data, num_pseudo_trials_needed)

    # Combine the original other trials with the pseudo trials
    combined_control_trials = np.vstack([data1[other_trials], pseudo_trials])

    filtered_data = np.vstack([data1[category_trials], combined_control_trials])
    
    labels = np.zeros(len(filtered_data), dtype=int)
    labels[len(category_trials):] = 1  

    n_times = len(data.times)-20
    n_channels = len(data.ch_names)
    accuracy_scores = np.zeros(n_times)
    precision_scores = np.zeros(n_times)
    weights_matrix = np.zeros((n_times, n_channels))
    intercepts = np.zeros(n_times)
    
    log_reg = LogisticRegression(penalty='l1', max_iter=1000, solver='liblinear', fit_intercept=True)
    pipeline = Pipeline([
        ('scaler', StandardScaler()),
        ('log_reg', log_reg)
    ])

    kf = StratifiedKFold(n_splits=10, shuffle=True, random_state=42)

    scoring = {
        'accuracy': 'accuracy',
        'precision': 'precision',
    }

    for t in range(n_times):
        X = filtered_data[:, :, t]
        y = labels

        for score_name, score_value in scoring.items():
            print(f"Processing time point {t}/{n_times} for score {score_name}...")
            scores = cross_val_score(pipeline, X, y, cv=kf, scoring=score_value, n_jobs=-1)

            if score_name == 'accuracy':
                accuracy_scores[t] = scores.mean()
            elif score_name == 'precision':
                precision_scores[t] = scores.mean()
        
        pipeline.fit(X, y)
        log_reg = pipeline.named_steps['log_reg']
        weights_matrix[t, :] = log_reg.coef_[0]
        intercepts[t] = log_reg.intercept_[0]

    return accuracy_scores, precision_scores, weights_matrix, intercepts

def generate_pseudo_trials(fixation_data, num_pseudo_trials_needed):
    pseudo_trials = []
    total_fixations = fixation_data.shape[0]

    while len(pseudo_trials) < num_pseudo_trials_needed:
        # Ensure there are enough pairs to form pseudo trials
        if total_fixations < 2:
            raise ValueError("Not enough fixation periods to create pseudo trials.")

        for i in range(total_fixations - 1):
            flipped_trial = np.flip(fixation_data[i], axis=1)
            combined_trial = np.concatenate((fixation_data[i], flipped_trial), axis=1)
            pseudo_trials.append(combined_trial)
           
            # Stop if we have enough trials
            if len(pseudo_trials) >= num_pseudo_trials_needed:
                break

    return np.array(pseudo_trials)



all_accuracy_scores = []
#all_weights_matrices = []
all_precision_scores = []
all_intercepts_scores = []

for participant_number in range(1, 44):  # Adjust the range for your participants
    i=participant_number
    if i == 10 or i == 41:
        continue
    accuracy_scores, precision_scores, weights_matrix,intercepts = analyze_eeg_data(participant_number) 
    all_accuracy_scores.append(accuracy_scores)
   # all_weights_matrices.append(weights_matrix)
    all_precision_scores.append(precision_scores)
    all_intercepts_scores.append(intercepts)

    
    export3 = pd.DataFrame(weights_matrix)
    fname = f'P{i}_weights_bodies.xlsx'
    export3.to_excel(fname,index=False,header=False)
    export = pd.DataFrame(all_accuracy_scores)
    # Save DataFrame to Excel
    export.to_excel('accuracy_scores_bodies_final.xlsx', index=False, header=False)
    
    
   # all_weights_matrices = np.array(all_weights_matrices)
    # Compute the average accuracy and weights across participants
   # average_weights_matrix = np.mean(all_weights_matrices, axis=0)
    #export2 = pd.DataFrame(average_weights_matrix)
    #export2.to_excel('weights_scores_body_average.xlsx', index=False, header=False)
    
    export4= pd.DataFrame(intercepts)
    export.to_excel('intercept_scores_bodies.xlsx',index=False,header=False)   

    export5= pd.DataFrame(all_precision_scores)
    export.to_excel('precision_scores_bodies.xlsx',index=False,header=False) 