#!/usr/bin/env python3
"""
Daily Timeline Visualization Script

This script generates weekly timeline visualizations of focus sessions.
"""

import os
import sys
import subprocess
import tempfile
from datetime import datetime

# Function to check and install dependencies
def check_and_install_dependencies():
    """Check if required packages are installed and install them if needed."""
    print("Checking required dependencies...")
    
    # Get the path to the requirements file
    script_dir = os.path.dirname(os.path.abspath(__file__))
    requirements_path = os.path.join(script_dir, 'requirements.txt')
    
    # Check if requirements.txt exists
    if not os.path.exists(requirements_path):
        print("Warning: requirements.txt not found in the script directory.")
        required_packages = [
            'pandas>=1.3.0',
            'matplotlib>=3.4.0',
            'numpy>=1.21.0'
        ]
    else:
        # Read requirements from file
        with open(requirements_path, 'r') as f:
            required_packages = [line.strip() for line in f if line.strip()]
    
    # Check for virtual environment
    in_venv = hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)
    
    if not in_venv:
        print("Creating and activating a virtual environment...")
        venv_dir = os.path.join(script_dir, 'venv')
        
        # Create virtual environment if it doesn't exist
        if not os.path.exists(venv_dir):
            try:
                subprocess.check_call([sys.executable, '-m', 'venv', venv_dir])
                print(f"Created virtual environment at {venv_dir}")
            except subprocess.CalledProcessError as e:
                print(f"Failed to create virtual environment: {e}")
                print("Continuing with system Python...")
        
        # Get the path to the Python executable in the virtual environment
        if os.name == 'nt':  # Windows
            venv_python = os.path.join(venv_dir, 'Scripts', 'python.exe')
        else:  # Unix/Linux/Mac
            venv_python = os.path.join(venv_dir, 'bin', 'python')
        
        if os.path.exists(venv_python):
            print(f"Restarting script with virtual environment Python: {venv_python}")
            # Re-run the current script with the virtual environment's Python
            cmd = [venv_python] + sys.argv
            os.execv(venv_python, cmd)
            # The above line replaces the current process, so the code below won't run
            # if the exec is successful
    
    # Check and install missing packages
    missing_packages = []
    for package in required_packages:
        package_name = package.split('==')[0].split('>=')[0].split('>')[0].strip()
        try:
            __import__(package_name.replace('-', '_'))
            print(f"✓ {package_name} is already installed")
        except ImportError:
            missing_packages.append(package)
            print(f"✗ {package_name} needs to be installed")
    
    if missing_packages:
        print("\nInstalling missing packages...")
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + missing_packages)
            print("All required packages have been installed successfully!")
        except subprocess.CalledProcessError as e:
            print(f"Error installing packages: {e}")
            print("Please install the required packages manually using:")
            print(f"pip install -r {requirements_path}")
            sys.exit(1)
    else:
        print("All required packages are already installed.")

# Check dependencies before importing them
check_and_install_dependencies()

# Now import the packages that require dependencies
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch
import numpy as np
import webbrowser
from datetime import datetime, timedelta
from collections import defaultdict
import matplotlib.dates as mdates

def load_session_data(csv_file):
    """Load and parse the session data from CSV"""
    # Read CSV with proper headers
    df = pd.read_csv(csv_file)
    
    # Rename columns to match our expected names
    df.columns = ['task_name', 'duration_minutes', 'websites', 'timestamp', 
                  'completion_notes', 'learnings', 'additional_notes']
    
    # Convert timestamp to datetime
    df['timestamp'] = pd.to_datetime(df['timestamp'], format='%Y-%m-%d %H:%M:%S')
    df['date'] = df['timestamp'].dt.date
    df['duration_minutes'] = pd.to_numeric(df['duration_minutes'], errors='coerce').fillna(0)
    
    # Filter out invalid sessions
    df = df[df['duration_minutes'] > 0]
    df = df[df['task_name'].notna() & (df['task_name'] != '')]
    
    # Add week information
    df['week_start'] = df['timestamp'].dt.to_period('W-MON').dt.start_time.dt.date
    df['day_of_week'] = df['timestamp'].dt.dayofweek  # Monday=0, Sunday=6
    
    return df

