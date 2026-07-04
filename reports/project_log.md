# Project Log

This file is automatically updated by the analysis pipeline.
## 02 Build External Dataset

- Timestamp: 2026-03-27 15:52:29
- Source file: `C:/Users/Sunny/OneDrive/Desktop/Medical school/Machine Learning and Thesis/NSQIP/Unr_Aneu/External_testing.csv`
- Rows retained for validation: 50
- Prespecified severe external outcomes: 6
- Descriptive-only columns retained outside the model matrix: 79
## 02 Build External Dataset

- Timestamp: 2026-03-27 16:10:02
- Source file: `C:/Users/Sunny/OneDrive/Desktop/Medical school/Machine Learning and Thesis/NSQIP/Unr_Aneu/External_testing.csv`
- Rows retained for validation: 50
- Prespecified severe external outcomes: 6
- Descriptive-only columns retained outside the model matrix: 79
## 02 Build External Dataset

- Timestamp: 2026-03-27 16:13:02
- Source file: `C:/Users/Sunny/OneDrive/Desktop/Medical school/Machine Learning and Thesis/NSQIP/Unr_Aneu/External_testing.csv`
- Rows retained for validation: 50
- Prespecified severe external outcomes: 6
- Descriptive-only columns retained outside the model matrix: 79
## 02 Build External Dataset

- Timestamp: 2026-03-27 16:29:30
- Source file: `C:/Users/Sunny/OneDrive/Desktop/Medical school/Machine Learning and Thesis/NSQIP/Unr_Aneu/External_testing.csv`
- Rows retained for validation: 50
- Prespecified severe external outcomes: 6
- Descriptive-only columns retained outside the model matrix: 79
## 01 Build Development Dataset

- Timestamp: 2026-03-27 16:29:41
- Source file: `C:/Users/Sunny/OneDrive/Desktop/Medical school/Machine Learning and Thesis/NSQIP/Unr_Aneu/Unr_Aneu_Calculator/OLD_dataset/UnrAneu_Final_1RowPerCaseid.xlsx`
- Rows retained: 1625
- Severe outcomes (`dindo_scores >= 3`): 224
- Modeling features retained: 26
## 03 Train Benchmarks

- Timestamp: 2026-03-27 16:29:51
- Development training rows: 1136
- Internal test rows held out: 489
- Models attempted: elastic_net, random_forest, xgboost, knn
- Models trained successfully: 1
## 06 Render Reports

- Timestamp: 2026-03-27 16:30:00
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 04 Internal Evaluation

- Timestamp: 2026-03-27 16:30:00
- Internal test metrics generated for: knn
- Selected primary model: `knn`
- Final full-development model fits saved for external validation.
## 05 External Validation

- Timestamp: 2026-03-27 16:30:14
- External validation rows scored: 50
- Models externally validated: knn
- External severe outcome events: 6
## 06 Render Reports

- Timestamp: 2026-03-27 16:30:18
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 03 Train Benchmarks

- Timestamp: 2026-03-27 16:31:48
- Development training rows: 1136
- Internal test rows held out: 489
- Models attempted: elastic_net, random_forest, xgboost, knn
- Models trained successfully: 2
## 06 Render Reports

- Timestamp: 2026-03-27 16:32:08
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 04 Internal Evaluation

- Timestamp: 2026-03-27 16:32:24
- Internal test metrics generated for: random_forest, knn
- Selected primary model: `random_forest`
- Final full-development model fits saved for external validation.
## 05 External Validation

- Timestamp: 2026-03-27 16:32:29
- External validation rows scored: 50
- Models externally validated: random_forest, knn
- External severe outcome events: 6
## 06 Render Reports

- Timestamp: 2026-03-27 16:32:34
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 06 Render Reports

- Timestamp: 2026-03-27 16:35:36
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-27 16:35:36
- Smoke tests run: 10
- Passed: 9
- Failed: 1
## 05b Generate SHAP Explanations

- Timestamp: 2026-03-27 16:46:35
- Primary model explained: `random_forest`
- External observations explained: 50
- SHAP features summarized: 26
## 06 Render Reports

