#!/usr/bin/env python3
"""
Show Focus Session Analysis

This script generates and displays an HTML report of focus session analysis.
It's designed to be called when a user enters "run analysis" in the intention field.
"""

import os
import webbrowser
import tempfile
from datetime import datetime
import visualize_logs

def read_file_content(file_path, default_content=''):
    """Safely read file content with error handling."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except (IOError, OSError) as e:
        print(f"Warning: Could not read {file_path}: {e}")
        return default_content

def generate_css():
    """Generate CSS styles for the HTML report."""
    return """
    <style>
        :root {
            --primary: #1a73e8;
            --primary-light: #e8f0fe;
            --text: #202124;
            --text-secondary: #5f6368;
            --background: #ffffff;
            --card-bg: #ffffff;
            --border: #dadce0;
            --shadow: 0 1px 2px 0 rgba(60,64,67,0.3), 0 1px 3px 1px rgba(60,64,67,0.15);
        }
        
        @media (prefers-color-scheme: dark) {
            :root {
                --primary: #8ab4f8;
                --primary-light: #1e3a8a;
                --text: #e8eaed;
                --text-secondary: #9aa0a6;
                --background: #202124;
                --card-bg: #2d2e30;
                --border: #5f6368;
                --shadow: 0 1px 3px 0 rgba(0,0,0,0.3), 0 1px 2px 0 rgba(0,0,0,0.2);
            }
        }
        
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background-color: var(--background);
            color: var(--text);
            line-height: 1.6;
            -webkit-font-smoothing: antialiased;
        }
        
        .container { 
            max-width: 1200px; 
            margin: 0 auto;
            padding: 20px;
        }
        
        header {
            background: var(--card-bg);
            padding: 20px;
            margin-bottom: 30px;
            box-shadow: var(--shadow);
            border-radius: 8px;
        }
        
        h1, h2, h3 {
            color: var(--text);
            margin-bottom: 15px;
        }
        
        h1 {
            font-size: 2.2em;
            margin-bottom: 5px;
        }
        
        h2 {
            font-size: 1.8em;
            margin-top: 30px;
        }
        
        h3 {
            font-size: 1.4em;
            margin-top: 20px;
        }
        
        .timestamp {
            color: var(--text-secondary);
            font-size: 0.9em;
            display: block;
            margin-bottom: 15px;
        }
        
        .charts-container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 25px;
            margin: 30px 0;
        }
        
        .chart-item {
            background: var(--card-bg);
            border-radius: 8px;
            overflow: hidden;
            box-shadow: var(--shadow);
            transition: transform 0.3s ease;
        }
        
        .chart-item:hover {
            transform: translateY(-5px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        
        img { 
            max-width: 100%; 
            height: auto; 
            display: block;
            border-radius: 4px;
        }
        
        .report { 
            background: var(--card-bg);
            padding: 25px; 
            border-radius: 8px; 
            white-space: pre-wrap;
            margin: 25px 0;
            border-left: 4px solid var(--primary);
            box-shadow: var(--shadow);
        }
        
        .section {
            margin: 40px 0;
        }
        
        .section-title {
            font-size: 1.8em;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--primary);
            color: var(--text);
        }
        
        .ai-section {
            background: var(--primary-light);
            padding: 20px;
            border-radius: 8px;
            margin: 30px 0;
        }
        
        /* Markdown styling */
        .markdown-content h1,
        .markdown-content h2,
        .markdown-content h3,
        .markdown-content h4,
        .markdown-content h5,
        .markdown-content h6 {
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            color: var(--text);
        }
        
        .markdown-content h1 { font-size: 1.8em; }
        .markdown-content h2 { font-size: 1.6em; }
        .markdown-content h3 { font-size: 1.4em; }
        .markdown-content h4 { font-size: 1.2em; }
        .markdown-content h5 { font-size: 1.1em; }
        .markdown-content h6 { font-size: 1em; }
        
        .markdown-content p {
            margin-bottom: 1em;
            line-height: 1.6;
        }
        
        .markdown-content ul,
        .markdown-content ol {
            margin-left: 2em;
            margin-bottom: 1em;
        }
        
        .markdown-content li {
            margin-bottom: 0.5em;
        }
        
        .markdown-content blockquote {
            border-left: 4px solid var(--primary);
            padding-left: 1em;
            margin-left: 0;
            margin-right: 0;
            font-style: italic;
            color: var(--text-secondary);
        }
        
        .markdown-content code {
            font-family: monospace;
            background-color: rgba(0, 0, 0, 0.1);
            padding: 0.2em 0.4em;
            border-radius: 3px;
            font-size: 0.9em;
        }
        
        .markdown-content pre {
            background-color: rgba(0, 0, 0, 0.1);
            padding: 1em;
            border-radius: 5px;
            overflow-x: auto;
            margin-bottom: 1em;
        }
        
        .markdown-content pre code {
            background-color: transparent;
            padding: 0;
        }
        
        .markdown-content a {
            color: var(--primary);
            text-decoration: none;
        }
        
        .markdown-content a:hover {
            text-decoration: underline;
        }
        
        .markdown-content table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 1em;
        }
        
        .markdown-content th,
        .markdown-content td {
            border: 1px solid var(--border);
            padding: 0.5em;
            text-align: left;
        }
        
        .markdown-content th {
            background-color: rgba(0, 0, 0, 0.05);
        }
    </style>
    """

def generate_html_report(output_dir):
    """Generate an HTML report with the analysis results."""
    # Check which reports are available
    has_gemini = os.path.exists(os.path.join(output_dir, 'gemini_insights.md'))
    has_insights = os.path.exists(os.path.join(output_dir, 'focus_insights.md'))
    
    # Get and sort chart files
    try:
        charts = [f for f in os.listdir(output_dir) 
                 if f.lower().endswith(('.png', '.jpg', '.jpeg', '.svg'))]
        
        # Sort charts to display in a consistent order
        chart_order = {
            'session_duration_over_time.png': 0,
            'daily_focus_hours.png': 1,
            'sessions_by_day.png': 2,
            'duration_distribution.png': 3,
            'cumulative_focus_time.png': 4
        }
        charts.sort(key=lambda x: chart_order.get(x.lower(), 99))
    except OSError as e:
        print(f"Warning: Could not read chart files: {e}")
        charts = []
    
    # Generate charts HTML
    charts_html = ''
    for chart in charts:
        chart_title = chart.replace('_', ' ').title().replace('.png', '')
        chart_path = os.path.abspath(os.path.join(output_dir, chart))
        charts_html += f"""
        <div class="chart-item">
            <h3>{chart_title}</h3>
            <div class="chart">
                <img src="{chart_path}" alt="{chart_title}">
            </div>
        </div>
        """
    
    # Generate AI insights section
    ai_content = read_file_content(
        os.path.join(output_dir, 'gemini_insights.md'), 
        'AI analysis not available. Make sure you have set up the Gemini API key.' if has_gemini else ''
    )
    
    # Generate key insights section
    insights_content = ''
    if has_insights:
        insights_content = read_file_content(os.path.join(output_dir, 'focus_insights.md'), '')
    
    # Prepare content for HTML embedding
    import html
    ai_content_escaped = html.escape(ai_content)
    insights_content_escaped = html.escape(insights_content) if has_insights else ''
    
    # Build the complete HTML
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>Focus Session Analysis</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    {generate_css()}
    <!-- Include Marked.js for Markdown rendering -->
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
</head>
<body>
    <div class="container">
        <header>
            <h1>Focus Session Analysis</h1>
            <span class="timestamp">Last updated: {timestamp}</span>
        </header>
        
        <!-- AI Analysis Section -->
        <div class="section">
            <h2 class="section-title">AI Analysis</h2>
            <div class="ai-section markdown-content" id="ai-analysis">
                <textarea id="ai-markdown" style="display:none;">{ai_content_escaped}</textarea>
                <!-- Content will be rendered by JavaScript -->
            </div>
        </div>
        
        <!-- Key Insights Section -->
        {f'''<div class="section">
            <h2 class="section-title">Key Insights</h2>
            <div class="report markdown-content" id="key-insights">
                <textarea id="insights-markdown" style="display:none;">{insights_content_escaped}</textarea>
                <!-- Content will be rendered by JavaScript -->
            </div>
        </div>''' if has_insights else ''}
        
        <!-- Charts Section -->
        <div class="section">
            <h2 class="section-title">Visualizations</h2>
            <div class="charts-container">
                {charts_html}
            </div>
        </div>
        
        <!-- Markdown rendering script -->
        <script>
            // Render markdown content
            document.addEventListener('DOMContentLoaded', function() {{
                // Render AI content
                const aiMarkdown = document.getElementById('ai-markdown');
                if (aiMarkdown) {{
                    document.getElementById('ai-analysis').innerHTML = marked.parse(aiMarkdown.value);
                }}
                
                // Render insights content
                const insightsMarkdown = document.getElementById('insights-markdown');
                if (insightsMarkdown) {{
                    document.getElementById('key-insights').innerHTML = marked.parse(insightsMarkdown.value);
                }}
            }});
            
            // Add smooth scrolling for better UX
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {{
                anchor.addEventListener('click', function (e) {{
                    e.preventDefault();
                    document.querySelector(this.getAttribute('href')).scrollIntoView({{
                        behavior: 'smooth'
                    }});
                }});
            }});
        </script>
    </div>
</body>
</html>"""
    
    return html_content

