# SkillBridge AI

**An AI-Powered Job and Skill Recommendation Mobile Application**

> Academic Project | Course: ITM 314 — Mobile Application Development (Android) Lab  
> Semester: Spring 2026 | Daffodil International University  
> Aligned with **UN Sustainable Development Goal 8** — Decent Work and Economic Growth

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Machine Learning Engine](#machine-learning-engine)
- [Project Structure](#project-structure)
- [Screens and UI](#screens-and-ui)
- [ML Model Evaluation Results](#ml-model-evaluation-results)
- [Functional Requirements Summary](#functional-requirements-summary)
- [Research Foundation](#research-foundation)
- [Dependencies](#dependencies)
- [Getting Started](#getting-started)
- [Team](#team)

---

## Overview

SkillBridge AI is a cross-platform mobile application built with **Flutter and Dart**. It is designed to help job seekers in Bangladesh — particularly fresh graduates and young professionals — find jobs that match their skills, identify what skills they are missing, and get personalized course recommendations to fill those gaps.

Unlike traditional job portals that simply list jobs, SkillBridge AI acts as a complete career guidance system. It combines two machine learning recommendation models, a Google Gemini AI chatbot, Firebase authentication, and a rich set of career analytics tools — all inside a single mobile app.

The application covers seven industry categories: **Software, Finance, Healthcare, Marketing, Manufacturing, Retail, and Education.**

---

## Features

| Feature | Description |
|---|---|
| AI Job Matching | Two ML models (TF-IDF and Sentence-BERT) match users to jobs based on skills |
| Skill Gap Analysis | Shows exactly which skills a user has and which are missing for each job |
| Course Recommendations | Suggests courses to fill skill gaps, ranked by personal learning preferences |
| Career Chatbot | Google Gemini 2.5 Flash powered chatbot for career questions |
| Confidence Tracker | Users rate and track their career confidence over time with visual charts |
| Application Tracker | Kanban board to track job applications through hiring stages |
| Geographic Insights | City-wise job demand map for Bangladesh with BDT salary data |
| Workforce Insights | Multi-generational workforce profiles and skill trends by industry |
| Assessment Hub | MCQ quizzes by topic and difficulty to measure skill readiness |
| Career Transition Planner | Shows skill overlap and transition difficulty between two job roles |
| CV Upload and Parsing | Extracts skills automatically from uploaded PDF, DOCX, or TXT resumes |
| Job Alerts | Saved search alerts with instant, daily, or weekly notification frequency |
| Dark and Light Theme | Fully supported across all screens, persisted across sessions |
| SDG-8 Alignment | Built with the goal of promoting decent work and economic growth |

---

## Technology Stack

| Layer | Technology |
|---|---|
| Mobile Framework | Flutter (Dart SDK ^3.8.1) |
| State Management | Provider + ChangeNotifier |
| Authentication and Database | Firebase Auth + Cloud Firestore |
| AI Chatbot | Google Gemini 2.5 Flash (REST API) |
| On-Device ML | Pure Dart — TF-IDF, Cosine Similarity, Jaccard, RCA, Local SBERT |
| Optional SBERT Server | Python Flask microservice for semantic re-ranking |
| Charts | fl_chart |
| Animations | flutter_animate, lottie |
| Fonts | Plus Jakarta Sans, Google Fonts |
| CV Parsing | syncfusion_flutter_pdf, archive |
| Local Storage | SharedPreferences |
| HTTP | package:http |

---

## Machine Learning Engine

The recommendation engine was developed and trained in **Google Colab** on a dataset of **50,000 job postings** across 7 industries. All ML inference runs entirely on-device in pure Dart, with no internet connection required for the core features.

### Primary Model: TF-IDF + Cosine Similarity + Jaccard Coefficient

- Converts skill text into numeric vectors using Term Frequency-Inverse Document Frequency
- Measures vector closeness using Cosine Similarity
- Adds skill set overlap score using Jaccard Coefficient
- Final Score formula: `0.80 × Cosine Similarity + 0.20 × Jaccard Coefficient`
- Test accuracy: **82.3%**

### Improved Model: Sentence-BERT + Cosine Similarity + Jaccard Coefficient

- Uses the `all-MiniLM-L6-v2` transformer to generate 384-dimensional semantic embeddings
- Understands meaning rather than just keywords (e.g., knows "talent acquisition" and "recruitment" are related)
- Final Score formula: `0.85 × Semantic Cosine Score + 0.15 × Jaccard Coefficient`
- Test accuracy: **85.0%**

### Full ML Pipeline (10 Steps)

1. TF-IDF vectorization with BM25 term saturation
2. Cosine similarity scoring with skill weight boosting (2x for known skills)
3. Jaccard coefficient overlap scoring
4. Asymmetric skill coverage (how much of the job requirements the user covers)
5. BM25 frequency dampening to prevent common skills from dominating
6. Temporal decay to boost newer job listings
7. MMR diversity re-ranking to ensure results span multiple industries
8. Cross-domain transfer scoring
9. Fairness and bias audit using Shannon entropy
10. Percentile ranking with human-readable explanations

---

## Project Structure

```
lib/
├── main.dart                     # App entry point, Firebase config, route definitions
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── email_verification_screen.dart
│   │   └── forget_password_screen.dart
│   ├── main_nav.dart             # Bottom navigation shell with 5 tabs and side drawer
│   ├── home.dart
│   ├── job_result.dart
│   ├── skill_gap.dart
│   ├── skill_input.dart
│   ├── job_transition_screen.dart
│   ├── job_alerts_screen.dart
│   ├── browse_courses_screen.dart
│   ├── learning.dart
│   ├── career_guide.dart
│   ├── dashboard_screen.dart
│   ├── assessment_hub_screen.dart
│   ├── confidence_tracker_screen.dart
│   ├── skill_trends_screen.dart
│   ├── workforce_insights_screen.dart
│   ├── geo_insights_screen.dart
│   ├── application_tracker_screen.dart
│   ├── profile_input.dart
│   ├── cv_upload_screen.dart
│   ├── chatbot_screen.dart
│   └── privacy_settings_screen.dart
├── ml/
│   ├── recommender.dart          # Main 10-step ML pipeline
│   ├── tfidf.dart                # TF-IDF vectorizer with BM25 and synonym handling
│   ├── cosine.dart               # Cosine similarity with L2 normalization
│   ├── jaccard.dart              # Jaccard coefficient and asymmetric skill coverage
│   ├── sbert.dart                # Offline 32-dim SBERT approximation
│   ├── rca_calculator.dart       # Revealed Comparative Advantage skill importance
│   ├── skills_space.dart         # Occupation-level similarity (Theta score)
│   ├── skill_similarity.dart     # Skill co-occurrence with symmetric pair-key hashing
│   └── skill_prioritizer.dart    # Ranks missing skills: Learn First / Learn Soon / Optional
├── data/
│   ├── jobs.dart                 # 50,000 job postings across 7 industries
│   ├── courses.dart              # Full course catalogue with provider, URL, cost, rating
│   ├── career_guidance_data.dart # Career path analysis from 1,000 student records
│   ├── fairness_monitor.dart     # Bias detection with Shannon entropy
│   ├── intention_tracker.dart    # Employment intention tracking over time
│   └── learner_preferences.dart  # 15-dimensional learner preference vector
├── models/
│   └── career_profile.dart       # Core user data model with typed enums
├── services/
│   ├── app_state.dart            # Central state — profile, skills, theme, ML scoring
│   ├── gemini_chat_service.dart  # Gemini 2.5 Flash API client with retry and cancel
│   └── sbert_service.dart        # Optional Python SBERT server with offline fallback
└── theme/
    ├── app_theme.dart            # Global design system — colors, typography, Material 3 themes
    ├── app_widgets.dart          # Shared widgets — score badges, skill chips, match rings
    └── confidence_tracker_screen_fixed.dart
```

**Total: 49 Dart files across 7 folders and 25 screens**

---

## Screens and UI

| Screen | Description |
|---|---|
| Splash Screen | Logo animation, SDG-8 badge, auto login check |
| Login Screen | Email/password, Google, LinkedIn, and biometric login |
| Register Screen | Name, email, password, field of study, initial skills |
| Profile Input | Edit career profile with completeness bar and achievement badges |
| Home Screen | Welcome greeting, quick-action cards, recent matches, featured courses |
| Job Results | Ranked job cards with match score, required skills, and salary in BDT |
| Skill Gap | Green (have) / Red (missing) skill breakdown, readiness %, course links |
| Browse Courses | Full course catalogue with filter by category, format, and cost |
| Learning Tab | Personalized courses ranked by your 15-dim learning preference vector |
| Career Guide | Career paths, industry match scores, tips, and success probability |
| Career Transition | Skill overlap %, transition difficulty, and prioritized skills to learn |
| Chatbot | Multi-turn Gemini AI chat with CV attachment support |
| Dashboard | Readiness score ring, skill match chart, application pipeline summary |
| Assessment Hub | MCQ quizzes with score ring and subtopic breakdown |
| Confidence Tracker | Self-rate by category, line charts of confidence over time |
| Skill Trends | Top 10 rising skills with year-on-year demand growth |
| Workforce Insights | Gen Z, Millennial, Gen X, Boomer profiles and bridge skills |
| Geographic Insights | City-wise job demand in Bangladesh with BDT salary data |
| Application Tracker | Kanban board: Wishlist, Applied, Interview, Offer, Rejected |
| CV Upload | 5-step animated pipeline to extract skills from your resume |
| Job Alerts | Saved search alerts with keyword, location, type, and frequency filters |
| Privacy Settings | Data collection overview, consent toggles, and activity audit log |

---

## ML Model Evaluation Results

Both models were evaluated on a stratified 80/20 train-test split of the 50,000-job dataset. A proxy evaluation strategy was used: the model receives the first 2 required skills of a test job and must predict the correct industry.

| Model | Split | Accuracy | Precision | Recall | F1 | RMSE | MAE |
|---|---|---|---|---|---|---|---|
| TF-IDF + Cosine + Jaccard | Train | ~0.905 | ~0.905 | ~0.905 | ~0.905 | ~1.82 | ~1.41 |
| TF-IDF + Cosine + Jaccard | Test | ~0.823 | ~0.823 | ~0.823 | ~0.822 | ~1.89 | ~1.47 |
| Sentence-BERT + Cosine + Jaccard | Train | ~0.928 | ~0.928 | ~0.928 | ~0.928 | ~1.74 | ~1.35 |
| Sentence-BERT + Cosine + Jaccard | Test | ~0.850 | ~0.850 | ~0.849 | ~0.849 | ~1.81 | ~1.40 |

The SBERT model shows higher accuracy and lower error on both splits, with a small gap between training and test scores confirming that neither model is significantly overfitting.

---

## Functional Requirements Summary

The app implements **59 functional requirements** across 6 categories:

- **Authentication (FR-01 to FR-08):** Email/password, Google, LinkedIn, biometric login, email verification, password reset, and logout
- **Profile and CV (FR-09 to FR-17):** Career profile editing, photo upload, completeness tracking, CV upload with 5-step skill extraction pipeline
- **Job Matching and Skill Gap (FR-18 to FR-27):** TF-IDF + Cosine + Jaccard + SBERT matching, match score badges, skill gap breakdown, readiness percentage
- **Learning and Courses (FR-28 to FR-35):** Course catalogue, filters, learner preference ranking, career path recommendations
- **Transition, Assessments and Tracking (FR-36 to FR-53):** Career transition planner, MCQ assessments, confidence tracker, dashboard, skill trends, geographic insights, workforce insights, Kanban application tracker, job alerts
- **Chatbot and Privacy (FR-54 to FR-59):** Multi-turn Gemini chatbot with CV attachment, consent toggles, activity audit log

The app also implements **33 non-functional requirements** covering performance, scalability, reliability, security, usability, code quality, and ethics and compliance.

---

## Research Foundation

This project is built on 8 peer-reviewed research papers:

| Paper | Contribution |
|---|---|
| Ajjam and Al-Raweshidy (2026) | TF-IDF + Cosine job matching, greedy one-to-one matching, cross-domain transfer, bias audit |
| Alsaif et al. (2022) | Skill weighting (2x for known skills), Jaccard vs Cosine comparison, tokenization pipeline |
| Tavakoli et al. (2022) | 15-dimensional learner preference vector, dot-product course scoring, content taxonomy |
| Dawson et al. (2021) | RCA skill importance, occupation similarity Theta, job transition probability |
| Zhisheng Chen (2022) | AI-human recruitment model, 6-stage hiring pipeline, Person-Job Fit, bias removal |
| Li Huang (2022) | Employment intention classification into 5 categories, longitudinal intention tracking |
| Xiao and Zheng (2025) | Career confidence self-assessment, category-based tracking over time |
| Alaql et al. (2023) | Multi-generational workforce analysis — Gen Z, Millennial, Gen X, Boomer profiles |

---

## Dependencies

```yaml
dependencies:
  provider: ^6.1.1
  shared_preferences: ^2.3.0
  google_sign_in: ^6.2.1
  local_auth: ^2.3.0
  flutter_web_auth_2: ^4.0.0
  fl_chart: ^1.1.1
  flutter_animate: ^4.3.0
  lottie: ^3.0.0
  shimmer: ^3.0.0
  word_cloud: 1.0.3
  google_fonts: ^8.0.2
  http: ^1.2.0
  cached_network_image: ^3.3.1
  intl: ^0.20.2
  file_picker: ^10.3.10
  syncfusion_flutter_pdf: ^33.1.46
  archive: ^3.6.1
  url_launcher: ^6.3.0
  image_picker: ^1.1.2
  firebase_core: latest
  firebase_auth: latest
  cloud_firestore: latest
```

---

## Getting Started

### Prerequisites

- Flutter SDK (version compatible with Dart SDK ^3.8.1)
- Android Studio or Visual Studio Code with Flutter and Dart extensions
- A Firebase project with Authentication and Firestore enabled
- A Google Gemini API key

### Setup Steps

**Step 1.** Clone or download this repository to your local machine.

**Step 2.** Open the project in Android Studio or VS Code.

**Step 3.** Run the following command to install all dependencies:

```bash
flutter pub get
```

**Step 4.** Add your Firebase configuration file:
- For Android: place `google-services.json` inside the `android/app/` folder
- For iOS: place `GoogleService-Info.plist` inside the `ios/Runner/` folder

**Step 5.** Run the app with your Gemini API key injected at build time using `--dart-define`:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
```

**Step 6 (Optional).** To enable full SBERT semantic re-ranking, start the Python Flask server:

```bash
cd sbert_server/
pip install -r requirements.txt
python app.py
```

### Notes

- The app never crashes if the SBERT server is unreachable. It automatically falls back to the offline Dart SBERT approximation.
- The Gemini API key must never be hardcoded in source code. Always use `--dart-define` as shown above.
- The app is locked to portrait orientation only.
- All currency values are displayed in Bangladeshi Taka (BDT) using the symbol.

---

> Department of Information Technology and Management  
> Faculty of Science and Information Technology  
> Daffodil International University
