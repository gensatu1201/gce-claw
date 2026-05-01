# 🚀 OpenClaw (OC) Deployment Guide: GCP + DuckDNS + HTTPS

This guide provides a streamlined process for deploying **OpenClaw** on Google Compute Engine using Terraform. This setup ensures your AI agent has a permanent address and automatic SSL (HTTPS) for secure communication.

## 📋 Prerequisites
* A **Google Cloud Platform** project with billing enabled.
* A free **DuckDNS** account.

---

## Phase 1: Claim Your Permanent URL
1. Go to [DuckDNS.org](https://www.duckdns.org) and sign in.
2. Create a unique subdomain (e.g., `jsmith-claw`).
3. Copy your **Token** and **Subdomain**. You will need these in Phase 3.

---

## Phase 2: Launch the Infrastructure
We will use **Google Cloud Shell** to provision the server.

1. Open **Google Cloud Shell**.
2. Run these commands:
```bash
# 1. Enable the Compute Engine API
gcloud services enable compute.googleapis.com

# 2. Clone the deployment repository
git clone [https://github.com/gensatu1201/gce-claw.git](https://github.com/gensatu1201/gce-claw.git)
cd gce-claw

# 3. Initialize and apply Terraform
terraform init
terraform apply -var="project_id=$(gcloud config get-value project)" -auto-approve
```

3. Once complete, log into your new server via SSH:
```bash
gcloud compute ssh claw-server --zone=us-central1-a
```

---

## Phase 3: The "One-Touch" Setup
Once you are **inside** the server terminal (prompt says `ubuntu@claw-server`), paste the following block after editing the first two lines.

```bash
# --- ⚠️ EDIT THE TWO LINES BELOW ⚠️ ---
DOMAIN="your-subdomain-here"
TOKEN="your-token-here"
# --------------------------------------

# 1. Force initial DuckDNS Sync
IP=$(curl -s [http://checkip.amazonaws.com](http://checkip.amazonaws.com))
curl -s "[https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$IP](https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=$IP)"

# 2. Run the OpenClaw 1-Line Installer
curl -fsSL [https://openclaw.ai/install.sh](https://openclaw.ai/install.sh) | bash

# 3. Setup the HTTPS config (Caddyfile) pointing to OpenClaw port 18789
cat <<EOF> Caddyfile
$DOMAIN.duckdns.org {
    reverse_proxy localhost:18789
}
EOF

# 4. Launch the HTTPS Provider (Caddy)
sudo docker run -d --name caddy --restart always \
  -p 80:80 -p 443:443 \
  --network host \
  -v $(pwd)/Caddyfile:/etc/caddy/Caddyfile \
  -v caddy_data:/data \
  caddy

# 5. Enable Auto-Sync (Updates IP every 5 mins automatically)
(crontab -l 2>/dev/null; echo "*/5 * * * * curl -s '[https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=](https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=)' >/dev/null 2>&1") | crontab -

echo "--------------------------------------------------------"
echo "✅ SETUP COMPLETE!"
echo "Your Secure OpenClaw link: https://$DOMAIN.duckdns.org"
echo "--------------------------------------------------------"
```

---

## 💡 Important Tips for Success

### 1. Persistence & Cost Savings
To save your budget, **STOP** your instance in the Google Cloud Console when not in use. 
* **To Resume:** Simply **START** the instance. 
* **Wait 5 minutes:** The server will automatically wake up OpenClaw, Caddy, and update your IP address. Your Telegram bot will resume automatically.

### 2. Secure Dashboard
By using Caddy, your OpenClaw dashboard is protected by HTTPS. This is vital because you will be entering sensitive API keys (like Gemini or OpenAI) into the interface.

### 3. Telegram Commands
Because this setup uses **Long Polling**, your Telegram bot will work perfectly even if the IP changes, as long as the server is powered on.
`````</EOF>