- Timestamp: 2026-03-27 16:46:44
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-27 16:46:44
- Smoke tests run: 10
- Passed: 10
- Failed: 0
## 06 Render Reports

- Timestamp: 2026-03-27 16:47:03
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 03 Train Benchmarks

- Timestamp: 2026-03-27 16:54:51
- Development training rows: 1136
- Internal test rows held out: 489
- Models attempted: elastic_net, random_forest, xgboost, knn, ann
- Models trained successfully: 3
## Smoke Tests

- Timestamp: 2026-03-27 16:55:01
- Smoke tests run: 10
- Passed: 10
- Failed: 0
## 05b Generate SHAP Explanations

- Timestamp: 2026-03-27 17:00:02
- Primary model explained: `random_forest`
- External observations explained: 50
- SHAP features summarized: 26
## 04 Internal Evaluation

- Timestamp: 2026-03-27 17:00:20
- Internal test metrics generated for: random_forest, knn, ann
- Selected primary model: `random_forest`
- Final full-development model fits saved for external validation.
## Smoke Tests

- Timestamp: 2026-03-27 17:00:30
- Smoke tests run: 10
- Passed: 10
- Failed: 0
## 06 Render Reports

- Timestamp: 2026-03-27 17:00:30
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 05 External Validation

- Timestamp: 2026-03-27 17:00:31
- External validation rows scored: 50
- Models externally validated: random_forest, knn, ann
- External severe outcome events: 6
## 05b Generate SHAP Explanations

- Timestamp: 2026-03-27 17:05:28
- Primary model explained: `random_forest`
- External observations explained: 50
- SHAP features summarized: 26
## 03b Train Benchmarks With SMOTE

- Timestamp: 2026-03-27 17:10:05
- Development training rows before SMOTE: 1136
- Internal test rows held out unchanged: 489
- Models attempted with SMOTE: elastic_net, random_forest, xgboost, knn, ann
- SMOTE models trained successfully: 3
## 03b Train Benchmarks With SMOTE

- Timestamp: 2026-03-27 17:11:09
- Development training rows before SMOTE: 1136
- Internal test rows held out unchanged: 489
- Models attempted with SMOTE: elastic_net, random_forest, xgboost, knn, ann
- SMOTE models trained successfully: 3
## 04b Internal Evaluation With SMOTE

- Timestamp: 2026-03-27 17:11:19
- Internal SMOTE test metrics generated for: random_forest, knn, ann
- Selected primary SMOTE model: `ann`
- Final full-development SMOTE model fits saved for external validation.
## 06 Render Reports

- Timestamp: 2026-03-27 17:11:29
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-27 17:11:29
- Smoke tests run: 15
- Passed: 13
- Failed: 2
## 05c External Validation With SMOTE

- Timestamp: 2026-03-27 17:11:29
- External validation rows scored with SMOTE-trained models: 50
- SMOTE models externally validated: random_forest, knn, ann
- External severe outcome events: 6
## 05d Generate SHAP Explanations With SMOTE

- Timestamp: 2026-03-27 17:14:27
- Primary SMOTE model explained: `ann`
- External observations explained with SMOTE model: 50
- SHAP features summarized: 26
## Smoke Tests

- Timestamp: 2026-03-27 17:14:48
- Smoke tests run: 15
- Passed: 15
- Failed: 0
## 06 Render Reports

- Timestamp: 2026-03-27 17:14:53
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 03 Train Benchmarks

- Timestamp: 2026-03-30 13:57:30
- Development training rows: 1136
- Internal test rows held out: 489
- Models attempted: elastic_net, random_forest, xgboost, knn, ann
- Models trained successfully: 5
## 04 Internal Evaluation

- Timestamp: 2026-03-30 13:57:58
- Internal test metrics generated for: elastic_net, random_forest, xgboost, knn, ann
- Selected primary model: `xgboost`
- Final full-development model fits saved for external validation.
## 05 External Validation

- Timestamp: 2026-03-30 13:58:06
- External validation rows scored: 50
- Models externally validated: elastic_net, random_forest, xgboost, knn, ann
- External severe outcome events: 6
## 05b Generate SHAP Explanations

- Timestamp: 2026-03-30 14:04:45
- Primary model explained: `xgboost`
- External observations explained: 50
- SHAP features summarized: 26
## 03b Train Benchmarks With SMOTE

