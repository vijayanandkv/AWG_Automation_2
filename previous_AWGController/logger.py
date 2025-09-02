import os
import time
import datetime

class awg_logger:
    def __init__(self, device_name='AWG'):
        self.device_name = device_name.upper()
        self._log_file_path = None
        self._initialize_log_file()

    # ---------------------- INITIALIZE LOG FILE ---------------------
    def _initialize_log_file(self):
        """Initialize the log file with timestamp in the format <DEVICE>_ddmmyyyy.txt"""
        today = datetime.datetime.today()
        #timestamp = now.strftime('%d%m%Y%H%M')
        file_name = f"{self.device_name.lower()}_{today.strftime('%d%m%Y')}.txt"
        self._log_file_path = os.path.join(os.getcwd(), file_name)

        with open(self._log_file_path, 'w') as f:
            f.write(f"Log file created for {self.device_name} at {today} \n")

    # ---------------------- APPEND LOG COMMAND ---------------------
    def _log_command(self, command: str, duration_ms: float = None, response: str = None):
        """Log SCPI command with optional duration and response"""
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_line = f"[{timestamp}] SCPI: {command}"

        if duration_ms is not None:
            log_line += f" | Duration: {duration_ms:.2f} ms"
        if response is not None:
            log_line += f" | Response: {response}"
        log_line += "\n"

        if self._log_file_path:
            with open(self._log_file_path, 'a') as f:
                f.write(log_line)

        return log_line  # For current command display in GUI

    def get_log_file_path(self):
        return self._log_file_path
