# HireAI - AI-Powered Interview & Recruitment Platform

HireAI is a state-of-the-art recruitment platform designed to solve the **African Talent Paradox** by leveraging advanced AI to conduct, analyze, and audit candidate interviews. It features a unique dual-voice system supporting both English and Amharic, ensuring professional expression and data-driven hiring decisions.

---

## 🚀 Key Features

- **Dual-Voice AI Interviews**: Seamless switching between English (Voiceflow) and Amharic (Addis AI) to cater to diverse talent pools.
- **Real-Time AI Analysis**: Powered by Gemini to provide instant auditing, scoring, and performance insights for every candidate.
- **Premium User Experience**: Interactive interfaces with Lottie animations, smooth transitions, and a glassmorphism design aesthetic.
- **Recruiter Dashboard**: Comprehensive campaign management, candidate tracking, and score auditing to ensure accountability.
- **High-Fidelity Audio**: Integration with ElevenLabs for lifelike AI voices that build trust and engagement during interviews.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Cross-platform excellence)
- **AI Orchestration**: [Voiceflow](https://www.voiceflow.com/) & [Addis AI](https://addisai.com/)
- **Voice Synthesis**: [ElevenLabs](https://elevenlabs.io/)
- **Intelligence Layer**: [Google Gemini AI](https://deepmind.google/technologies/gemini/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Visuals**: [Lottie](https://lottiefiles.com/) & [Animate Do](https://pub.dev/packages/animate_do)

## 📂 Project Structure

```bash
lib/
├── models/         # Data structures (JobCampaign, Candidate, etc.)
├── screens/        # UI Layers (Company Dashboard, AI Interview, etc.)
├── services/       # Core Logic (AI Routing, Voiceflow, Addis AI, ElevenLabs)
├── theme/          # Premium design tokens and styles
├── utils/          # Helper functions and constants
└── widgets/        # Reusable UI components
```

## 📦 Getting Started

### Prerequisites

- Flutter SDK (^3.7.0)
- API Keys for Voiceflow, ElevenLabs, and Gemini.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Minas-27/HireAI.git
   cd hire_ai
   ```

2. **Configure Environment Variables**:
   Create a `.env` file in the root directory and add your keys:
   ```env
   VOICEFLOW_API_KEY=your_key
   ELEVENLABS_API_KEY=your_key
   GEMINI_API_KEY=your_key
   ADDIS_AI_API_KEY=your_key
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

## 🌍 Vision: The African Talent Paradox

HireAI is built specifically to bridge the gap between talented individuals in Africa and global opportunities. By providing a platform where candidates can express themselves professionally in their native languages while being audited by objective AI, we eliminate hiring bias and uncover hidden gems in the workforce.

---

Built with ❤️ for the future of African recruitment.