- Timestamp: 2026-03-30 14:06:17
- Development training rows before SMOTE: 1136
- Internal test rows held out unchanged: 489
- Models attempted with SMOTE: elastic_net, random_forest, xgboost, knn, ann
- SMOTE models trained successfully: 5
## 04b Internal Evaluation With SMOTE

- Timestamp: 2026-03-30 14:06:30
- Internal SMOTE test metrics generated for: elastic_net, random_forest, xgboost, knn, ann
- Selected primary SMOTE model: `elastic_net`
- Final full-development SMOTE model fits saved for external validation.
## 05c External Validation With SMOTE

- Timestamp: 2026-03-30 14:06:39
- External validation rows scored with SMOTE-trained models: 50
- SMOTE models externally validated: elastic_net, random_forest, xgboost, knn, ann
- External severe outcome events: 6
## 05d Generate SHAP Explanations With SMOTE

- Timestamp: 2026-03-30 14:08:49
- Primary SMOTE model explained: `elastic_net`
- External observations explained with SMOTE model: 50
- SHAP features summarized: 26
## Smoke Tests

- Timestamp: 2026-03-30 14:09:05
- Smoke tests run: 15
- Passed: 15
- Failed: 0
## 06 Render Reports

- Timestamp: 2026-03-30 14:09:05
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 03 Train Benchmarks

- Timestamp: 2026-03-30 14:29:52
- Development training rows: 1136
- Internal test rows held out: 489
- Models attempted: elastic_net, random_forest, xgboost, knn, ann
- Models trained successfully: 5
## 04 Internal Evaluation

- Timestamp: 2026-03-30 14:30:00
- Internal test metrics generated for: elastic_net, random_forest, xgboost, knn, ann
- Selected primary model: `xgboost`
- Saved internal top-k capture, threshold grid, and locked threshold-rule outputs.
- Final full-development model fits saved for external validation.
## 05 External Validation

- Timestamp: 2026-03-30 14:30:02
- External validation rows scored: 50
- Models externally validated: elastic_net, random_forest, xgboost, knn, ann
- External severe outcome events: 6
- Applied locked internal threshold rules to the external cohort.
## 05b Generate SHAP Explanations

- Timestamp: 2026-03-30 14:34:50
- Primary model explained: `xgboost`
- External observations explained: 50
- SHAP features summarized: 26
## 03b Train Benchmarks With SMOTE

- Timestamp: 2026-03-30 14:36:21
- Development training rows before SMOTE: 1136
- Internal test rows held out unchanged: 489
- Models attempted with SMOTE: elastic_net, random_forest, xgboost, knn, ann
- SMOTE models trained successfully: 5
## 04b Internal Evaluation With SMOTE

- Timestamp: 2026-03-30 14:36:32
- Internal SMOTE test metrics generated for: elastic_net, random_forest, xgboost, knn, ann
- Selected primary SMOTE model: `elastic_net`
- Saved SMOTE top-k capture, threshold grid, and locked threshold-rule outputs.
- Final full-development SMOTE model fits saved for external validation.
## 05c External Validation With SMOTE

- Timestamp: 2026-03-30 14:36:35
- External validation rows scored with SMOTE-trained models: 50
- SMOTE models externally validated: elastic_net, random_forest, xgboost, knn, ann
- External severe outcome events: 6
- Applied locked internal SMOTE threshold rules to the external cohort.
## 05d Generate SHAP Explanations With SMOTE

- Timestamp: 2026-03-30 14:40:42
- Primary SMOTE model explained: `elastic_net`
- External observations explained with SMOTE model: 50
- SHAP features summarized: 26
## 03c Train Benchmarks With Class Weights

- Timestamp: 2026-03-30 14:41:40
- Development training rows before weighting: 1136
- Internal test rows held out unchanged: 489
- Models attempted with class weights: elastic_net, random_forest, xgboost, knn, ann
- Weighted models trained successfully: 4
## 04c Internal Evaluation With Class Weights

