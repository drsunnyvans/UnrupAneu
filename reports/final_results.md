# Final Results

This Markdown report is generated automatically by the R pipeline.

## Analysis Summary

- Primary development endpoint: `dindo_scores >= 3`.
- Modeling restricted to harmonized pre-operative predictors only.
- Excluded from modeling: identifiers, ASA and other aggregate scores, post-operative or peri-operative variables, CPT fields, and external-only descriptive fields.
- External validation uses a prespecified severe-event composite because Dindo-Clavien is not present in the external file.
- SHAP outputs remain in the repository as exploratory artifacts, but they are omitted from the publication-facing summary because the feature attributions were not judged clinically reliable enough to report.

## Cohort Sizes

| cohort | n_rows | n_events | event_rate |
| --- | --- | --- | --- |
| development | 1625.000 | 224.000 | 0.138 |
| external | 50.000 | 6.000 | 0.120 |

## Final Modeling Feature Set

| canonical_name | feature_type | notes |
| --- | --- | --- |
| age | numeric | Continuous age in years |
| sex | categorical | Canonicalized to Female or Male |
| race | categorical | Harmonized into broad race groups |
| admission_source | categorical | External extra detail retained only descriptively |
| elective_surgery | binary | Planned elective procedure status |
| functional_status | categorical | Independent versus dependent status |
| diabetes | binary | Any diabetes versus none |
| smoking | binary | Current smoking status |
| dyspnea | binary | Dyspnea present or absent |
| copd | binary | Chronic obstructive pulmonary disease |
| heart_failure | binary | History of congestive heart failure |
| dialysis | binary | Dialysis dependence |
| active_malignancy | binary | Active malignancy |
| coagulopathy | binary | Bleeding disorder or coagulopathy |
| bmi | numeric | Body mass index |
| sodium | numeric | Serum sodium |
| bun | numeric | Blood urea nitrogen |
| creatinine | numeric | Serum creatinine |
| albumin | numeric | Serum albumin |
| bilirubin | numeric | Serum bilirubin |
| ast | numeric | Aspartate aminotransferase |
| alk_phos | numeric | Alkaline phosphatase |
| wbc | numeric | White blood cell count |
| platelets | numeric | Platelet count |
| ptt | numeric | Partial thromboplastin time |
| inr | numeric | International normalized ratio |

## Exclusion Inventory

| scope | rule_type | rule_value | reason |
| --- | --- | --- | --- |
| development | exact | caseid | Identifier should never enter modeling |
| development | exact | pufyear | Calendar extraction year not intended as a predictor |
| development | exact | dischdest | Post-operative leakage |
| development | exact | anesthes | Peri-operative variable excluded by plan |
| development | exact | optime | Post-operative or intra-operative leakage |
| development | exact | tothlos | Post-operative leakage |
| development | exact | admqtr | Administrative timing variable not modeled |
| development | exact | htooday | Post-operative leakage |
| development | exact | returnor | Post-operative leakage |
| development | exact | doptodis | Post-operative leakage |
| development | exact | asaclas | Aggregate risk score explicitly excluded |
| development | exact | mortprob | Model-generated risk score excluded |
| development | exact | morbprob | Model-generated risk score excluded |
| development | exact | height | Raw height excluded because BMI retained |
| development | exact | weight | Raw weight excluded because BMI retained |
| development | exact | ventilat | Unavailable in external harmonized modeling set |
| development | exact | ascites | Unavailable in external harmonized modeling set |
| development | exact | hypermed | Mismatch with external hypertension coding kept descriptive only |
| development | exact | renafail | Mismatch with external CKD definition kept descriptive only |
| development | exact | wndinf | Potential active infection variable not carried into harmonized set |
| development | exact | steroid | External immunosuppression mismatch kept descriptive only |
| development | exact | wtloss | Unavailable in external harmonized modeling set |
| development | exact | transfus | Potentially peri-operative and excluded |
| development | exact | prsepis | Excluded to avoid active sepsis leakage concerns |
| development | exact | prhct | Unavailable in external harmonized modeling set |
| development | exact | dindo_scores | Outcome source column not a predictor |
| development | pattern | ^proc_proc[0-9]+_cpt[0-9]+$ | CPT procedure fields explicitly excluded |
| development | pattern | ^cpt_proc[0-9]+_cpt[0-9]+$ | CPT code fields explicitly excluded |
| external | exact | id | Identifier should never enter modeling |
| external | exact | asa_class | Aggregate risk score explicitly excluded |
| external | exact | preop_demographics_labs_complete | Completeness flag excluded |
| external | exact | medical_comorbidities_complete | Completeness flag excluded |
| external | exact | aneurysm_characteristics_complete | Completeness flag excluded |
| external | exact | procedure_details_complete | Completeness flag excluded |
| external | exact | postop_outcomes_complete | Completeness flag excluded |
| external | exact | procedure_type | Procedure detail retained for description only |
| external | exact | endovascular | Procedure detail retained for description only |
| external | exact | procedure_duration_min | Peri-operative variable excluded |
| external | exact | reop | Post-operative outcome variable excluded |
| external | pattern | ^reop_type___[0-9]+$ | Post-operative detail excluded |
| external | pattern | ^presenting_symptoms___[0-9]+$ | External-only descriptive detail excluded |
| external | pattern | ^aneurysm_side(_[0-9]+)?$ | External-only descriptive aneurysm detail excluded |
| external | pattern | ^aneurysm_location(_[0-9]+)?$ | External-only descriptive aneurysm detail excluded |
| external | pattern | ^aneurysm_size_mm(_[0-9]+)?$ | External-only descriptive aneurysm detail excluded |
| external | pattern | ^neck_width_mm(_[0-9]+)?$ | External-only descriptive aneurysm detail excluded |
| external | pattern | ^aneurysm_morphology_type(_[0-9]+)?$ | External-only descriptive aneurysm detail excluded |
| external | pattern | ^irregular_morphology(_[0-9]+)?$ | External-only descriptive aneurysm detail excluded |
| external | exact | hypertension | Retained for cohort description only because coding mismatch with development file |
| external | exact | hyperlipidemia | External-only descriptive comorbidity |
| external | exact | cad | External-only descriptive comorbidity |
| external | exact | prior_mi | External-only descriptive comorbidity |
| external | exact | atrial_fibrillation | External-only descriptive comorbidity |
| external | exact | pvd | External-only descriptive comorbidity |
| external | exact | prior_stroke_tia | External-only descriptive comorbidity |
| external | exact | osa | External-only descriptive comorbidity |
| external | exact | ckd | External-only descriptive comorbidity |
| external | exact | connective_tissue_disorder | External-only descriptive comorbidity |
| external | exact | immunosuppression | External-only descriptive comorbidity |
| external | exact | aneurysm_multiple_indicato | External-only descriptive aneurysm detail |
| external | exact | renal_insufficiency | Post-operative outcome variable excluded |
| external | exact | superficial_ssi | Post-operative outcome variable excluded |
| external | exact | deep_ssi | Post-operative outcome variable excluded |
| external | exact | organ_space_ssi | Post-operative outcome variable excluded |
| external | exact | pneumonia | Post-operative outcome variable excluded |
| external | exact | uti | Post-operative outcome variable excluded |
| external | exact | c_diff | Post-operative outcome variable excluded |
| external | exact | sepsis | Post-operative outcome variable excluded |
| external | exact | septic_shock | Post-operative outcome variable excluded |
| external | exact | dvt | Post-operative outcome variable excluded |
| external | exact | pe | Post-operative outcome variable excluded |
| external | exact | reintubation | Post-operative outcome variable excluded |
| external | exact | vent_failure_48h | Post-operative outcome variable excluded |
| external | exact | mi | Post-operative outcome variable excluded |
| external | exact | cardiac_arrest | Post-operative outcome variable excluded |
| external | exact | cva | Post-operative outcome variable excluded |
| external | exact | new_neuro_deficit | Post-operative outcome variable excluded |
| external | exact | coma | Post-operative outcome variable excluded |
| external | exact | return_to_or | Post-operative outcome variable excluded |
| external | exact | death | Post-operative outcome variable excluded |

## Benchmark Models Tried

| model_name | status | message | best_pr_auc | best_roc_auc | best_tuning |
| --- | --- | --- | --- | --- | --- |
| elastic_net | trained | Cross-validation completed | 0.186 | 0.520 | alpha=1; lambda=0.01 |
| random_forest | trained | Cross-validation completed | 0.266 | 0.590 | mtry=7 |
| xgboost | trained | Cross-validation completed | 0.260 | 0.597 | nrounds=100; max_depth=2; eta=0.05; subsample=0.8; colsample_bytree=0.8 |
| knn | trained | Cross-validation completed | 0.200 | 0.565 | k=11 |
| ann | trained | Cross-validation completed | 0.233 | 0.591 | size=3; decay=1e-04 |

## Publication Comparison Table: Internal

| arm | model_name | pr_auc | roc_auc | brier_score | calibration_slope | sensitivity | specificity | ppv | npv |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Original | xgboost | 0.259 | 0.625 | 0.115 | 0.827 | 0.044 | 0.998 | 0.750 | 0.866 |
| Original | random_forest | 0.254 | 0.588 | 0.119 | 0.436 | 0.059 | 0.998 | 0.800 | 0.868 |
| Original | elastic_net | 0.222 | 0.527 | 0.136 | 0.201 | 0.015 | 1.000 | 1.000 | 0.863 |
| Original | knn | 0.207 | 0.589 | 0.123 | 0.051 | 0.000 | 0.998 | 0.000 | 0.861 |
| Original | ann | 0.187 | 0.577 | 0.163 | 0.101 | 0.103 | 0.922 | 0.175 | 0.864 |
| SMOTE | elastic_net | 0.234 | 0.549 | 0.128 | 0.037 | 0.074 | 0.995 | 0.714 | 0.869 |
| SMOTE | xgboost | 0.201 | 0.601 | 0.144 | 0.490 | 0.074 | 0.960 | 0.227 | 0.865 |
| SMOTE | ann | 0.191 | 0.567 | 0.289 | 0.010 | 0.500 | 0.667 | 0.195 | 0.892 |
| SMOTE | knn | 0.188 | 0.541 | 0.274 | 0.017 | 0.368 | 0.698 | 0.164 | 0.872 |
| SMOTE | random_forest | 0.171 | 0.564 | 0.143 | 0.228 | 0.044 | 0.964 | 0.167 | 0.862 |
| Weighted | xgboost | 0.240 | 0.618 | 0.210 | 0.825 | 0.441 | 0.734 | 0.211 | 0.890 |
| Weighted | elastic_net | 0.208 | 0.548 | 0.131 | 0.040 | 0.015 | 1.000 | 1.000 | 0.863 |
| Weighted | ann | 0.177 | 0.562 | 0.273 | 0.020 | 0.544 | 0.534 | 0.159 | 0.879 |
| Weighted | random_forest | 0.157 | 0.504 | 0.126 | 0.013 | 0.000 | 1.000 | NA | 0.861 |

## Publication Comparison Table: External

