#!/bin/bash
# User data script for EC2 instances

# Update system
yum update -y || apt-get update -y

# Install web server
yum install -y httpd || apt-get install -y apache2

# Start web server
systemctl start httpd || systemctl start apache2
systemctl enable httpd || systemctl enable apache2

# Create index page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>${environment} Environment</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        h1 { color: #333; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🚀 ${environment} Environment</h1>
    <div class="info">
        <p><strong>Instance Name:</strong> ${name}</p>
        <p><strong>Environment:</strong> ${environment}</p>
        <p><strong>Instance ID:</strong> $(ec2-metadata --instance-id | cut -d " " -f 2)</p>
        <p><strong>Region:</strong> $(ec2-metadata --availability-zone | cut -d " " -f 2 | sed 's/.$//')</p>
        <p><strong>Deployed with:</strong> Terraform + Vault</p>
    </div>
</body>
</html>
EOF

echo "✅ User data script completed"