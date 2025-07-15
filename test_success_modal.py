#!/usr/bin/env python3
"""
Test script to verify success modal and logout functionality.
Run this script after starting the services to test the new features.
"""

import requests
import time
import json
from datetime import date

# Configuration
API_BASE_URL = "http://localhost:5000"
FRONTEND_URL = "http://localhost:3000"

def test_attendance_submission_success():
    """Test that attendance submission returns success message"""
    print("🔍 Testing attendance submission success response...")
    
    # Create a dummy JWT token for testing
    test_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJzdHVkZW50MSIsInByZWZlcnJlZF91c2VybmFtZSI6InN0dWRlbnQxIiwiZXhwIjoxNzA5MzQ3MjAwfQ.dummy_signature"
    
    headers = {
        "Authorization": f"Bearer {test_token}",
        "Content-Type": "application/json"
    }
    
    # Test attendance submission
    attendance_data = {
        "date": str(date.today()),
        "status": "Present"
    }
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/attendance",
            json=attendance_data,
            headers=headers,
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            if "message" in data:
                print(f"✅ Success message received: {data['message']}")
                return True
            else:
                print("❌ No success message in response")
                return False
        else:
            print(f"❌ Request failed with status: {response.status_code}")
            return False
            
    except requests.RequestException as e:
        print(f"❌ Request error: {e}")
        return False

def test_frontend_accessibility():
    """Test that frontend is accessible"""
    print("🔍 Testing frontend accessibility...")
    
    try:
        response = requests.get(f"{FRONTEND_URL}", timeout=5)
        if response.status_code == 200:
            print("✅ Frontend is accessible")
            return True
        else:
            print(f"❌ Frontend returned status: {response.status_code}")
            return False
    except requests.RequestException as e:
        print(f"❌ Frontend error: {e}")
        return False

def test_backend_health():
    """Test backend health endpoint"""
    print("🔍 Testing backend health...")
    
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Backend is healthy: {data}")
            return True
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return False
    except requests.RequestException as e:
        print(f"❌ Backend health error: {e}")
        return False

def main():
    """Run all tests for the updated attendance system"""
    print("🚀 Testing Updated Attendance System with Success Modal & Logout")
    print("=" * 65)
    
    # Wait for services to start
    print("⏳ Waiting for services to start...")
    time.sleep(3)
    
    tests = [
        ("Backend Health", test_backend_health),
        ("Frontend Accessibility", test_frontend_accessibility),
        ("Attendance Submission Success", test_attendance_submission_success),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n--- {test_name} ---")
        result = test_func()
        results.append((test_name, result))
        time.sleep(1)
    
    # Summary
    print("\n" + "=" * 65)
    print("📊 TEST SUMMARY")
    print("=" * 65)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{test_name}: {status}")
        if result:
            passed += 1
    
    print(f"\nTotal: {passed}/{len(tests)} tests passed")
    
    # Manual testing instructions
    print("\n" + "=" * 65)
    print("🧪 MANUAL TESTING INSTRUCTIONS")
    print("=" * 65)
    print()
    print("To test the new features manually:")
    print("1. 🌐 Open http://localhost:3000")
    print("2. 🔐 Click 'Login with Keycloak'")
    print("3. 👤 Login with: student1 / student123")
    print("4. 📝 Select attendance status and click 'Submit Attendance'")
    print("5. ✅ You should see a success modal with:")
    print("   - Green checkmark icon")
    print("   - 'Attendance Submitted Successfully!' message")
    print("   - 'Continue' button")
    print("   - 'Logout' button")
    print("6. 🔄 Click 'Continue' to close modal and stay logged in")
    print("7. 🚪 Click 'Logout' (either in modal or top-right) to logout")
    print()
    print("🎯 Expected Results:")
    print("- Success modal appears after submission")
    print("- Modal can be closed with 'Continue' button")
    print("- Logout button clears session and returns to login")
    print("- Top-right logout button works anytime")
    print("- Attendance records are still displayed correctly")
    
    if passed == len(tests):
        print("\n🎉 All automated tests passed! Ready for manual testing.")
    else:
        print("\n⚠️  Some tests failed. Check service logs:")
        print("   docker-compose logs -f")
        
    return passed == len(tests)

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)