def run_analysis():
    """Run the analysis and generate the report."""
    try:
        # Create output directory
        output_dir = os.path.join('focus_insights', 'latest')
        os.makedirs(output_dir, exist_ok=True)
        
        print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Starting analysis...")
        
        # Load and clean data
        df = visualize_logs.load_and_clean_data('logs.csv')
        
        # Generate visualizations and reports
        visualize_logs.create_visualizations(df, output_dir=output_dir)
        visualize_logs.generate_insights_report(df, output_dir=output_dir)
        
        # Try to generate Gemini report if available
        try:
            print("Generating AI analysis...")
            visualize_logs.generate_gemini_report(df, output_dir=output_dir)
        except Exception as e:
            print(f"Note: Could not generate Gemini report: {e}")
        
        # Generate HTML report
        html_content = generate_html_report(output_dir)
        
        # Save HTML to a permanent file in the output directory
        html_path = os.path.join(output_dir, 'focus_report.html')
        with open(html_path, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        # Get absolute path for browser
        abs_path = os.path.abspath(html_path)
        
        # Open in default browser
        webbrowser.open(f'file://{abs_path}')
        
        print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Analysis complete! Report saved to {html_path} and opened in browser.")
        return html_path
        
    except Exception as e:
        print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Error generating analysis: {e}")
        return None

def main():
    """Main function to run the analysis once."""
    print("Starting focus session analysis tool")
    
    try:
        html_path = run_analysis()
        print(f"\nAnalysis complete. Report saved to {html_path}")
        print("You can close this window.")
        return html_path
            
    except KeyboardInterrupt:
        print("\nAnalysis stopped by user.")
    except Exception as e:
        print(f"Unexpected error: {e}")

if __name__ == "__main__":
    main()