- Timestamp: 2026-03-30 14:41:48
- Internal weighted test metrics generated for: elastic_net, random_forest, xgboost, ann
- Selected primary weighted model: `xgboost`
- Saved weighted top-k capture, threshold grid, and locked threshold-rule outputs.
- Final full-development weighted model fits saved for external validation.
## 05e External Validation With Class Weights

- Timestamp: 2026-03-30 14:41:50
- External validation rows scored with weighted models: 50
- Weighted models externally validated: elastic_net, random_forest, xgboost, ann
- External severe outcome events: 6
- Applied locked internal weighted threshold rules to the external cohort.
## 05f Generate SHAP Explanations With Class Weights

- Timestamp: 2026-03-30 14:50:07
- Primary weighted model explained: `xgboost`
- External observations explained with weighted model: 50
- SHAP features summarized: 26
## 06 Render Reports

- Timestamp: 2026-03-30 14:50:07
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-30 14:50:08
- Smoke tests run: 32
- Passed: 32
- Failed: 0
## 03d Build Ensemble Candidates

- Timestamp: 2026-03-30 21:31:41
- Ensemble components: original_xgboost, smote_ann, weighted_xgboost
- OOF training rows generated for ensemble stacking: 1136
- Internal test prediction rows prepared for ensemble evaluation: 489
- External prediction rows prepared for ensemble evaluation: 50
## 06 Render Reports

- Timestamp: 2026-03-30 21:31:41
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-30 21:31:42
- Smoke tests run: 39
- Passed: 33
- Failed: 6
## 03d Build Ensemble Candidates

- Timestamp: 2026-03-30 21:32:11
- Ensemble components: original_xgboost, smote_ann, weighted_xgboost
- OOF training rows generated for ensemble stacking: 1136
- Internal test prediction rows prepared for ensemble evaluation: 489
- External prediction rows prepared for ensemble evaluation: 50
## 04d Internal Ensemble Evaluation

- Timestamp: 2026-03-30 21:32:14
- Ensemble candidates evaluated: stacked_logistic, soft_vote_pr_weighted, soft_vote_equal
- Selected primary ensemble: `stacked_logistic`
- Saved ensemble weights, stacked logistic coefficients, top-k capture, and locked threshold-rule outputs.
## 05g External Ensemble Validation

- Timestamp: 2026-03-30 21:32:15
- Ensemble candidates externally validated: stacked_logistic, soft_vote_pr_weighted, soft_vote_equal
- External rows scored for ensemble analysis: 50
- Applied locked internal ensemble threshold rules to the external cohort.
## 06 Render Reports

- Timestamp: 2026-03-30 21:32:15
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-30 21:32:15
- Smoke tests run: 39
- Passed: 39
- Failed: 0
## 06 Render Reports

- Timestamp: 2026-03-30 21:47:32
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-30 21:47:32
- Smoke tests run: 43
- Passed: 43
- Failed: 0
## 06 Render Reports

- Timestamp: 2026-03-30 21:54:21
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## Smoke Tests

- Timestamp: 2026-03-30 21:54:21
- Smoke tests run: 47
- Passed: 47
- Failed: 0
## 06 Render Reports

- Timestamp: 2026-03-30 21:58:24
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 06 Render Reports

- Timestamp: 2026-03-30 22:00:07
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 06 Render Reports

- Timestamp: 2026-03-30 22:05:03
- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.
- Project log remains cumulative and chronological.
## 08 Generate Publication Descriptive Tables

- Timestamp: 2026-03-30 22:36:44
- Generated internal-versus-external patient comparison table.
- Generated external aneurysm and procedure characteristics table.
- Generated model-definition table for the benchmarked algorithms and analysis strategies.
- Generated NSQIP development-variable and external variable-inventory tables for publication.
## 08 Generate Publication Descriptive Tables

- Timestamp: 2026-03-30 22:37:40
- Generated internal-versus-external patient comparison table.
- Generated external aneurysm and procedure characteristics table.
- Generated model-definition table for the benchmarked algorithms and analysis strategies.
- Generated NSQIP development-variable and external variable-inventory tables for publication.
## 09 Generate Internal vs External Significance Tests

- Timestamp: 2026-03-30 22:47:24
- Generated simple cohort-comparison tests across harmonized modeled variables.
- Used one-way ANOVA for numeric variables and chi-square tests for categorical variables.
- Added both raw and FDR-adjusted p-values to the publication table.
## 08 Generate Publication Descriptive Tables

