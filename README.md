# 📱 Warung Wise – Your AI Business Partner （by group NEXT LEVEL)

> **"Empowering Micro-Hawkers. From Invisible to Bankable."**

Warung Wise is an AI-powered mobile application designed to help Malaysian micro-hawkers track costs, optimize pricing, and generate credit-ready financial reports without requiring any formal accounting knowledge.

---

## 🌍 1. Problem Statement & Impact (SDG Alignment)

### The Challenge
In Malaysia, over **1 million micro-hawkers**—primarily from the B40 community—remain financially invisible due to informal and unstructured bookkeeping practices. 
* **Mental Accounting:** Reliance on mental math and manual "555 notebooks" prevents accurate tracking of real-time Cost of Goods Sold (COGS).
* **Unconscious Losses:** Many vendors unknowingly operate at a loss amid rising raw material prices and inflation.
* **Complex Alternatives:** Existing accounting software is too complex for their literacy levels and fast-paced work environment.
* **The "Unbankable" Trap:** The absence of formal financial records renders them “unbankable,” limiting their access to micro-financing (e.g., TEKUN, MARA) and hindering business sustainability.

### SDG Alignment
Our solution directly addresses the United Nations Sustainable Development Goals:
* 🎯 **SDG 1: No Poverty** - By preventing hidden business losses and enabling access to micro-financing, we help B40 hawkers sustain their livelihoods.
* 📈 **SDG 8: Decent Work and Economic Growth** - By digitizing informal businesses, we promote formalization, financial inclusion, and micro-enterprise growth.

---

## 🚀 2. Core Value Proposition & Features

Warung Wise is not just a bookkeeping app; it is an **AI-powered survival tool** functioning as a "Virtual CFO" for hawkers.

### 🧠 Pillar 1: AI Smart Bookkeeping (Effortless Recording)
*Eliminates manual data entry for fast-paced hawkers.*
* 📸 **Smart Receipt Scan (`dashboard_page.dart` & `receipt_review_page.dart`):** Users simply snap a photo of messy, handwritten, or printed receipts. AI extracts items, prices, and categories. Users can review and confirm data before it enters the ledger.
* 🎤 **Voice Ledger:** For sales recording, users tap the mic and speak (e.g., *"Jual 20 bungkus Nasi Lemak"*). AI converts speech into structured financial income records instantly.
* 📊 **Automatic Categorization:** Transactions are automatically organized into ingredients, utilities, and daily sales.

### 💰 Pillar 2: Profit Intelligence Engine (Real-Time Business Advice)
*Prevents unconscious losses and protects margins.*
* 📈 **Real-Time Cost Monitoring (`gemini_service.dart`):** Powered by Gemini, the app analyzes ingredient prices and adjusts costs realistically based on Malaysian inflation and market fluctuations (implemented via prompt engineering).
* ⚠️ **Margin Alert System & AI Pie Charts (`report_page.dart`):** Visualizes expense breakdowns and warns users when profit per item drops due to rising raw material costs.
* 🧮 **Pricing Simulator:** Predicts profit changes if users increase their selling price, helping them optimize their menu confidently.

### 🏦 Pillar 3: Credit & Financial Empowerment (Unlock Micro-Loans)
*Helps informal hawkers become "Bankable."*
* 📊 **Digital Credit History Builder (`report_page.dart`):** Transforms daily scattered data into a structured "AI Verified Credit Score".
* 💵 **Interactive Loan Simulator:** Hawkers can use a slider to test TEKUN loan amounts. The AI instantly calculates the Debt Service Ratio against their net profit and warns if the monthly commitment is too high.
* 📄 **One-Click P&L Report:** Automatically generates professional Profit & Loss statements, enabling users to download a PDF to apply for micro-loans directly.

---

## 🛠 3. Technical Architecture & Google Technologies

We leveraged Google's ecosystem to build a scalable, intelligent, and seamless application.