| arm | model_name | pr_auc | roc_auc | brier_score | calibration_slope | sensitivity | specificity | ppv | npv |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Original | xgboost | 0.190 | 0.504 | 0.107 | 0.289 | 0.000 | 1.000 | NA | 0.880 |
| Original | random_forest | 0.155 | 0.460 | 0.115 | -0.145 | 0.000 | 1.000 | NA | 0.880 |
| Original | ann | 0.144 | 0.458 | 0.144 | -0.081 | 0.000 | 0.955 | 0.000 | 0.875 |
| Original | knn | 0.142 | 0.479 | 0.119 | -0.019 | 0.000 | 1.000 | NA | 0.880 |
| Original | elastic_net | 0.130 | 0.500 | 0.120 | NA | 0.000 | 1.000 | NA | 0.880 |
| SMOTE | random_forest | 0.266 | 0.405 | 0.123 | -0.662 | 0.000 | 1.000 | NA | 0.880 |
| SMOTE | ann | 0.197 | 0.536 | 0.210 | 0.064 | 0.333 | 0.795 | 0.182 | 0.897 |
| SMOTE | elastic_net | 0.157 | 0.561 | 0.122 | 0.053 | 0.000 | 1.000 | NA | 0.880 |
| SMOTE | xgboost | 0.154 | 0.477 | 0.128 | -0.178 | 0.000 | 1.000 | NA | 0.880 |
| SMOTE | knn | 0.099 | 0.352 | 0.180 | -1.335 | 0.000 | 0.932 | 0.000 | 0.872 |
| Weighted | xgboost | 0.267 | 0.447 | 0.209 | -0.027 | 0.167 | 0.795 | 0.100 | 0.875 |
| Weighted | ann | 0.202 | 0.536 | 0.232 | 0.053 | 0.167 | 0.773 | 0.091 | 0.872 |
| Weighted | random_forest | 0.131 | 0.451 | 0.112 | -0.276 | 0.000 | 1.000 | NA | 0.880 |
| Weighted | elastic_net | 0.123 | 0.455 | 0.119 | -0.053 | 0.000 | 1.000 | NA | 0.880 |

## Publication Key Results Table

| arm | model | internal_pr_auc | internal_roc_auc | external_pr_auc | external_roc_auc | external_top10_recall | external_top10_event_rate | external_top10_lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Ensemble | Stacked Logistic Ensemble | 0.259 | 0.625 | 0.221 | 0.527 | 0.167 | 0.200 | 1.667 |
| Ensemble | Soft-Vote Ensemble (PR-Weighted) | 0.239 | 0.612 | 0.202 | 0.523 | 0.167 | 0.200 | 1.667 |
| Ensemble | Soft-Vote Ensemble (Equal) | 0.235 | 0.606 | 0.202 | 0.515 | 0.167 | 0.200 | 1.667 |
| Original | XGBoost | 0.259 | 0.625 | 0.190 | 0.504 | 0.167 | 0.200 | 1.667 |
| Original | Random Forest | 0.254 | 0.588 | 0.155 | 0.460 | 0.167 | 0.200 | 1.667 |
| Original | ANN | 0.187 | 0.577 | 0.144 | 0.458 | 0.000 | 0.000 | 0.000 |
| Original | kNN | 0.207 | 0.589 | 0.142 | 0.479 | 0.167 | 0.200 | 1.667 |
| Original | Elastic Net | 0.222 | 0.527 | 0.130 | 0.500 | 0.000 | 0.000 | 0.000 |
| SMOTE | Random Forest | 0.171 | 0.564 | 0.266 | 0.405 | 0.167 | 0.200 | 1.667 |
| SMOTE | ANN | 0.191 | 0.567 | 0.197 | 0.536 | 0.167 | 0.200 | 1.667 |
| SMOTE | Elastic Net | 0.234 | 0.549 | 0.157 | 0.561 | 0.167 | 0.200 | 1.667 |
| SMOTE | XGBoost | 0.201 | 0.601 | 0.154 | 0.477 | 0.167 | 0.200 | 1.667 |
| SMOTE | kNN | 0.188 | 0.541 | 0.099 | 0.352 | 0.000 | 0.000 | 0.000 |
| Weighted | XGBoost | 0.240 | 0.618 | 0.267 | 0.447 | 0.167 | 0.200 | 1.667 |
| Weighted | ANN | 0.177 | 0.562 | 0.202 | 0.536 | 0.167 | 0.200 | 1.667 |
| Weighted | Random Forest | 0.157 | 0.504 | 0.131 | 0.451 | 0.000 | 0.000 | 0.000 |
| Weighted | Elastic Net | 0.208 | 0.548 | 0.123 | 0.455 | 0.167 | 0.200 | 1.667 |

## Publication ROC Figures

- Internal original ROC figure: `results/figures/publication_internal_original_roc.png`
- Internal SMOTE ROC figure: `results/figures/publication_internal_smote_roc.png`
- Internal weighted ROC figure: `results/figures/publication_internal_weighted_roc.png`
- External original ROC figure: `results/figures/publication_external_original_roc.png`
- External SMOTE ROC figure: `results/figures/publication_external_smote_roc.png`
- External weighted ROC figure: `results/figures/publication_external_weighted_roc.png`

## Internal Test Results

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| xgboost | internal_test | 0.259 | 0.625 | 0.115 | -0.284 | 0.827 | 0.044 | 0.998 | 0.750 | 0.866 | 0.500 | 489.000 | 68.000 |
| random_forest | internal_test | 0.254 | 0.588 | 0.119 | -1.010 | 0.436 | 0.059 | 0.998 | 0.800 | 0.868 | 0.500 | 489.000 | 68.000 |
| elastic_net | internal_test | 0.222 | 0.527 | 0.136 | 0.902 | 0.201 | 0.015 | 1.000 | 1.000 | 0.863 | 0.500 | 489.000 | 68.000 |
| knn | internal_test | 0.207 | 0.589 | 0.123 | -1.578 | 0.051 | 0.000 | 0.998 | 0.000 | 0.861 | 0.500 | 489.000 | 68.000 |
| ann | internal_test | 0.187 | 0.577 | 0.163 | -1.498 | 0.101 | 0.103 | 0.922 | 0.175 | 0.864 | 0.500 | 489.000 | 68.000 |

## Internal High-Risk Capture

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ann | internal_test | top_5_pct | 0.050 | 25.000 | 6.000 | 0.240 | 0.088 | 0.240 | 1.726 |
| ann | internal_test | top_10_pct | 0.100 | 49.000 | 7.000 | 0.143 | 0.103 | 0.143 | 1.027 |
| ann | internal_test | top_20_pct | 0.200 | 98.000 | 20.000 | 0.204 | 0.294 | 0.204 | 1.468 |
| elastic_net | internal_test | top_5_pct | 0.050 | 25.000 | 8.000 | 0.320 | 0.118 | 0.320 | 2.301 |
| elastic_net | internal_test | top_10_pct | 0.100 | 49.000 | 10.000 | 0.204 | 0.147 | 0.204 | 1.468 |
| elastic_net | internal_test | top_20_pct | 0.200 | 98.000 | 20.000 | 0.204 | 0.294 | 0.204 | 1.468 |
| knn | internal_test | top_5_pct | 0.050 | 25.000 | 8.000 | 0.320 | 0.118 | 0.320 | 2.301 |
| knn | internal_test | top_10_pct | 0.100 | 49.000 | 11.000 | 0.224 | 0.162 | 0.224 | 1.614 |
| knn | internal_test | top_20_pct | 0.200 | 98.000 | 21.000 | 0.214 | 0.309 | 0.214 | 1.541 |
| random_forest | internal_test | top_5_pct | 0.050 | 25.000 | 9.000 | 0.360 | 0.132 | 0.360 | 2.589 |
| random_forest | internal_test | top_10_pct | 0.100 | 49.000 | 15.000 | 0.306 | 0.221 | 0.306 | 2.201 |
| random_forest | internal_test | top_20_pct | 0.200 | 98.000 | 23.000 | 0.235 | 0.338 | 0.235 | 1.688 |
| xgboost | internal_test | top_5_pct | 0.050 | 25.000 | 9.000 | 0.360 | 0.132 | 0.360 | 2.589 |
| xgboost | internal_test | top_10_pct | 0.100 | 49.000 | 13.000 | 0.265 | 0.191 | 0.265 | 1.908 |
| xgboost | internal_test | top_20_pct | 0.200 | 98.000 | 21.000 | 0.214 | 0.309 | 0.214 | 1.541 |

