
try:
    import flask
    print("Flask is installed")
except ImportError:
    print("Flask is NOT installed")

try:
    import flask_cors
    print("Flask-CORS is installed")
except ImportError:
    print("Flask-CORS is NOT installed")
