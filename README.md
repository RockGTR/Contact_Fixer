# Contact Fixer

A utility app to fix and standardize phone numbers in Google Contacts.

## Getting Started

### Prerequisites
- Python 3.8+
- Flutter SDK (future)

### Quick Start (Backend)
1.  **Setup Environment**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install -r backend/requirements.txt
    ```

2.  **Run Server**
    ```bash
    uvicorn backend.main:app --reload
    ```
3.  **Verify**: Open `http://127.0.0.1:8000/health` or `http://127.0.0.1:8000/docs`.

## Documentation
- [Architecture & Stack](docs/ARCHITECTURE.md)
- [Git Workflow](docs/git_workflow_guide.md)
