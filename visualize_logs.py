#!/usr/bin/env python
"""
Focus Session Log Visualizer

This script analyzes and visualizes data from focus session logs.
It provides insights on session durations, patterns, and productivity trends.
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
from datetime import datetime
import numpy as np
from matplotlib.dates import DateFormatter
import os

# Import Google Generative AI
import sys
import subprocess

# Ensure the google-generativeai package is installed
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    print("Installing google-generativeai package...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "google-generativeai"])
    try:
        import google.generativeai as genai
        GEMINI_AVAILABLE = True
        print("Successfully installed google-generativeai package.")
    except ImportError:
        print("Failed to install google-generativeai package. Gemini report will be skipped.")
        GEMINI_AVAILABLE = False

# Set style
sns.set(style="whitegrid")
plt.rcParams.update({'font.size': 12})

def load_and_clean_data(csv_path):
    """Load and clean the focus session logs data."""
    # Load data
    df = pd.read_csv(csv_path)
    
    # Convert Start column to datetime
    df['Start'] = pd.to_datetime(df['Start'])
    
    # Convert Duration to numeric, handling any non-numeric values
    df['Duration(min)'] = pd.to_numeric(df['Duration(min)'], errors='coerce')
    
    # Sort by date
    df = df.sort_values('Start')
    
    # Add date column (without time)
    df['Date'] = df['Start'].dt.date
    
    # Add day of week
    df['DayOfWeek'] = df['Start'].dt.day_name()
    
    # Add hour of day
    df['Hour'] = df['Start'].dt.hour
    
    return df

def extract_keywords(df, column='Intent'):
    """Extract common keywords from intentions."""
    # Join all non-empty intentions
    all_text = ' '.join(df[column].dropna().astype(str))
    
    # Remove special characters and convert to lowercase
    all_text = re.sub(r'[^\w\s]', ' ', all_text.lower())
    
    # Split into words
    words = all_text.split()
    
    # Count word frequencies
    word_counts = pd.Series(words).value_counts()
    
    # Filter out common stop words and very short words
    stop_words = ['the', 'and', 'to', 'a', 'of', 'for', 'in', 'on', 'with', 'is', 'it', 'that', 'be', 'as', 'this', 'by', 'an', 'at']
    word_counts = word_counts[~word_counts.index.isin(stop_words)]
    word_counts = word_counts[word_counts.index.str.len() > 2]
    
    return word_counts.head(20)

def create_visualizations(df, output_dir='.'):
    """Create and save visualizations."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # 1. Session durations over time
    plt.figure(figsize=(12, 6))
    plt.plot(df['Start'], df['Duration(min)'], marker='o', linestyle='-', alpha=0.7)
    plt.title('Focus Session Durations Over Time')
    plt.xlabel('Date')
    plt.ylabel('Duration (minutes)')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/session_durations.png')
    
    # 2. Distribution of session durations
    plt.figure(figsize=(10, 6))
    sns.histplot(df['Duration(min)'].dropna(), bins=15, kde=True)
    plt.title('Distribution of Session Durations')
    plt.xlabel('Duration (minutes)')
    plt.ylabel('Frequency')
    plt.tight_layout()
    plt.savefig(f'{output_dir}/duration_distribution.png')
    
    # 3. Sessions by day of week
    plt.figure(figsize=(10, 6))
    day_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    day_counts = df['DayOfWeek'].value_counts().reindex(day_order)
    sns.barplot(x=day_counts.index, y=day_counts.values)
    plt.title('Focus Sessions by Day of Week')
    plt.xlabel('Day of Week')
    plt.ylabel('Number of Sessions')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/sessions_by_day.png')
    
    # 4. Sessions by hour of day
    plt.figure(figsize=(12, 6))
    hour_counts = df['Hour'].value_counts().sort_index()
    sns.barplot(x=hour_counts.index, y=hour_counts.values)
    plt.title('Focus Sessions by Hour of Day')
    plt.xlabel('Hour of Day (24-hour format)')
    plt.ylabel('Number of Sessions')
    plt.xticks(range(0, 24))
    plt.tight_layout()
    plt.savefig(f'{output_dir}/sessions_by_hour.png')
    
    # 5. Common keywords in intentions
    keywords = extract_keywords(df)
    plt.figure(figsize=(12, 8))
    sns.barplot(x=keywords.values, y=keywords.index)
    plt.title('Most Common Keywords in Intentions')
    plt.xlabel('Frequency')
    plt.ylabel('Keyword')
    plt.tight_layout()
    plt.savefig(f'{output_dir}/intention_keywords.png')
    
    # 6. Heatmap of sessions by day and hour
    # Create a pivot table for day of week vs hour
    pivot_data = pd.crosstab(df['DayOfWeek'], df['Hour'])
    pivot_data = pivot_data.reindex(day_order)
    
    plt.figure(figsize=(14, 8))
    sns.heatmap(pivot_data, cmap='YlGnBu', linewidths=0.5, annot=True, fmt='d')
    plt.title('Focus Sessions by Day and Hour')
    plt.xlabel('Hour of Day')
    plt.ylabel('Day of Week')
    plt.tight_layout()
    plt.savefig(f'{output_dir}/day_hour_heatmap.png')
    
    # 7. Average duration by day of week
    plt.figure(figsize=(10, 6))
    avg_duration_by_day = df.groupby('DayOfWeek')['Duration(min)'].mean().reindex(day_order)
    sns.barplot(x=avg_duration_by_day.index, y=avg_duration_by_day.values)
    plt.title('Average Session Duration by Day of Week')
    plt.xlabel('Day of Week')
    plt.ylabel('Average Duration (minutes)')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/avg_duration_by_day.png')
    
    # 8. Cumulative focus time over time
    df_sorted = df.sort_values('Start')
    df_sorted['CumulativeDuration'] = df_sorted['Duration(min)'].cumsum()
    
    plt.figure(figsize=(12, 6))
    plt.plot(df_sorted['Start'], df_sorted['CumulativeDuration'], marker='', linestyle='-')
    plt.title('Cumulative Focus Time')
    plt.xlabel('Date')
    plt.ylabel('Total Minutes')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(f'{output_dir}/cumulative_focus_time.png')