## Internal Threshold Rule Performance

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | internal_test | max_f2 | 0.150 | 0.008 | 0.054 | 0.222 | 0.527 | 0.136 | 0.902 | 0.201 | 0.044 | 0.998 | 0.750 | 0.866 | 0.150 | 489.000 | 68.000 |
| elastic_net | internal_test | top_10_pct | 0.000 | 1.000 | 0.447 | 0.222 | 0.527 | 0.136 | 0.902 | 0.201 | 1.000 | 0.000 | 0.139 | NA | 0.000 | 489.000 | 68.000 |
| elastic_net | internal_test | top_20_pct | 0.000 | 1.000 | 0.447 | 0.222 | 0.527 | 0.136 | 0.902 | 0.201 | 1.000 | 0.000 | 0.139 | NA | 0.000 | 489.000 | 68.000 |
| random_forest | internal_test | max_f2 | 0.080 | 0.736 | 0.467 | 0.254 | 0.588 | 0.119 | -1.010 | 0.436 | 0.868 | 0.285 | 0.164 | 0.930 | 0.080 | 489.000 | 68.000 |
| random_forest | internal_test | target_sensitivity_0_30 | 0.220 | 0.204 | 0.309 | 0.254 | 0.588 | 0.119 | -1.010 | 0.436 | 0.338 | 0.817 | 0.230 | 0.884 | 0.220 | 489.000 | 68.000 |
| random_forest | internal_test | target_sensitivity_0_50 | 0.130 | 0.489 | 0.342 | 0.254 | 0.588 | 0.119 | -1.010 | 0.436 | 0.515 | 0.515 | 0.146 | 0.868 | 0.130 | 489.000 | 68.000 |
| random_forest | internal_test | top_10_pct | 0.266 | 0.104 | 0.232 | 0.254 | 0.588 | 0.119 | -1.010 | 0.436 | 0.221 | 0.914 | 0.294 | 0.879 | 0.266 | 489.000 | 68.000 |
| random_forest | internal_test | top_20_pct | 0.220 | 0.204 | 0.309 | 0.254 | 0.588 | 0.119 | -1.010 | 0.436 | 0.338 | 0.817 | 0.230 | 0.884 | 0.220 | 489.000 | 68.000 |
| xgboost | internal_test | max_f2 | 0.080 | 0.838 | 0.469 | 0.259 | 0.625 | 0.115 | -0.284 | 0.827 | 0.941 | 0.178 | 0.156 | 0.949 | 0.080 | 489.000 | 68.000 |
| xgboost | internal_test | target_sensitivity_0_30 | 0.170 | 0.213 | 0.293 | 0.259 | 0.625 | 0.115 | -0.284 | 0.827 | 0.324 | 0.805 | 0.212 | 0.881 | 0.170 | 489.000 | 68.000 |
| xgboost | internal_test | target_sensitivity_0_50 | 0.130 | 0.391 | 0.389 | 0.259 | 0.625 | 0.115 | -0.284 | 0.827 | 0.529 | 0.632 | 0.188 | 0.893 | 0.130 | 489.000 | 68.000 |
| xgboost | internal_test | top_10_pct | 0.223 | 0.100 | 0.202 | 0.259 | 0.625 | 0.115 | -0.284 | 0.827 | 0.191 | 0.914 | 0.265 | 0.875 | 0.223 | 489.000 | 68.000 |
| xgboost | internal_test | top_20_pct | 0.173 | 0.200 | 0.284 | 0.259 | 0.625 | 0.115 | -0.284 | 0.827 | 0.309 | 0.817 | 0.214 | 0.880 | 0.173 | 489.000 | 68.000 |
| knn | internal_test | max_f2 | 0.090 | 0.695 | 0.441 | 0.207 | 0.589 | 0.123 | -1.578 | 0.051 | 0.794 | 0.321 | 0.159 | 0.906 | 0.090 | 489.000 | 68.000 |
| knn | internal_test | target_sensitivity_0_30 | 0.180 | 0.368 | 0.365 | 0.207 | 0.589 | 0.123 | -1.578 | 0.051 | 0.485 | 0.651 | 0.183 | 0.887 | 0.180 | 489.000 | 68.000 |
| knn | internal_test | target_sensitivity_0_50 | 0.090 | 0.695 | 0.441 | 0.207 | 0.589 | 0.123 | -1.578 | 0.051 | 0.794 | 0.321 | 0.159 | 0.906 | 0.090 | 489.000 | 68.000 |
| knn | internal_test | top_10_pct | 0.273 | 0.147 | 0.203 | 0.207 | 0.589 | 0.123 | -1.578 | 0.051 | 0.206 | 0.862 | 0.194 | 0.871 | 0.273 | 489.000 | 68.000 |
| knn | internal_test | top_20_pct | 0.182 | 0.368 | 0.365 | 0.207 | 0.589 | 0.123 | -1.578 | 0.051 | 0.485 | 0.651 | 0.183 | 0.887 | 0.182 | 489.000 | 68.000 |
| ann | internal_test | max_f2 | 0.010 | 0.761 | 0.435 | 0.187 | 0.577 | 0.163 | -1.498 | 0.101 | 0.824 | 0.249 | 0.151 | 0.897 | 0.010 | 489.000 | 68.000 |
| ann | internal_test | target_sensitivity_0_30 | 0.160 | 0.217 | 0.278 | 0.187 | 0.577 | 0.163 | -1.498 | 0.101 | 0.309 | 0.798 | 0.198 | 0.877 | 0.160 | 489.000 | 68.000 |
| ann | internal_test | target_sensitivity_0_50 | 0.040 | 0.401 | 0.363 | 0.187 | 0.577 | 0.163 | -1.498 | 0.101 | 0.500 | 0.615 | 0.173 | 0.884 | 0.040 | 489.000 | 68.000 |
| ann | internal_test | top_10_pct | 0.400 | 0.119 | 0.167 | 0.187 | 0.577 | 0.163 | -1.498 | 0.101 | 0.162 | 0.888 | 0.190 | 0.868 | 0.400 | 489.000 | 68.000 |
| ann | internal_test | top_20_pct | 0.169 | 0.200 | 0.270 | 0.187 | 0.577 | 0.163 | -1.498 | 0.101 | 0.294 | 0.815 | 0.204 | 0.877 | 0.169 | 489.000 | 68.000 |

## External Validation Results

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| xgboost | external_validation | 0.190 | 0.504 | 0.107 | -1.397 | 0.289 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| random_forest | external_validation | 0.155 | 0.460 | 0.115 | -2.287 | -0.145 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| ann | external_validation | 0.144 | 0.458 | 0.144 | -2.422 | -0.081 | 0.000 | 0.955 | 0.000 | 0.875 | 0.500 | 50.000 | 6.000 |
| knn | external_validation | 0.142 | 0.479 | 0.119 | -2.174 | -0.019 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| elastic_net | external_validation | 0.130 | 0.500 | 0.120 | -1.992 | NA | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |

## External High-Risk Capture

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ann | external_validation | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| ann | external_validation | top_10_pct | 0.100 | 5.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| ann | external_validation | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |
| elastic_net | external_validation | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| elastic_net | external_validation | top_10_pct | 0.100 | 5.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| elastic_net | external_validation | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |
| knn | external_validation | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| knn | external_validation | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| knn | external_validation | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |
| random_forest | external_validation | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| random_forest | external_validation | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| random_forest | external_validation | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |
| xgboost | external_validation | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| xgboost | external_validation | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| xgboost | external_validation | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |

## External Threshold Rule Performance

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | external_validation | max_f2 | 0.150 | 0.000 | NA | 0.130 | 0.500 | 0.120 | -1.992 | NA | 0.000 | 1.000 | NA | 0.880 | 0.150 | 50.000 | 6.000 |
| elastic_net | external_validation | top_10_pct | 0.000 | 1.000 | 0.405 | 0.130 | 0.500 | 0.120 | -1.992 | NA | 1.000 | 0.000 | 0.120 | NA | 0.000 | 50.000 | 6.000 |
| elastic_net | external_validation | top_20_pct | 0.000 | 1.000 | 0.405 | 0.130 | 0.500 | 0.120 | -1.992 | NA | 1.000 | 0.000 | 0.120 | NA | 0.000 | 50.000 | 6.000 |
| random_forest | external_validation | max_f2 | 0.080 | 0.680 | 0.345 | 0.155 | 0.460 | 0.115 | -2.287 | -0.145 | 0.667 | 0.318 | 0.118 | 0.875 | 0.080 | 50.000 | 6.000 |
| random_forest | external_validation | target_sensitivity_0_30 | 0.220 | 0.220 | 0.286 | 0.155 | 0.460 | 0.115 | -2.287 | -0.145 | 0.333 | 0.795 | 0.182 | 0.897 | 0.220 | 50.000 | 6.000 |
| random_forest | external_validation | target_sensitivity_0_50 | 0.130 | 0.500 | 0.306 | 0.155 | 0.460 | 0.115 | -2.287 | -0.145 | 0.500 | 0.500 | 0.120 | 0.880 | 0.130 | 50.000 | 6.000 |
| random_forest | external_validation | top_10_pct | 0.266 | 0.120 | 0.167 | 0.155 | 0.460 | 0.115 | -2.287 | -0.145 | 0.167 | 0.886 | 0.167 | 0.886 | 0.266 | 50.000 | 6.000 |
| random_forest | external_validation | top_20_pct | 0.220 | 0.220 | 0.286 | 0.155 | 0.460 | 0.115 | -2.287 | -0.145 | 0.333 | 0.795 | 0.182 | 0.897 | 0.220 | 50.000 | 6.000 |
| xgboost | external_validation | max_f2 | 0.080 | 0.800 | 0.312 | 0.190 | 0.504 | 0.107 | -1.397 | 0.289 | 0.667 | 0.182 | 0.100 | 0.800 | 0.080 | 50.000 | 6.000 |
| xgboost | external_validation | target_sensitivity_0_30 | 0.170 | 0.120 | 0.167 | 0.190 | 0.504 | 0.107 | -1.397 | 0.289 | 0.167 | 0.886 | 0.167 | 0.886 | 0.170 | 50.000 | 6.000 |
| xgboost | external_validation | target_sensitivity_0_50 | 0.130 | 0.280 | 0.263 | 0.190 | 0.504 | 0.107 | -1.397 | 0.289 | 0.333 | 0.727 | 0.143 | 0.889 | 0.130 | 50.000 | 6.000 |
| xgboost | external_validation | top_10_pct | 0.223 | 0.060 | 0.185 | 0.190 | 0.504 | 0.107 | -1.397 | 0.289 | 0.167 | 0.955 | 0.333 | 0.894 | 0.223 | 50.000 | 6.000 |
| xgboost | external_validation | top_20_pct | 0.173 | 0.120 | 0.167 | 0.190 | 0.504 | 0.107 | -1.397 | 0.289 | 0.167 | 0.886 | 0.167 | 0.886 | 0.173 | 50.000 | 6.000 |
| knn | external_validation | max_f2 | 0.090 | 0.380 | 0.233 | 0.142 | 0.479 | 0.119 | -2.174 | -0.019 | 0.333 | 0.614 | 0.105 | 0.871 | 0.090 | 50.000 | 6.000 |
| knn | external_validation | target_sensitivity_0_30 | 0.180 | 0.140 | 0.161 | 0.142 | 0.479 | 0.119 | -2.174 | -0.019 | 0.167 | 0.864 | 0.143 | 0.884 | 0.180 | 50.000 | 6.000 |
| knn | external_validation | target_sensitivity_0_50 | 0.090 | 0.380 | 0.233 | 0.142 | 0.479 | 0.119 | -2.174 | -0.019 | 0.333 | 0.614 | 0.105 | 0.871 | 0.090 | 50.000 | 6.000 |
| knn | external_validation | top_10_pct | 0.273 | 0.020 | NA | 0.142 | 0.479 | 0.119 | -2.174 | -0.019 | 0.000 | 0.977 | 0.000 | 0.878 | 0.273 | 50.000 | 6.000 |
| knn | external_validation | top_20_pct | 0.182 | 0.040 | NA | 0.142 | 0.479 | 0.119 | -2.174 | -0.019 | 0.000 | 0.955 | 0.000 | 0.875 | 0.182 | 50.000 | 6.000 |
| ann | external_validation | max_f2 | 0.010 | 0.300 | 0.385 | 0.144 | 0.458 | 0.144 | -2.422 | -0.081 | 0.500 | 0.727 | 0.200 | 0.914 | 0.010 | 50.000 | 6.000 |
| ann | external_validation | target_sensitivity_0_30 | 0.160 | 0.080 | NA | 0.144 | 0.458 | 0.144 | -2.422 | -0.081 | 0.000 | 0.909 | 0.000 | 0.870 | 0.160 | 50.000 | 6.000 |
| ann | external_validation | target_sensitivity_0_50 | 0.040 | 0.240 | 0.278 | 0.144 | 0.458 | 0.144 | -2.422 | -0.081 | 0.333 | 0.773 | 0.167 | 0.895 | 0.040 | 50.000 | 6.000 |
| ann | external_validation | top_10_pct | 0.400 | 0.040 | NA | 0.144 | 0.458 | 0.144 | -2.422 | -0.081 | 0.000 | 0.955 | 0.000 | 0.875 | 0.400 | 50.000 | 6.000 |
| ann | external_validation | top_20_pct | 0.169 | 0.080 | NA | 0.144 | 0.458 | 0.144 | -2.422 | -0.081 | 0.000 | 0.909 | 0.000 | 0.870 | 0.169 | 50.000 | 6.000 |

## Selected Primary Model

| primary_model | internal_pr_auc | internal_roc_auc | internal_brier_score | internal_calibration_slope | top10_recall | top10_ppv | top10_lift |
| --- | --- | --- | --- | --- | --- | --- | --- |
| xgboost | 0.259 | 0.625 | 0.115 | 0.827 | 0.191 | 0.265 | 1.908 |

## Benchmark Models Tried With SMOTE

