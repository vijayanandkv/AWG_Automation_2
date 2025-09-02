import json
import os

class ConfigLoader:
    def __init__(self, config_filename="config.json"):
        config_path = os.path.join(os.path.dirname(__file__), config_filename)
        if not os.path.exists(config_path):
            raise FileNotFoundError(f"Configuration file '{config_path}' not found.")
        with open(config_path, "r") as f:
            self.config = json.load(f)

    def get(self, key, default=None):
        return self.config.get(key, default)

    def __getitem__(self, key):
        return self.config[key]

    def as_dict(self):
        return self.config

# Optional convenience function
def load_config(config_path="config.json"):
    return ConfigLoader(config_path)
