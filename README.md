# Contact Fixer

A powerful utility app to fix, standardize, and format phone numbers in your Google Contacts. It automatically detects missing country codes, formats numbers to international standards, and provides an interactive interface to review changes before syncing them back to Google.

## Features

- **Smart Analysis**: Scans your contacts to identify numbers with missing country codes or incorrect formatting.
- **Interactive "Phone Fixer"**:
  - **Swipe Interface**: Tinder-style card interface to quickly Accept (Right), Skip (Left), or Edit (Up) suggestions.
  - **List View**: Bulk review changes in a traditional list format.
- **Region Support**: Automatically suggests country codes based on your selected region.
- **Safe Syncing**: Changes are staged first. You review them before they are physically pushed to Google Contacts.
- **Undo/Rollback**: Staged changes can be modified or deleted before syncing.
- **Privacy Focused**: Runs locally on your machine.

## Tech Stack

- **Backend**: Python (FastAPI), Google People API
- **Frontend**: Flutter (Mobile/Web), Material Design 3

## Getting Started

### Prerequisites
- Python 3.9+
- Flutter SDK (3.x+)
- Google Cloud Project with "Google People API" enabled and `credentials.json`

### 1. Backend Setup
1.  **Clone and Enter Directory**
    ```bash
    git clone https://github.com/yourusername/Contact_Fixer.git
    cd Contact_Fixer
    ```

2.  **Create Virtual Environment**
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # macOS/Linux
    # .\venv\Scripts\activate  # Windows
    ```

3.  **Install Dependencies**
    ```bash
    pip install -r backend/requirements.txt
    ```

4.  **Google Credentials**
    - Place your `credentials.json` file in the `backend/` directory.

5.  **Run Server**
    ```bash
    uvicorn backend.main:app --reload --host 0.0.0.0
    ```
    - API Documentation available at: `http://127.0.0.1:8000/docs`

### 2. Frontend Setup
1.  **Navigate to Frontend**
    ```bash
    cd frontend
    ```

2.  **Install Packages**
    ```bash
    flutter pub get
    ```

3.  **Run App**
    ```bash
    flutter run
    ```
    - Select your target device (iOS Simulator, Android Emulator, or Chrome).

## Documentation
- [Architecture & Stack](docs/ARCHITECTURE.md)
- [Git Workflow](docs/git_workflow_guide.md)
