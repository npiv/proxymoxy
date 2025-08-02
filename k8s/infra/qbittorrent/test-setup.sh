#!/bin/bash

# qBittorrent + Tailscale VPN Setup Testing Script
# This script validates that the VPN configuration is working correctly

set -e

NAMESPACE="infra"
POD_NAME=""

echo "=== qBittorrent + Tailscale VPN Setup Validation ==="
echo

# Function to get pod name
get_pod_name() {
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=qbittorrent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
}

# Function to wait for pod to be ready
wait_for_pod() {
    echo "Waiting for qBittorrent pod to be ready..."
    kubectl wait --for=condition=ready pod -l app=qbittorrent -n $NAMESPACE --timeout=300s
    get_pod_name
    echo "Pod ready: $POD_NAME"
}

# Test 1: Check if pod is running
test_pod_status() {
    echo "=== Test 1: Pod Status ==="
    get_pod_name
    
    if [[ -z "$POD_NAME" ]]; then
        echo "❌ FAIL: qBittorrent pod not found"
        return 1
    fi
    
    STATUS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.phase}')
    if [[ "$STATUS" == "Running" ]]; then
        echo "✅ PASS: Pod is running"
    else
        echo "❌ FAIL: Pod status is $STATUS"
        return 1
    fi
}

# Test 2: Check Tailscale connection
test_tailscale_connection() {
    echo "=== Test 2: Tailscale Connection ==="
    
    # Check if Tailscale is connected
    if kubectl exec $POD_NAME -n $NAMESPACE -c tailscale -- tailscale status >/dev/null 2>&1; then
        echo "✅ PASS: Tailscale is connected"
        
        # Show connection details
        echo "Tailscale status:"
        kubectl exec $POD_NAME -n $NAMESPACE -c tailscale -- tailscale status
    else
        echo "❌ FAIL: Tailscale is not connected"
        return 1
    fi
}

# Test 3: Check VPN interface
test_vpn_interface() {
    echo "=== Test 3: VPN Interface ==="
    
    if kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- ip link show tun0 >/dev/null 2>&1; then
        echo "✅ PASS: VPN interface (tun0) exists"
        
        # Show interface details
        echo "VPN interface details:"
        kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- ip addr show tun0
    else
        echo "❌ FAIL: VPN interface (tun0) not found"
        return 1
    fi
}