- Timestamp: 2026-03-30 22:49:07
- Generated internal-versus-external patient comparison table.
- Generated external aneurysm and procedure characteristics table.
- Generated model-definition table for the benchmarked algorithms and analysis strategies.
- Generated NSQIP development-variable and external variable-inventory tables for publication.
## 08 Generate Publication Descriptive Tables

- Timestamp: 2026-03-30 22:50:36
- Generated internal-versus-external patient comparison table.
- Generated external aneurysm and procedure characteristics table.
- Generated model-definition table for the benchmarked algorithms and analysis strategies.
- Generated NSQIP development-variable and external variable-inventory tables for publication.
## 08 Generate Publication Descriptive Tables

- Timestamp: 2026-03-30 22:50:59
- Generated internal-versus-external patient comparison table.
- Generated external aneurysm and procedure characteristics table.
- Generated model-definition table for the benchmarked algorithms and analysis strategies.
- Generated NSQIP development-variable and external variable-inventory tables for publication.
## 10 Build Development Dataset With ASA

- Timestamp: 2026-04-04 16:24:04
- Source file: `C:/Users/Sunny/OneDrive/Desktop/Medical school/Machine Learning and Thesis/NSQIP/Unr_Aneu/Unr_Aneu_Calculator/OLD_dataset/UnrAneu_Final_1RowPerCaseid.xlsx`
- Mapping file: `feature_mapping_asa.csv`
- Rows retained: 1625
- Severe outcomes (`dindo_scores >= 3`): 224
- Modeling features retained: 27
## 11 Build External Dataset With ASA

- Timestamp: 2026-04-04 16:24:04
- Source file: `C:/Users/Sunny/OneDrive/Desktop/Medical school/Machine Learning and Thesis/NSQIP/Unr_Aneu/External_testing.csv`
- Mapping file: `feature_mapping_asa.csv`
- Rows retained for validation: 50
- External severe outcomes: 6
- Modeling features retained: 27
## 12 Train Benchmarks With ASA

- Timestamp: 2026-04-04 16:26:42
- Dataset tag: `asa`
- Analysis tag: `asa`
- Development training rows: 1136
- Internal test rows held out: 489
- Models trained successfully: 5
## 12b Train Benchmarks With SMOTE And ASA

- Timestamp: 2026-04-04 16:30:54
- Dataset tag: `asa`
- Analysis tag: `smote_asa`
- Development training rows: 1136
- Internal test rows held out: 489
- Models trained successfully: 5
## 12c Train Benchmarks With Class Weights And ASA

- Timestamp: 2026-04-04 16:34:04
- Dataset tag: `asa`
- Analysis tag: `weighted_asa`
- Development training rows: 1136
- Internal test rows held out: 489
- Models trained successfully: 4
## 13 Internal Evaluation With ASA

- Timestamp: 2026-04-04 16:34:19
- Internal test metrics generated for: elastic_net, random_forest, xgboost, knn, ann
- Selected primary model: `xgboost`
## 13b Internal Evaluation With SMOTE And ASA

- Timestamp: 2026-04-04 16:34:40
- Internal test metrics generated for: elastic_net, random_forest, xgboost, knn, ann
- Selected primary model: `elastic_net`
## 13c Internal Evaluation With Class Weights And ASA

- Timestamp: 2026-04-04 16:34:53
- Internal test metrics generated for: elastic_net, random_forest, xgboost, ann
- Selected primary model: `xgboost`
## 14 External Validation With ASA

- Timestamp: 2026-04-04 16:34:55
- External validation rows scored: 50
- Models externally validated: elastic_net, random_forest, xgboost, knn, ann
## 14b External Validation With SMOTE And ASA

- Timestamp: 2026-04-04 16:34:58
- External validation rows scored: 50
- Models externally validated: elastic_net, random_forest, xgboost, knn, ann
## 14c External Validation With Class Weights And ASA

- Timestamp: 2026-04-04 16:35:00
- External validation rows scored: 50
- Models externally validated: elastic_net, random_forest, xgboost, ann
