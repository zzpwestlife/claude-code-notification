#!/usr/bin/env python3
import json
import argparse
import os
import sys
from datetime import datetime

def generate_html(data, output_file):
    timestamps = []
    totals = []
    
    table_rows = ""
    
    for entry in data:
        # data is the 'data' field from log
        ts = entry.get('end_ts')
        if not ts: continue
        
        ts_str = datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
        timestamps.append(ts_str)
        
        total = entry.get('total_ms', 0)
        totals.append(round(total, 2))
        
        prompt = entry.get('prompt', '')
        # Truncate prompt
        prompt_display = (prompt[:75] + '...') if len(prompt) > 75 else prompt
        if not prompt_display:
            prompt_display = "<em>(No prompt captured)</em>"
        else:
            # Escape HTML chars vaguely (simple)
            prompt_display = prompt_display.replace('<', '&lt;').replace('>', '&gt;')
        
        table_rows += f"""
        <tr>
            <td>{ts_str}</td>
            <td>{prompt_display}</td>
            <td>{total:.2f} ms</td>
        </tr>
        """
        
    html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Claude Code Benchmark Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; margin: 20px; color: #333; }}
        .container {{ max_width: 1000px; margin: 0 auto; }}
        h1 {{ color: #2c3e50; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.2); }}
        th, td {{ border: 1px solid #ddd; padding: 12px; text-align: left; }}
        th {{ background-color: #f8f9fa; font-weight: 600; }}
        tr:nth-child(even) {{ background-color: #f9f9f9; }}
        tr:hover {{ background-color: #f1f1f1; }}
        .chart-container {{ position: relative; height: 400px; width: 100%; margin-bottom: 40px; }}
        td:nth-child(2) {{ font-family: monospace; font-size: 0.9em; color: #555; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Claude Code Performance Report</h1>
        <p>Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        
        <div class="chart-container">
            <canvas id="perfChart"></canvas>
        </div>
        
        <h2>Interaction Logs</h2>
        <table>
            <thead>
                <tr>
                    <th>Completion Time</th>
                    <th>Prompt (Snippet)</th>
                    <th>Total Response Time</th>
                </tr>
            </thead>
            <tbody>
                {table_rows}
            </tbody>
        </table>
    </div>

    <script>
        const ctx = document.getElementById('perfChart').getContext('2d');
        new Chart(ctx, {{
            type: 'line',
            data: {{
                labels: {json.dumps(timestamps)},
                datasets: [
                    {{
                        label: 'Response Time (ms)',
                        data: {json.dumps(totals)},
                        borderColor: 'rgb(75, 192, 192)',
                        backgroundColor: 'rgba(75, 192, 192, 0.2)',
                        tension: 0.1,
                        fill: true
                    }}
                ]
            }},
            options: {{
                responsive: true,
                maintainAspectRatio: false,
                scales: {{
                    y: {{
                        beginAtZero: true,
                        title: {{ display: true, text: 'Milliseconds' }}
                    }}
                }},
                plugins: {{
                    title: {{
                        display: true,
                        text: 'Response Time Trend'
                    }},
                    tooltip: {{
                        callbacks: {{
                            afterLabel: function(context) {{
                                return '';
                            }}
                        }}
                    }}
                }}
            }}
        }});
    </script>
</body>
</html>
    """
    
    with open(output_file, 'w') as f:
        f.write(html)
    print(f"Report generated: {output_file}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('log_file', nargs='?', default='claude_bench.jsonl', help='Path to .jsonl log file')
    parser.add_argument('--output', '-o', default='report.html', help='Output HTML file')
    args = parser.parse_args()
    
    if not os.path.exists(args.log_file):
        print(f"Log file not found: {args.log_file}")
        print("No interactions recorded yet. Try using Claude Code first.")
        sys.exit(1)

    data = []
    with open(args.log_file, 'r') as f:
        for line in f:
            try:
                entry = json.loads(line)
                if entry.get('type') == 'INTERACTION' and entry.get('data'):
                    data.append(entry['data'])
            except:
                continue
    
    generate_html(data, args.output)

if __name__ == '__main__':
    main()