| model_name | status | message | best_pr_auc | best_roc_auc | best_tuning |
| --- | --- | --- | --- | --- | --- |
| elastic_net | trained | Cross-validation with SMOTE completed | 0.257 | 0.586 | alpha=0.5; lambda=0.1 |
| random_forest | trained | Cross-validation with SMOTE completed | 0.174 | 0.562 | mtry=7 |
| xgboost | trained | Cross-validation with SMOTE completed | 0.214 | 0.573 | nrounds=100; max_depth=2; eta=0.1; subsample=0.8; colsample_bytree=0.8 |
| knn | trained | Cross-validation with SMOTE completed | 0.196 | 0.559 | k=3 |
| ann | trained | Cross-validation with SMOTE completed | 0.198 | 0.603 | size=3; decay=1e-04 |

## Internal Test Results With SMOTE

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | internal_test_smote | 0.234 | 0.549 | 0.128 | -1.481 | 0.037 | 0.074 | 0.995 | 0.714 | 0.869 | 0.500 | 489.000 | 68.000 |
| xgboost | internal_test_smote | 0.201 | 0.601 | 0.144 | -1.348 | 0.490 | 0.074 | 0.960 | 0.227 | 0.865 | 0.500 | 489.000 | 68.000 |
| ann | internal_test_smote | 0.191 | 0.567 | 0.289 | -1.799 | 0.010 | 0.500 | 0.667 | 0.195 | 0.892 | 0.500 | 489.000 | 68.000 |
| knn | internal_test_smote | 0.188 | 0.541 | 0.274 | -1.753 | 0.017 | 0.368 | 0.698 | 0.164 | 0.872 | 0.500 | 489.000 | 68.000 |
| random_forest | internal_test_smote | 0.171 | 0.564 | 0.143 | -1.556 | 0.228 | 0.044 | 0.964 | 0.167 | 0.862 | 0.500 | 489.000 | 68.000 |

## Internal High-Risk Capture With SMOTE

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ann | internal_test_smote | top_5_pct | 0.050 | 25.000 | 4.000 | 0.160 | 0.059 | 0.160 | 1.151 |
| ann | internal_test_smote | top_10_pct | 0.100 | 49.000 | 8.000 | 0.163 | 0.118 | 0.163 | 1.174 |
| ann | internal_test_smote | top_20_pct | 0.200 | 98.000 | 20.000 | 0.204 | 0.294 | 0.204 | 1.468 |
| elastic_net | internal_test_smote | top_5_pct | 0.050 | 25.000 | 7.000 | 0.280 | 0.103 | 0.280 | 2.014 |
| elastic_net | internal_test_smote | top_10_pct | 0.100 | 49.000 | 12.000 | 0.245 | 0.176 | 0.245 | 1.761 |
| elastic_net | internal_test_smote | top_20_pct | 0.200 | 98.000 | 19.000 | 0.194 | 0.279 | 0.194 | 1.394 |
| knn | internal_test_smote | top_5_pct | 0.050 | 25.000 | 5.000 | 0.200 | 0.074 | 0.200 | 1.438 |
| knn | internal_test_smote | top_10_pct | 0.100 | 49.000 | 10.000 | 0.204 | 0.147 | 0.204 | 1.468 |
| knn | internal_test_smote | top_20_pct | 0.200 | 98.000 | 20.000 | 0.204 | 0.294 | 0.204 | 1.468 |
| random_forest | internal_test_smote | top_5_pct | 0.050 | 25.000 | 5.000 | 0.200 | 0.074 | 0.200 | 1.438 |
| random_forest | internal_test_smote | top_10_pct | 0.100 | 49.000 | 9.000 | 0.184 | 0.132 | 0.184 | 1.321 |
| random_forest | internal_test_smote | top_20_pct | 0.200 | 98.000 | 19.000 | 0.194 | 0.279 | 0.194 | 1.394 |
| xgboost | internal_test_smote | top_5_pct | 0.050 | 25.000 | 6.000 | 0.240 | 0.088 | 0.240 | 1.726 |
| xgboost | internal_test_smote | top_10_pct | 0.100 | 49.000 | 11.000 | 0.224 | 0.162 | 0.224 | 1.614 |
| xgboost | internal_test_smote | top_20_pct | 0.200 | 98.000 | 19.000 | 0.194 | 0.279 | 0.194 | 1.394 |

## Internal Threshold Rule Performance With SMOTE

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | internal_test_smote | max_f2 | 0.010 | 0.337 | 0.320 | 0.234 | 0.549 | 0.128 | -1.481 | 0.037 | 0.412 | 0.675 | 0.170 | 0.877 | 0.010 | 489.000 | 68.000 |
| elastic_net | internal_test_smote | target_sensitivity_0_30 | 0.040 | 0.284 | 0.280 | 0.234 | 0.549 | 0.128 | -1.481 | 0.037 | 0.338 | 0.724 | 0.165 | 0.871 | 0.040 | 489.000 | 68.000 |
| elastic_net | internal_test_smote | top_10_pct | 0.179 | 0.100 | 0.187 | 0.234 | 0.549 | 0.128 | -1.481 | 0.037 | 0.176 | 0.912 | 0.245 | 0.873 | 0.179 | 489.000 | 68.000 |
| elastic_net | internal_test_smote | top_20_pct | 0.096 | 0.200 | 0.257 | 0.234 | 0.549 | 0.128 | -1.481 | 0.037 | 0.279 | 0.812 | 0.194 | 0.875 | 0.096 | 489.000 | 68.000 |
| random_forest | internal_test_smote | max_f2 | 0.120 | 0.853 | 0.457 | 0.171 | 0.564 | 0.143 | -1.556 | 0.228 | 0.926 | 0.159 | 0.151 | 0.931 | 0.120 | 489.000 | 68.000 |
| random_forest | internal_test_smote | target_sensitivity_0_30 | 0.330 | 0.247 | 0.267 | 0.171 | 0.564 | 0.143 | -1.556 | 0.228 | 0.309 | 0.762 | 0.174 | 0.872 | 0.330 | 489.000 | 68.000 |
| random_forest | internal_test_smote | target_sensitivity_0_50 | 0.260 | 0.452 | 0.375 | 0.171 | 0.564 | 0.143 | -1.556 | 0.228 | 0.544 | 0.563 | 0.167 | 0.884 | 0.260 | 489.000 | 68.000 |
| random_forest | internal_test_smote | top_10_pct | 0.436 | 0.104 | 0.155 | 0.171 | 0.564 | 0.143 | -1.556 | 0.228 | 0.147 | 0.903 | 0.196 | 0.868 | 0.436 | 489.000 | 68.000 |
| random_forest | internal_test_smote | top_20_pct | 0.362 | 0.200 | 0.257 | 0.171 | 0.564 | 0.143 | -1.556 | 0.228 | 0.279 | 0.812 | 0.194 | 0.875 | 0.362 | 489.000 | 68.000 |
| xgboost | internal_test_smote | max_f2 | 0.220 | 0.648 | 0.450 | 0.201 | 0.601 | 0.144 | -1.348 | 0.490 | 0.779 | 0.373 | 0.167 | 0.913 | 0.220 | 489.000 | 68.000 |
| xgboost | internal_test_smote | target_sensitivity_0_30 | 0.380 | 0.221 | 0.276 | 0.201 | 0.601 | 0.144 | -1.348 | 0.490 | 0.309 | 0.793 | 0.194 | 0.877 | 0.380 | 489.000 | 68.000 |
| xgboost | internal_test_smote | target_sensitivity_0_50 | 0.310 | 0.374 | 0.385 | 0.201 | 0.601 | 0.144 | -1.348 | 0.490 | 0.515 | 0.648 | 0.191 | 0.892 | 0.310 | 489.000 | 68.000 |
| xgboost | internal_test_smote | top_10_pct | 0.447 | 0.100 | 0.171 | 0.201 | 0.601 | 0.144 | -1.348 | 0.490 | 0.162 | 0.910 | 0.224 | 0.870 | 0.447 | 489.000 | 68.000 |
| xgboost | internal_test_smote | top_20_pct | 0.387 | 0.200 | 0.257 | 0.201 | 0.601 | 0.144 | -1.348 | 0.490 | 0.279 | 0.812 | 0.194 | 0.875 | 0.387 | 489.000 | 68.000 |
| knn | internal_test_smote | max_f2 | 0.010 | 0.515 | 0.363 | 0.188 | 0.541 | 0.274 | -1.753 | 0.017 | 0.559 | 0.492 | 0.151 | 0.873 | 0.010 | 489.000 | 68.000 |
| knn | internal_test_smote | target_sensitivity_0_30 | 0.660 | 0.311 | 0.295 | 0.188 | 0.541 | 0.274 | -1.753 | 0.017 | 0.368 | 0.698 | 0.164 | 0.872 | 0.660 | 489.000 | 68.000 |
| knn | internal_test_smote | target_sensitivity_0_50 | 0.330 | 0.515 | 0.363 | 0.188 | 0.541 | 0.274 | -1.753 | 0.017 | 0.559 | 0.492 | 0.151 | 0.873 | 0.330 | 489.000 | 68.000 |
| knn | internal_test_smote | top_10_pct | 1.000 | 0.143 | 0.205 | 0.188 | 0.541 | 0.274 | -1.753 | 0.017 | 0.206 | 0.867 | 0.200 | 0.871 | 1.000 | 489.000 | 68.000 |
| knn | internal_test_smote | top_20_pct | 0.667 | 0.311 | 0.295 | 0.188 | 0.541 | 0.274 | -1.753 | 0.017 | 0.368 | 0.698 | 0.164 | 0.872 | 0.667 | 489.000 | 68.000 |
| ann | internal_test_smote | max_f2 | 0.010 | 0.730 | 0.390 | 0.191 | 0.567 | 0.289 | -1.799 | 0.010 | 0.721 | 0.268 | 0.137 | 0.856 | 0.010 | 489.000 | 68.000 |
| ann | internal_test_smote | target_sensitivity_0_30 | 0.890 | 0.209 | 0.281 | 0.191 | 0.567 | 0.289 | -1.799 | 0.010 | 0.309 | 0.808 | 0.206 | 0.879 | 0.890 | 489.000 | 68.000 |
| ann | internal_test_smote | target_sensitivity_0_50 | 0.680 | 0.344 | 0.386 | 0.191 | 0.567 | 0.289 | -1.799 | 0.010 | 0.500 | 0.682 | 0.202 | 0.894 | 0.680 | 489.000 | 68.000 |
| ann | internal_test_smote | top_10_pct | 0.899 | 0.164 | 0.256 | 0.191 | 0.567 | 0.289 | -1.799 | 0.010 | 0.265 | 0.853 | 0.225 | 0.878 | 0.899 | 489.000 | 68.000 |
| ann | internal_test_smote | top_20_pct | 0.898 | 0.200 | 0.270 | 0.191 | 0.567 | 0.289 | -1.799 | 0.010 | 0.294 | 0.815 | 0.204 | 0.877 | 0.898 | 489.000 | 68.000 |