def create_weekly_timeline(weekly_sessions, week_start_date):
    """Create a weekly timeline visualization with all 7 days side by side"""
    fig, axes = plt.subplots(1, 7, figsize=(20, 12), sharey=True)
    
    # Create a teal-to-purple gradient background to match webpage
    fig.patch.set_facecolor('#a8e6cf')  # Light teal background
    fig.suptitle(f"Week of {week_start_date.strftime('%B %d - %B %d, %Y')}", 
                 fontsize=18, fontweight='bold', y=0.95, color='white')
    
    # Days of the week
    day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    
    # Calculate the time range for this week
    start_hour = 7  # Start at 7 AM
    latest_end_hour = start_hour
    
    # Find the latest session end time for this week
    for day_idx in range(7):
        if day_idx in weekly_sessions:
            for _, session in weekly_sessions[day_idx].iterrows():
                session_start_hour = session['timestamp'].hour + session['timestamp'].minute / 60
                session_end_hour = session_start_hour + session['duration_minutes'] / 60
                latest_end_hour = max(latest_end_hour, session_end_hour)
    
    # Add some padding to the end time
    latest_end_hour = min(24, latest_end_hour + 0.5)
    
    # Set up each day's timeline
    for day_idx, ax in enumerate(axes):
        ax.set_ylim(latest_end_hour, start_hour)  # Inverted Y axis
        ax.set_xlim(-0.05, 1.05)
        ax.set_facecolor('white')
        
        # Day label with darker color for contrast
        ax.set_title(f"{day_names[day_idx]}", 
                    fontsize=12, fontweight='bold', pad=10, color='#2c3e50')
        
        # Add only time labels on leftmost plot (no grid lines)
        if day_idx == 0:
            for hour in range(int(start_hour), int(latest_end_hour) + 1):
                ax.text(-0.1, hour, f"{hour:02d}:00", ha='right', va='center', fontsize=11)
        
        # Add sessions for this day
        if day_idx in weekly_sessions:
            sessions_for_day = weekly_sessions[day_idx].sort_values('timestamp')
            
            # Use a teal-to-purple gradient like the webpage
            num_sessions = len(sessions_for_day)
            if num_sessions == 1:
                colors = ['#b8f2e6']  # Light teal
            else:
                # Create gradient from light teal to light purple
                colors = []
                for i in range(num_sessions):
                    ratio = i / (num_sessions - 1) if num_sessions > 1 else 0
                    # Gradient from light teal to light purple/pink
                    r = int(184 + (238 - 184) * ratio)    # b8 to ee (teal to purple red component)
                    g = int(242 + (187 - 242) * ratio)    # f2 to bb (teal to purple green component)  
                    b = int(230 + (238 - 230) * ratio)    # e6 to ee (teal to purple blue component)
                    colors.append(f"#{r:02x}{g:02x}{b:02x}")
            
            for i, (_, session) in enumerate(sessions_for_day.iterrows()):
                start_time = session['timestamp']
                duration_hours = session['duration_minutes'] / 60
                
                # Calculate position
                start_hour_pos = start_time.hour + start_time.minute / 60
                
                # Skip sessions that start before 7 AM
                if start_hour_pos < start_hour:
                    continue
                
                # Draw the session block with teal-purple gradient
                rect = FancyBboxPatch(
                    (0.05, start_hour_pos), 0.9, duration_hours,
                    facecolor=colors[i % len(colors)], edgecolor='none', linewidth=0, alpha=0.9,
                    boxstyle="round,pad=0.01"
                )
                ax.add_patch(rect)
                
                # Add session name label (black text for readability)
                session_name = session['task_name']
                if len(session_name) > 18:
                    session_name = session_name[:15] + '...'
                
                # Position text in the middle of the block
                text_y = start_hour_pos + duration_hours / 2
                ax.text(0.5, text_y, session_name, ha='center', va='center', 
                       fontsize=10, fontweight='bold', wrap=True, rotation=0, color='black')
        
        # Calculate daily stats
        daily_total = 0
        if day_idx in weekly_sessions:
            daily_total = weekly_sessions[day_idx]['duration_minutes'].sum()
        
        # Add daily total at the bottom (just the number)
        ax.text(0.5, latest_end_hour + 0.6, f"{daily_total/60:.1f}h", 
               ha='center', va='bottom', fontsize=12, fontweight='bold', color='#2c3e50')
        
        # Clean up the axes
        ax.set_xticks([])
        ax.set_yticks([])
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['bottom'].set_visible(False)
        ax.spines['left'].set_visible(False)
    
    plt.tight_layout()
    plt.subplots_adjust(top=0.85, bottom=0.05)
    return fig

