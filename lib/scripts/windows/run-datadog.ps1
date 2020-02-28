# Fix datadog.yaml for apm log file since it cannot be set via env vars currently
$DATADOG_DIR="C:\Users\vcap\app\datadog"
echo "apm_config:" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"
echo "  log_file: $DATADOG_DIR\trace.log" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"

# Write the DD tags we detect out to the datadog.yaml file
$tags = & "$DATADOG_DIR\scripts\get_tags.ps1"
$tags_out = "tags:`n"
foreach ($element in $tags) {
    $tags_out += "    - $element`n"
}
echo "$tags_out" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"

# Update the path to the check configuration files
echo "confd_path: $DATADOG_DIR\AppData\datadog-agent\conf.d" | Out-File "$DATADOG_DIR\AppData\datadog.yaml" -Append -Encoding "UTF8"

# Write the config for the logs
$LOGS_CONFIG_DIR="$DATADOG_DIR\AppData\datadog-agent\conf.d\logs.d"
New-Item $LOGS_CONFIG_DIR -ItemType "directory" -Force
echo "{`"logs`":$Env:LOGS_CONFIG}" | Out-File $LOGS_CONFIG_DIR\logs.yaml

# Logs, core checks, and dogstatsd
Start-Process "$DATADOG_DIR\bin\agent.exe" -ArgumentList "run -c $DATADOG_DIR\AppData" -NoNewWindow

# Start redirecting logs to the agent port
Start-Process "$DATADOG_DIR\scripts\redirect_logs.ps1"

# Traces
Start-Process "$DATADOG_DIR\bin\agent\trace-agent.exe" -ArgumentList "--config $DATADOG_DIR\AppData\datadog.yaml" -NoNewWindow