## External Validation Results With SMOTE

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| random_forest | external_validation_smote | 0.266 | 0.405 | 0.123 | -2.974 | -0.662 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| ann | external_validation_smote | 0.197 | 0.536 | 0.210 | -1.892 | 0.064 | 0.333 | 0.795 | 0.182 | 0.897 | 0.500 | 50.000 | 6.000 |
| elastic_net | external_validation_smote | 0.157 | 0.561 | 0.122 | -1.401 | 0.053 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| xgboost | external_validation_smote | 0.154 | 0.477 | 0.128 | -2.236 | -0.178 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| knn | external_validation_smote | 0.099 | 0.352 | 0.180 | -20.089 | -1.335 | 0.000 | 0.932 | 0.000 | 0.872 | 0.500 | 50.000 | 6.000 |

## External High-Risk Capture With SMOTE

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ann | external_validation_smote | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| ann | external_validation_smote | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| ann | external_validation_smote | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |
| elastic_net | external_validation_smote | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| elastic_net | external_validation_smote | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| elastic_net | external_validation_smote | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |
| knn | external_validation_smote | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| knn | external_validation_smote | top_10_pct | 0.100 | 5.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| knn | external_validation_smote | top_20_pct | 0.200 | 10.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| random_forest | external_validation_smote | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| random_forest | external_validation_smote | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| random_forest | external_validation_smote | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |
| xgboost | external_validation_smote | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| xgboost | external_validation_smote | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| xgboost | external_validation_smote | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |

## External Threshold Rule Performance With SMOTE

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | external_validation_smote | max_f2 | 0.010 | 0.180 | 0.152 | 0.157 | 0.561 | 0.122 | -1.401 | 0.053 | 0.167 | 0.818 | 0.111 | 0.878 | 0.010 | 50.000 | 6.000 |
| elastic_net | external_validation_smote | target_sensitivity_0_30 | 0.040 | 0.140 | 0.161 | 0.157 | 0.561 | 0.122 | -1.401 | 0.053 | 0.167 | 0.864 | 0.143 | 0.884 | 0.040 | 50.000 | 6.000 |
| elastic_net | external_validation_smote | top_10_pct | 0.179 | 0.040 | NA | 0.157 | 0.561 | 0.122 | -1.401 | 0.053 | 0.000 | 0.955 | 0.000 | 0.875 | 0.179 | 50.000 | 6.000 |
| elastic_net | external_validation_smote | top_20_pct | 0.096 | 0.040 | NA | 0.157 | 0.561 | 0.122 | -1.401 | 0.053 | 0.000 | 0.955 | 0.000 | 0.875 | 0.096 | 50.000 | 6.000 |
| random_forest | external_validation_smote | max_f2 | 0.120 | 0.840 | 0.379 | 0.266 | 0.405 | 0.123 | -2.974 | -0.662 | 0.833 | 0.159 | 0.119 | 0.875 | 0.120 | 50.000 | 6.000 |
| random_forest | external_validation_smote | target_sensitivity_0_30 | 0.330 | 0.120 | 0.167 | 0.266 | 0.405 | 0.123 | -2.974 | -0.662 | 0.167 | 0.886 | 0.167 | 0.886 | 0.330 | 50.000 | 6.000 |
| random_forest | external_validation_smote | target_sensitivity_0_50 | 0.260 | 0.240 | 0.278 | 0.266 | 0.405 | 0.123 | -2.974 | -0.662 | 0.333 | 0.773 | 0.167 | 0.895 | 0.260 | 50.000 | 6.000 |
| random_forest | external_validation_smote | top_10_pct | 0.436 | 0.000 | NA | 0.266 | 0.405 | 0.123 | -2.974 | -0.662 | 0.000 | 1.000 | NA | 0.880 | 0.436 | 50.000 | 6.000 |
| random_forest | external_validation_smote | top_20_pct | 0.362 | 0.020 | 0.200 | 0.266 | 0.405 | 0.123 | -2.974 | -0.662 | 0.167 | 1.000 | 1.000 | 0.898 | 0.362 | 50.000 | 6.000 |
| xgboost | external_validation_smote | max_f2 | 0.220 | 0.400 | 0.227 | 0.154 | 0.477 | 0.128 | -2.236 | -0.178 | 0.333 | 0.591 | 0.100 | 0.867 | 0.220 | 50.000 | 6.000 |
| xgboost | external_validation_smote | target_sensitivity_0_30 | 0.380 | 0.060 | NA | 0.154 | 0.477 | 0.128 | -2.236 | -0.178 | 0.000 | 0.932 | 0.000 | 0.872 | 0.380 | 50.000 | 6.000 |
| xgboost | external_validation_smote | target_sensitivity_0_50 | 0.310 | 0.260 | 0.270 | 0.154 | 0.477 | 0.128 | -2.236 | -0.178 | 0.333 | 0.750 | 0.154 | 0.892 | 0.310 | 50.000 | 6.000 |
| xgboost | external_validation_smote | top_10_pct | 0.447 | 0.000 | NA | 0.154 | 0.477 | 0.128 | -2.236 | -0.178 | 0.000 | 1.000 | NA | 0.880 | 0.447 | 50.000 | 6.000 |
| xgboost | external_validation_smote | top_20_pct | 0.387 | 0.060 | NA | 0.154 | 0.477 | 0.128 | -2.236 | -0.178 | 0.000 | 0.932 | 0.000 | 0.872 | 0.387 | 50.000 | 6.000 |
| knn | external_validation_smote | max_f2 | 0.010 | 0.260 | NA | 0.099 | 0.352 | 0.180 | -20.089 | -1.335 | 0.000 | 0.705 | 0.000 | 0.838 | 0.010 | 50.000 | 6.000 |
| knn | external_validation_smote | target_sensitivity_0_30 | 0.660 | 0.060 | NA | 0.099 | 0.352 | 0.180 | -20.089 | -1.335 | 0.000 | 0.932 | 0.000 | 0.872 | 0.660 | 50.000 | 6.000 |
| knn | external_validation_smote | target_sensitivity_0_50 | 0.330 | 0.260 | NA | 0.099 | 0.352 | 0.180 | -20.089 | -1.335 | 0.000 | 0.705 | 0.000 | 0.838 | 0.330 | 50.000 | 6.000 |
| knn | external_validation_smote | top_10_pct | 1.000 | 0.020 | NA | 0.099 | 0.352 | 0.180 | -20.089 | -1.335 | 0.000 | 0.977 | 0.000 | 0.878 | 1.000 | 50.000 | 6.000 |
| knn | external_validation_smote | top_20_pct | 0.667 | 0.020 | NA | 0.099 | 0.352 | 0.180 | -20.089 | -1.335 | 0.000 | 0.977 | 0.000 | 0.878 | 0.667 | 50.000 | 6.000 |
| ann | external_validation_smote | max_f2 | 0.010 | 1.000 | 0.405 | 0.197 | 0.536 | 0.210 | -1.892 | 0.064 | 1.000 | 0.000 | 0.120 | NA | 0.010 | 50.000 | 6.000 |
| ann | external_validation_smote | target_sensitivity_0_30 | 0.890 | 0.040 | NA | 0.197 | 0.536 | 0.210 | -1.892 | 0.064 | 0.000 | 0.955 | 0.000 | 0.875 | 0.890 | 50.000 | 6.000 |
| ann | external_validation_smote | target_sensitivity_0_50 | 0.680 | 0.180 | 0.303 | 0.197 | 0.536 | 0.210 | -1.892 | 0.064 | 0.333 | 0.841 | 0.222 | 0.902 | 0.680 | 50.000 | 6.000 |
| ann | external_validation_smote | top_10_pct | 0.899 | 0.040 | NA | 0.197 | 0.536 | 0.210 | -1.892 | 0.064 | 0.000 | 0.955 | 0.000 | 0.875 | 0.899 | 50.000 | 6.000 |
| ann | external_validation_smote | top_20_pct | 0.898 | 0.040 | NA | 0.197 | 0.536 | 0.210 | -1.892 | 0.064 | 0.000 | 0.955 | 0.000 | 0.875 | 0.898 | 50.000 | 6.000 |

## Selected Primary SMOTE Model

| primary_model_smote | internal_pr_auc | internal_roc_auc | internal_brier_score | internal_calibration_slope | top10_recall | top10_ppv | top10_lift |
| --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | 0.234 | 0.549 | 0.128 | 0.037 | 0.176 | 0.245 | 1.761 |

## Benchmark Models Tried With Class Weights

| model_name | status | message | best_pr_auc | best_roc_auc | best_tuning |
| --- | --- | --- | --- | --- | --- |
| elastic_net | trained | Cross-validation with class weights completed | 0.278 | 0.607 | alpha=1; lambda=0.1; use_weights=TRUE |
| random_forest | trained | Cross-validation with class weights completed | 0.159 | 0.499 | mtry=16; use_weights=TRUE |
| xgboost | trained | Cross-validation with class weights completed | 0.242 | 0.575 | nrounds=100; max_depth=2; eta=0.05; subsample=0.8; colsample_bytree=0.8; use_weights=TRUE |
| knn | failed | Weighted training is not implemented for knn. | NA | NA |  |
| ann | trained | Cross-validation with class weights completed | 0.223 | 0.553 | size=3; decay=0.001; use_weights=TRUE |

## Internal Test Results With Class Weights

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| xgboost | internal_test_weighted | 0.240 | 0.618 | 0.210 | -1.675 | 0.825 | 0.441 | 0.734 | 0.211 | 0.890 | 0.500 | 489.000 | 68.000 |
| elastic_net | internal_test_weighted | 0.208 | 0.548 | 0.131 | -1.438 | 0.040 | 0.015 | 1.000 | 1.000 | 0.863 | 0.500 | 489.000 | 68.000 |
| ann | internal_test_weighted | 0.177 | 0.562 | 0.273 | -1.735 | 0.020 | 0.544 | 0.534 | 0.159 | 0.879 | 0.500 | 489.000 | 68.000 |
| random_forest | internal_test_weighted | 0.157 | 0.504 | 0.126 | -1.794 | 0.013 | 0.000 | 1.000 | NA | 0.861 | 0.500 | 489.000 | 68.000 |

## Internal High-Risk Capture With Class Weights

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ann | internal_test_weighted | top_5_pct | 0.050 | 25.000 | 4.000 | 0.160 | 0.059 | 0.160 | 1.151 |
| ann | internal_test_weighted | top_10_pct | 0.100 | 49.000 | 10.000 | 0.204 | 0.147 | 0.204 | 1.468 |
| ann | internal_test_weighted | top_20_pct | 0.200 | 98.000 | 19.000 | 0.194 | 0.279 | 0.194 | 1.394 |
| elastic_net | internal_test_weighted | top_5_pct | 0.050 | 25.000 | 6.000 | 0.240 | 0.088 | 0.240 | 1.726 |
| elastic_net | internal_test_weighted | top_10_pct | 0.100 | 49.000 | 7.000 | 0.143 | 0.103 | 0.143 | 1.027 |
| elastic_net | internal_test_weighted | top_20_pct | 0.200 | 98.000 | 16.000 | 0.163 | 0.235 | 0.163 | 1.174 |
| random_forest | internal_test_weighted | top_5_pct | 0.050 | 25.000 | 5.000 | 0.200 | 0.074 | 0.200 | 1.438 |
| random_forest | internal_test_weighted | top_10_pct | 0.100 | 49.000 | 7.000 | 0.143 | 0.103 | 0.143 | 1.027 |
| random_forest | internal_test_weighted | top_20_pct | 0.200 | 98.000 | 13.000 | 0.133 | 0.191 | 0.133 | 0.954 |
| xgboost | internal_test_weighted | top_5_pct | 0.050 | 25.000 | 8.000 | 0.320 | 0.118 | 0.320 | 2.301 |
| xgboost | internal_test_weighted | top_10_pct | 0.100 | 49.000 | 13.000 | 0.265 | 0.191 | 0.265 | 1.908 |
| xgboost | internal_test_weighted | top_20_pct | 0.200 | 98.000 | 17.000 | 0.173 | 0.250 | 0.173 | 1.247 |