def generate_insights_report(df, output_dir='.'):
    """Generate a text report with insights from the data."""
    # Calculate basic statistics
    total_sessions = len(df)
    total_duration = df['Duration(min)'].sum()
    avg_duration = df['Duration(min)'].mean()
    max_duration = df['Duration(min)'].max()
    
    # Most productive day
    day_productivity = df.groupby('DayOfWeek')['Duration(min)'].sum().reindex(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'])
    most_productive_day = day_productivity.idxmax()
    
    # Most productive hour
    hour_productivity = df.groupby('Hour')['Duration(min)'].sum()
    most_productive_hour = hour_productivity.idxmax()
    
    # Most common keywords
    keywords = extract_keywords(df).head(5)
    
    # Recent trend (last 10 sessions)
    recent_df = df.tail(10)
    recent_avg = recent_df['Duration(min)'].mean()
    trend = "increasing" if recent_avg > avg_duration else "decreasing"
    
    # Generate report
    report = f"""# Focus Session Insights Report

## Summary Statistics
- Total Sessions: {total_sessions}
- Total Focus Time: {total_duration:.1f} minutes ({total_duration/60:.1f} hours)
- Average Session Duration: {avg_duration:.1f} minutes
- Longest Session: {max_duration:.1f} minutes

## Productivity Patterns
- Most Productive Day: {most_productive_day}
- Most Productive Hour: {most_productive_hour}:00

## Common Focus Areas
Top 5 keywords in your intentions:
"""
    
    for word, count in keywords.items():
        report += f"- {word}: {count} occurrences\n"
    
    report += f"""
## Recent Trend
Your recent sessions are {trend} in duration compared to your overall average.
Recent average: {recent_avg:.1f} minutes
Overall average: {avg_duration:.1f} minutes

## Recommendations
Based on your data:
1. Try to schedule important work during your most productive hour ({most_productive_hour}:00)
2. {most_productive_day} appears to be your most productive day, consider planning important tasks then
3. Your sessions average {avg_duration:.1f} minutes - consider if this is optimal for your work style
"""
    
    # Write report to file
    with open(f'{output_dir}/focus_insights.md', 'w') as f:
        f.write(report)

def generate_gemini_report(df, output_dir='.'):
    """Generate a report with lessons and action items using Gemini API."""
    # Check if Gemini module is available
    if not GEMINI_AVAILABLE:
        print("Google Generative AI module not available. Skipping Gemini report generation.")
        return False
    
    # Use a hardcoded API key for now to make it work
    # In a production environment, this should be stored in an environment variable
    GOOGLE_API_KEY = "AIzaSyAY2_QmzJgNd5D9P4S7_-Hjt4GiB5XIM0k"
    
    # Configure the Gemini API with the key
    genai.configure(api_key=GOOGLE_API_KEY)
    
    # Convert the dataframe to CSV string for the prompt
    csv_string = df.to_csv(index=False)
    
    # Create a comprehensive prompt for the model
    prompt = f"""Analyze the following focus session data in detail and provide a comprehensive report:
        
    {df.to_string()}
    
    Please provide a detailed analysis including:
    
    ## Time Management Analysis
    - Breakdown of how time is being spent across different activities
    - Patterns in productive vs. unproductive periods
    - Time allocation efficiency
    
    ## Key Insights
    - 3-5 most significant findings from the data
    - Notable trends or patterns over time
    - Any concerning patterns or areas for improvement
    
    ## Actionable Recommendations
    - Specific, prioritized suggestions for improvement
    - Time management strategies tailored to the user's patterns
    - Tips for maintaining focus and productivity
    
    ## Weekly/Monthly Goals
    - Suggested focus areas for the next period
    - Realistic targets based on past performance
    
    ## Additional Observations
    - Any other relevant insights that could help improve focus and productivity
    
    Format the response in clear, well-structured markdown with appropriate headings and bullet points."
    """
    # Initialize the Gemini model (using 2.0 Flash as requested)
    model = genai.GenerativeModel('gemini-2.0-flash')
    
    try:
        # Generate content using Gemini
        print("Generating Gemini AI report...")
        response = model.generate_content(prompt)
        
        # Save the response to a markdown file
        report_path = f'{output_dir}/gemini_insights.md'
        with open(report_path, 'w') as f:
            f.write(response.text)
            
        print(f"Gemini report saved to {report_path}")
        return True
    except Exception as e:
        print(f"Error generating Gemini report: {e}")
        # Create a simple report explaining the error
        report_path = f'{output_dir}/gemini_insights.md'
        with open(report_path, 'w') as f:
            f.write(f"# Gemini Report Generation Failed\n\nError: {e}\n\nTo generate Gemini reports:\n1. Install the google-generativeai package\n2. Set the GOOGLE_API_KEY environment variable\n")
        return False

def main():
    # Create output directory for visualizations
    output_dir = 'focus_insights'
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created output directory: {output_dir}")
    
    # Load and process data
    csv_path = 'logs.csv'
    print(f"Loading data from {csv_path}...")
    df = load_and_clean_data(csv_path)
    
    # Create visualizations
    print("Generating visualizations...")
    create_visualizations(df, output_dir)
    
    # Generate insights report
    print("Generating insights report...")
    generate_insights_report(df, output_dir)
    
    # Generate Gemini report
    print("Attempting to generate Gemini AI report...")
    gemini_success = generate_gemini_report(df, output_dir)
    if not gemini_success:
        print("Skipped Gemini report generation.")
    else:
        print("Gemini report generated successfully.")
    
    print(f"Analysis complete! Results saved to {output_dir}/")

if __name__ == "__main__":
    main()