### 🤖 Google AI Technologies
1. **Gemini 2.5 Flash (Google AI Studio):** Acts as the core "brain" and "eyes" of the app.
   - **Multimodal Vision:** Instead of traditional OCR, we directly feed receipt images to Gemini 2.5 Flash, which reads messy handwriting and structures the data into a clean JSON format.
   - **Market Analysis:** Serves as a "senior market price analyst" to evaluate realistic price fluctuations for raw materials.
   - **Business Insight Generation:** Powers the financial health assessment and interactive charts.

### 💻 Google Developer Technologies
1. **Flutter:** Used to build a highly responsive, cross-platform mobile application. We utilized packages like `fl_chart` for dynamic, interactive financial visualizations and `speech_to_text` for hands-free operations.
2. **Firebase (Firestore):** Integrated for scalable backend database management. Configured in `main.dart` to sync transaction records, user data, and generated AI reports securely in the cloud.

### Core Workflows
1. **Smart Bookkeeping:** Camera Snap ➔ Gemini 2.5 Flash (Multimodal JSON Structuring) ➔ ReceiptReviewPage (Human-in-the-Loop) ➔ Firestore.

2. **Voice Ledger:** User Voice ➔ Speech-to-Text ➔ Smart Regex & NLP Keyword Extraction (Zero-latency local processing) ➔ Auto-calculate Profit Margin ➔ Firestore.

3. **Financial Analysis:** Historical Data Aggregation ➔ Gemini Analysis ➔ Interactive Charts & Loan Simulation (report_page.dart).

---

## 🚧 4. Implementation Details & Challenges Faced

### The Challenge: Parsing Messy Hawker Receipts and Ensuring Trust
**Problem:** Receipts from local wet markets are often handwritten, faded, or use heavy abbreviations (e.g., "Bawang Merah" written as "Bwg mrh"). Furthermore, 100% automated AI data entry makes older hawkers anxious about data accuracy.

**Solution & Trade-off:** We implemented a "Human-in-the-Loop" architecture. Instead of saving AI-extracted data directly to the database, the AI forwards the data to a `ReceiptReviewPage`. Here, users can verify, edit, or delete items before confirming. This trade-off slightly increases the number of clicks but drastically improves data accuracy and user trust.

### The Challenge: Structuring AI Responses
**Problem:** Early tests with Gemini often returned conversational text instead of raw data for our pricing engine.

**Solution:** We heavily optimized our prompt engineering in `gemini_service.dart` (e.g., specifying *"Output ONLY a number. No explanation. No currency symbol"*). We then mapped the JSON response robustly to prevent UI crashes.

---

## 🌍 5. Scalability & Future Roadmap

How can Warung Wise grow in the next 2-3 years?
1. **Integration with Real Banking APIs (Open Banking):** Partner with institutions like TEKUN or Bank Simpanan Nasional (BSN) so hawkers can apply for micro-loans directly within the app via API, bypassing physical branch visits.
2. **Supplier Marketplace Integration:** If the AI detects a hawker is overpaying for chicken, the app can automatically recommend cheaper wholesale suppliers nearby using Google Maps API.
3. **Multi-Language Support:** Expand Gemini's voice recognition to support regional dialects (e.g., Kelantanese Malay, Hokkien, Tamil) to increase adoption among rural hawkers.

---

## ⚙️ 6. Repository Setup Instructions

To run the Warung Wise prototype locally:

1. **Prerequisites:** Ensure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2. **Clone the Repository:**
   ```bash
   git clone https://github.com/Jasminekhoo/NEXT-LEVEL.git
   cd warung_wise
3. **Install Dependencies:**
    ```bash
    flutter clean
    flutter pub get
4. **Firebase Configuration:**
   The project includes a firebase_options.dart file.
   
5. **API Key Configuration (Important):**
   For security reasons, the Gemini API key is not uploaded to GitHub. You need to provide your own API key to run the AI features.
   * Go to the `lib/` folder and create a new file named `api_config.dart`.
   * Add the following code and insert your Gemini API Key:
   ```dart
   class ApiConfig {
     static const String geminiApiKey = "YOUR_GEMINI_API_KEY_HERE";
   }
6. **Run the App:**
    ```bash
    flutter run
---
Built by Group NEXT LEVEL for KitaHack 2026.