## Internal Threshold Rule Performance With Class Weights

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | internal_test_weighted | max_f2 | 0.010 | 0.301 | 0.310 | 0.208 | 0.548 | 0.131 | -1.438 | 0.040 | 0.382 | 0.713 | 0.177 | 0.877 | 0.010 | 489.000 | 68.000 |
| elastic_net | internal_test_weighted | target_sensitivity_0_30 | 0.020 | 0.270 | 0.309 | 0.208 | 0.548 | 0.131 | -1.438 | 0.040 | 0.368 | 0.746 | 0.189 | 0.880 | 0.020 | 489.000 | 68.000 |
| elastic_net | internal_test_weighted | top_10_pct | 0.089 | 0.102 | 0.124 | 0.208 | 0.548 | 0.131 | -1.438 | 0.040 | 0.118 | 0.900 | 0.160 | 0.863 | 0.089 | 489.000 | 68.000 |
| elastic_net | internal_test_weighted | top_20_pct | 0.044 | 0.200 | 0.216 | 0.208 | 0.548 | 0.131 | -1.438 | 0.040 | 0.235 | 0.805 | 0.163 | 0.867 | 0.044 | 489.000 | 68.000 |
| random_forest | internal_test_weighted | max_f2 | 0.010 | 0.996 | 0.441 | 0.157 | 0.504 | 0.126 | -1.794 | 0.013 | 0.985 | 0.002 | 0.138 | 0.500 | 0.010 | 489.000 | 68.000 |
| random_forest | internal_test_weighted | target_sensitivity_0_30 | 0.150 | 0.339 | 0.251 | 0.157 | 0.504 | 0.126 | -1.794 | 0.013 | 0.324 | 0.658 | 0.133 | 0.858 | 0.150 | 489.000 | 68.000 |
| random_forest | internal_test_weighted | target_sensitivity_0_50 | 0.100 | 0.556 | 0.349 | 0.157 | 0.504 | 0.126 | -1.794 | 0.013 | 0.559 | 0.444 | 0.140 | 0.862 | 0.100 | 489.000 | 68.000 |
| random_forest | internal_test_weighted | top_10_pct | 0.248 | 0.104 | 0.124 | 0.157 | 0.504 | 0.126 | -1.794 | 0.013 | 0.118 | 0.898 | 0.157 | 0.863 | 0.248 | 489.000 | 68.000 |
| random_forest | internal_test_weighted | top_20_pct | 0.196 | 0.204 | 0.175 | 0.157 | 0.504 | 0.126 | -1.794 | 0.013 | 0.191 | 0.793 | 0.130 | 0.859 | 0.196 | 489.000 | 68.000 |
| xgboost | internal_test_weighted | max_f2 | 0.350 | 0.730 | 0.461 | 0.240 | 0.618 | 0.210 | -1.675 | 0.825 | 0.853 | 0.290 | 0.162 | 0.924 | 0.350 | 489.000 | 68.000 |
| xgboost | internal_test_weighted | target_sensitivity_0_30 | 0.530 | 0.221 | 0.276 | 0.240 | 0.618 | 0.210 | -1.675 | 0.825 | 0.309 | 0.793 | 0.194 | 0.877 | 0.530 | 489.000 | 68.000 |
| xgboost | internal_test_weighted | target_sensitivity_0_50 | 0.460 | 0.391 | 0.410 | 0.240 | 0.618 | 0.210 | -1.675 | 0.825 | 0.559 | 0.637 | 0.199 | 0.899 | 0.460 | 489.000 | 68.000 |
| xgboost | internal_test_weighted | top_10_pct | 0.601 | 0.100 | 0.202 | 0.240 | 0.618 | 0.210 | -1.675 | 0.825 | 0.191 | 0.914 | 0.265 | 0.875 | 0.601 | 489.000 | 68.000 |
| xgboost | internal_test_weighted | top_20_pct | 0.537 | 0.200 | 0.230 | 0.240 | 0.618 | 0.210 | -1.675 | 0.825 | 0.250 | 0.808 | 0.173 | 0.870 | 0.537 | 489.000 | 68.000 |
| ann | internal_test_weighted | max_f2 | 0.010 | 0.530 | 0.386 | 0.177 | 0.562 | 0.273 | -1.735 | 0.020 | 0.603 | 0.482 | 0.158 | 0.883 | 0.010 | 489.000 | 68.000 |
| ann | internal_test_weighted | target_sensitivity_0_30 | 0.630 | 0.319 | 0.327 | 0.177 | 0.562 | 0.273 | -1.735 | 0.020 | 0.412 | 0.696 | 0.179 | 0.880 | 0.630 | 489.000 | 68.000 |
| ann | internal_test_weighted | target_sensitivity_0_50 | 0.560 | 0.452 | 0.375 | 0.177 | 0.562 | 0.273 | -1.735 | 0.020 | 0.544 | 0.563 | 0.167 | 0.884 | 0.560 | 489.000 | 68.000 |
| ann | internal_test_weighted | top_10_pct | 0.929 | 0.100 | 0.156 | 0.177 | 0.562 | 0.273 | -1.735 | 0.020 | 0.147 | 0.907 | 0.204 | 0.868 | 0.929 | 489.000 | 68.000 |
| ann | internal_test_weighted | top_20_pct | 0.635 | 0.249 | 0.305 | 0.177 | 0.562 | 0.273 | -1.735 | 0.020 | 0.353 | 0.767 | 0.197 | 0.880 | 0.635 | 489.000 | 68.000 |

## External Validation Results With Class Weights

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| xgboost | external_validation_weighted | 0.267 | 0.447 | 0.209 | -2.001 | -0.027 | 0.167 | 0.795 | 0.100 | 0.875 | 0.500 | 50.000 | 6.000 |
| ann | external_validation_weighted | 0.202 | 0.536 | 0.232 | -1.928 | 0.053 | 0.167 | 0.773 | 0.091 | 0.872 | 0.500 | 50.000 | 6.000 |
| random_forest | external_validation_weighted | 0.131 | 0.451 | 0.112 | -2.693 | -0.276 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| elastic_net | external_validation_weighted | 0.123 | 0.455 | 0.119 | -2.599 | -0.053 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |

## External High-Risk Capture With Class Weights

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ann | external_validation_weighted | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| ann | external_validation_weighted | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| ann | external_validation_weighted | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |
| elastic_net | external_validation_weighted | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| elastic_net | external_validation_weighted | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| elastic_net | external_validation_weighted | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |
| random_forest | external_validation_weighted | top_5_pct | 0.050 | 3.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| random_forest | external_validation_weighted | top_10_pct | 0.100 | 5.000 | 0.000 | 0.000 | 0.000 | 0.000 | 0.000 |
| random_forest | external_validation_weighted | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |
| xgboost | external_validation_weighted | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| xgboost | external_validation_weighted | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| xgboost | external_validation_weighted | top_20_pct | 0.200 | 10.000 | 1.000 | 0.100 | 0.167 | 0.100 | 0.833 |

## External Threshold Rule Performance With Class Weights

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| elastic_net | external_validation_weighted | max_f2 | 0.010 | 0.200 | 0.147 | 0.123 | 0.455 | 0.119 | -2.599 | -0.053 | 0.167 | 0.795 | 0.100 | 0.875 | 0.010 | 50.000 | 6.000 |
| elastic_net | external_validation_weighted | target_sensitivity_0_30 | 0.020 | 0.160 | 0.156 | 0.123 | 0.455 | 0.119 | -2.599 | -0.053 | 0.167 | 0.841 | 0.125 | 0.881 | 0.020 | 50.000 | 6.000 |
| elastic_net | external_validation_weighted | top_10_pct | 0.089 | 0.040 | NA | 0.123 | 0.455 | 0.119 | -2.599 | -0.053 | 0.000 | 0.955 | 0.000 | 0.875 | 0.089 | 50.000 | 6.000 |
| elastic_net | external_validation_weighted | top_20_pct | 0.044 | 0.120 | 0.167 | 0.123 | 0.455 | 0.119 | -2.599 | -0.053 | 0.167 | 0.886 | 0.167 | 0.886 | 0.044 | 50.000 | 6.000 |
| random_forest | external_validation_weighted | max_f2 | 0.010 | 1.000 | 0.405 | 0.131 | 0.451 | 0.112 | -2.693 | -0.276 | 1.000 | 0.000 | 0.120 | NA | 0.010 | 50.000 | 6.000 |
| random_forest | external_validation_weighted | target_sensitivity_0_30 | 0.150 | 0.240 | 0.278 | 0.131 | 0.451 | 0.112 | -2.693 | -0.276 | 0.333 | 0.773 | 0.167 | 0.895 | 0.150 | 50.000 | 6.000 |
| random_forest | external_validation_weighted | target_sensitivity_0_50 | 0.100 | 0.400 | 0.227 | 0.131 | 0.451 | 0.112 | -2.693 | -0.276 | 0.333 | 0.591 | 0.100 | 0.867 | 0.100 | 50.000 | 6.000 |
| random_forest | external_validation_weighted | top_10_pct | 0.248 | 0.000 | NA | 0.131 | 0.451 | 0.112 | -2.693 | -0.276 | 0.000 | 1.000 | NA | 0.880 | 0.248 | 50.000 | 6.000 |
| random_forest | external_validation_weighted | top_20_pct | 0.196 | 0.080 | NA | 0.131 | 0.451 | 0.112 | -2.693 | -0.276 | 0.000 | 0.909 | 0.000 | 0.870 | 0.196 | 50.000 | 6.000 |
| xgboost | external_validation_weighted | max_f2 | 0.350 | 0.760 | 0.323 | 0.267 | 0.447 | 0.209 | -2.001 | -0.027 | 0.667 | 0.227 | 0.105 | 0.833 | 0.350 | 50.000 | 6.000 |
| xgboost | external_validation_weighted | target_sensitivity_0_30 | 0.530 | 0.160 | 0.156 | 0.267 | 0.447 | 0.209 | -2.001 | -0.027 | 0.167 | 0.841 | 0.125 | 0.881 | 0.530 | 50.000 | 6.000 |
| xgboost | external_validation_weighted | target_sensitivity_0_50 | 0.460 | 0.320 | 0.125 | 0.267 | 0.447 | 0.209 | -2.001 | -0.027 | 0.167 | 0.659 | 0.062 | 0.853 | 0.460 | 50.000 | 6.000 |
| xgboost | external_validation_weighted | top_10_pct | 0.601 | 0.080 | 0.179 | 0.267 | 0.447 | 0.209 | -2.001 | -0.027 | 0.167 | 0.932 | 0.250 | 0.891 | 0.601 | 50.000 | 6.000 |
| xgboost | external_validation_weighted | top_20_pct | 0.537 | 0.160 | 0.156 | 0.267 | 0.447 | 0.209 | -2.001 | -0.027 | 0.167 | 0.841 | 0.125 | 0.881 | 0.537 | 50.000 | 6.000 |
| ann | external_validation_weighted | max_f2 | 0.010 | 1.000 | 0.405 | 0.202 | 0.536 | 0.232 | -1.928 | 0.053 | 1.000 | 0.000 | 0.120 | NA | 0.010 | 50.000 | 6.000 |
| ann | external_validation_weighted | target_sensitivity_0_30 | 0.630 | 0.200 | 0.147 | 0.202 | 0.536 | 0.232 | -1.928 | 0.053 | 0.167 | 0.795 | 0.100 | 0.875 | 0.630 | 50.000 | 6.000 |
| ann | external_validation_weighted | target_sensitivity_0_50 | 0.560 | 0.200 | 0.147 | 0.202 | 0.536 | 0.232 | -1.928 | 0.053 | 0.167 | 0.795 | 0.100 | 0.875 | 0.560 | 50.000 | 6.000 |
| ann | external_validation_weighted | top_10_pct | 0.929 | 0.000 | NA | 0.202 | 0.536 | 0.232 | -1.928 | 0.053 | 0.000 | 1.000 | NA | 0.880 | 0.929 | 50.000 | 6.000 |
| ann | external_validation_weighted | top_20_pct | 0.635 | 0.200 | 0.147 | 0.202 | 0.536 | 0.232 | -1.928 | 0.053 | 0.167 | 0.795 | 0.100 | 0.875 | 0.635 | 50.000 | 6.000 |

