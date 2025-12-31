<div align="center">

# 🧠 MarketSync-EA — AI-Driven Aglogrithmic Trading System

[![MQL5](https://img.shields.io/badge/MQL5-MetaTrader_5-green?style=for-the-badge&logo=metatrader-5)](https://www.metatrader5.com/en)
[![Next.js](https://img.shields.io/badge/Next.js-14-black?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-412991?style=for-the-badge&logo=openai)](https://openai.com/)
[![TensorFlow.js](https://img.shields.io/badge/TensorFlow.js-Machine_Learning-orange?style=for-the-badge&logo=tensorflow)](https://www.tensorflow.org/js)

**A sophisticated MetaTrader 5 Expert Advisor (EA) integrating real-time market data, machine learning, and Large Language Models (LLMs) for dynamic trading strategies.**

*🔄 Experimental Research Project*

[Report Bug](https://github.com/sajidmahamud835/MarketSync-EA/issues) · [Request Feature](https://github.com/sajidmahamud835/MarketSync-EA/issues)

</div>

---

## 🔬 About The Project

**MarketSync-EA** represents the convergence of traditional algorithmic trading with modern artificial intelligence. In an era where financial markets are increasingly driven by high-frequency data and complex patterns, static algorithms often fail to adapt.

This project serves as a research testbed for investigating the efficacy of **Hybrid Intelligence Trading Systems**. By combining deterministic technical analysis (MQL5) with probabilistic machine learning models (JS inference) and semantic market understanding (GPT-4), MarketSync aims to create a trading agent capable of "reasoning" about market conditions rather than simply reacting to them.

### 🎯 Research Objectives

1.  **Adaptive Strategy Generation**: Can an LLM effectively modify trading parameters in real-time based on news sentiment and macro-economic data?
2.  **Cross-Platform Latency Analysis**: Evaluating the performance overhead of bridging MQL5 (C++) with an external Node.js/Next.js inference engine.
3.  **Pattern Recognition**: Utilizing TensorFlow.js to identify non-linear price action patterns that elude standard indicators.

---

## ⚙️ Technical Architecture

The system operates on a decoupled architecture to leverage the strengths of specific environments:

1.  **Execution Layer (MQL5)**: Runs directly on the MetaTrader 5 terminal. Responsible for high-speed order execution, tick data collection, and basic risk management constraints.
2.  **Intelligence Layer (Next.js/Node.js)**: Acts as the brain. Receives sanitized market data from the EA, processes it through ML models and GPT-4 APIs, and returns actionable trading signals or parameter adjustments.
3.  **Communication Bridge**: REST API / WebSocket integration facilitating bi-directional data flow between the robust trading terminal and the flexible web backend.

---

## ✨ Features

### 🟢 Implemented Capabilities

| Component | Feature Description |
|-----------|---------------------|
| **Core EA** | Basic grid and trend following logic implemented in MQL5 |
| **Data Bridge** | Real-time tick data streaming to external API endpoints |
| **LLM Integration** | Connection to OpenAI GPT-4 for "Market Sentiment Analysis" prompts |
| **Dashboard** | Next.js frontend for monitoring bot status and logs |

### 🗓️ Research & Development Plan (Todo)

- [ ] **Optimized inference Latency**: Reduce the round-trip time between MQL5 and Node.js to under 50ms.
- [ ] **Sentiment Analysis Module**: Scrape financial news calendars (e.g., ForexFactory) and feed data to GPT-4 for event-risk scoring.
- [ ] **Reinforcement Learning**: Implement a Deep Q-Network (DQN) agent that learns optimal stop-loss/take-profit dynamic placement.
- [ ] **Backtesting Engine**: Create a mechanism to replay historical data through the full web-stack for accurate strategy verification.

---

## 🚀 Getting Started

### Prerequisites

- **MetaTrader 5 Client**: Installed and configured with a demo account.
- **Node.js**: v18.0 or higher.
- **OpenAI API Key**: For GPT-4 features.

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/sajidmahamud835/MarketSync-EA.git
    cd MarketSync-EA
    ```

2.  **Setup the Backend (Intelligence Layer)**
    ```bash
    cd backend
    npm install
    # Configure .env with your OpenAI Keys
    npm run dev
    ```

3.  **Deploy the EA**
    - Copy the contents of the `MT5` folder to your MetaTrader 5 `MQL5/Experts` directory.
    - Compile the `.mq5` source files.
    - Attach the EA to a chart and ensure "Allow WebRequests" is enabled in MT5 settings, adding your localhost URL.

---

## 🤝 Related Projects

Explore other components of the research portfolio:

1.  **[GridMaster Pro MT5 EA](https://github.com/sajidmahamud835/grid-master-pro-mt5-ea)** - A dedicated, high-performance Grid Trading implementation without the external AI dependency.
2.  **[Slippage Tracker Client](https://github.com/sajidmahamud835/slippage-tracker-client)** - Essential tool for monitoring execution quality and broker latency, crucial for validating EA performance.
3.  **[BankSync](https://github.com/sajidmahamud835/banksync)** - Understanding the broader fintech ecosystem with banking integration, relevant for future fund management features.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">

**[Sajid Mahamud](https://github.com/sajidmahamud835)**

*Researcher • Developer • Trader*

</div>
