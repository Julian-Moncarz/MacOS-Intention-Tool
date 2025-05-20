# Focus Session Analysis Tool

A tool for analyzing focus sessions, generating insights, and displaying them in a user-friendly HTML report.

## Features

- Analyzes focus session data from logs
- Generates visualizations and charts
- Creates AI-powered insights using Google's Gemini API
- Displays results in a clean, responsive HTML report
- Automatically opens the report in your default web browser

## Requirements

- Python 3.9+
- Required packages are listed in `requirements.txt`

## Setup

1. Clone this repository
2. Create a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

## Usage

Run the analysis tool:

```
python show_analysis.py
```

This will:
1. Process your focus session logs
2. Generate visualizations and insights
3. Create an HTML report
4. Automatically open the report in your default browser

## Files

- `show_analysis.py`: Main script that generates and displays the HTML report
- `visualize_logs.py`: Handles data processing and visualization generation
- `focus_session.sh`: Shell script for starting focus sessions
- `requirements.txt`: List of Python dependencies

## License

MIT