## Selected Primary Class-Weighted Model

| primary_model_weighted | internal_pr_auc | internal_roc_auc | internal_brier_score | internal_calibration_slope | top10_recall | top10_ppv | top10_lift |
| --- | --- | --- | --- | --- | --- | --- | --- |
| xgboost | 0.240 | 0.618 | 0.210 | 0.825 | 0.191 | 0.265 | 1.908 |

## Ensemble Candidates

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| stacked_logistic | internal_test_ensemble | 0.259 | 0.625 | 0.115 | 0.164 | 1.106 | 0.029 | 0.998 | 0.667 | 0.864 | 0.500 | 489.000 | 68.000 |
| soft_vote_pr_weighted | internal_test_ensemble | 0.239 | 0.612 | 0.156 | -1.372 | 0.604 | 0.206 | 0.884 | 0.222 | 0.873 | 0.500 | 489.000 | 68.000 |
| soft_vote_equal | internal_test_ensemble | 0.235 | 0.606 | 0.162 | -1.442 | 0.520 | 0.353 | 0.850 | 0.276 | 0.891 | 0.500 | 489.000 | 68.000 |

## Ensemble Internal High-Risk Capture

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| stacked_logistic | internal_test_ensemble | top_5_pct | 0.050 | 25.000 | 8.000 | 0.320 | 0.118 | 0.320 | 2.301 |
| stacked_logistic | internal_test_ensemble | top_10_pct | 0.100 | 49.000 | 13.000 | 0.265 | 0.191 | 0.265 | 1.908 |
| stacked_logistic | internal_test_ensemble | top_20_pct | 0.200 | 98.000 | 25.000 | 0.255 | 0.368 | 0.255 | 1.834 |
| soft_vote_equal | internal_test_ensemble | top_5_pct | 0.050 | 25.000 | 6.000 | 0.240 | 0.088 | 0.240 | 1.726 |
| soft_vote_equal | internal_test_ensemble | top_10_pct | 0.100 | 49.000 | 10.000 | 0.204 | 0.147 | 0.204 | 1.468 |
| soft_vote_equal | internal_test_ensemble | top_20_pct | 0.200 | 98.000 | 26.000 | 0.265 | 0.382 | 0.265 | 1.908 |
| soft_vote_pr_weighted | internal_test_ensemble | top_5_pct | 0.050 | 25.000 | 7.000 | 0.280 | 0.103 | 0.280 | 2.014 |
| soft_vote_pr_weighted | internal_test_ensemble | top_10_pct | 0.100 | 49.000 | 10.000 | 0.204 | 0.147 | 0.204 | 1.468 |
| soft_vote_pr_weighted | internal_test_ensemble | top_20_pct | 0.200 | 98.000 | 27.000 | 0.276 | 0.397 | 0.276 | 1.981 |

## Ensemble Internal Threshold Rule Performance

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| stacked_logistic | internal_test_ensemble | max_f2 | 0.090 | 0.961 | 0.451 | 0.259 | 0.625 | 0.115 | 0.164 | 1.106 | 0.985 | 0.043 | 0.143 | 0.947 | 0.090 | 489.000 | 68.000 |
| stacked_logistic | internal_test_ensemble | target_sensitivity_0_30 | 0.170 | 0.194 | 0.327 | 0.259 | 0.625 | 0.115 | 0.164 | 1.106 | 0.353 | 0.831 | 0.253 | 0.888 | 0.170 | 489.000 | 68.000 |
| stacked_logistic | internal_test_ensemble | target_sensitivity_0_50 | 0.140 | 0.384 | 0.435 | 0.259 | 0.625 | 0.115 | 0.164 | 1.106 | 0.588 | 0.648 | 0.213 | 0.907 | 0.140 | 489.000 | 68.000 |
| stacked_logistic | internal_test_ensemble | top_10_pct | 0.198 | 0.100 | 0.202 | 0.259 | 0.625 | 0.115 | 0.164 | 1.106 | 0.191 | 0.914 | 0.265 | 0.875 | 0.198 | 489.000 | 68.000 |
| stacked_logistic | internal_test_ensemble | top_20_pct | 0.168 | 0.200 | 0.338 | 0.259 | 0.625 | 0.115 | 0.164 | 1.106 | 0.368 | 0.827 | 0.255 | 0.890 | 0.168 | 489.000 | 68.000 |
| soft_vote_equal | internal_test_ensemble | max_f2 | 0.120 | 0.953 | 0.454 | 0.235 | 0.606 | 0.162 | -1.442 | 0.520 | 0.985 | 0.052 | 0.144 | 0.957 | 0.120 | 489.000 | 68.000 |
| soft_vote_equal | internal_test_ensemble | target_sensitivity_0_30 | 0.500 | 0.178 | 0.334 | 0.235 | 0.606 | 0.162 | -1.442 | 0.520 | 0.353 | 0.850 | 0.276 | 0.891 | 0.500 | 489.000 | 68.000 |
| soft_vote_equal | internal_test_ensemble | target_sensitivity_0_50 | 0.370 | 0.362 | 0.390 | 0.235 | 0.606 | 0.162 | -1.442 | 0.520 | 0.515 | 0.663 | 0.198 | 0.894 | 0.370 | 489.000 | 68.000 |
| soft_vote_equal | internal_test_ensemble | top_10_pct | 0.549 | 0.100 | 0.156 | 0.235 | 0.606 | 0.162 | -1.442 | 0.520 | 0.147 | 0.907 | 0.204 | 0.868 | 0.549 | 489.000 | 68.000 |
| soft_vote_equal | internal_test_ensemble | top_20_pct | 0.485 | 0.200 | 0.351 | 0.235 | 0.606 | 0.162 | -1.442 | 0.520 | 0.382 | 0.829 | 0.265 | 0.893 | 0.485 | 489.000 | 68.000 |
| soft_vote_pr_weighted | internal_test_ensemble | max_f2 | 0.140 | 0.924 | 0.456 | 0.239 | 0.612 | 0.156 | -1.372 | 0.604 | 0.971 | 0.083 | 0.146 | 0.946 | 0.140 | 489.000 | 68.000 |
| soft_vote_pr_weighted | internal_test_ensemble | target_sensitivity_0_30 | 0.490 | 0.155 | 0.302 | 0.239 | 0.612 | 0.156 | -1.372 | 0.604 | 0.309 | 0.869 | 0.276 | 0.886 | 0.490 | 489.000 | 68.000 |
| soft_vote_pr_weighted | internal_test_ensemble | target_sensitivity_0_50 | 0.370 | 0.342 | 0.410 | 0.239 | 0.612 | 0.156 | -1.372 | 0.604 | 0.529 | 0.689 | 0.216 | 0.901 | 0.370 | 489.000 | 68.000 |
| soft_vote_pr_weighted | internal_test_ensemble | top_10_pct | 0.517 | 0.100 | 0.156 | 0.239 | 0.612 | 0.156 | -1.372 | 0.604 | 0.147 | 0.907 | 0.204 | 0.868 | 0.517 | 489.000 | 68.000 |
| soft_vote_pr_weighted | internal_test_ensemble | top_20_pct | 0.456 | 0.200 | 0.365 | 0.239 | 0.612 | 0.156 | -1.372 | 0.604 | 0.397 | 0.831 | 0.276 | 0.895 | 0.456 | 489.000 | 68.000 |

## Ensemble External Validation Results

| model_name | dataset | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| stacked_logistic | external_validation_ensemble | 0.221 | 0.527 | 0.105 | -0.620 | 0.700 | 0.000 | 1.000 | NA | 0.880 | 0.500 | 50.000 | 6.000 |
| soft_vote_pr_weighted | external_validation_ensemble | 0.202 | 0.523 | 0.139 | -1.687 | 0.302 | 0.167 | 0.932 | 0.250 | 0.891 | 0.500 | 50.000 | 6.000 |
| soft_vote_equal | external_validation_ensemble | 0.202 | 0.515 | 0.142 | -1.698 | 0.289 | 0.167 | 0.909 | 0.200 | 0.889 | 0.500 | 50.000 | 6.000 |

## Ensemble External High-Risk Capture

| model_name | dataset | top_k | proportion_flagged | n_flagged | events_captured | event_rate | recall | ppv | lift |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| stacked_logistic | external_validation_ensemble | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| stacked_logistic | external_validation_ensemble | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| stacked_logistic | external_validation_ensemble | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |
| soft_vote_equal | external_validation_ensemble | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| soft_vote_equal | external_validation_ensemble | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| soft_vote_equal | external_validation_ensemble | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |
| soft_vote_pr_weighted | external_validation_ensemble | top_5_pct | 0.050 | 3.000 | 1.000 | 0.333 | 0.167 | 0.333 | 2.778 |
| soft_vote_pr_weighted | external_validation_ensemble | top_10_pct | 0.100 | 5.000 | 1.000 | 0.200 | 0.167 | 0.200 | 1.667 |
| soft_vote_pr_weighted | external_validation_ensemble | top_20_pct | 0.200 | 10.000 | 2.000 | 0.200 | 0.333 | 0.200 | 1.667 |

## Ensemble External Threshold Rule Performance