# Test 4: IP leak test
test_ip_leak() {
    echo "=== Test 4: IP Leak Detection ==="
    
    # Get IP through VPN interface
    VPN_IP=$(kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- curl -s --max-time 10 --interface tun0 https://ipinfo.io/ip 2>/dev/null || echo "FAILED")
    
    # Try to get IP through default interface (should fail)
    DEFAULT_IP=$(kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- curl -s --max-time 5 https://ipinfo.io/ip 2>/dev/null || echo "BLOCKED")
    
    echo "VPN IP: $VPN_IP"
    echo "Default route IP: $DEFAULT_IP"
    
    if [[ "$VPN_IP" != "FAILED" ]] && [[ "$DEFAULT_IP" == "BLOCKED" ]]; then
        echo "✅ PASS: No IP leak detected - all traffic through VPN"
    elif [[ "$VPN_IP" == "FAILED" ]]; then
        echo "❌ FAIL: Cannot get IP through VPN interface"
        return 1
    elif [[ "$DEFAULT_IP" != "BLOCKED" ]]; then
        echo "⚠️  WARNING: Possible IP leak - default interface accessible"
        echo "   This might be expected in some network configurations"
    fi
}

# Test 5: DNS leak test
test_dns_leak() {
    echo "=== Test 5: DNS Configuration ==="
    
    # Check DNS configuration
    echo "DNS configuration:"
    kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- cat /etc/resolv.conf
    
    # Test DNS resolution through VPN
    if kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- nslookup google.com >/dev/null 2>&1; then
        echo "✅ PASS: DNS resolution working"
    else
        echo "❌ FAIL: DNS resolution not working"
        return 1
    fi
}

# Test 6: qBittorrent web UI accessibility
test_web_ui() {
    echo "=== Test 6: qBittorrent Web UI ==="
    
    # Test internal access
    if kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- curl -s --max-time 10 http://localhost:8080 >/dev/null 2>&1; then
        echo "✅ PASS: qBittorrent web UI accessible internally"
    else
        echo "❌ FAIL: qBittorrent web UI not accessible internally"
        return 1
    fi
    
    # Test cluster access via service
    echo "Testing cluster service access..."
    kubectl run test-pod --rm -i --tty --image=busybox --restart=Never -- /bin/sh -c "wget -qO- --timeout=10 http://qbittorrent-internal.infra.svc.cluster.local:8080" >/dev/null 2>&1 && echo "✅ PASS: Service accessible from cluster" || echo "❌ FAIL: Service not accessible from cluster"
}

# Test 7: Exit node verification
test_exit_node() {
    echo "=== Test 7: Exit Node Verification ==="
    
    # Get current exit node
    EXIT_NODE_INFO=$(kubectl exec $POD_NAME -n $NAMESPACE -c tailscale -- tailscale status --json | grep -o '"ExitNodeStatus":[^}]*}' || echo "")
    
    if [[ -n "$EXIT_NODE_INFO" ]]; then
        echo "Exit node information:"
        echo "$EXIT_NODE_INFO"
        echo "✅ PASS: Exit node information available"
    else
        echo "⚠️  WARNING: Exit node information not found"
    fi
    
    # Check if we're using Mullvad
    EXTERNAL_IP_INFO=$(kubectl exec $POD_NAME -n $NAMESPACE -c qbittorrent -- curl -s --max-time 10 --interface tun0 https://ipinfo.io/json 2>/dev/null || echo "{}")
    
    echo "External IP information:"
    echo "$EXTERNAL_IP_INFO"
    
    if echo "$EXTERNAL_IP_INFO" | grep -i mullvad >/dev/null 2>&1; then
        echo "✅ PASS: Using Mullvad exit node"
    else
        echo "⚠️  INFO: Check if you're using the intended exit node"
    fi
}

# Test 8: Container health checks
test_health_checks() {
    echo "=== Test 8: Container Health Checks ==="
    
    # Check liveness probes
    TAILSCALE_READY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.containerStatuses[?(@.name=="tailscale")].ready}')
    QBITTORRENT_READY=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.containerStatuses[?(@.name=="qbittorrent")].ready}')
    
    if [[ "$TAILSCALE_READY" == "true" ]]; then
        echo "✅ PASS: Tailscale container healthy"
    else
        echo "❌ FAIL: Tailscale container not ready"
    fi
    
    if [[ "$QBITTORRENT_READY" == "true" ]]; then
        echo "✅ PASS: qBittorrent container healthy" 
    else
        echo "❌ FAIL: qBittorrent container not ready"
    fi
}

# Main execution
main() {
    echo "Starting validation tests..."
    echo
    
    # Wait for pod to be ready
    wait_for_pod
    
    # Run all tests
    FAILED_TESTS=0
    
    test_pod_status || ((FAILED_TESTS++))
    echo
    
    test_tailscale_connection || ((FAILED_TESTS++))
    echo
    
    test_vpn_interface || ((FAILED_TESTS++))
    echo
    
    test_ip_leak || ((FAILED_TESTS++))
    echo
    
    test_dns_leak || ((FAILED_TESTS++))
    echo
    
    test_web_ui || ((FAILED_TESTS++))
    echo
    
    test_exit_node || ((FAILED_TESTS++))
    echo
    
    test_health_checks || ((FAILED_TESTS++))
    echo
    
    # Summary
    echo "=== Test Summary ==="
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "🎉 ALL TESTS PASSED! Your qBittorrent + Tailscale VPN setup is working correctly."
    else
        echo "❌ $FAILED_TESTS test(s) failed. Please check the output above for details."
        exit 1
    fi
}

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
fi

# Run main function
main