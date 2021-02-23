function FindProxyForUrl(url, host) {
    if (url === host) {
        return "DIRECT";
    } else {
        return "PROXY https://localhost:5001";
    }
}
