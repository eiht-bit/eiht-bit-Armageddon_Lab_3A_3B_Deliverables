#!/bin/bash
dnf update -y
dnf install -y python3-pip amazon-cloudwatch-agent
pip3 install flask pymysql boto3

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/rdsapp.log",
            "log_group_name": "/aws/ec2/lab-rds-app",
            "log_stream_name": "{instance_id}/app-logs",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWCONFIG

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json \
  -s

mkdir -p /opt/rdsapp

cat > /opt/rdsapp/app.py << 'PYEOF'
import json
import os
import boto3
import pymysql
from flask import Flask, request
import logging

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
ssm = boto3.client("ssm", region_name=REGION)

def get_ssm_param(name):
    resp = ssm.get_parameter(Name=name)
    return resp['Parameter']['Value']

DB_HOST = get_ssm_param("/lab/db/endpoint")
DB_PORT = int(get_ssm_param("/lab/db/port"))
DB_NAME = get_ssm_param("/lab/db/name")

SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysqli")
secrets = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    resp = secrets.get_secret_value(SecretId=SECRET_ID)
    return json.loads(resp["SecretString"])

# Configure logging to file (CloudWatch Agent reads this)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/rdsapp.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def get_conn():
    try:
        c = get_db_creds()
        user = c["username"]
        password = c["password"]
        conn = pymysql.connect(
            host=DB_HOST, user=user, password=password,
            port=DB_PORT, database=DB_NAME, autocommit=True
        )
        logger.info("DB_CONNECTION_SUCCESS")
        return conn
    except Exception as e:
        logger.error(f"DB_CONNECTION_ERROR: {str(e)}")
        raise

app = Flask(__name__)

@app.route("/")
def home():
    return '''
    <h2>EC2 → RDS Notes App (Lab 1C - Bonus A - Private + CloudWatch Agent)</h2>
    <p>POST /add?note=hello</p>
    <p>GET /list</p>
    <p>GET /health</p>
    '''

@app.route("/health")
def health():
    try:
        conn = get_conn()
        conn.close()
        logger.info("HEALTH_CHECK_SUCCESS")
        return "OK", 200
    except Exception as e:
        logger.error(f"HEALTH_CHECK_FAILED: {str(e)}")
        return f"DB Connection Failed: {str(e)}", 500

@app.route("/init")
def init_db():
    try:
        c = get_db_creds()
        user = c["username"]
        password = c["password"]
        conn = pymysql.connect(host=DB_HOST, user=user, password=password, port=DB_PORT, autocommit=True)
        cur = conn.cursor()
        cur.execute("CREATE DATABASE IF NOT EXISTS labdb;")
        cur.execute("USE labdb;")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                note VARCHAR(255) NOT NULL
            );
        """)
        cur.close()
        conn.close()
        logger.info("DB_INIT_SUCCESS")
        return "Initialized labdb + notes table."
    except Exception as e:
        logger.error(f"INIT_ERROR: {e}")
        return f"Init failed: {e}", 500

@app.route("/add", methods=["POST", "GET"])
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        logger.warning("ADD_NOTE_MISSING_PARAM")
        return "Missing note param. Try: /add?note=hello", 400
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("INSERT INTO notes(note) VALUES(%s);", (note,))
        cur.close()
        conn.close()
        logger.info(f"ADD_NOTE_SUCCESS: {note}")
        return f"Inserted note: {note}"
    except Exception as e:
        logger.error(f"ADD_ERROR: {e}")
        return f"Failed to add note: {e}", 500

@app.route("/list")
def list_notes():
    try:
        conn = get_conn()
        cur = conn.cursor()
        cur.execute("SELECT id, note FROM notes ORDER BY id DESC;")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        logger.info(f"LIST_NOTES_SUCCESS: {len(rows)} notes")
        out = "<h3>Notes</h3><ul>"
        for r in rows:
            out += f"<li>{r[0]}: {r[1]}</li>"
        out += "</ul>"
        return out
    except Exception as e:
        logger.error(f"LIST_ERROR: {e}")
        return f"Failed to list notes: {e}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
PYEOF

# Create systemd service
cat > /etc/systemd/system/rdsapp.service << 'SVCEOF'
[Unit]
Description=EC2 to RDS Notes App (Lab 1C - Bonus A)
After=network.target

[Service]
WorkingDirectory=/opt/rdsapp
Environment=SECRET_ID=lab/rds/mysqli
Environment=AWS_REGION=ap-northeast-1
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable rdsapp
systemctl start rdsapp