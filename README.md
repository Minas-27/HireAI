# HireAI

AI-powered interview and recruitment platform designed to make candidate evaluation more accessible, structured, and data-driven.

HireAI combines AI-powered interviews, multilingual voice interaction, automated candidate analysis, and recruiter tools into a single recruitment workflow. The platform supports both English and Amharic to better serve diverse talent pools.

## Features

- **Multilingual AI Interviews** — Conduct interviews in English and Amharic with seamless language switching.
- **AI-Powered Candidate Analysis** — Analyze interview responses and generate candidate scores, insights, and performance evaluations using Google Gemini.
- **Voice-Based Interviews** — Provide natural voice interactions using Voiceflow, Addis AI, and ElevenLabs.
- **Recruiter Dashboard** — Manage recruitment campaigns, monitor candidates, and review interview results.
- **Candidate Tracking** — Track candidates throughout the recruitment process and review their interview performance.
- **Interview Auditing** — Provide structured scoring and analysis to support more consistent hiring decisions.
- **Interactive UI** — Modern interface with smooth transitions, animations, and reusable components.

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application framework |
| Dart | Programming language |
| Voiceflow | AI interview orchestration and English voice interaction |
| Addis AI | Amharic AI interaction |
| ElevenLabs | AI voice synthesis |
| Google Gemini | Candidate analysis and evaluation |
| Provider | State management |
| Lottie | UI animations |
| Animate Do | UI animations and transitions |

## Project Structure

```text
lib/
├── models/         # Application data models
├── screens/        # Application screens and UI layers
├── services/       # AI, voice, and application services
├── theme/          # Design tokens, themes, and styling
├── utils/          # Helpers, constants, and utilities
└── widgets/        # Reusable UI components
```

## Getting Started

### Prerequisites

Before running the project, make sure you have:

- Flutter SDK 3.7.0 or later
- Dart SDK compatible with the installed Flutter version
- Android Studio or Visual Studio Code
- API credentials for the required AI and voice services

### Installation

Clone the repository:

```bash
git clone https://github.com/Minas-27/HireAI.git
cd HireAI
```

Install the project dependencies:

```bash
flutter pub get
```

### Environment Configuration

Create a `.env` file in the project root and configure the required API credentials:

```env
VOICEFLOW_API_KEY=your_key
ELEVENLABS_API_KEY=your_key
GEMINI_API_KEY=your_key
ADDIS_AI_API_KEY=your_key
```

Do not commit `.env` or any file containing API credentials to the repository.

### Run the Application

```bash
flutter run
```

## Application Workflow

HireAI is designed around a structured recruitment workflow:

```text
Recruiter
   |
   v
Create Recruitment Campaign
   |
   v
Candidate
   |
   v
AI-Powered Interview
   |
   +----------------------+
   |                      |
   v                      v
English                Amharic
Voiceflow              Addis AI
   |                      |
   +----------+-----------+
              |
              v
       Interview Analysis
              |
              v
        Gemini Evaluation
              |
              v
     Candidate Score & Insights
              |
              v
       Recruiter Dashboard
```

## Vision

HireAI aims to improve access to professional recruitment opportunities across Africa by combining multilingual AI interviews with structured candidate evaluation.

The platform is designed to help candidates communicate naturally in languages they are comfortable with while giving recruiters consistent tools for evaluating interview performance.

By supporting both English and Amharic voice interactions, HireAI addresses an important challenge in multilingual recruitment: enabling candidates to demonstrate their skills without language becoming an unnecessary barrier.

## Roadmap

- [x] AI-powered interview workflow
- [x] English voice interaction
- [x] Amharic voice interaction
- [x] AI-powered candidate analysis
- [x] Candidate scoring
- [x] Recruiter dashboard
- [x] Recruitment campaign management
- [x] Candidate tracking
- [ ] Expanded African language support
- [ ] Advanced candidate analytics
- [ ] Interview recording and review
- [ ] Automated recruitment reports
- [ ] Web-based recruiter dashboard
- [ ] Production deployment

## Contributing

Contributions and improvements are welcome.

1. Fork the repository.
2. Create a feature branch:

```bash
git checkout -b feature/AmazingFeature
```

3. Commit your changes:

```bash
git commit -m "Add AmazingFeature"
```

4. Push your branch:

```bash
git push origin feature/AmazingFeature
```

5. Open a Pull Request.

Please ensure that API keys and other sensitive configuration values are never committed to the repository.

## License

This project is currently maintained by the project team. Licensing information will be added as the project reaches its public release stage.

## Author

**Minas (Abraham Addisu)**

- GitHub: [@Minas-27](https://github.com/Minas-27)
- LinkedIn: [Abraham Addisu](https://www.linkedin.com/in/abraham-addisu-b39b08338)

## Acknowledgments

- Flutter
- Google Gemini
- Google ML Kit and AI ecosystem
- Voiceflow
- Addis AI
- ElevenLabs
- Flutter open-source community
