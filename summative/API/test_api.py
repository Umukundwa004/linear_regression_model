"""
API Testing Script
Test the Bike Rental Prediction API locally
"""

import requests
import json
from typing import Dict

API_BASE_URL = "http://localhost:8005"

def test_health():
    """Test the health check endpoint"""
    print("📋 Testing Health Check Endpoint...")
    try:
        response = requests.get(f"{API_BASE_URL}/")
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}\n")
        return False


def test_single_prediction():
    """Test single prediction endpoint"""
    print("🔮 Testing Single Prediction Endpoint...")
    
    payload = {
        "date": "2012-03-15",
        "hour": 14,
        "holiday": 0,
        "weather": 1,
        "temp": 25.5,
        "humidity": 65.0,
        "windspeed": 12.5
    }
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/predict",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}\n")
        return False


def test_batch_prediction():
    """Test batch prediction endpoint"""
    print("📊 Testing Batch Prediction Endpoint...")
    
    payload = {
        "predictions": [
            {
                "date": "2012-03-15",
                "hour": 14,
                "holiday": 0,
                "weather": 1,
                "temp": 25.5,
                "humidity": 65.0,
                "windspeed": 12.5
            },
            {
                "date": "2012-06-21",
                "hour": 18,
                "holiday": 1,
                "weather": 2,
                "temp": 28.0,
                "humidity": 70.0,
                "windspeed": 15.0
            }
        ]
    }
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/predict-batch",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}\n")
        return False


def test_model_info():
    """Test model info endpoint"""
    print("ℹ️ Testing Model Info Endpoint...")
    try:
        response = requests.get(f"{API_BASE_URL}/model-info")
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {e}\n")
        return False


def test_invalid_input():
    """Test validation with invalid input"""
    print("⚠️ Testing Input Validation (Expected to fail)...")
    
    invalid_payload = {
        "date": "2012-03-15",
        "hour": 14,
        "holiday": 0,
        "weather": 5,  # Invalid! Should be 1-4
        "temp": 25.5,
        "humidity": 65.0,
        "windspeed": 12.5
    }
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/predict",
            json=invalid_payload,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}\n")
        return response.status_code == 422  # Should be validation error
    except Exception as e:
        print(f"❌ Error: {e}\n")
        return False


def main():
    """Run all tests"""
    print("=" * 60)
    print("🚴 BIKE RENTAL PREDICTION API - TEST SUITE")
    print("=" * 60 + "\n")
    
    results = {
        "Health Check": test_health(),
        "Single Prediction": test_single_prediction(),
        "Batch Prediction": test_batch_prediction(),
        "Model Info": test_model_info(),
        "Input Validation": test_invalid_input(),
    }
    
    print("=" * 60)
    print("📊 TEST SUMMARY")
    print("=" * 60)
    for test_name, result in results.items():
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{test_name}: {status}")
    
    passed = sum(results.values())
    total = len(results)
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
    else:
        print(f"\n⚠️ {total - passed} test(s) failed")


if __name__ == "__main__":
    main()