| model_name | dataset | rule_name | threshold_rule | flagged_fraction | f2_score | pr_auc | roc_auc | brier_score | calibration_intercept | calibration_slope | sensitivity | specificity | ppv | npv | threshold | n | events |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| stacked_logistic | external_validation_ensemble | max_f2 | 0.090 | 0.960 | 0.417 | 0.221 | 0.527 | 0.105 | -0.620 | 0.700 | 1.000 | 0.045 | 0.125 | 1.000 | 0.090 | 50.000 | 6.000 |
| stacked_logistic | external_validation_ensemble | target_sensitivity_0_30 | 0.170 | 0.140 | 0.323 | 0.221 | 0.527 | 0.105 | -0.620 | 0.700 | 0.333 | 0.886 | 0.286 | 0.907 | 0.170 | 50.000 | 6.000 |
| stacked_logistic | external_validation_ensemble | target_sensitivity_0_50 | 0.140 | 0.220 | 0.286 | 0.221 | 0.527 | 0.105 | -0.620 | 0.700 | 0.333 | 0.795 | 0.182 | 0.897 | 0.140 | 50.000 | 6.000 |
| stacked_logistic | external_validation_ensemble | top_10_pct | 0.198 | 0.100 | 0.172 | 0.221 | 0.527 | 0.105 | -0.620 | 0.700 | 0.167 | 0.909 | 0.200 | 0.889 | 0.198 | 50.000 | 6.000 |
| stacked_logistic | external_validation_ensemble | top_20_pct | 0.168 | 0.140 | 0.323 | 0.221 | 0.527 | 0.105 | -0.620 | 0.700 | 0.333 | 0.886 | 0.286 | 0.907 | 0.168 | 50.000 | 6.000 |
| soft_vote_equal | external_validation_ensemble | max_f2 | 0.120 | 0.980 | 0.411 | 0.202 | 0.515 | 0.142 | -1.698 | 0.289 | 1.000 | 0.023 | 0.122 | 1.000 | 0.120 | 50.000 | 6.000 |
| soft_vote_equal | external_validation_ensemble | target_sensitivity_0_30 | 0.500 | 0.100 | 0.172 | 0.202 | 0.515 | 0.142 | -1.698 | 0.289 | 0.167 | 0.909 | 0.200 | 0.889 | 0.500 | 50.000 | 6.000 |
| soft_vote_equal | external_validation_ensemble | target_sensitivity_0_50 | 0.370 | 0.240 | 0.278 | 0.202 | 0.515 | 0.142 | -1.698 | 0.289 | 0.333 | 0.773 | 0.167 | 0.895 | 0.370 | 50.000 | 6.000 |
| soft_vote_equal | external_validation_ensemble | top_10_pct | 0.549 | 0.060 | 0.185 | 0.202 | 0.515 | 0.142 | -1.698 | 0.289 | 0.167 | 0.955 | 0.333 | 0.894 | 0.549 | 50.000 | 6.000 |
| soft_vote_equal | external_validation_ensemble | top_20_pct | 0.485 | 0.140 | 0.323 | 0.202 | 0.515 | 0.142 | -1.698 | 0.289 | 0.333 | 0.886 | 0.286 | 0.907 | 0.485 | 50.000 | 6.000 |
| soft_vote_pr_weighted | external_validation_ensemble | max_f2 | 0.140 | 0.980 | 0.411 | 0.202 | 0.523 | 0.139 | -1.687 | 0.302 | 1.000 | 0.023 | 0.122 | 1.000 | 0.140 | 50.000 | 6.000 |
| soft_vote_pr_weighted | external_validation_ensemble | target_sensitivity_0_30 | 0.490 | 0.100 | 0.172 | 0.202 | 0.523 | 0.139 | -1.687 | 0.302 | 0.167 | 0.909 | 0.200 | 0.889 | 0.490 | 50.000 | 6.000 |
| soft_vote_pr_weighted | external_validation_ensemble | target_sensitivity_0_50 | 0.370 | 0.220 | 0.286 | 0.202 | 0.523 | 0.139 | -1.687 | 0.302 | 0.333 | 0.795 | 0.182 | 0.897 | 0.370 | 50.000 | 6.000 |
| soft_vote_pr_weighted | external_validation_ensemble | top_10_pct | 0.517 | 0.080 | 0.179 | 0.202 | 0.523 | 0.139 | -1.687 | 0.302 | 0.167 | 0.932 | 0.250 | 0.891 | 0.517 | 50.000 | 6.000 |
| soft_vote_pr_weighted | external_validation_ensemble | top_20_pct | 0.456 | 0.140 | 0.323 | 0.202 | 0.523 | 0.139 | -1.687 | 0.302 | 0.333 | 0.886 | 0.286 | 0.907 | 0.456 | 50.000 | 6.000 |

## Selected Ensemble

| primary_ensemble | internal_pr_auc | internal_roc_auc | internal_brier_score | internal_calibration_slope | top10_recall | top10_ppv | top10_lift |
| --- | --- | --- | --- | --- | --- | --- | --- |
| stacked_logistic | 0.259 | 0.625 | 0.115 | 1.106 | 0.191 | 0.265 | 1.908 |

## Ensemble Weights And Coefficients

### PR-Weighted Soft Voting

| component_id | weight |
| --- | --- |
| original_xgboost | 0.3595 |
| smote_ann | 0.2767 |
| weighted_xgboost | 0.3638 |

### Stacked Logistic Coefficients

| term | coefficient |
| --- | --- |
| (Intercept) | -2.5861 |
| original_xgboost | 3.9124 |
| smote_ann | 0.4467 |
| weighted_xgboost | 0.0337 |

## Smoke Tests

| test_name | status | details |
| --- | --- | --- |
| development_dataset_exists | PASS | Development dataset exists. |
| external_dataset_exists | PASS | External dataset exists. |
| harmonized_feature_columns_match | PASS | Development and external model matrices share the same feature columns. |
| excluded_columns_absent | PASS | Excluded identifier, ASA, post-op, and CPT fields are absent from the development model dataset. |
| outcome_is_binary_yes_no | PASS | Development and external outcomes are encoded as No/Yes. |
| training_status_exists | PASS | Training status file exists. |
| at_least_one_model_trained | PASS | At least one benchmark model trained successfully. |
| training_status_smote_exists | PASS | SMOTE training status file exists. |
| at_least_one_smote_model_trained | PASS | At least one SMOTE benchmark model trained successfully. |
| training_status_weighted_exists | PASS | Weighted training status file exists. |
| at_least_one_weighted_model_trained | PASS | At least one weighted benchmark model trained successfully. |
| model_selection_exists | PASS | Model selection file exists. |
| external_metrics_exist | PASS | External metrics file exists. |
| model_selection_smote_exists | PASS | SMOTE model selection file exists. |
| external_metrics_smote_exist | PASS | SMOTE external metrics file exists. |
| model_selection_weighted_exists | PASS | Weighted model selection file exists. |
| external_metrics_weighted_exist | PASS | Weighted external metrics file exists. |
| ensemble_selection_exists | PASS | Ensemble model selection file exists. |
| ensemble_external_metrics_exist | PASS | Ensemble external metrics file exists. |
| internal_topk_exists | PASS | internal_topk exists. |
| internal_thresholds_exists | PASS | internal_thresholds exists. |
| external_topk_exists | PASS | external_topk exists. |
| external_thresholds_exists | PASS | external_thresholds exists. |
| internal_topk_smote_exists | PASS | internal_topk_smote exists. |
| internal_thresholds_smote_exists | PASS | internal_thresholds_smote exists. |
| external_topk_smote_exists | PASS | external_topk_smote exists. |
| external_thresholds_smote_exists | PASS | external_thresholds_smote exists. |
| internal_topk_weighted_exists | PASS | internal_topk_weighted exists. |
| internal_thresholds_weighted_exists | PASS | internal_thresholds_weighted exists. |
| external_topk_weighted_exists | PASS | external_topk_weighted exists. |
| external_thresholds_weighted_exists | PASS | external_thresholds_weighted exists. |
| ensemble_oof_exists | PASS | ensemble_oof exists. |
| ensemble_internal_topk_exists | PASS | ensemble_internal_topk exists. |
| ensemble_internal_thresholds_exists | PASS | ensemble_internal_thresholds exists. |
| ensemble_external_topk_exists | PASS | ensemble_external_topk exists. |
| ensemble_external_thresholds_exists | PASS | ensemble_external_thresholds exists. |
| publication_internal_table_exists | PASS | publication_internal_table exists. |
| publication_external_table_exists | PASS | publication_external_table exists. |
| publication_internal_original_roc_exists | PASS | publication_internal_original_roc exists. |
| publication_internal_smote_roc_exists | PASS | publication_internal_smote_roc exists. |
| publication_internal_weighted_roc_exists | PASS | publication_internal_weighted_roc exists. |
| publication_external_original_roc_exists | PASS | publication_external_original_roc exists. |
| publication_external_smote_roc_exists | PASS | publication_external_smote_roc exists. |
| publication_external_weighted_roc_exists | PASS | publication_external_weighted_roc exists. |
| shap_summary_exists | PASS | Primary-model SHAP summary exists. |
| shap_summary_smote_exists | PASS | Primary SMOTE-model SHAP summary exists. |
| shap_summary_weighted_exists | PASS | Primary weighted-model SHAP summary exists. |

## Output Artifacts

- Internal metrics: `results/metrics/internal_test_metrics.csv`
- Internal top-k metrics: `results/metrics/internal_test_topk_metrics.csv`
- Internal threshold metrics: `results/metrics/internal_test_threshold_rule_metrics.csv`
- External metrics: `results/metrics/external_validation_metrics.csv`
- External top-k metrics: `results/metrics/external_validation_topk_metrics.csv`
- External threshold metrics: `results/metrics/external_validation_threshold_rule_metrics.csv`
- SMOTE internal metrics: `results/metrics/internal_test_metrics_smote.csv`
- SMOTE internal top-k metrics: `results/metrics/internal_test_topk_metrics_smote.csv`
- SMOTE external metrics: `results/metrics/external_validation_metrics_smote.csv`
- SMOTE external top-k metrics: `results/metrics/external_validation_topk_metrics_smote.csv`
- Weighted internal metrics: `results/metrics/internal_test_metrics_weighted.csv`
- Weighted external metrics: `results/metrics/external_validation_metrics_weighted.csv`
- Publication internal comparison table: `results/metrics/publication_internal_model_comparison.csv`
- Publication external comparison table: `results/metrics/publication_external_model_comparison.csv`
- Publication key results table: `results/metrics/publication_key_results_table.csv`
- Ensemble internal metrics: `results/metrics/ensemble_internal_test_metrics.csv`
- Ensemble external metrics: `results/metrics/ensemble_external_validation_metrics.csv`
- Ensemble selection: `results/metrics/ensemble_model_selection.csv`
- Internal original ROC figure: `results/figures/publication_internal_original_roc.png`
- Internal SMOTE ROC figure: `results/figures/publication_internal_smote_roc.png`
- Internal weighted ROC figure: `results/figures/publication_internal_weighted_roc.png`
- External original ROC figure: `results/figures/publication_external_original_roc.png`
- External SMOTE ROC figure: `results/figures/publication_external_smote_roc.png`
- External weighted ROC figure: `results/figures/publication_external_weighted_roc.png`
- Smoke tests: `results/metrics/pipeline_smoke_tests.csv`
- Saved models: `results/models/`
- Figures: `results/figures/`