def generate_html_report(df):
    """Generate HTML page with all weekly timelines"""
    # Group sessions by week
    weekly_sessions_dict = {}
    
    for week_start, week_data in df.groupby('week_start'):
        weekly_sessions = {}
        for day_of_week, day_data in week_data.groupby('day_of_week'):
            weekly_sessions[day_of_week] = day_data.sort_values('timestamp')
        weekly_sessions_dict[week_start] = weekly_sessions
    
    # Create output directory relative to script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "focus_timeline_report")
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate timeline for each week
    timeline_files = []
    
    # Sort weeks chronologically
    sorted_weeks = sorted(weekly_sessions_dict.keys())
    
    for week_start in sorted_weeks:
        weekly_sessions = weekly_sessions_dict[week_start]
        
        # Create timeline
        fig = create_weekly_timeline(weekly_sessions, week_start)
        
        # Save as PNG
        filename = f"week_{week_start.strftime('%Y_%m_%d')}.png"
        filepath = os.path.join(output_dir, filename)
        fig.savefig(filepath, dpi=150, bbox_inches='tight', facecolor='white')
        plt.close(fig)
        
        # Calculate week stats
        total_weekly_minutes = sum(weekly_sessions[day]['duration_minutes'].sum() 
                                 for day in weekly_sessions if day in weekly_sessions)
        total_sessions = sum(len(weekly_sessions[day]) 
                           for day in weekly_sessions if day in weekly_sessions)
        
        timeline_files.append((week_start, filename, total_weekly_minutes, total_sessions))
    
    # Generate HTML page
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Weekly Focus Session Timeline Report</title>
        <style>
            * {{
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }}
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: linear-gradient(135deg, #a8e6cf 0%, #d7b5d8 50%, #f1c0e8 100%);
                min-height: 100vh;
                padding: 20px;
            }}
            .container {{
                max-width: 1200px;
                margin: 0 auto;
            }}
            .header {{
                background: linear-gradient(135deg, #a8e6cf 0%, #d7b5d8 100%);
                color: white;
                padding: 30px;
                border-radius: 20px;
                margin-bottom: 30px;
                text-align: center;
                box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            }}
            .header h1 {{
                font-size: 2.5em;
                font-weight: 300;
                margin-bottom: 10px;
            }}
            .header p {{
                opacity: 0.9;
                font-size: 1.1em;
            }}
            .week-section {{
                background: white;
                margin-bottom: 30px;
                border-radius: 20px;
                overflow: hidden;
                box-shadow: 0 8px 32px rgba(0,0,0,0.08);
            }}
            .week-header {{
                background: linear-gradient(135deg, #a8e6cf 0%, #d7b5d8 100%);
                color: white;
                padding: 25px 30px;
                font-size: 1.4em;
                font-weight: 500;
            }}
            .timeline-container {{
                padding: 30px;
                background: #fafcfb;
            }}
            .timeline-box {{
                background: white;
                border-radius: 15px;
                padding: 20px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.05);
            }}
            .timeline-image {{
                width: 100%;
                height: auto;
                border-radius: 10px;
                display: block;
            }}
            .week-summary {{
                padding: 30px;
                background: linear-gradient(135deg, #f0f9f6 0%, #f7f0f9 100%);
                display: flex;
                justify-content: center;
                gap: 30px;
                flex-wrap: wrap;
            }}
            .stat-box {{
                background: linear-gradient(135deg, #b8f2e6 0%, #eebbee 100%);
                color: #2c3e50;
                padding: 20px;
                border-radius: 15px;
                min-width: 140px;
                text-align: center;
                box-shadow: 0 4px 15px rgba(0,0,0,0.08);
            }}
            .stat-value {{
                font-size: 2.2em;
                font-weight: 600;
                margin-bottom: 8px;
                color: #1a1a1a;
            }}
            .stat-label {{
                font-size: 0.95em;
                color: #4a5568;
                font-weight: 500;
            }}
            .overview {{
                background: white;
                padding: 40px;
                border-radius: 20px;
                margin-bottom: 30px;
                box-shadow: 0 8px 32px rgba(0,0,0,0.08);
            }}
            .overview h2 {{
                color: #2c3e50;
                margin-bottom: 25px;
                font-size: 1.8em;
                font-weight: 500;
            }}
            .overview-stats {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
                gap: 25px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Weekly Focus Timeline</h1>
                <p>Generated on {datetime.now().strftime('%B %d, %Y at %H:%M')}</p>
            </div>
            
            <div class="overview">
                <h2>Overview Statistics</h2>
                <div class="overview-stats">
                    <div class="stat-box">
                        <div class="stat-value">{len(sorted_weeks)}</div>
                        <div class="stat-label">Weeks Tracked</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value">{len(df)}</div>
                        <div class="stat-label">Total Sessions</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value">{df['duration_minutes'].sum()/60:.0f}</div>
                        <div class="stat-label">Total Hours</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value">{df['duration_minutes'].mean()/60:.1f}</div>
                        <div class="stat-label">Avg Session</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value">{df['duration_minutes'].sum()/60/len(sorted_weeks):.1f}</div>
                        <div class="stat-label">Avg Hours/Week</div>
                    </div>
                </div>
            </div>
    """
    
    # Add weekly sections
    for week_start, filename, total_weekly_minutes, total_sessions in timeline_files:
        avg_per_day = total_weekly_minutes / 7
        week_end = week_start + timedelta(days=6)
        
        html_content += f"""
            <div class="week-section">
                <div class="week-header">
                    Week of {week_start.strftime('%B %d')} - {week_end.strftime('%B %d, %Y')}
                </div>
                <div class="timeline-container">
                    <div class="timeline-box">
                        <img src="{filename}" alt="Weekly Timeline" class="timeline-image">
                    </div>
                </div>
                <div class="week-summary">
                    <div class="stat-box">
                        <div class="stat-value">{total_weekly_minutes/60:.1f}</div>
                        <div class="stat-label">Total Hours</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value">{total_sessions}</div>
                        <div class="stat-label">Sessions</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-value">{avg_per_day/60:.1f}</div>
                        <div class="stat-label">Avg Hours/Day</div>
                    </div>
                </div>
            </div>
        """
    
    html_content += """
        </div>
    </body>
    </html>
    """
    
    # Save HTML file
    html_file = os.path.join(output_dir, "focus_timeline_report.html")
    with open(html_file, 'w') as f:
        f.write(html_content)
    
    return html_file

def main():
    """Main function to generate the timeline report"""
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    csv_file = os.path.join(script_dir, "logs.csv")
    
    if not os.path.exists(csv_file):
        print(f"Error: {csv_file} not found!")
        print("Please ensure logs.csv is in the same directory as this script.")
        return
    
    print("📊 Loading session data...")
    df = load_session_data(csv_file)
    
    if df.empty:
        print("No valid session data found in logs.csv!")
        return
    
    weeks_count = df['week_start'].nunique()
    print(f"✅ Found {len(df)} valid sessions across {weeks_count} weeks")
    print("🎨 Generating weekly timeline visualizations...")
    
    html_file = generate_html_report(df)
    
    print(f"✅ Report generated successfully!")
    print(f"📂 Files saved in: {os.path.abspath('focus_timeline_report')}")
    print(f"🌐 Opening report: {html_file}")
    
    # Open the HTML file in the default browser
    webbrowser.open(f"file://{os.path.abspath(html_file)}")

if __name__ == "__main__":
    main()
