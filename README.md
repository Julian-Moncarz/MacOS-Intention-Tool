# Intention Tool

A productivity tool that helps you track, manage, and analyze your focus sessions. This tool allows you to set intentions for work sessions, record your activities, and gain valuable insights about your productivity patterns through data visualization and AI-powered analysis.

## Features

- **Focus Session Management**: Start and track dedicated work sessions with clear intentions
- **Activity Logging**: Record what you're working on and for how long
- **Data Analysis**: Analyze your focus session data from logs
- **Visualization**: Generate charts and graphs to visualize your productivity patterns
- **AI Insights**: Get AI-powered insights about your work habits using Google's Gemini API
- **Reporting**: View results in a clean, responsive HTML report
- **Seamless Experience**: Automatically opens the report in your default web browser

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

### Starting a Focus Session

```
./focus_session.sh
```

This will:
1. Prompt you to set an intention for your work session
2. Start tracking your focus session
3. Log your activities and time spent

### Analyzing Your Focus Sessions

```
python show_analysis.py
```

This will:
1. Process your focus session logs
2. Generate visualizations of your productivity patterns
3. Create AI-powered insights about your work habits
4. Display everything in an HTML report
5. Automatically open the report in your default browser

## Files

- `focus_session.sh`: Shell script for starting and managing focus sessions
- `show_analysis.py`: Main script that generates and displays the HTML report
- `visualize_logs.py`: Handles data processing and visualization generation
- `logs.csv`: Stores your focus session data
- `focus_insights/`: Directory containing AI-generated insights
- `requirements.txt`: List of Python dependencies

## License

MIT
