"""
Compatibility patches for Flask/Werkzeug version mismatches
This module MUST be imported before any Flask-WTF imports
"""

import sys
import json


def apply_all_patches():
    """Apply all necessary compatibility patches"""

    # Patch 1: Flask Markup compatibility
    try:
        from markupsafe import Markup

        # Try to import flask and patch it
        try:
            import flask

            if not hasattr(flask, "Markup"):
                flask.Markup = Markup
                print("✅ Applied Flask Markup compatibility patch")
        except ImportError:
            # Flask not imported yet, create mock module
            import types

            flask_mock = types.ModuleType("flask")
            flask_mock.Markup = Markup
            sys.modules["flask"] = flask_mock
            print("✅ Created Flask mock with Markup compatibility")
    except ImportError:
        print("❌ Failed to apply Flask Markup patch")

    # Patch 2: Flask JSONEncoder compatibility
    try:
        import flask.json

        if not hasattr(flask.json, "JSONEncoder"):
            flask.json.JSONEncoder = json.JSONEncoder
            print("✅ Applied Flask JSONEncoder compatibility patch")
    except (ImportError, AttributeError):
        # Try to create flask.json module if it doesn't exist
        try:
            import flask

            if not hasattr(flask, "json"):
                import types

                flask_json_mock = types.ModuleType("flask.json")
                flask_json_mock.JSONEncoder = json.JSONEncoder
                flask.json = flask_json_mock
                sys.modules["flask.json"] = flask_json_mock
                print("✅ Created Flask JSON mock with JSONEncoder")
        except (ImportError, AttributeError) as e:
            print(f"⚠️  Flask JSONEncoder patch failed: {e}")

    # Patch 3: Werkzeug url_encode compatibility
    try:
        import werkzeug.urls

        if not hasattr(werkzeug.urls, "url_encode"):
            from urllib.parse import urlencode

            werkzeug.urls.url_encode = urlencode
            print("✅ Applied Werkzeug url_encode compatibility patch")
    except (ImportError, AttributeError) as e:
        print(f"⚠️  Werkzeug patch not needed or failed: {e}")

    # Patch 4: Werkzeug url_quote compatibility (just in case)
    try:
        import werkzeug.urls

        if not hasattr(werkzeug.urls, "url_quote"):
            from urllib.parse import quote

            werkzeug.urls.url_quote = quote
            print("✅ Applied Werkzeug url_quote compatibility patch")
    except (ImportError, AttributeError):
        pass


# Auto-apply patches when module is imported
apply_all_patches()
