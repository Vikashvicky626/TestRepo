# DNS Troubleshooting Guide - securetechsquad.com

## 🔍 Problem Analysis

Your domain `securetechsquad.com` is experiencing a "Host Not Found" error. Here's what I discovered:

### DNS Resolution Status
✅ **Domain Resolves**: `securetechsquad.com` → `139.84.222.64`  
❌ **Server Not Responding**: Port 80 connection failed

## 🎯 Root Cause

The domain is resolving correctly, but the server at `139.84.222.64` is not responding on port 80. This means:

1. **DNS Configuration**: ✅ Working correctly
2. **Server/Application**: ❌ Not running or not accessible

## 🔧 Troubleshooting Steps

### Step 1: Verify Your Vultr Server IP
```bash
# Check your actual Vultr server IP address
# Log into your Vultr account and compare with: 139.84.222.64
```

### Step 2: Update DNS Records (if needed)
If `139.84.222.64` is NOT your Vultr server IP:

1. **Log into your domain registrar** (where you bought securetechsquad.com)
2. **Find DNS management** or **DNS settings**
3. **Update A record**:
   - **Type**: A
   - **Name**: @ (or blank)
   - **Value**: [Your actual Vultr server IP]
   - **TTL**: 300 (5 minutes)

### Step 3: Deploy Your Application
If the IP is correct but server isn't responding:

```bash
# On your Vultr server, deploy the application
cd /path/to/your/app
./deploy-http.sh
```

### Step 4: Check Application Status
```bash
# Verify containers are running
sudo docker ps

# Check if port 80 is listening
sudo netstat -tlnp | grep :80

# Check nginx logs
sudo docker logs attendance-nginx
```

### Step 5: Configure Firewall (if needed)
```bash
# Allow HTTP traffic on port 80
sudo ufw allow 80/tcp
sudo ufw reload
```

## 📋 Quick DNS Check Commands

```bash
# Check DNS resolution
dig securetechsquad.com

# Check specific record types
dig securetechsquad.com A     # IPv4 address
dig securetechsquad.com AAAA  # IPv6 address
dig securetechsquad.com CNAME # Alias records

# Test server connectivity
curl -I http://securetechsquad.com
telnet securetechsquad.com 80
```

## 🚀 Deployment Checklist

### DNS Configuration:
- [ ] Domain points to correct Vultr server IP
- [ ] A record is set for `@` (root domain)
- [ ] WWW record is set (optional)
- [ ] TTL is set to 300 (5 minutes) for faster updates

### Server Configuration:
- [ ] Application is deployed and running
- [ ] Docker containers are up: `sudo docker ps`
- [ ] Port 80 is accessible: `sudo netstat -tlnp | grep :80`
- [ ] Firewall allows HTTP: `sudo ufw status`

### Application Status:
- [ ] Nginx container is running
- [ ] Frontend container is running
- [ ] Backend container is running
- [ ] Database container is running

## 🛠️ Common DNS Record Types

| Record Type | Purpose | Example |
|-------------|---------|---------|
| A | Maps domain to IPv4 | securetechsquad.com → 139.84.222.64 |
| AAAA | Maps domain to IPv6 | securetechsquad.com → 2001:db8::1 |
| CNAME | Alias for another domain | www.securetechsquad.com → securetechsquad.com |
| MX | Email server | securetechsquad.com → mail.securetechsquad.com |

## 📞 Next Steps

1. **Check Vultr Server IP**: Compare with `139.84.222.64`
2. **Update DNS if needed**: Point to correct server IP
3. **Deploy application**: Use `./deploy-http.sh` script
4. **Wait for DNS propagation**: Can take 5-48 hours globally

## 🔄 DNS Propagation

After updating DNS records:
- **Local**: 5-15 minutes
- **Regional**: 1-6 hours  
- **Global**: 24-48 hours

You can check propagation status at: https://www.whatsmydns.net/

## 🆘 Emergency Checklist

If still not working:

1. **Verify Server**: SSH into Vultr server and check if it's running
2. **Check Application**: Ensure Docker containers are running
3. **Test Direct IP**: Try accessing `http://[your-server-ip]` directly
4. **Check Logs**: Review nginx and application logs
5. **Restart Services**: Restart Docker containers if needed

## 📧 Support

If you need help:
1. **Vultr Support**: For server/IP issues
2. **Domain Registrar**: For DNS management issues
3. **Application Logs**: Check Docker container logs for errors

---

**Current Status**: Domain resolves to `139.84.222.64` but server not responding on port 80